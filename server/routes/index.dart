// routes/index.dart
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart' as pg; // 'as pg' 접두사 유지

Future<Response> onRequest(RequestContext context) async {
  // 3. 'await'을 제거! Pool을 동기적으로 읽어옴
  final pool = context.read<pg.Pool<void>>();

  // 4. 쿼리를 실행하는 'withConnection' 부분은 비동기이므로 'await' 유지
  final result = await pool.withConnection(
    (connection) => connection.execute(
      pg.Sql.named('SELECT * FROM users WHERE id = @id'),
      parameters: {'id': 1},
    ),
  );

  // ... (이후 쿼리 결과 처리 코드는 동일)
  if (result.isEmpty) {
    return Response(statusCode: 404, body: 'User not found');
  }

  final user = result.first.toColumnMap();
  return Response.json(body: user);
}