class Post {
  final int id;
  final int userId;
  final String title;
  final String content;
  final String category;
  final String? createdAt;
  final int viewCount;
  final int likeCount;
  final int commentCount;
  // UI에서 author를 찾으므로 추가 (DB에 없으면 '익명' 처리)
  final String author; 

  Post({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.category,
    this.createdAt,
    this.viewCount = 0,
    this.likeCount = 0,
    this.commentCount = 0,
    this.author = '익명',
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] is int ? json['id'] : 0,
      userId: json['user_id'] is int ? json['user_id'] : 0,
      title: json['title']?.toString() ?? '제목 없음',
      content: json['content']?.toString() ?? '',
      category: json['category']?.toString() ?? 'free',
      createdAt: json['created_at']?.toString(),
      viewCount: json['views'] is int ? json['views'] : 0,
      likeCount: json['likes'] is int ? json['likes'] : 0,
      commentCount: json['comment_count'] is int ? json['comment_count'] : 0,
      // DB에서 author_name 같은걸 안 주면 그냥 '익명'
      author: json['author_name']?.toString() ?? '익명', 
    );
  }
}

// ✅ [추가됨] Comment 클래스 정의
class Comment {
  final int id;
  final int postId;
  final int userId;
  final String content;
  final String? createdAt;
  final String author;

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    this.createdAt,
    this.author = '익명',
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] is int ? json['id'] : 0,
      postId: json['post_id'] is int ? json['post_id'] : 0,
      userId: json['user_id'] is int ? json['user_id'] : 0,
      content: json['content']?.toString() ?? '',
      createdAt: json['created_at']?.toString(),
      author: json['author_name']?.toString() ?? '익명',
    );
  }
}