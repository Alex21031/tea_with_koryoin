import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: 405,
      body: {'error': 'Method not allowed'},
    );
  }

  try {
    final pool = context.read<Pool>();
    final params = context.request.uri.queryParameters;
    
    final page = int.tryParse(params['page'] ?? '1') ?? 1;
    final limit = 10;
    final offset = (page - 1) * limit;

    // 전체 게시물 수 조회
    final countResult = await pool.execute(
      Sql.named('SELECT COUNT(*) FROM posts'),
    );
    final totalPosts = countResult.first[0] as int;
    final totalPages = (totalPosts / limit).ceil();

    // 게시물 목록 조회 (최신순)
    final result = await pool.execute(
      Sql.named('''
        SELECT p.id, p.title, p.content, p.created_at, 
               u.username, u.id as user_id
        FROM posts p
        JOIN users u ON p.user_id = u.id
        ORDER BY p.created_at DESC
        LIMIT @limit OFFSET @offset
      '''),
      parameters: {
        'limit': limit,
        'offset': offset,
      },
    );

    final posts = result.map((row) => {
      'id': row[0],
      'title': row[1],
      'content': row[2],
      'created_at': row[3].toString(),
      'author': row[4],
      'author_id': row[5],
    }).toList();

    return Response.json(
      statusCode: 200,
      body: {
        'success': true,
        'posts': posts,
        'pagination': {
          'current_page': page,
          'total_pages': totalPages,
          'total_posts': totalPosts,
          'has_next': page < totalPages,
          'has_prev': page > 1,
        },
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'error': '서버 오류가 발생했습니다: $e'},
    );
  }
}