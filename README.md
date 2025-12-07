# tea_with_koryoin

간단 소개
---------
tea_with_koryoin은 Dart(주로 Flutter) 기반으로 작성된 프로젝트이며 고려인(Koryoin) 위한 커뮤니티 기능을 제공하는 모바일/웹 앱을 목표로 했습니다.

핵심 특징
---------
- 사용자 인증(회원가입/로그인)
- 게시물 작성 및 편집
- 사용자 간 채팅 기능
- 인증을 받기 위해 서버로 파인 전송


요구사항
---------
- Flutter SDK (권장 버전: 최신 안정화 버전)
- Dart SDK (Flutter 설치 시 포함)
- (옵션) Firebase, REST API 백엔드 또는 로컬/원격 데이터베이스
- 플랫폼별 빌드 도구 (Android SDK, Xcode 등)

설치 및 로컬 실행
-----------------
1. 저장소 복제
   git clone https://github.com/Alex21031/tea_with_koryoin.git
   cd tea_with_koryoin

2. 의존성 설치
   flutter pub get

3. 디바이스 연결 후 실행
   flutter run

4. 웹 빌드(선택)
   flutter build web
   또는 개발에서:
   flutter run -d chrome


프로젝트 구조(예시)
-------------------
- lib/              # 앱 소스코드
- assets/           # 이미지/폰트 등 정적 자원
- test/             # 단위/위젯 테스트
- pubspec.yaml      # 의존성 및 리소스 선언

테스트
-----
단위 및 위젯 테스트 실행:
flutter test

빌드 및 배포
------------
- Android APK: flutter build apk --release
- iOS: flutter build ios --release (Xcode 설정 필요)
- Web: flutter build web


라이선스
--------
이 프로젝트는 MIT 라이선스 하에 공개되어 있습니다. 자세한 내용은 LICENSE 파일을 참조하세요.



