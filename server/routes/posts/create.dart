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

    final result = await pool.execute(
      Sql.named('''
        INSERT INTO posts (user_id, title, content, created_at)
        VALUES (@user_id, @title, @content, NOW())
        RETURNING id, title, content, created_at
      '''),
      parameters: {
        'user_id': userId,
        'title': title,
        'content': content,
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
          'created_at': post[3].toString(),
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