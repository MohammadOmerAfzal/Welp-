// controllers/user_controller.dart
import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';

class UserController {
  final DatabaseReference _db = FirebaseDatabase.instance.ref().child('users');

  Future<User?> getUser(String userId) async {
    final ref = _db.child(userId);
    final snapshot = await ref.get();
    if (snapshot.exists) {
      return User.fromMap(Map<String, dynamic>.from(snapshot.value as Map));
    }
    return null;
  }


  Future<void> updateFavorites(String userId, List<String> favorites) async {
    if (userId.isEmpty) {
      print('❌ Invalid username: Cannot update favorites.');
      return;
    }
    try {
      await _db.child(userId).update({'favorites': favorites});
      print('🔥 Writing favorites to: /users/$userId/favorites');

    } catch (e) {
      print('Error updating favorites: $e');
    }
  }


  Future<void> toggleFavorite(String userId, String businessId, List<String> currentFavorites) async {
    final updatedFavorites = List<String>.from(currentFavorites);
    if (updatedFavorites.contains(businessId)) {
      updatedFavorites.remove(businessId);
    } else {
      updatedFavorites.add(businessId);
    }
    await updateFavorites(userId, updatedFavorites);
  }
  Future<void> makeOwner(String userId) async {
    try {
      await _db.child(userId).update({'userType': 1});
      print('✅ User $userId is now an owner.');
    } catch (e) {
      print('❌ Error making user owner: $e');
    }
  }


  Future<void> updateUser(User user) async {
    try {
      await _db.child(user.userId).set(user.toMap());
    } catch (e) {
      print('Error updating user: $e');
    }
  }
}