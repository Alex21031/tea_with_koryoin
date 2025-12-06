import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class WritePostScreen extends StatefulWidget {
  const WritePostScreen({super.key});

  @override
  State<WritePostScreen> createState() => _WritePostScreenState();
}

class _WritePostScreenState extends State<WritePostScreen> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final ApiService _apiService = ApiService();
  
  final List<String> _categories = ['전문가 게시판', '자유 게시판', '일자리 공고', '홍보 게시판'];
  String _selectedCategory = '자유 게시판'; // 기본값을 안전하게 '자유 게시판'으로 설정

  bool _isLoading = false;

  // 제출 버튼 활성화 여부 (제목, 내용이 있어야 함)
  bool get _canSubmit {
    return !_isLoading && 
           _titleCtrl.text.isNotEmpty && 
           _contentCtrl.text.isNotEmpty;
  }

  void _submit() async {
    if (!_canSubmit) return;

    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      await _apiService.createPost(user.id, _titleCtrl.text, _contentCtrl.text, _selectedCategory);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('게시물이 등록되었습니다.')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _titleCtrl.addListener(() => setState(() {}));
    _contentCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // 현재 유저의 역할 확인 (없으면 일반 유저 취급)
    final bool isExpert = user.role == 'expert';

    return Scaffold(
      appBar: AppBar(
        title: const Text('글쓰기', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 게시판 선택 드롭다운
            const Text('게시판', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                  // 항목 리스트 생성
                  items: _categories.map((String category) {
                    // 전문가 게시판이고, 내가 전문가가 아니면 -> 비활성화(enabled: false)
                    final bool isDisabled = (category == '전문가 게시판' && !isExpert);
                    
                    return DropdownMenuItem<String>(
                      value: category,
                      enabled: !isDisabled, // 여기서 클릭 가능 여부 결정
                      child: Row(
                        children: [
                          Text(
                            category,
                            style: TextStyle(
                              // 비활성화되면 회색, 아니면 검은색
                              color: isDisabled ? Colors.grey[400] : Colors.grey[800],
                              decoration: isDisabled ? TextDecoration.lineThrough : null, // 취소선 추가 (선택사항)
                            ),
                          ),
                          if (category == '전문가 게시판') ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.lock, 
                              size: 16, 
                              color: isDisabled ? Colors.grey[400] : Colors.orangeAccent
                            ),
                          ]
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() => _selectedCategory = newValue);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 2. 제목 입력
            const Text('제목', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                hintText: '제목을 입력하세요',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
            const SizedBox(height: 24),

            // 3. 내용 입력
            const Text('내용', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: _contentCtrl,
              maxLines: 10,
              decoration: InputDecoration(
                hintText: '내용을 입력하세요',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 30),

            // 4. 게시하기 버튼
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _canSubmit ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF757575),
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('게시하기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}