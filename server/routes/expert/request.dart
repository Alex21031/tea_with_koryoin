import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:path/path.dart' as p;

Future<Response> onRequest(RequestContext context) async {
  // 1. POST 요청인지 확인
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405);
  }

  try {
    // 2. 파일 및 데이터 받기
    final formData = await context.request.formData();
    final uploadedFile = formData.files['certificate'];
    final userId = formData.fields['user_id'];

    if (uploadedFile == null || userId == null) {
      return Response.json(statusCode: 400, body: {'error': '파일 또는 유저 ID가 누락되었습니다.'});
    }

    // 3. 파일 저장 (public/uploads 폴더)
    final uploadDir = Directory('public/uploads');
    if (!await uploadDir.exists()) {
      await uploadDir.create(recursive: true);
    }

    final filename = '${DateTime.now().millisecondsSinceEpoch}_${uploadedFile.name}';
    final filePath = p.join(uploadDir.path, filename);
    
    // 실제 파일 쓰기
    await File(filePath).writeAsBytes(await uploadedFile.readAsBytes());

    // 4. DB 업데이트 (users 테이블의 certificate_path 컬럼 수정)
    final pool = context.read<Pool>();
    
    // 유저 ID가 int형인지 확인
    final userIdInt = int.tryParse(userId);
    if (userIdInt == null) {
      return Response.json(statusCode: 400, body: {'error': '잘못된 유저 ID입니다.'});
    }

    await pool.execute(
      Sql.named('UPDATE users SET certificate_path = @path WHERE id = @id'),
      parameters: {
        'path': filePath,
        'id': userIdInt,
      },
    );

    return Response.json(statusCode: 201, body: {'success': true, 'message': '인증 요청이 완료되었습니다.'});

  } catch (e) {
    print("서버 에러: $e");
    return Response.json(statusCode: 500, body: {'error': '서버 내부 오류: $e'});
  }
}