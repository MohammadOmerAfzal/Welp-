class Review {
  String id;
  String userId;
  String userName;
  double rating;
  String comment;
  final String? imageUrl; // Nullable
  final String timestamp;

  String? reply;

  Review({
    required this.id,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    this.imageUrl,
    this.reply,
    required this.timestamp,
  });

  factory Review.fromMap(Map<String, dynamic> data, String docId) {
    return Review(
      id: docId,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      comment: data['comment'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      reply: data['reply'] ?? '',
      timestamp: data['timestamp'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'imageUrl': imageUrl,
      'timestamp': timestamp,
      if (reply != null) 'reply': reply,
    };
  }
}
