import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _currentPassCtrl = TextEditingController(); // 현재 비번 (확인용)
  final _newPassCtrl = TextEditingController();     // 새 비번 (선택)

  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 기존 정보 채워넣기
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      _nameCtrl.text = user.username;
      _phoneCtrl.text = user.phone;
    }
  }

  void _submit() async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      // API 호출
      final updatedUser = await _apiService.updateUser(
        userId: user.id,
        username: _nameCtrl.text,
        phone: _phoneCtrl.text,
        // 비번 필드가 비어있지 않을 때만 전송
        currentPassword: _currentPassCtrl.text.isEmpty ? null : _currentPassCtrl.text,
        newPassword: _newPassCtrl.text.isEmpty ? null : _newPassCtrl.text,
      );

      // Provider 상태 업데이트 (중요: 그래야 화면에 바로 반영됨)
      // AuthProvider에 _user를 업데이트하는 기능이 없으므로, 임시로 로그아웃 시키거나
      // AuthProvider에 setUser 같은 메서드를 추가하는 것이 좋음.
      // 여기서는 일단 성공 메시지 띄우고 뒤로가기
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('정보가 수정되었습니다. 다시 로그인해주세요.')));
      
      // 정보 갱신을 위해 로그아웃 처리 (가장 깔끔함)
      Provider.of<AuthProvider>(context, listen: false).logout();
      Navigator.popUntil(context, (route) => route.isFirst);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('정보 수정')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('기본 정보', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: '사용자명', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: '전화번호', border: OutlineInputBorder())),
            
            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 10),
            
            const Text('비밀번호 변경 (선택사항)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            const Text('비밀번호를 변경하려면 현재 비밀번호를 꼭 입력해야 합니다.', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 16),
            TextField(
              controller: _currentPassCtrl, 
              obscureText: true,
              decoration: const InputDecoration(labelText: '현재 비밀번호', border: OutlineInputBorder())
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newPassCtrl, 
              obscureText: true,
              decoration: const InputDecoration(labelText: '새 비밀번호', border: OutlineInputBorder())
            ),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('수정 완료'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}