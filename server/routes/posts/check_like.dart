import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

Future<Response> onRequest(RequestContext context) async {
  // GET 또는 POST 허용 (편의상 POST로 구현)
  if (context.request.method != HttpMethod.post) {
    return Response.json(statusCode: 405, body: {'error': 'Method not allowed'});
  }

  try {
    final pool = context.read<Pool>();
    final body = await context.request.json() as Map<String, dynamic>;

    final postId = body['post_id'] as int?;
    final userId = body['user_id'] as int?;

    if (postId == null || userId == null) {
      return Response.json(statusCode: 400, body: {'error': '데이터 누락'});
    }

    // 1. 좋아요 여부 확인
    final likeResult = await pool.execute(
      Sql.named('SELECT id FROM likes WHERE user_id = @uid AND post_id = @pid'),
      parameters: {'uid': userId, 'pid': postId},
    );
    final bool isLiked = likeResult.isNotEmpty;

    // 2. 최신 좋아요 개수 확인 (다른 사람이 눌렀을 수도 있으므로)
    final countResult = await pool.execute(
      Sql.named('SELECT likes FROM posts WHERE id = @pid'),
      parameters: {'pid': postId},
    );
    
    // 게시글이 삭제되었을 경우 대비
    if (countResult.isEmpty) {
      return Response.json(statusCode: 404, body: {'error': '게시글 없음'});
    }

    final int likeCount = countResult.first[0] as int;

    return Response.json(statusCode: 200, body: {
      'success': true,
      'is_liked': isLiked,
      'like_count': likeCount,
    });

  } catch (e) {
    return Response.json(statusCode: 500, body: {'error': '오류: $e'});
  }
}