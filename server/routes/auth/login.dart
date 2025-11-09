import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:crypto/crypto.dart';

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

    final email = body['email'] as String?;
    final password = body['password'] as String?;

    if (email == null || password == null) {
      return Response.json(
        statusCode: 400,
        body: {'error': '이메일과 비밀번호를 입력해주세요.'},
      );
    }

    final hashedPassword = sha256.convert(utf8.encode(password)).toString();

    final result = await pool.execute(
      Sql.named('''
        SELECT id, email, username, phone, created_at
        FROM users
        WHERE email = @email AND password = @password
      '''),
      parameters: {
        'email': email,
        'password': hashedPassword,
      },
    );

    if (result.isEmpty) {
      return Response.json(
        statusCode: 401,
        body: {'error': '이메일 또는 비밀번호가 올바르지 않습니다.'},
      );
    }

    final user = result.first;

    return Response.json(
      statusCode: 200,
      body: {
        'success': true,
        'message': '로그인 성공',
        'user': {
          'id': user[0],
          'email': user[1],
          'username': user[2],
          'phone': user[3],
          'created_at': user[4].toString(),
        },
        'token': 'dummy_token_${user[0]}',
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'error': '서버 오류가 발생했습니다: $e'},
    );
  }
}