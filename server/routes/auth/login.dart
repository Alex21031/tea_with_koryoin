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

    // [최종 수정] SELECT 문에 certificate_path와 role 컬럼을 추가했습니다.
    final result = await pool.execute(
      Sql.named('''
        SELECT 
          id, 
          email, 
          name, 
          username, 
          phone, 
          created_at,
          certificate_path,  -- << 추가: 전문가 요청 상태 확인용
          role              -- << 추가: 전문가 역할 확인용
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

    // PostgreSQL 결과 인덱스:
    // 0: id, 1: email, 2: name, 3: username, 4: phone, 5: created_at
    // 6: certificate_path, 7: role

    return Response.json(
      statusCode: 200,
      body: {
        'success': true,
        'message': '로그인 성공',
        'user': {
          'id': user[0],
          'email': user[1],
          'name': user[2],
          'username': user[3],
          'phone': user[4],
          'created_at': user[5].toString(),
          'certificate_path': user[6], // << 추가: 심사 중 플래그
          'role': user[7],             // << 추가: 역할
        },
        'token': 'dummy_token_${user[0]}',
      },
    );
  } catch (e) {
    // 서버 로그에 상세 에러 출력
    print('🚨 Login Server Error: $e'); 
    return Response.json(
      statusCode: 500,
      body: {'error': '서버 오류가 발생했습니다: $e'},
    );
  }
}