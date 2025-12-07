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

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;
  
  // 탭 목록 (화면 표시용 한글)
  final List<String> _tabs = ['전문가 게시판', '자유 게시판', '일자리', '홍보'];
  
  String _searchKeyword = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    
    // 탭 변경 시 화면을 갱신하여 _loadPosts()가 다시 호출되게 함
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {}); // 탭 애니메이션이 끝난 후 리빌드
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // 게시물 불러오기 로직
  Future<List<Post>> _loadPosts() {
    String currentTab = _tabs[_tabController.index];
    String categoryParam = 'free'; // 기본값

    // ✅ [핵심 매핑] 화면의 '한글' 탭을 백엔드가 이해하는 '영어'로 변환
    switch (currentTab) {
      case '전문가 게시판':
        categoryParam = 'expert';
        break;
      case '자유 게시판':
        categoryParam = 'free';
        break;
      case '일자리':
        categoryParam = 'job';
        break;
      case '홍보':
        categoryParam = 'promotion';
        break;
      default:
        categoryParam = 'free';
    }

    print("📡 데이터 요청: category=$categoryParam, keyword=$_searchKeyword"); // 디버깅용 로그

    return _apiService.getPosts(
      1, // 페이지 번호 (필요 시 추후 변수로 관리)
      category: categoryParam,
      keyword: _searchKeyword,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '커뮤니티 게시판',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.language, color: Colors.black), 
            onPressed: () {}
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. 검색창
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search, color: Colors.grey[600], size: 20),
                hintText: '검색어를 입력하세요',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
              ),
              onSubmitted: (val) => setState(() => _searchKeyword = val),
            ),
          ),

          // 2. 탭바 (TabBar)
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: false, // 탭 개수가 적으므로 고정
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.black,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.tab,
              labelPadding: EdgeInsets.zero, // 간격 좁힘
              tabs: _tabs.map((t) => Tab(
                height: 40, 
                child: Center(
                  child: Text(
                    t,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14, 
                    ),
                  ),
                ),
              )).toList(),
            ),
          ),

          // 3. 게시물 리스트 (FutureBuilder)
          Expanded(
            child: FutureBuilder<List<Post>>(
              future: _loadPosts(), // setState가 호출될 때마다 다시 실행됨
              builder: (context, snapshot) {
                // 로딩 중
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                // 에러 발생
                if (snapshot.hasError) {
                  return Center(child: Text('오류 발생: ${snapshot.error}'));
                }

                // 데이터 없음
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.article_outlined, size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 10),
                        Text('등록된 게시글이 없습니다.', style: TextStyle(color: Colors.grey[500])),
                      ],
                    ),
                  );
                }

                // 데이터 있음 -> 리스트 표시
                final posts = snapshot.data!;
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: posts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, idx) => _buildPostCard(posts[idx]),
                );
              },
            ),
          ),
        ],
      ),
      
      // 4. 글쓰기 버튼
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // 글쓰기 화면으로 이동하고, 돌아왔을 때 결과(true)가 있으면 새로고침
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WritePostScreen()),
          );
          
          if (result == true) {
            setState(() {}); // 목록 새로고침
          }
        },
        label: const Text('글쓰기', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add, size: 20),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }

  // 게시글 카드 UI
  Widget _buildPostCard(Post post) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          // 카드 그림자 효과
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목
            Text(
              post.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            // 내용 (최대 2줄)
            Text(
              post.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.4),
            ),
            const SizedBox(height: 12),
            // 하단 정보 (작성자, 날짜)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text("익명", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
                Text(
                  _formatDate(post.createdAt ?? DateTime.now().toString()), 
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 날짜 포맷팅 함수
  String _formatDate(String dateStr) {
    try {
      DateTime date = DateTime.parse(dateStr);
      Duration diff = DateTime.now().difference(date);
      if (diff.inMinutes < 1) return '방금 전';
      if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
      if (diff.inHours < 24) return '${diff.inHours}시간 전';
      if (diff.inDays < 7) return '${diff.inDays}일 전';
      return "${date.year}.${date.month}.${date.day}";
    } catch (e) {
      return dateStr;
    }
  }
}