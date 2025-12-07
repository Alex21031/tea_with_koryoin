import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

Future<Response> onRequest(RequestContext context) async {
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

    // 1. 이미 좋아요를 눌렀는지 확인
    final check = await pool.execute(
      Sql.named('SELECT id FROM likes WHERE user_id = @uid AND post_id = @pid'),
      parameters: {'uid': userId, 'pid': postId},
    );

    bool isLiked = false;

    if (check.isNotEmpty) {
      // 2-A. 이미 눌렀으면 -> 좋아요 취소 (삭제)
      await pool.execute(
        Sql.named('DELETE FROM likes WHERE user_id = @uid AND post_id = @pid'),
        parameters: {'uid': userId, 'pid': postId},
      );
      // 게시판 테이블 카운트 감소
      await pool.execute(
        Sql.named('UPDATE posts SET likes = likes - 1 WHERE id = @pid'),
        parameters: {'pid': postId},
      );
      isLiked = false;
    } else {
      // 2-B. 안 눌렀으면 -> 좋아요 추가
      await pool.execute(
        Sql.named('INSERT INTO likes (user_id, post_id) VALUES (@uid, @pid)'),
        parameters: {'uid': userId, 'pid': postId},
      );
      // 게시판 테이블 카운트 증가
      await pool.execute(
        Sql.named('UPDATE posts SET likes = likes + 1 WHERE id = @pid'),
        parameters: {'pid': postId},
      );
      isLiked = true;
    }

    // 최신 좋아요 개수 가져오기
    final countResult = await pool.execute(
      Sql.named('SELECT likes FROM posts WHERE id = @pid'),
      parameters: {'pid': postId},
    );
    final currentCount = countResult.first[0] as int;

    return Response.json(statusCode: 200, body: {
      'success': true,
      'is_liked': isLiked,
      'like_count': currentCount
    });

  } catch (e) {
    return Response.json(statusCode: 500, body: {'error': '오류: $e'});
  }
}