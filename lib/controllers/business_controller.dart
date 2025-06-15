import 'package:firebase_database/firebase_database.dart';
import '../models/business_model.dart';

class BusinessController {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  /// Fetch all businesses
  Future<List<Business>> fetchBusinesses() async {
    try {
      final snapshot = await _db.child('businesses').get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return data.entries.map((entry) {
          return Business.fromMap(Map<String, dynamic>.from(entry.value), entry.key);
        }).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching businesses: $e');
      return [];
    }
  }

  /// Get a single business by ID
  Future<Business> getBusiness(String id) async {
    try {
      final snapshot = await _db.child('businesses/$id').get();
      if (snapshot.exists) {
        return Business.fromMap(Map<String, dynamic>.from(snapshot.value as Map), id);
      } else {
        throw Exception('Business not found');
      }
    } catch (e) {
      print('Error fetching business $id: $e');
      rethrow;
    }
  }

  /// Add a new business
  Future<void> addBusiness(Business business) async {
    try {
      final newRef = _db.child('businesses').push();
      await newRef.set(business.toMap());

      // Optionally store business ID under user's node
      await _db.child('users/${business.ownerid}/businesses/${newRef.key}').set(true);
    } catch (e) {
      print('Error adding business: $e');
    }
  }

  /// Fetch businesses owned by a specific user
  Future<List<Business>> fetchBusinessesByUser(String userId) async {
    try {
      final snapshot = await _db.child('businesses').get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return data.entries
            .map((entry) => Business.fromMap(Map<String, dynamic>.from(entry.value), entry.key))
            .where((business) => business.ownerid == userId)
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching user businesses: $e');
      return [];
    }
  }

  /// Delete a business by ID and clean related data
  Future<void> deleteBusiness(String businessId) async {
    try {
      final businessSnapshot = await _db.child('businesses/$businessId').get();
      if (!businessSnapshot.exists) {
        print('Business not found: $businessId');
        return;
      }

      final businessData = Map<String, dynamic>.from(businessSnapshot.value as Map);
      final ownerId = businessData['ownerid'];

      // Delete the business itself
      await _db.child('businesses/$businessId').remove();

      // Delete all reviews associated with the business
      await _db.child('reviews/$businessId').remove();

      // Remove business reference from user's businesses list
      await _db.child('users/$ownerId/businesses/$businessId').remove();

      print('Successfully deleted business $businessId and cleaned up related data.');
    } catch (e) {
      print('Error deleting business and related data: $e');
    }
  }
}
