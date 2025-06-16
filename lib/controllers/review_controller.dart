// ------------------ controllers/review_controller.dart ------------------
import 'package:firebase_database/firebase_database.dart';
import '../models/review_model.dart';

class ReviewController {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  /// Fetch reviews for a specific restaurant
  Future<List<Review>> fetchReviews(String businessId) async {
    try {
      final snapshot = await _db.child('reviews/$businessId').get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return data.entries.map((entry) {
          return Review.fromMap(Map<String, dynamic>.from(entry.value), entry.key);
        }).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching reviews: $e');
      return [];
    }
  }

  /// Add a new review to a restaurant
  Future<void> addReview(String businessId, String userId, Review review) async {
    try {
      // 1. Push review to reviews node
      await _db.child('reviews/$businessId').push().set(review.toMap());

      // 2. Also update user's personal review map
      await _db.child('users/$userId/reviews/$businessId').set(review.comment);
    } catch (e) {
      print('Error adding review: $e');
    }
  }
  /// Add or update a reply to a specific review
  Future<void> addReplyToReview(String businessId, String reviewId, String reply) async {
    try {
      await _db.child('reviews/$businessId/$reviewId/reply').set(reply);
      print('Reply added to review $reviewId');
    } catch (e) {
      print('Error adding reply: $e');
    }
  }

}
