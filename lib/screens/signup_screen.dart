import 'dart:io'; // File 타입을 위해 필수
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart'; // [필수] file_picker 패키지
import '../providers/auth_provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // 텍스트 컨트롤러
  final _nameCtrl = TextEditingController();      
  final _usernameCtrl = TextEditingController();  
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _passConfirmCtrl = TextEditingController(); 

  // UI 상태 변수
  String _selectedType = '일반 사용자'; 
  File? _selectedFile; // 선택된 파일 객체 저장

  final List<Map<String, String>> _userTypes = [
    {'title': '일반 사용자', 'desc': ''},
    {'title': '전문가', 'desc': '전문가로 가입하시면 인증까지 최대 72시간이 소요될 수 있습니다.'},
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _passConfirmCtrl.dispose();
    super.dispose();
  }

  // [수정됨] 파일 선택 함수 (FilePicker 사용)
  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'pdf', 'doc', 'docx'], // 허용할 확장자
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('파일 선택 중 오류 발생: $e')),
      );
    }
  }

  // 회원가입 제출 로직
  void _submit() async {
    // 1. 비밀번호 일치 확인
    if (_passCtrl.text != _passConfirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호가 일치하지 않습니다.')),
      );
      return;
    }

    // 2. 필수 입력값 확인
    if (_nameCtrl.text.isEmpty || _usernameCtrl.text.isEmpty || 
        _emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('필수 정보를 모두 입력해주세요.')),
      );
      return;
    }

    // 3. 전문가 선택 시 파일 업로드 필수 체크
    if (_selectedType == '전문가' && _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('전문가 인증 서류를 업로드해주세요.')),
      );
      return;
    }

    try {
      // 4. Provider 호출 (파일 전달)
      await Provider.of<AuthProvider>(context, listen: false).signup(
        email: _emailCtrl.text, 
        name: _nameCtrl.text,
        username: _usernameCtrl.text,
        phone: _phoneCtrl.text, 
        password: _passCtrl.text,
        certificateFile: _selectedType == '전문가' ? _selectedFile : null,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회원가입 성공! 로그인해주세요.'))
      );
      Navigator.pop(context); // 로그인 화면 등으로 복귀
    } catch (e) {
      if (!mounted) return;
      // 에러 메시지에서 'Exception: ' 접두사 제거 (보기 좋게)
      final msg = e.toString().replaceAll('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('회원가입', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabeledTextField('이름 (실명)', '홍길동', _nameCtrl),
            _buildLabeledTextField('사용자명 (닉네임)', 'user123', _usernameCtrl),
            _buildLabeledTextField('이메일', 'example@email.com', _emailCtrl, type: TextInputType.emailAddress),
            _buildLabeledTextField('전화번호', '010-1234-5678', _phoneCtrl, type: TextInputType.phone),
            _buildLabeledTextField('비밀번호', '8자 이상 입력해주세요', _passCtrl, obscure: true),
            _buildLabeledTextField('비밀번호 확인', '비밀번호를 다시 입력해주세요', _passConfirmCtrl, obscure: true),
            
            const SizedBox(height: 24),
            const Text('계정 유형', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),

            ..._userTypes.map((type) => _buildTypeSelection(type['title']!, type['desc']!)).toList(),

            const SizedBox(height: 24),

            if (_selectedType == '전문가')
              _buildDocUploadSection(),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A0A2A), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: const Text('가입하기', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabeledTextField(String label, String hint, TextEditingController ctrl, {bool obscure = false, TextInputType? type}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: ctrl,
            obscureText: obscure,
            keyboardType: type,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelection(String title, String desc) {
    final isSelected = _selectedType == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = title;
          // 전문가가 아니게 되면 선택된 파일 초기화
          if (_selectedType != '전문가') _selectedFile = null; 
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0A0A2A) : Colors.grey[300]!,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? const Color(0xFF0A0A2A) : Colors.grey[400],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isSelected ? Colors.black : Colors.grey[800])),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(desc, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // [수정됨] 파일 선택 UI
  Widget _buildDocUploadSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFFEEF6FF), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('전문가 자격 증명서류', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text('자격증, 경력증명서 등을 업로드해주세요 (PDF, JPG, PNG)', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 16),
          
          GestureDetector(
            onTap: _pickFile, // 클릭 시 파일 피커 실행
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!, width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_selectedFile == null) ...[
                    const Icon(Icons.upload_file, size: 40, color: Colors.blue),
                    const SizedBox(height: 12),
                    Text('파일을 선택하려면 터치하세요', style: TextStyle(color: Colors.grey[500])),
                  ] else ...[
                    const Icon(Icons.check_circle, size: 40, color: Colors.green),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        _selectedFile!.path.split('/').last, // 파일명만 표시
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}