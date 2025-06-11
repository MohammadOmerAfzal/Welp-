// ------------------ controllers/review_controller.dart ------------------
import 'package:firebase_database/firebase_database.dart';
import '../models/review_model.dart';

class ReviewController {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  /// Fetch reviews for a specific restaurant
  Future<List<Review>> fetchReviews(String restaurantId) async {
    try {
      final snapshot = await _db.child('reviews/$restaurantId').get();
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
  Future<void> addReview(String restaurantId, Review review) async {
    try {
      await _db.child('reviews/$restaurantId').push().set(review.toMap());
    } catch (e) {
      print('Error adding review: $e');
    }
  }
}
