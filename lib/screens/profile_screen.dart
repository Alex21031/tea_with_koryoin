import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    if (user == null) return const Scaffold(body: Center(child: Text('로그인 정보 없음')));

    return Scaffold(
      appBar: AppBar(title: const Text('마이페이지')),
      body: Column(
        children: [
          const SizedBox(height: 30),
          // 프로필 아이콘
          const CircleAvatar(radius: 50, backgroundColor: Colors.grey, child: Icon(Icons.person, size: 60, color: Colors.white)),
          const SizedBox(height: 20),
          
          // 이름 및 역할
          Text(user.username, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(10)),
            child: Text(user.role == 'expert' ? '전문가 (Expert)' : '일반 회원', style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 30),

          // 메뉴 리스트
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.email),
                  title: const Text('이메일'),
                  subtitle: Text(user.email),
                ),
                ListTile(
                  leading: const Icon(Icons.phone),
                  title: const Text('전화번호'),
                  subtitle: Text(user.phone),
                ),
                const Divider(),
                // 정보 수정 버튼
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.blue),
                  title: const Text('정보 수정'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                  },
                ),
                // 로그아웃 버튼
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('로그아웃', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    // 로그아웃 처리
                    Provider.of<AuthProvider>(context, listen: false).logout();
                    // main.dart의 Consumer가 감지하여 로그인 화면으로 자동 전환됨
                    // 현재 스택에 쌓인 페이지들을 모두 닫아줌
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}