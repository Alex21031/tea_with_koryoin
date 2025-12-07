import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.delete) {
    return Response.json(statusCode: 405, body: {'error': 'Method not allowed'});
  }

  try {
    final pool = context.read<Pool>();
    final body = await context.request.json() as Map<String, dynamic>;

    final postId = body['post_id'] as int?;
    final userId = body['user_id'] as int?; // 요청하는 사람 ID

    if (postId == null || userId == null) {
      return Response.json(statusCode: 400, body: {'error': '잘못된 요청입니다.'});
    }

    // 작성자인지 확인하고 삭제
    final result = await pool.execute(
      Sql.named('DELETE FROM posts WHERE id = @postId AND user_id = @userId'),
      parameters: {'postId': postId, 'userId': userId},
    );

    if (result.affectedRows == 0) {
      return Response.json(statusCode: 403, body: {'error': '삭제 권한이 없거나 게시물이 없습니다.'});
    }

    return Response.json(statusCode: 200, body: {'success': true});
  } catch (e) {
    return Response.json(statusCode: 500, body: {'error': '서버 오류: $e'});
  }
}