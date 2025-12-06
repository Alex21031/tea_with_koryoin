import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/post.dart';

class ApiService {
  // 안드로이드 에뮬레이터용 주소
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
  Future<void> signup(String email, String username, String phone, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/signup'),
      headers: _headers(),
      body: jsonEncode({
        'email': email,
        'username': username,
        'phone': phone,
        'password': password,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception(jsonDecode(response.body)['error']);
    }
  }

  // 게시물 목록 조회
  Future<List<Post>> getPosts(int page, {String? category, String? keyword}) async {
    String url = '$baseUrl/posts?page=$page';
    if (category != null && category.isNotEmpty) {
      url += '&category=$category';
    }
    if (keyword != null && keyword.isNotEmpty) {
      url += '&q=$keyword';
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

  // 게시물 작성 (카테고리 포함)
  Future<void> createPost(int userId, String title, String content, String category) async {
    final response = await http.post(
      Uri.parse('$baseUrl/posts/create'),
      headers: _headers(),
      body: jsonEncode({
        'user_id': userId,
        'title': title,
        'content': content,
        'category': category,
      }),
    );

    if (response.statusCode == 403) {
      throw Exception('전문가만 작성할 수 있는 게시판입니다.');
    } else if (response.statusCode != 201) {
      throw Exception(jsonDecode(response.body)['error'] ?? '게시물 작성 실패');
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
      body: jsonEncode({'post_id': postId, 'user_id': userId, 'content': content}),
    );
    if (response.statusCode != 201) throw Exception('댓글 작성 실패');
  }

  // [중요] 사용자 정보 수정 (이 메서드가 닫는 괄호 안에 있어야 함)
  Future<User> updateUser({
    required int userId,
    String? username,
    String? phone,
    String? currentPassword,
    String? newPassword,
  }) async {
    final body = {
      'user_id': userId,
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
} 