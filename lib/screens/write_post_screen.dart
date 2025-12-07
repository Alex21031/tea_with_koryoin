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

  final Map<String, int> _boardIdMap = {
    '전문가 게시판': 2,
    '자유 게시판': 1,
    '일자리 공고': 3,
    '홍보 게시판': 4,
  };

  String _selectedCategory = '자유 게시판'; 

  bool _isLoading = false;

  bool get _canSubmit {
    return !_isLoading && 
           _titleCtrl.text.trim().isNotEmpty && 
           _contentCtrl.text.trim().isNotEmpty;
  }

  void _submit() async {
    if (!_canSubmit) return;

    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      int boardId = _boardIdMap[_selectedCategory]!; 
      
      print("📡 전송하는 게시판 ID: $boardId ($_selectedCategory)");

      await _apiService.createPost(
        title: _titleCtrl.text,
        content: _contentCtrl.text,
        authorId: int.parse(user.id),
        boardId: boardId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('게시물이 등록되었습니다.')));
      Navigator.pop(context, true);
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
    _titleCtrl.addListener(() { setState(() {}); });
    _contentCtrl.addListener(() { setState(() {}); });
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
            // 1. 게시판 선택
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
                  // ✅ [수정 핵심] Map의 Key들을 직접 사용하여 드롭다운 아이템 생성
                  items: _boardIdMap.keys.map((String category) {
                    // 전문가 게시판은 전문가만 선택 가능
                    final bool isDisabled = (category == '전문가 게시판' && !isExpert);
                    
                    return DropdownMenuItem<String>(
                      value: category,
                      enabled: !isDisabled,
                      child: Row(
                        children: [
                          Text(
                            category,
                            style: TextStyle(
                              color: isDisabled ? Colors.grey[400] : Colors.grey[800],
                              decoration: isDisabled ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          if (category == '전문가 게시판') ...[
                            const SizedBox(width: 8),
                            Icon(Icons.lock, size: 16, color: isDisabled ? Colors.grey[400] : Colors.orangeAccent),
                          ]
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) setState(() => _selectedCategory = newValue);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 2. 제목
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

            // 3. 내용
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