import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

const String serverUrl = 'http://localhost:8080';
String? currentUserToken;
Map<String, dynamic>? currentUser;

void main() async {
  while (true) {
    if (currentUser == null) {
      await showLoginMenu();
    } else {
      await showMainMenu();
    }
  }
}

// 로그인/회원가입 메뉴
Future<void> showLoginMenu() async {
  clearScreen();
  print('═══════════════════════════════════');
  print('   Tea with Koryoin');
  print('═══════════════════════════════════\n');
  print('1. 회원가입');
  print('2. 로그인');
  print('0. 종료\n');
  stdout.write('선택: ');

  final choice = stdin.readLineSync()?.trim();

  switch (choice) {
    case '1':
      await signupFlow();
      break;
    case '2':
      await loginFlow();
      break;
    case '0':
      print('\n프로그램을 종료합니다.');
      exit(0);
    default:
      print('❌ 잘못된 선택입니다.');
      await pause();
  }
}

// 메인 메뉴 (로그인 후)
Future<void> showMainMenu() async {
  clearScreen();
  print('═══════════════════════════════════');
  print('   Tea with Koryoin');
  print('═══════════════════════════════════');
  print('환영합니다, ${currentUser!['username']}님!\n');
  print('1. 게시물 목록');
  print('2. 게시물 작성');
  print('3. 마이페이지');
  print('4. 로그아웃');
  print('0. 종료\n');
  stdout.write('선택: ');

  final choice = stdin.readLineSync()?.trim();

  switch (choice) {
    case '1':
      await viewPosts();
      break;
    case '2':
      await createPost();
      break;
    case '3':
      await viewMyPage();
      break;
    case '4':
      await logout();
      break;
    case '0':
      print('\n프로그램을 종료합니다.');
      exit(0);
    default:
      print('❌ 잘못된 선택입니다.');
      await pause();
  }
}

// 회원가입
Future<void> signupFlow() async {
  clearScreen();
  print('═══════════════════════════════════');
  print('   회원가입');
  print('═══════════════════════════════════\n');

  try {
    stdout.write('이메일: ');
    final email = stdin.readLineSync()?.trim();

    stdout.write('사용자명: ');
    final username = stdin.readLineSync()?.trim();

    stdout.write('전화번호: ');
    final phone = stdin.readLineSync()?.trim();

    stdout.write('비밀번호: ');
    stdin.echoMode = false;
    final password = stdin.readLineSync()?.trim();
    stdin.echoMode = true;
    print('');

    stdout.write('비밀번호 확인: ');
    stdin.echoMode = false;
    final passwordConfirm = stdin.readLineSync()?.trim();
    stdin.echoMode = true;
    print('\n');

    if (email == null || email.isEmpty) {
      print('❌ 이메일을 입력해주세요.');
      await pause();
      return;
    }

    if (username == null || username.isEmpty) {
      print('❌ 사용자명을 입력해주세요.');
      await pause();
      return;
    }

    if (phone == null || phone.isEmpty) {
      print('❌ 전화번호를 입력해주세요.');
      await pause();
      return;
    }

    if (password == null || password.isEmpty) {
      print('❌ 비밀번호를 입력해주세요.');
      await pause();
      return;
    }

    if (password != passwordConfirm) {
      print('❌ 비밀번호가 일치하지 않습니다.');
      await pause();
      return;
    }

    if (!isValidEmail(email)) {
      print('❌ 올바른 이메일 형식이 아닙니다.');
      await pause();
      return;
    }

    print('회원가입 처리 중...\n');

    final response = await http.post(
      Uri.parse('$serverUrl/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'username': username,
        'phone': phone,
        'password': password,
      }),
    );

    final responseData = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 201) {
      print('✅ 회원가입 성공!');
      print('로그인 화면으로 돌아갑니다.\n');
      await pause();
    } else {
      print('❌ 회원가입 실패: ${responseData['error']}');
      await pause();
    }
  } catch (e) {
    print('❌ 오류 발생: $e');
    await pause();
  }
}

// 로그인
Future<void> loginFlow() async {
  clearScreen();
  print('═══════════════════════════════════');
  print('   로그인');
  print('═══════════════════════════════════\n');

  try {
    stdout.write('이메일: ');
    final email = stdin.readLineSync()?.trim();

    stdout.write('비밀번호: ');
    stdin.echoMode = false;
    final password = stdin.readLineSync()?.trim();
    stdin.echoMode = true;
    print('\n');

    if (email == null || email.isEmpty || password == null || password.isEmpty) {
      print('❌ 이메일과 비밀번호를 입력해주세요.');
      await pause();
      return;
    }

    print('로그인 처리 중...\n');

    final response = await http.post(
      Uri.parse('$serverUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final responseData = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      currentUser = responseData['user'] as Map<String, dynamic>;
      currentUserToken = responseData['token'] as String?;
      print('✅ 로그인 성공! 환영합니다, ${currentUser!['username']}님\n');
      await pause();
    } else {
      print('❌ 로그인 실패: ${responseData['error']}');
      await pause();
    }
  } catch (e) {
    print('❌ 오류 발생: $e');
    await pause();
  }
}

// 게시물 목록
int currentPage = 1;

Future<void> viewPosts() async {
  while (true) {
    clearScreen();
    print('═══════════════════════════════════');
    print('   게시물 목록');
    print('═══════════════════════════════════\n');

    try {
      final response = await http.get(
        Uri.parse('$serverUrl/posts?page=$currentPage'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final posts = data['posts'] as List<dynamic>;
        final pagination = data['pagination'] as Map<String, dynamic>;

        if (posts.isEmpty) {
          print('📝 게시물이 없습니다.\n');
        } else {
          for (var i = 0; i < posts.length; i++) {
            final post = posts[i] as Map<String, dynamic>;
            print('─────────────────────────────────');
            print('번호: ${post['id']}');
            print('제목: ${post['title']}');
            print('작성자: ${post['author']}');
            print('작성일: ${post['created_at']}');
            print('내용: ${post['content']}');
          }
          print('─────────────────────────────────\n');

          print('페이지: ${pagination['current_page']} / ${pagination['total_pages']}');
          print('전체 게시물: ${pagination['total_posts']}개\n');
        }

        print('n: 다음 페이지 | p: 이전 페이지 | 0: 뒤로가기');
        stdout.write('선택: ');

        final choice = stdin.readLineSync()?.trim().toLowerCase();

        if (choice == 'n' && pagination['has_next'] == true) {
          currentPage++;
        } else if (choice == 'p' && pagination['has_prev'] == true) {
          currentPage--;
        } else if (choice == '0') {
          currentPage = 1;
          return;
        } else if (choice == 'n' || choice == 'p') {
          print('❌ 더 이상 페이지가 없습니다.');
          await pause();
        }
      } else {
        print('❌ 게시물을 불러올 수 없습니다.');
        await pause();
        return;
      }
    } catch (e) {
      print('❌ 오류 발생: $e');
      await pause();
      return;
    }
  }
}

// 게시물 작성
Future<void> createPost() async {
  clearScreen();
  print('═══════════════════════════════════');
  print('   게시물 작성');
  print('═══════════════════════════════════\n');

  try {
    stdout.write('제목: ');
    final title = stdin.readLineSync()?.trim();

    print('내용 (입력 완료 후 빈 줄에서 Enter):');
    final contentLines = <String>[];
    while (true) {
      final line = stdin.readLineSync();
      if (line == null || line.trim().isEmpty) break;
      contentLines.add(line);
    }
    final content = contentLines.join('\n').trim();

    if (title == null || title.isEmpty) {
      print('❌ 제목을 입력해주세요.');
      await pause();
      return;
    }

    if (content.isEmpty) {
      print('❌ 내용을 입력해주세요.');
      await pause();
      return;
    }

    print('\n게시물 작성 중...\n');

    final response = await http.post(
      Uri.parse('$serverUrl/posts/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': currentUser!['id'],
        'title': title,
        'content': content,
      }),
    );

    final responseData = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 201) {
      print('✅ 게시물이 작성되었습니다!\n');
      await pause();
    } else {
      print('❌ 게시물 작성 실패: ${responseData['error']}');
      await pause();
    }
  } catch (e) {
    print('❌ 오류 발생: $e');
    await pause();
  }
}

// 마이페이지
Future<void> viewMyPage() async {
  while (true) {
    clearScreen();
    print('═══════════════════════════════════');
    print('   마이페이지');
    print('═══════════════════════════════════\n');
    print('사용자 ID: ${currentUser!['id']}');
    print('이메일: ${currentUser!['email']}');
    print('사용자명: ${currentUser!['username']}');
    print('전화번호: ${currentUser!['phone']}');
    print('가입일시: ${currentUser!['created_at']}\n');
    
    print('1. 정보 수정');
    print('0. 뒤로가기\n');
    stdout.write('선택: ');

    final choice = stdin.readLineSync()?.trim();

    if (choice == '1') {
      await updateProfile();
    } else if (choice == '0') {
      return;
    }
  }
}

// 정보 수정
Future<void> updateProfile() async {
  clearScreen();
  print('═══════════════════════════════════');
  print('   정보 수정');
  print('═══════════════════════════════════\n');
  print('변경하지 않을 항목은 Enter를 누르세요.\n');

  try {
    stdout.write('새 사용자명 (현재: ${currentUser!['username']}): ');
    final username = stdin.readLineSync()?.trim();

    stdout.write('새 전화번호 (현재: ${currentUser!['phone']}): ');
    final phone = stdin.readLineSync()?.trim();

    stdout.write('비밀번호를 변경하시겠습니까? (y/n): ');
    final changePassword = stdin.readLineSync()?.trim().toLowerCase() == 'y';

    String? currentPassword;
    String? newPassword;

    if (changePassword) {
      stdout.write('현재 비밀번호: ');
      stdin.echoMode = false;
      currentPassword = stdin.readLineSync()?.trim();
      stdin.echoMode = true;
      print('');

      stdout.write('새 비밀번호: ');
      stdin.echoMode = false;
      newPassword = stdin.readLineSync()?.trim();
      stdin.echoMode = true;
      print('');

      stdout.write('새 비밀번호 확인: ');
      stdin.echoMode = false;
      final newPasswordConfirm = stdin.readLineSync()?.trim();
      stdin.echoMode = true;
      print('');

      if (newPassword != newPasswordConfirm) {
        print('❌ 새 비밀번호가 일치하지 않습니다.');
        await pause();
        return;
      }
    }

    print('\n정보 수정 중...\n');

    final body = <String, dynamic>{
      'user_id': currentUser!['id'],
    };

    if (username != null && username.isNotEmpty) {
      body['username'] = username;
    }
    if (phone != null && phone.isNotEmpty) {
      body['phone'] = phone;
    }
    if (changePassword && currentPassword != null && newPassword != null) {
      body['current_password'] = currentPassword;
      body['new_password'] = newPassword;
    }

    final response = await http.put(
      Uri.parse('$serverUrl/users/update'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    final responseData = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      currentUser = responseData['user'] as Map<String, dynamic>;
      print('✅ 정보가 수정되었습니다!\n');
      await pause();
    } else {
      print('❌ 정보 수정 실패: ${responseData['error']}');
      await pause();
    }
  } catch (e) {
    print('❌ 오류 발생: $e');
    await pause();
  }
}

// 로그아웃
Future<void> logout() async {
  currentUser = null;
  currentUserToken = null;
  print('\n✅ 로그아웃되었습니다.\n');
  await pause();
}

// 유틸리티 함수들
void clearScreen() {
  if (Platform.isWindows) {
    print(Process.runSync('cls', [], runInShell: true).stdout);
  } else {
    print(Process.runSync('clear', [], runInShell: true).stdout);
  }
}

Future<void> pause() async {
  stdout.write('계속하려면 Enter를 누르세요...');
  stdin.readLineSync();
}

bool isValidEmail(String email) {
  final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  return regex.hasMatch(email);
}