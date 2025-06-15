// controllers/user_controller.dart
import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';

class UserController {
  final DatabaseReference _db = FirebaseDatabase.instance.ref().child('users');

  Future<User?> getUser(String userId) async {
    final ref = FirebaseDatabase.instance.ref('users/$userId');
    final snapshot = await ref.get();
    if (snapshot.exists) {
      return User.fromMap(Map<String, dynamic>.from(snapshot.value as Map));
    }
    return null;
  }


  Future<void> updateFavorites(String username, List<String> favorites) async {
    try {
      await _db.child(username).update({'favorites': favorites});
    } catch (e) {
      print('Error updating favorites: $e');
    }
  }

  Future<void> toggleFavorite(String username, String businessId, List<String> currentFavorites) async {
    final updatedFavorites = List<String>.from(currentFavorites);
    if (updatedFavorites.contains(businessId)) {
      updatedFavorites.remove(businessId);
    } else {
      updatedFavorites.add(businessId);
    }
    await updateFavorites(username, updatedFavorites);
  }

  Future<void> updateUser(User user) async {
    try {
      await _db.child(user.username).set(user.toMap());
    } catch (e) {
      print('Error updating user: $e');
    }
  }
}
