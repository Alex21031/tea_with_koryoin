import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response.json(
      statusCode: 405,
      body: {'error': 'Method not allowed'},
    );
  }

  try {
    final pool = context.read<Pool>();
    final body = await context.request.json() as Map<String, dynamic>;

    final userId = body['user_id'] as int?;
    final title = body['title'] as String?;
    final content = body['content'] as String?;
    final category = body['category'] as String? ?? 'free'; 

    if (userId == null || title == null || content == null) {
      return Response.json(
        statusCode: 400,
        body: {'error': '제목과 내용은 필수입니다.'},
      );
    }

    if (title.trim().isEmpty || content.trim().isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {'error': '제목과 내용을 입력해주세요.'},
      );
    }

    // [수정 2] SQL 쿼리에 category 컬럼과 값을 추가했습니다.
    final result = await pool.execute(
      Sql.named('''
        INSERT INTO posts (user_id, title, content, category, created_at)
        VALUES (@user_id, @title, @content, @category, NOW())
        RETURNING id, title, content, category, created_at
      '''),
      parameters: {
        'user_id': userId,
        'title': title,
        'content': content,
        'category': category, // [수정 3] 파라미터에 카테고리 추가
      },
    );

    final post = result.first;

    return Response.json(
      statusCode: 201,
      body: {
        'success': true,
        'message': '게시물이 작성되었습니다.',
        'post': {
          'id': post[0],
          'title': post[1],
          'content': post[2],
          'category': post[3], // 응답에도 카테고리 포함
          'created_at': post[4].toString(),
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