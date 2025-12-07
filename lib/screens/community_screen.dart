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
  
  final List<String> _tabs = ['전문가 게시판', '자유 게시판', '일자리', '홍보'];
  
  String _searchKeyword = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<List<Post>> _loadPosts() {
    String currentTab = _tabs[_tabController.index];
    String categoryParam = 'free'; // 기본값

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

    print("데이터 요청: category=$categoryParam, keyword=$_searchKeyword");

    return _apiService.getPosts(
      1,
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

          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: false,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.black,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.tab,
              labelPadding: EdgeInsets.zero,
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

          Expanded(
            child: FutureBuilder<List<Post>>(
              future: _loadPosts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                
                if (snapshot.hasError) {
                  return Center(child: Text('오류 발생: ${snapshot.error}'));
                }

                
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
      
      
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WritePostScreen()),
          );
          
          if (result == true) {
            setState(() {});
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
            Text(
              post.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              post.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.4),
            ),
            const SizedBox(height: 12),
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