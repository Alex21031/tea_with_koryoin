import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:crypto/crypto.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.put) {
    return Response.json(
      statusCode: 405,
      body: {'error': 'Method not allowed'},
    );
  }

  try {
    final pool = context.read<Pool>();
    final body = await context.request.json() as Map<String, dynamic>;

    final userId = body['user_id'] as int?;
    final username = body['username'] as String?;
    final phone = body['phone'] as String?;
    final currentPassword = body['current_password'] as String?;
    final newPassword = body['new_password'] as String?;

    if (userId == null) {
      return Response.json(
        statusCode: 400,
        body: {'error': '사용자 ID가 필요합니다.'},
      );
    }

    // 비밀번호 변경을 원하는 경우
    if (newPassword != null && newPassword.isNotEmpty) {
      if (currentPassword == null || currentPassword.isEmpty) {
        return Response.json(
          statusCode: 400,
          body: {'error': '현재 비밀번호를 입력해주세요.'},
        );
      }

      // 현재 비밀번호 확인
      final hashedCurrentPassword = sha256.convert(utf8.encode(currentPassword)).toString();
      final passwordCheck = await pool.execute(
        Sql.named('SELECT id FROM users WHERE id = @user_id AND password = @password'),
        parameters: {
          'user_id': userId,
          'password': hashedCurrentPassword,
        },
      );

      if (passwordCheck.isEmpty) {
        return Response.json(
          statusCode: 401,
          body: {'error': '현재 비밀번호가 올바르지 않습니다.'},
        );
      }

      // 새 비밀번호로 업데이트
      final hashedNewPassword = sha256.convert(utf8.encode(newPassword)).toString();
      await pool.execute(
        Sql.named('UPDATE users SET password = @password WHERE id = @user_id'),
        parameters: {
          'user_id': userId,
          'password': hashedNewPassword,
        },
      );
    }

    // 사용자명 업데이트
    if (username != null && username.isNotEmpty) {
      // 사용자명 중복 확인
      final usernameCheck = await pool.execute(
        Sql.named('SELECT id FROM users WHERE username = @username AND id != @user_id'),
        parameters: {
          'username': username,
          'user_id': userId,
        },
      );

      if (usernameCheck.isNotEmpty) {
        return Response.json(
          statusCode: 409,
          body: {'error': '이미 존재하는 사용자명입니다.'},
        );
      }

      await pool.execute(
        Sql.named('UPDATE users SET username = @username WHERE id = @user_id'),
        parameters: {
          'username': username,
          'user_id': userId,
        },
      );
    }

    // 전화번호 업데이트
    if (phone != null && phone.isNotEmpty) {
      // 전화번호 중복 확인
      final phoneCheck = await pool.execute(
        Sql.named('SELECT id FROM users WHERE phone = @phone AND id != @user_id'),
        parameters: {
          'phone': phone,
          'user_id': userId,
        },
      );

      if (phoneCheck.isNotEmpty) {
        return Response.json(
          statusCode: 409,
          body: {'error': '이미 존재하는 전화번호입니다.'},
        );
      }

      await pool.execute(
        Sql.named('UPDATE users SET phone = @phone WHERE id = @user_id'),
        parameters: {
          'phone': phone,
          'user_id': userId,
        },
      );
    }

    // 업데이트된 사용자 정보 조회
    final result = await pool.execute(
      Sql.named('''
        SELECT id, email, username, phone, created_at
        FROM users
        WHERE id = @user_id
      '''),
      parameters: {'user_id': userId},
    );

    final user = result.first;

    return Response.json(
      statusCode: 200,
      body: {
        'success': true,
        'message': '정보가 수정되었습니다.',
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