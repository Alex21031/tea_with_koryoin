import 'package:flutter/material.dart';
import '../models/post.dart';
import '../services/api_service.dart';
import 'post_detail_screen.dart';
import 'write_post_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;
  final List<String> _tabs = ['전문가 정보', '자유 게시판', '일자리', '홍보'];
  String _searchKeyword = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  Future<List<Post>> _loadPosts() {
    String category = _tabs[_tabController.index];
    // 탭 이름과 실제 DB 저장값이 다를 수 있으니 매핑하거나 그대로 사용
    // 예: '전문가 정보' -> '전문가 게시판' 등 (DB 값에 맞춰 조정 필요)
    String dbCategory = category; 
    if (category == '전문가 정보') dbCategory = '전문가 게시판';
    if (category == '일자리') dbCategory = '일자리 공고';
    if (category == '홍보') dbCategory = '홍보 게시판';
    
    return _apiService.getPosts(1, category: dbCategory, keyword: _searchKeyword);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('커뮤니티 게시판', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false, // 왼쪽 정렬
        automaticallyImplyLeading: false, // 뒤로가기 버튼 제거 (하단 탭 있으므로)
        actions: [
          IconButton(
            icon: const Icon(Icons.language, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. 검색창
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                hintText: '검색어를 입력하세요',
                hintStyle: TextStyle(color: Colors.grey[500]),
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                filled: true,
                fillColor: const Color(0xFFF5F5F5), // 연한 회색 배경
              ),
              onSubmitted: (val) => setState(() => _searchKeyword = val),
            ),
          ),
          
          // 2. 탭바 (알약 모양 느낌은 아니지만 깔끔하게)
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Colors.black,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.black,
              indicatorWeight: 3,
              labelPadding: const EdgeInsets.symmetric(horizontal: 16),
              tabs: _tabs.map((t) => Tab(text: t)).toList(),
            ),
          ),
          
          // 3. 게시글 리스트
          Expanded(
            child: FutureBuilder<List<Post>>(
              future: _loadPosts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                   return Center(
                     child: Column(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         Icon(Icons.article_outlined, size: 60, color: Colors.grey[300]),
                         const SizedBox(height: 16),
                         Text('게시글이 없습니다.', style: TextStyle(color: Colors.grey[500])),
                       ],
                     ),
                   );
                }
                
                final posts = snapshot.data!;
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: posts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (ctx, idx) => _buildPostCard(posts[idx]),
                );
              },
            ),
          ),
        ],
      ),
      // [수정] 플로팅 액션 버튼 디자인 변경 (검은색 알약 모양)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const WritePostScreen()));
          setState(() {}); 
        },
        label: const Text('글쓰기', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add),
        backgroundColor: const Color(0xFF1A1A1A), // 진한 검정 (사진과 유사)
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }

  // [수정] 카드 디자인을 사진과 똑같이 구현
  Widget _buildPostCard(Post post) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)));
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.all(20), // 넉넉한 패딩
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16), // 둥근 모서리
          border: Border.all(color: const Color(0xFFEEEEEE)), // 아주 연한 테두리
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단: 작성자 정보 및 시간
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[100],
                  child: Text(post.author.isNotEmpty ? post.author[0] : '?', 
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(post.author, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(width: 6),
                        // 역할 뱃지 (전문가 등)
                        if (post.authorRole == 'expert')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(6)),
                            child: const Text('전문가', style: TextStyle(fontSize: 11, color: Color(0xFF1565C0), fontWeight: FontWeight.bold)),
                          )
                        else if (post.authorRole == 'admin')
                           Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(6)),
                            child: const Text('관리자', style: TextStyle(fontSize: 11, color: Color(0xFFC62828), fontWeight: FontWeight.bold)),
                          )
                        else 
                          Container( // 일반 회원도 뱃지 (행정사 등 역할이 있다면 여기 표시)
                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                             decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(6)),
                             child: Text(post.authorRole == 'general' ? '회원' : post.authorRole, 
                               style: TextStyle(fontSize: 11, color: Colors.grey[700], fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(_formatDate(post.createdAt), style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 제목
            Text(post.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, height: 1.3)),
            const SizedBox(height: 8),
            
            // 내용 (최대 3줄)
            Text(
              post.content, 
              maxLines: 3, 
              overflow: TextOverflow.ellipsis, 
              style: TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.5)
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    // 날짜 포맷팅 로직 (예: 방금 전, 2시간 전, 1일 전)
    // 여기선 간단하게 앞 10자리만 자르거나 시간 표시
    try {
       DateTime date = DateTime.parse(dateStr);
       Duration diff = DateTime.now().difference(date);
       if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
       if (diff.inHours < 24) return '${diff.inHours}시간 전';
       if (diff.inDays < 7) return '${diff.inDays}일 전';
       return dateStr.substring(0, 10);
    } catch (e) {
      return dateStr;
    }
  }
}