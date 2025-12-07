import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

Future<Response> onRequest(RequestContext context) async {
  // 1. POST 요청만 허용
  if (context.request.method != HttpMethod.post) {
    return Response.json(statusCode: 405, body: {'error': 'Method not allowed'});
  }

  try {
    final pool = context.read<Pool>();
    final body = await context.request.json() as Map<String, dynamic>;

    // 2. 데이터 추출
    // 프론트엔드에서 보내주는 키 이름: post_id, user_id, content
    final postId = body['post_id'] as int?;
    final userId = body['user_id'] as int?;
    final content = body['content'] as String?;

    // 3. 필수 데이터 검증
    if (postId == null || userId == null || content == null || content.trim().isEmpty) {
      return Response.json(statusCode: 400, body: {'error': '댓글 내용이나 정보가 누락되었습니다.'});
    }

    // 4. DB 저장 (INSERT INTO comments)
    // 보여주신 DB 스크린샷에 맞춰 컬럼명을 지정했습니다.
    await pool.execute(
      Sql.named('''
        INSERT INTO comments (post_id, user_id, content, created_at) 
        VALUES (@postId, @userId, @content, NOW())
      '''),
      parameters: {
        'postId': postId,
        'userId': userId,
        'content': content,
      },
    );

    await pool.execute(
      Sql.named('UPDATE posts SET comment_count = comment_count + 1 WHERE id = @postId'),
      parameters: {'postId': postId},
    );

    return Response.json(
      statusCode: 201, 
      body: {'success': true, 'message': '댓글이 작성되었습니다.'}
    );

  } catch (e) {
    print('🚨 댓글 작성 중 오류: $e'); // 서버 터미널에 에러 출력
    return Response.json(statusCode: 500, body: {'error': '서버 오류: $e'});
  }
}