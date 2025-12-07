import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/post.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class PostDetailScreen extends StatefulWidget {
  final Post post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _commentCtrl = TextEditingController();
  
  late Future<List<Comment>> _commentsFuture;
  
  // UI 상태 관리 변수
  late int _likeCount;
  late int _commentCount;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.post.likeCount;
    _commentCount = widget.post.commentCount;
    
    _commentsFuture = _apiService.getComments(widget.post.id);

    _fetchLikeStatus();
  }

  void _fetchLikeStatus() async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return;

    try {
      final result = await _apiService.checkLikeStatus(widget.post.id, int.parse(user.id));
      if (mounted) {
        setState(() {
          _isLiked = result['is_liked'];
          _likeCount = result['like_count'];
        });
      }
    } catch (e) {
      print('좋아요 상태 로드 실패: $e');
    }
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  void _deletePost() async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('삭제'),
        content: const Text('정말 이 게시물을 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('삭제', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.deletePost(widget.post.id, int.parse(user.id));
        if (!mounted) return;
        Navigator.pop(context, true); 
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('삭제되었습니다.')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: $e')));
      }
    }
  }

  void _toggleLike() async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
      return;
    }

    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });

    try {
      final result = await _apiService.likePost(widget.post.id, int.parse(user.id));
      setState(() {
        _isLiked = result['is_liked'];
        _likeCount = result['like_count'];
      });
    } catch (e) {
      print('좋아요 오류: $e');
      setState(() {
        _isLiked = !_isLiked;
        _likeCount += _isLiked ? 1 : -1;
      });
    }
  }

  // 댓글 작성 함수
  void _submitComment() async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return;
    if (_commentCtrl.text.trim().isEmpty) return;

    try {
      await _apiService.createComment(widget.post.id, int.parse(user.id), _commentCtrl.text);
      _commentCtrl.clear();
      
      setState(() {
        _commentsFuture = _apiService.getComments(widget.post.id);
        _commentCount++; 
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final bool isMyPost = (user != null && user.id == widget.post.userId.toString());

    final displayDate = widget.post.createdAt ?? DateTime.now().toString();
    final dateString = displayDate.length >= 16 ? displayDate.substring(0, 16) : displayDate;
    final authorName = widget.post.author.isNotEmpty ? widget.post.author : '익명';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context), 
        ),
        actions: [
          if (isMyPost)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _deletePost,
            ),
        ],
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 작성자 정보
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.grey[200], 
                        child: Text(authorName[0], style: const TextStyle(color: Colors.black54))
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(authorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(dateString, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 제목 및 내용
                  Text(
                    widget.post.title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.post.content,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 30),

                  // 통계 (좋아요, 댓글)
                  Row(
                    children: [
                      // 좋아요 버튼
                      GestureDetector(
                        onTap: _toggleLike,
                        child: Row(
                          children: [
                            Icon(
                              _isLiked ? Icons.favorite : Icons.favorite_border, 
                              size: 24, 
                              color: _isLiked ? Colors.red : Colors.grey[400]
                            ),
                            const SizedBox(width: 6),
                            Text('$_likeCount', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      // 댓글 아이콘
                      Row(
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 22, color: Colors.grey[400]),
                          const SizedBox(width: 6),
                          Text('$_commentCount', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 40),

                  // 댓글 목록
                  const Text('댓글', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  FutureBuilder<List<Comment>>(
                    future: _commentsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text('첫 번째 댓글을 남겨보세요!', style: TextStyle(color: Colors.grey)),
                        );
                      }
                      return Column(
                        children: snapshot.data!.map((c) => _buildCommentItem(c)).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // 댓글 입력창
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentCtrl,
                    decoration: InputDecoration(
                      hintText: '댓글을 입력하세요',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _submitComment,
                  icon: const Icon(Icons.send),
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(Comment comment) {
    final cDate = comment.createdAt ?? '';
    final displayDate = cDate.length >= 10 ? cDate.substring(0, 10) : cDate;
    final cAuthor = comment.author.isNotEmpty ? comment.author : '익명';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey[200],
            child: Text(cAuthor[0], style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(cAuthor, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(displayDate, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment.content, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}