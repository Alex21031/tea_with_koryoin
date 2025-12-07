import 'dart:convert';
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

Future<Response> onRequest(RequestContext context) async {
  // 1. POST 메서드 확인
  if (context.request.method != HttpMethod.post) {
    return Response.json(statusCode: 405, body: {'error': 'Method not allowed'});
  }

  // 2. Multipart 요청인지 확인
  final contentType = context.request.headers['content-type'] ?? '';
  if (!contentType.contains('multipart/form-data')) {
    return Response.json(
      statusCode: 400, 
      body: {'error': 'Content-Type must be multipart/form-data'}
    );
  }

  try {
    final pool = context.read<Pool>();

    // 3. FormData 파싱
    final formData = await context.request.formData();
    final fields = formData.fields;
    final files = formData.files;

    // 데이터 추출
    final email = fields['email'];
    final password = fields['password'];
    final username = fields['username']; // 사용자명(닉네임)
    final phone = fields['phone'];
    final name = fields['name']; // 실명
    
    // 파일 추출 (키값: 'certificate')
    final uploadedFile = files['certificate']; 

    // 4. 필수값 검증
    if (email == null || password == null || username == null || phone == null || name == null) {
      return Response.json(
        statusCode: 400,
        body: {'error': '이메일, 비밀번호, 이름, 사용자명, 전화번호는 필수입니다.'},
      );
    }

    // 5. 중복 검사 (이메일, 사용자명, 전화번호)
    final emailCheck = await pool.execute(Sql.named('SELECT id FROM users WHERE email = @email'), parameters: {'email': email});
    if (emailCheck.isNotEmpty) return Response.json(statusCode: 409, body: {'error': '이미 존재하는 이메일입니다.'});

    final usernameCheck = await pool.execute(Sql.named('SELECT id FROM users WHERE username = @username'), parameters: {'username': username});
    if (usernameCheck.isNotEmpty) return Response.json(statusCode: 409, body: {'error': '이미 존재하는 사용자명입니다.'});

    final phoneCheck = await pool.execute(Sql.named('SELECT id FROM users WHERE phone = @phone'), parameters: {'phone': phone});
    if (phoneCheck.isNotEmpty) return Response.json(statusCode: 409, body: {'error': '이미 존재하는 전화번호입니다.'});

    // 6. 파일 저장 로직
    String? savedFilePath;
    if (uploadedFile != null) {
      // 프로젝트 루트의 public/uploads 폴더에 저장 (폴더가 없으면 생성해야 함)
      final uploadDir = Directory('public/uploads');
      if (!await uploadDir.exists()) {
        await uploadDir.create(recursive: true);
      }

      // 파일명 충돌 방지: timestamp_파일명
      final filename = '${DateTime.now().millisecondsSinceEpoch}_${uploadedFile.name}';
      final filePath = p.join(uploadDir.path, filename);
      
      // 파일 쓰기
      final fileOnDisk = File(filePath);
      await fileOnDisk.writeAsBytes(await uploadedFile.readAsBytes());
      
      savedFilePath = filePath; // DB에 저장할 경로
    }

    // 7. DB Insert (비밀번호 해싱 포함)
    final hashedPassword = sha256.convert(utf8.encode(password)).toString();
    
    final result = await pool.execute(
      Sql.named('''
        INSERT INTO users (email, password, name, username, phone, certificate_path, created_at)
        VALUES (@email, @password, @name, @username, @phone, @certificatePath, NOW())
        RETURNING id, email, name, username, phone, certificate_path, created_at
      '''),
      parameters: {
        'email': email,
        'password': hashedPassword,
        'name': name,
        'username': username,
        'phone': phone,
        'certificatePath': savedFilePath, // 파일 없으면 null 들어감
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
          'name': user[2],
          'username': user[3],
          'phone': user[4],
          'certificate_path': user[5],
        },
      },
    );

  } catch (e) {
    return Response.json(statusCode: 500, body: {'error': '서버 오류: $e'});
  }
}