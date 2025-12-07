import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import '../models/post.dart'; // Post 모델 import
import 'expert_request_screen.dart'; 
import 'post_detail_screen.dart'; // 게시글 상세 화면 import

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // 수정 모드 상태
  bool _isEditing = false;
  bool _isLoading = false;

  // 컨트롤러
  late TextEditingController _usernameCtrl; 
  late TextEditingController _phoneCtrl;    
  late TextEditingController _introCtrl;    
  
  String _introduction = "한국에서 공부하고 있는 유학생입니다. 한국 문화와 언어에 관심이 많습니다.";
  
  // 내 게시글 목록 및 로딩 상태
  List<Post> _myPosts = [];
  bool _isPostsLoading = false;

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _usernameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _introCtrl = TextEditingController();

    // 화면 진입 시 내 게시글 불러오기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchMyPosts();
    });
  }

  // 내 게시글 불러오기 함수
  Future<void> _fetchMyPosts() async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return;

    setState(() => _isPostsLoading = true);
    try {
      // API에 user_id를 전달하여 내 글만 가져옴
      final posts = await _apiService.getPosts(1, userId: int.parse(user.id));
      setState(() {
        _myPosts = posts;
      });
    } catch (e) {
      print('내 게시글 로드 실패: $e');
    } finally {
      if (mounted) setState(() => _isPostsLoading = false);
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _phoneCtrl.dispose();
    _introCtrl.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
  }

  void _cancelEditing(User user) {
    setState(() {
      _isEditing = false;
      _usernameCtrl.text = user.username;
      _phoneCtrl.text = user.phone;
      _introCtrl.text = _introduction;
    });
  }

  void _saveProfile(User user) async {
    setState(() => _isLoading = true);
    try {
      await _apiService.updateUser(
        userId: int.parse(user.id),
        username: _usernameCtrl.text,
        phone: _phoneCtrl.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('프로필이 저장되었습니다.')));

      setState(() {
        _introduction = _introCtrl.text;
        _isEditing = false; 
      });
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_isEditing) {
       if (_usernameCtrl.text != user.username) _usernameCtrl.text = user.username;
       if (_phoneCtrl.text != user.phone) _phoneCtrl.text = user.phone;
       if (_introCtrl.text != _introduction) _introCtrl.text = _introduction;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        title: const Text(
          '마이페이지',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTopProfileCard(user),
            const SizedBox(height: 16),
            _isEditing ? _buildEditForm(user) : _buildViewForm(user),  
            const SizedBox(height: 16),
            _buildSettingsCard(context, user),
            const SizedBox(height: 16),
            
            // 내 게시글 카드 (여기에 리스트 전달)
            _buildMyPostsCard(),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomSheet: _isEditing ? null : Container(
        color: const Color(0xFFF5F5F5),
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () {
              authProvider.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text(
              '로그아웃',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }

  // --- 위젯 빌더 ---

  Widget _buildTopProfileCard(User user) {
    final initial = user.username.isNotEmpty ? user.username[0] : (user.name.isNotEmpty ? user.name[0] : '?');
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey[200],
              child: Text(
                initial,
                style: const TextStyle(fontSize: 30, color: Colors.black54),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              user.name.isNotEmpty ? user.name : user.username,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              user.email,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            
            if (_isEditing)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _saveProfile(user),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A0A2A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isLoading 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('저장', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _cancelEditing(user),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('취소', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  onPressed: _startEditing,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A0A2A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: const Text(
                    '프로필 수정',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewForm(User user) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('프로필 정보', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildInfoRow(Icons.account_circle_outlined, '닉네임', user.username),
            _buildInfoRow(Icons.person_outline, '이름', user.name.isNotEmpty ? user.name : '이름 없음'),
            _buildInfoRow(Icons.email_outlined, '이메일', user.email),
            _buildInfoRow(Icons.phone_outlined, '전화번호', user.phone),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.description_outlined, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('소개', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                      const SizedBox(height: 4),
                      Text(_introduction, style: const TextStyle(fontSize: 14, height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditForm(User user) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('프로필 수정', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildEditField('닉네임', _usernameCtrl),
            _buildEditField('이름', TextEditingController(text: user.name), readOnly: true),
            _buildEditField('이메일', TextEditingController(text: user.email), readOnly: true),
            _buildEditField('전화번호', _phoneCtrl, keyboardType: TextInputType.phone),
            _buildEditField('소개', _introCtrl, maxLines: 3),
          ],
        ),
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller, 
      {bool readOnly = false, TextInputType? keyboardType, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                label == '닉네임' ? Icons.account_circle_outlined :
                label == '이름' ? Icons.person_outline :
                label == '이메일' ? Icons.email_outlined :
                label == '전화번호' ? Icons.phone_outlined : Icons.description_outlined,
                size: 18, color: Colors.black87
              ),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            readOnly: readOnly,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: TextStyle(color: readOnly ? Colors.grey[600] : Colors.black),
            decoration: InputDecoration(
              filled: true,
              fillColor: readOnly ? Colors.grey[200] : const Color(0xFFF5F5F5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, User user) {
    final bool isVerified = user.role == 'expert';
    final bool isPending = !isVerified && (user.certificatePath != null && user.certificatePath!.isNotEmpty);

    String statusText = '미인증';
    Color statusColor = Colors.grey;
    Color statusBgColor = Colors.grey[200]!;

    if (isVerified) {
      statusText = '인증됨';
      statusColor = Colors.blue;
      statusBgColor = Colors.blue[50]!;
    } else if (isPending) {
      statusText = '심사 중';
      statusColor = Colors.orange;
      statusBgColor = Colors.orange[50]!;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('설정', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('전문가 인증', style: TextStyle(fontSize: 14)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: OutlinedButton(
                onPressed: (isVerified || isPending) 
                    ? () {
                        String message = isVerified 
                            ? '이미 전문가 인증이 완료되었습니다.' 
                            : '전문가 인증 심사가 진행 중입니다.';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
                        );
                      }
                    : () {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (_) => const ExpertRequestScreen()),
                        );
                      },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: isVerified ? Colors.blue[100]! : (isPending ? Colors.orange[200]! : Colors.grey[300]!)
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  backgroundColor: Colors.white,
                ),
                child: Text(
                  isVerified 
                      ? '전문가 인증 완료' 
                      : (isPending ? '심사 요청 완료' : '전문가 인증 신청'),
                  style: TextStyle(
                    color: isVerified ? Colors.blue : (isPending ? Colors.orange : Colors.black), 
                    fontWeight: FontWeight.bold
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ [수정 완료] 내 게시글 목록 카드
  Widget _buildMyPostsCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // 상단 헤더
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('내가 작성한 게시글', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    _myPosts.length.toString(), 
                    style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold)
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 내용물 (로딩 중, 없음, 있음)
            if (_isPostsLoading)
              const Center(child: CircularProgressIndicator())
            else if (_myPosts.isEmpty)
              Column(
                children: [
                  const SizedBox(height: 20),
                  Icon(Icons.description_outlined, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text('아직 작성한 게시글이 없습니다', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                  const SizedBox(height: 20),
                ],
              )
            else
              // 게시글 리스트 (최근 5개만 보여주거나, 전체 스크롤)
              ListView.separated(
                shrinkWrap: true, // 카드 내부이므로 높이 수축
                physics: const NeverScrollableScrollPhysics(), // 전체 페이지 스크롤 사용
                itemCount: _myPosts.length,
                separatorBuilder: (_, __) => const Divider(height: 20),
                itemBuilder: (context, index) {
                  final post = _myPosts[index];
                  // 날짜 포맷 (앞부분 10자리만)
                  final date = post.createdAt?.substring(0, 10) ?? '';
                  
                  return InkWell(
                    onTap: () {
                      // 상세 페이지로 이동
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  date,
                                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}