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
    final username = body['username'] as String?;
    final phone = body['phone'] as String?;

    if (email == null || password == null || username == null || phone == null) {
      return Response.json(
        statusCode: 400,
        body: {'error': '이메일, 비밀번호, 사용자명, 전화번호는 필수입니다.'},
      );
    }

    // 이메일 중복 확인
    final emailCheck = await pool.execute(
      Sql.named('SELECT id FROM users WHERE email = @email'),
      parameters: {'email': email},
    );

    if (emailCheck.isNotEmpty) {
      return Response.json(
        statusCode: 409,
        body: {'error': '이미 존재하는 이메일입니다.'},
      );
    }

    // 사용자명 중복 확인
    final usernameCheck = await pool.execute(
      Sql.named('SELECT id FROM users WHERE username = @username'),
      parameters: {'username': username},
    );

    if (usernameCheck.isNotEmpty) {
      return Response.json(
        statusCode: 409,
        body: {'error': '이미 존재하는 사용자명입니다.'},
      );
    }

    // 전화번호 중복 확인
    final phoneCheck = await pool.execute(
      Sql.named('SELECT id FROM users WHERE phone = @phone'),
      parameters: {'phone': phone},
    );

    if (phoneCheck.isNotEmpty) {
      return Response.json(
        statusCode: 409,
        body: {'error': '이미 존재하는 전화번호입니다.'},
      );
    }

    final hashedPassword = sha256.convert(utf8.encode(password)).toString();

    final result = await pool.execute(
      Sql.named('''
        INSERT INTO users (email, password, username, phone, created_at)
        VALUES (@email, @password, @username, @phone, NOW())
        RETURNING id, email, username, phone, created_at
      '''),
      parameters: {
        'email': email,
        'password': hashedPassword,
        'username': username,
        'phone': phone,
      },
    );

    final user = result.first;

    return Response.json(
      statusCode: 201,
      body: {
        'success': true,
        'message': '회원가입이 완료되었습니다.',
        'user': {
          'id': user[0],
          'email': user[1],
          'username': user[2],
          'phone': user[3],
          'created_at': user[4].toString(),
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