// ------------------ controllers/restaurant_controller.dart ------------------
import 'package:firebase_database/firebase_database.dart';
import '../models/restaurant_model.dart';

class RestaurantController {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  /// Fetch all restaurants
  Future<List<Restaurant>> fetchRestaurants() async {
    try {
      final snapshot = await _db.child('restaurants').get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return data.entries.map((entry) {
          return Restaurant.fromMap(Map<String, dynamic>.from(entry.value), entry.key);
        }).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching restaurants: $e');
      return [];
    }
  }

  /// Get a single restaurant by ID
  Future<Restaurant> getRestaurant(String id) async {
    try {
      final snapshot = await _db.child('restaurants/$id').get();
      if (snapshot.exists) {
        return Restaurant.fromMap(Map<String, dynamic>.from(snapshot.value as Map), id);
      } else {
        throw Exception('Restaurant not found');
      }
    } catch (e) {
      print('Error fetching restaurant $id: $e');
      rethrow;
    }
  }
}
