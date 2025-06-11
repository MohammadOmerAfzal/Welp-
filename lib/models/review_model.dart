// ------------------ models/review_model.dart ------------------
class Review {
  String id;
  String userId;
  String userName;
  double rating;
  String comment;
  String imageUrl;

  Review({
    required this.id,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.imageUrl,
  });

  factory Review.fromMap(Map<String, dynamic> data, String docId) {
    return Review(
      id: docId,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      comment: data['comment'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'imageUrl': imageUrl,
    };
  }
}