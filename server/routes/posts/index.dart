import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

Future<Response> onRequest(RequestContext context) async {
  final method = context.request.method;

  if (method == HttpMethod.get) {
    return _getPosts(context);
  } else if (method == HttpMethod.post) {
    return _createPost(context);
  } else {
    return Response.json(statusCode: 405, body: {'error': 'Method not allowed'});
  }
}

// ==========================================
// 1. 게시물 조회 (GET) - 유저별 필터 추가됨
// ==========================================
Future<Response> _getPosts(RequestContext context) async {
  try {
    final pool = context.read<Pool>();
    final params = context.request.uri.queryParameters;

    final page = int.tryParse(params['page'] ?? '1') ?? 1;
    final category = params['category'];
    final keyword = params['q'];
    // ✅ [추가] 특정 유저의 글만 보기 위한 파라미터
    final userIdParam = params['user_id']; 

    final limit = 10;
    final offset = (page - 1) * limit;

    var query = 'SELECT * FROM posts WHERE 1=1';
    final Map<String, dynamic> queryParams = {};

    if (category != null && category.isNotEmpty) {
      query += ' AND category = @category';
      queryParams['category'] = category;
    }

    if (keyword != null && keyword.isNotEmpty) {
      query += ' AND (title ILIKE @keyword OR content ILIKE @keyword)';
      queryParams['keyword'] = '%$keyword%';
    }

    // ✅ [추가] 유저 ID 필터링 로직
    if (userIdParam != null && userIdParam.isNotEmpty) {
      query += ' AND user_id = @userId';
      queryParams['userId'] = int.parse(userIdParam);
    }

    query += ' ORDER BY created_at DESC LIMIT $limit OFFSET $offset';

    final result = await pool.execute(Sql.named(query), parameters: queryParams);

    // DateTime 변환 및 결과 반환
    final posts = result.map((row) {
      final map = row.toColumnMap();
      return map.map((key, value) {
        if (value is DateTime) {
          return MapEntry(key, value.toIso8601String());
        }
        return MapEntry(key, value);
      });
    }).toList();

    return Response.json(body: {'posts': posts});

  } catch (e) {
    print('🚨 게시물 조회 중 오류 발생: $e');
    return Response.json(statusCode: 500, body: {'error': '게시물을 불러오는 중 오류가 발생했습니다: $e'});
  }
}

// ==========================================
// 2. 게시물 작성 (POST)
// ==========================================
Future<Response> _createPost(RequestContext context) async {
  final Map<int, String> boardCategoryMap = {
    1: 'free',
    2: 'expert',
    3: 'job',
    4: 'promotion',
  };

  try {
    final pool = context.read<Pool>();
    final body = await context.request.json() as Map<String, dynamic>;
    
    final authorId = body['author_id'] as int?; 
    final boardId = body['board_id'] as int?; 
    final title = body['title'] as String?;
    final content = body['content'] as String?;

    if (authorId == null || boardId == null || title == null || content == null) {
      return Response.json(statusCode: 400, body: {'error': '필수 데이터가 누락되었습니다.'});
    }

    final categoryString = boardCategoryMap[boardId];

    if (categoryString == null) {
       return Response.json(statusCode: 400, body: {'error': '유효하지 않은 게시판 ID입니다.'});
    }

    if (boardId == 2) {
      final userResult = await pool.execute(
        Sql.named('SELECT role FROM users WHERE id = @id'),
        parameters: {'id': authorId},
      );
      
      if (userResult.isEmpty) {
         return Response.json(statusCode: 400, body: {'error': '존재하지 않는 사용자입니다.'});
      }

      final userRole = userResult.first[0] as String?;
      if (userRole != 'expert') {
        return Response.json(statusCode: 403, body: {'error': '전문가만 작성 가능합니다.'});
      }
    }
    
    await pool.execute(
      Sql.named('''
        INSERT INTO posts (title, content, user_id, category, created_at, updated_at) 
        VALUES (@title, @content, @authorId, @category, NOW(), NOW())
      '''),
      parameters: {
        'title': title,
        'content': content,
        'authorId': authorId,
        'category': categoryString,
      },
    );

    return Response.json(statusCode: 201, body: {'success': true, 'message': '작성 완료'});

  } catch (e) {
    print('🚨 게시물 작성 중 오류: $e');
    return Response.json(statusCode: 500, body: {'error': '서버 오류: $e'});
  }
}