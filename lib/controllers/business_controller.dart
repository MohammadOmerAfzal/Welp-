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
    } catch (e) {
      print('Error adding business: $e');
    }
  }
}
