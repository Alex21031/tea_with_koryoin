import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) return Response.json(statusCode: 405);

  try {
    final pool = context.read<Pool>();
    final params = context.request.uri.queryParameters;
    final postId = int.tryParse(params['post_id'] ?? '');

    if (postId == null) return Response.json(statusCode: 400, body: {'error': 'post_id is required'});

    final result = await pool.execute(
      Sql.named('''
        SELECT c.id, c.content, c.created_at, u.username
        FROM comments c
        JOIN users u ON c.user_id = u.id
        WHERE c.post_id = @pid
        ORDER BY c.created_at ASC
      '''),
      parameters: {'pid': postId},
    );

    final comments = result.map((row) => {
      'id': row[0],
      'content': row[1],
      'created_at': row[2].toString(),
      'username': row[3],
    }).toList();

    return Response.json(statusCode: 200, body: {'comments': comments});
  } catch (e) {
    return Response.json(statusCode: 500, body: {'error': e.toString()});
  }
}