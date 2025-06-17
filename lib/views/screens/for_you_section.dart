import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/business_model.dart';
import '../../models/user_model.dart';

class ForYouSection extends StatelessWidget {
  final User user;
  final List<Business> allBusinesses;
  final double? userLat;
  final double? userLong;

  const ForYouSection({
    super.key,
    required this.user,
    required this.allBusinesses,
    this.userLat,
    this.userLong,
  });

  @override
  Widget build(BuildContext context) {
    final recommendations = getRecommendedBusinesses(
      user: user,
      allBusinesses: allBusinesses,
      userLat: userLat,
      userLong: userLong,
    );

    if (recommendations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No recommendations found',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 18,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: recommendations.length,
        itemBuilder: (context, index) {
          final business = recommendations[index];
          final avgRating = business.averageRating;
          final isFavorite = user.favorites.contains(business.id);

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Material(
                color: Colors.white,
                child: InkWell(
                  onTap: () {
                    // Replace with actual navigation logic
                    // Navigator.pushNamed(context, '/business/${business.id}');
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          // Business Image
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: business.imageBase64List.isNotEmpty
                                ? Image.network(
                              business.imageBase64List.first,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey[200],
                                child: Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 50,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ),
                            )
                                : Container(
                              color: Colors.grey[200],
                              child: Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 50,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ),
                          ),
                          // Rating Chip
                          if (avgRating > 0)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      avgRating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    const Icon(Icons.star,
                                        color: Colors.amber, size: 16),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      Divider(),
                      // Business Info
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        business.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        business.category,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // IconButton(
                                //   icon: Icon(
                                //     isFavorite ? Icons.favorite : Icons.favorite_border,
                                //     color: isFavorite ? Colors.red : Colors.black,
                                //     size: 28,
                                //   ),
                                //   onPressed: () {
                                //     // Handle favorite toggle here if needed
                                //   },
                                // ),
                              ],
                            ),
                            if (userLat != null && userLong != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  children: [
                                    Icon(Icons.location_on,
                                        size: 16, color: Colors.blue),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${_calculateDistance(userLat!, userLong!, business.latitude, business.longitude).toStringAsFixed(1)} km',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Business> getRecommendedBusinesses({
    required User user,
    required List<Business> allBusinesses,
    double? userLat,
    double? userLong,
  }) {
    final Set<String> favCategories = allBusinesses
        .where((b) => user.favorites.contains(b.id))
        .map((b) => b.category)
        .toSet();

    const double maxDistance = 50.0;

    List<Business> recommended = allBusinesses.where((b) {
      if (user.favorites.contains(b.id)) return false;

      final categoryMatch = favCategories.contains(b.category);

      bool locationMatch = true;
      if (userLat != null && userLong != null) {
        final dist = _calculateDistance(userLat, userLong, b.latitude, b.longitude);
        locationMatch = dist <= maxDistance;
      }

      return categoryMatch && locationMatch;
    }).toList();

    recommended.sort((a, b) => b.averageRating.compareTo(a.averageRating));
    return recommended;
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) * cos(_degToRad(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degToRad(double deg) => deg * (pi / 180);
}