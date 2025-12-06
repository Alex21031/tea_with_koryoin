class Post {
  final int id;
  final String title;
  final String content;
  final String author;
  final String authorRole;
  final String createdAt;
  final int views;
  final int likes;
  final int commentCount;
  final String category;

  Post({
    required this.id, required this.title, required this.content, required this.author,
    required this.authorRole, required this.createdAt,
    this.views = 0, this.likes = 0, this.commentCount = 0, this.category = '자유 게시판',
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      author: json['author'],
      authorRole: json['author_role'] ?? 'general',
      createdAt: json['created_at'],
      views: json['views'] ?? 0,
      likes: json['likes'] ?? 0,
      commentCount: json['comment_count'] ?? 0,
      category: json['category'] ?? '자유 게시판',
    );
  }
}

class Comment {
  final int id;
  final String content;
  final String username;
  final String createdAt;

  Comment({required this.id, required this.content, required this.username, required this.createdAt});

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      content: json['content'],
      username: json['username'],
      createdAt: json['created_at'],
    );
  }
}