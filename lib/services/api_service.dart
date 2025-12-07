import 'dart:convert';
import 'dart:io'; 
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/post.dart';

class ApiService {
  // 안드로이드 에뮬레이터: 10.0.2.2, iOS: localhost, 실기기: PC IP
  static const String baseUrl = 'http://10.0.2.2:8080';

  // 헤더 생성 도우미
  Map<String, String> _headers({String? token}) {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // 로그인
  Future<User> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers(),
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return User.fromJson(data['user'], token: data['token']);
    } else {
      throw Exception(jsonDecode(response.body)['error']);
    }
  }

  // 회원가입
  Future<void> signup({
    required String email,
    required String name,
    required String username,
    required String phone,
    required String password,
    File? certificateFile,
  }) async {
    final url = Uri.parse('$baseUrl/auth/signup');
    var request = http.MultipartRequest('POST', url);

    request.fields['email'] = email;
    request.fields['name'] = name;
    request.fields['username'] = username;
    request.fields['phone'] = phone;
    request.fields['password'] = password;

    if (certificateFile != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'certificate', 
        certificateFile.path,
      ));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 201) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? '회원가입 실패');
    }
  }

  // 게시물 목록 조회 (유저 ID 필터 포함)
  Future<List<Post>> getPosts(int page, {String? category, String? keyword, int? userId}) async {
    String url = '$baseUrl/posts?page=$page';
    
    if (category != null && category.isNotEmpty) {
      url += '&category=$category';
    }
    if (keyword != null && keyword.isNotEmpty) {
      url += '&q=$keyword';
    }
    // 내 글 보기 기능용 파라미터
    if (userId != null) {
      url += '&user_id=$userId';
    }

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> postsJson = data['posts'];
      return postsJson.map((json) => Post.fromJson(json)).toList();
    } else {
      throw Exception('게시물을 불러오지 못했습니다.');
    }
  }

  // 게시물 작성
  Future<void> createPost({
    required String title,
    required String content,
    required int authorId,
    required int boardId, 
  }) async {
    final url = Uri.parse('$baseUrl/posts');
    final response = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({
        'author_id': authorId,
        'title': title,
        'content': content,
        'board_id': boardId,
      }),
    );

    if (response.statusCode == 403) {
      throw Exception('권한이 없습니다 (전문가 등급 필요).');
    } else if (response.statusCode != 201) {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? '게시물 작성 실패');
    }
  }

  // 댓글 목록 조회
  Future<List<Comment>> getComments(int postId) async {
    final response = await http.get(Uri.parse('$baseUrl/comments/read?post_id=$postId'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['comments'] as List).map((json) => Comment.fromJson(json)).toList();
    } else {
      throw Exception('댓글 로드 실패');
    }
  }

  // 댓글 작성
  Future<void> createComment(int postId, int userId, String content) async {
    final response = await http.post(
      Uri.parse('$baseUrl/comments/create'),
      headers: _headers(),
      body: jsonEncode({
        'post_id': postId, 
        'user_id': userId, 
        'content': content
      }),
    );
    if (response.statusCode != 201) throw Exception('댓글 작성 실패');
  }

  // 사용자 정보 수정
  Future<User> updateUser({
    required int userId,
    String? name,
    String? username,
    String? phone,
    String? currentPassword,
    String? newPassword,
  }) async {
    final body = {
      'user_id': userId,
      if (name != null) 'name': name,
      if (username != null) 'username': username,
      if (phone != null) 'phone': phone,
      if (currentPassword != null) 'current_password': currentPassword,
      if (newPassword != null) 'new_password': newPassword,
    };

    final response = await http.put(
      Uri.parse('$baseUrl/users/update'),
      headers: _headers(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return User.fromJson(data['user']);
    } else {
      throw Exception(jsonDecode(response.body)['error']);
    }
  }

  // 전문가 인증 신청
  Future<void> requestExpertVerification({
    required int userId, 
    required File file,
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/expert/request');
    var request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['user_id'] = userId.toString();
    request.files.add(await http.MultipartFile.fromPath('certificate', file.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 201) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? '신청 실패');
    }
  }

  // ✅ [수정 완료] 게시물 삭제 (클래스 내부로 이동됨)
  Future<void> deletePost(int postId, int userId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/posts/delete'),
      headers: _headers(),
      body: jsonEncode({'post_id': postId, 'user_id': userId}),
    );

    if (response.statusCode != 200) {
      throw Exception('삭제 실패: ${response.body}');
    }
  }

  // ✅ [수정 완료] 좋아요 토글 (클래스 내부로 이동됨)
  Future<Map<String, dynamic>> likePost(int postId, int userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/posts/like'),
      headers: _headers(),
      body: jsonEncode({'post_id': postId, 'user_id': userId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body); 
    } else {
      throw Exception('좋아요 요청 실패');
    }
  }


  Future<Map<String, dynamic>> checkLikeStatus(int postId, int userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/posts/check_like'),
      headers: _headers(),
      body: jsonEncode({'post_id': postId, 'user_id': userId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body); // {'is_liked': true, 'like_count': 5}
    } else {
      throw Exception('좋아요 상태 확인 실패');
    }
  }
}