import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

Future<Response> onRequest(RequestContext context) async {
  // 1. POST 요청만 허용
  if (context.request.method != HttpMethod.post) {
    return Response.json(
      statusCode: 405,
      body: {'error': 'Method not allowed'},
    );
  }

  try {
    final pool = context.read<Pool>();
    final body = await context.request.json() as Map<String, dynamic>;

    // 2. 데이터 파싱
    final userId = body['user_id'] as int?;
    final title = body['title'] as String?;
    final content = body['content'] as String?;
    final category = body['category'] as String? ?? '자유 게시판'; // 없으면 기본값

    // 3. 기본 유효성 검사
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

    // 4. [보안] 전문가 게시판 권한 확인 로직
    if (category == '전문가 게시판') {
      // DB에서 유저의 실제 역할(role) 조회
      final userResult = await pool.execute(
        Sql.named('SELECT role FROM users WHERE id = @uid'),
        parameters: {'uid': userId},
      );

      if (userResult.isEmpty) {
        return Response.json(statusCode: 404, body: {'error': '사용자를 찾을 수 없습니다.'});
      }

      final userRole = userResult.first[0] as String?;
      
      // 역할이 'expert'가 아니면 거부 (403 Forbidden)
      if (userRole != 'expert') {
        return Response.json(
          statusCode: 403, 
          body: {'error': '전문가 등급만 작성할 수 있습니다.'}
        );
      }
    }

    // 5. DB 저장 (카테고리 컬럼 추가됨)
    final result = await pool.execute(
      Sql.named('''
        INSERT INTO posts (user_id, title, content, category, created_at, views, likes, comment_count)
        VALUES (@user_id, @title, @content, @category, NOW(), 0, 0, 0)
        RETURNING id, title, content, category, created_at
      '''),
      parameters: {
        'user_id': userId,
        'title': title,
        'content': content,
        'category': category,
      },
    );

    final post = result.first;

    // 6. 성공 응답
    return Response.json(
      statusCode: 201,
      body: {
        'success': true,
        'message': '게시물이 작성되었습니다.',
        'post': {
          'id': post[0],
          'title': post[1],
          'content': post[2],
          'category': post[3],
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