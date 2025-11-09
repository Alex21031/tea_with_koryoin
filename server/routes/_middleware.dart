import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';


final _pool = Pool.withEndpoints(
  [
    Endpoint(
      host: 'localhost',
      port: 5432,
      database: 'postgres',
      username: 'postgres',
      password: 'imt2374835@',
    ),
  ],
  settings: PoolSettings(
    maxConnectionCount: 4,
    sslMode: SslMode.disable,
  ),
);


Handler middleware(Handler handler) {
  final handlerWithPool = handler.use(
    provider<Pool>(
      (context) => _pool,
    ),
  );

  // 2. 위에서 만든 handlerWithPool을 로깅 미들웨어로 감쌉니다.
  return (RequestContext context) async {
    final request = context.request;
    final method = request.method.value;
    final path = request.uri.path;

    // 3. 요청 로그
    print('===> [Request] $method $path');

    // 4. DB Pool이 적용된 핸들러(handlerWithPool)를 실행합니다.
    final response = await handlerWithPool(context);

    // 5. 응답 로그
    final statusCode = response.statusCode;
    print('<=== [Response] $method $path - $statusCode');

    return response;
  };
}