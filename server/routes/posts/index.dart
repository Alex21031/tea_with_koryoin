import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

Future<Response> onRequest(RequestContext context) async {
  // 1. GET 요청 확인
  if (context.request.method != HttpMethod.get) {
    return Response.json(statusCode: 405, body: {'error': 'Method not allowed'});
  }

  try {
    final pool = context.read<Pool>();
    final params = context.request.uri.queryParameters;
    
    // 2. 파라미터 파싱
    final page = int.tryParse(params['page'] ?? '1') ?? 1;
    final category = params['category']; 
    final keyword = params['q'];        
    
    final limit = 10;
    final offset = (page - 1) * limit;

    // [디버깅 로그] 요청 들어온 파라미터 확인
    print('--- [GET /posts 요청] ---');
    print('Page: $page, Category: $category, Keyword: $keyword');

    // 3. 동적 쿼리 조건 생성
    List<String> conditions = [];
    Map<String, dynamic> sqlParams = {'limit': limit, 'offset': offset};

    // 카테고리 필터 (전체가 아닐 때만)
    if (category != null && category != '전체' && category.isNotEmpty) {
      conditions.add('p.category = @category');
      sqlParams['category'] = category;
    }

    // 검색어 필터
    if (keyword != null && keyword.isNotEmpty) {
      conditions.add('(p.title ILIKE @keyword OR p.content ILIKE @keyword)');
      sqlParams['keyword'] = '%$keyword%';
    }

    String whereClause = conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';

    // 4. 쿼리 실행 (LEFT JOIN 사용: 유저 정보가 없어도 글은 가져옴)
    // COALESCE(u.username, '알수없음'): 유저가 삭제되었으면 '알수없음'으로 표시
    final result = await pool.execute(
      Sql.named('''
        SELECT p.id, p.title, p.content, p.created_at, p.views, p.likes, p.comment_count, p.category,
               COALESCE(u.username, '알수없음') as username, 
               COALESCE(u.role, 'general') as role, 
               p.user_id
        FROM posts p
        LEFT JOIN users u ON p.user_id = u.id
        $whereClause
        ORDER BY p.created_at DESC
        LIMIT @limit OFFSET @offset
      '''),
      parameters: sqlParams,
    );

    // [디버깅 로그] 조회된 개수 확인
    print('조회된 게시글 수: ${result.length}');

    final posts = result.map((row) => {
      'id': row[0],
      'title': row[1],
      'content': row[2],
      'created_at': row[3].toString(),
      'views': row[4] ?? 0,
      'likes': row[5] ?? 0,
      'comment_count': row[6] ?? 0,
      'category': row[7] ?? '자유 게시판',
      'author': row[8],     // username
      'author_role': row[9], // role
      'author_id': row[10], // user_id
    }).toList();

    return Response.json(statusCode: 200, body: {'success': true, 'posts': posts});
  } catch (e) {
    // [디버깅 로그] 에러 발생 시
    print('에러 발생: $e');
    return Response.json(statusCode: 500, body: {'error': e.toString()});
  }
}