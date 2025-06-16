import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'dart:math';
import '../../models/review_model.dart';
import '../../models/user_model.dart';
import '../../controllers/user_controller.dart';
import '../../models/user_session.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchText = '';
  String _selectedTab = 'Our picks';
  String? _selectedCategory;
  final DatabaseReference _businessRef =
  FirebaseDatabase.instance.ref().child('businesses');
  Position? _currentPosition;
  late User _user;
  late Future<List<Review>> _userReviewsFuture;
  Set<String> _availableCategories = {};
  final UserController _userController = UserController();

  @override
  void initState() {
    super.initState();
    _user = UserSession.user!;
    _userReviewsFuture = _fetchUserReviews(_user.userId);
    _fetchCurrentLocation();
  }



  Future<List<Review>> _fetchUserReviews(String userId) async {
    final snapshot = await FirebaseDatabase.instance.ref('reviews').get();
    List<Review> allReviews = [];

    if (snapshot.exists && snapshot.value is Map) {
      final reviewData = Map<String, dynamic>.from(snapshot.value as Map);

      reviewData.forEach((restaurantId, reviews) {
        final restaurantReviews = Map<String, dynamic>.from(reviews);
        restaurantReviews.forEach((reviewId, review) {
          final parsedReview = Review.fromMap(
            Map<String, dynamic>.from(review),
            reviewId,
          );

          if (parsedReview.userId == userId) {
            allReviews.add(parsedReview);
          }
        });
      });
    }

    return allReviews;
  }

  Future<void> _handleRegisterBusiness() async {
    if (_user.userType == 0) {
      print("MAKING AN OWNER");
      await _userController.makeOwner(_user.userId);

      // 🔔 Fetch the updated user from the database
      final updatedUser = await _userController.getUser(_user.userId);
      setState(() {
        _user = updatedUser!;
      });
    } else {
      print("ALREADY AN OWNER");
    }

    Navigator.pushNamedAndRemoveUntil(context, '/ownerhome', (_) => false);
  }


  Future<void> _fetchCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) return;
    }

    final position = await Geolocator.getCurrentPosition();
    setState(() => _currentPosition = position);
  }

  // Optimistic toggle — update UI instantly, then sync with Firebase
  void _toggleFavorite(String businessId) {
    final isCurrentlyFavorite = _user.favorites.contains(businessId);

    // 🔁 Immediately update local state
    setState(() {
      _user = _user.copyWith(
        favorites: isCurrentlyFavorite
            ? _user.favorites.where((id) => id != businessId).toList()
            : [..._user.favorites, businessId],
      );
    });

    // 🟡 Run Firebase update in background
    _performToggleFavorite(businessId, isCurrentlyFavorite);
  }

  Future<void> _performToggleFavorite(
      String businessId, bool isCurrentlyFavorite) async {
    try {
      await _userController.toggleFavorite(_user.userId, businessId, _user.favorites);
    } catch (e) {
      // Revert UI if Firebase fails
      setState(() {
        _user = _user.copyWith(
          favorites: isCurrentlyFavorite
              ? [..._user.favorites, businessId]
              : _user.favorites.where((id) => id != businessId).toList(),
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update favorites: $e")),
      );
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371;
    double dLat = _deg2rad(lat2 - lat1);
    double dLon = _deg2rad(lon2 - lon1);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180);

  Widget _buildCategoryDropdown() {
    List<String> categories = _availableCategories.toList()..sort();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: DropdownButton<String>(
        hint: const Text("Filter by category"),
        value: _selectedCategory,
        isExpanded: true,
        items: [
          const DropdownMenuItem(
            value: null,
            child: Text("All Categories"),
          ),
          ...categories.map((cat) => DropdownMenuItem(
            value: cat,
            child: Text(cat),
          )),
        ],
        onChanged: (val) => setState(() => _selectedCategory = val),
      ),
    );
  }

  Widget _buildTab(String label) {
    final isSelected = _selectedTab == label;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = label),
        child: Chip(
          label: Text(label),
          backgroundColor: isSelected ? Colors.blueAccent : Colors.grey.shade300,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        drawer: Drawer(
          child: SafeArea(
            child: Column(
              children: [

                UserAccountsDrawerHeader(
                  accountName: Text(UserSession.user?.username ?? 'User Name'),
                  accountEmail: const Text(''), // ✅ Avoid null issues
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text(
                      (UserSession.user?.username.isNotEmpty == true)
                          ? UserSession.user!.username[0]
                          : 'U',
                      style: const TextStyle(fontSize: 24, color: Colors.white),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.business_sharp),
                  title: const Text('Register a business'),
                  onTap: _handleRegisterBusiness,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Your Reviews',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<Review>>(
                    future: _fetchUserReviews(UserSession.userId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('No reviews yet.'));
                      } else {
                        return ListView.builder(
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            final review = snapshot.data![index];
                            return ListTile(
                              leading: const Icon(Icons.rate_review),
                              title: Text("${review.rating} ★"),
                              subtitle: Text(review.comment),
                            );
                          },
                        );
                      }
                    },
                  ),
                ),
                const Spacer(), // ✅ Pushes Logout to bottom
                ListTile(
                  leading: const Icon(Icons.verified_user),
                  title: const Text('About Us'),
                  onTap: () {
                    Navigator.pushNamedAndRemoveUntil(context, '/aboutus', (_) => false);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Logout'),
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
                  },
                ),
              ],
            ),
          ),
        ),

        appBar: AppBar(
          title: const Text('Welp!')
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search businesses...',
                fillColor: Colors.white,
                filled: true,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (val) {
                setState(() => _searchText = val.toLowerCase());
              },
            ),
          ),
          const SizedBox(height: 10),
          _buildCategoryDropdown(),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  _buildTab('Our picks'),
                  _buildTab('For you'),
                  _buildTab('Near you'),
                  _buildTab('Your favorites'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: _businessRef.onValue,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                List<Map<String, dynamic>> businessList = data.entries
                    .map((entry) => {
                  'id': entry.key,
                  ...Map<String, dynamic>.from(entry.value),
                })
                    .where((business) =>
                    (business['name'] ?? '').toLowerCase().contains(_searchText))
                    .toList();

                _availableCategories = businessList
                    .map((b) => b['category']?.toString() ?? '')
                    .where((c) => c.isNotEmpty)
                    .toSet();

                if (_selectedCategory != null) {
                  businessList = businessList
                      .where((b) => b['category'] == _selectedCategory)
                      .toList();
                }

                if (_selectedTab == 'Your favorites') {
                  businessList = businessList
                      .where((b) => _user.favorites.contains(b['id']))
                      .toList();
                }

                if (_selectedTab == 'Near you' && _currentPosition != null) {
                  businessList = businessList.map((b) {
                    final lat = b['latitude'];
                    final lon = b['longitude'];
                    if (lat != null && lon != null) {
                      final distance = _calculateDistance(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                        lat.toDouble(),
                        lon.toDouble(),
                      );
                      b['distance'] = distance;
                    } else {
                      b['distance'] = double.infinity;
                    }
                    return b;
                  }).toList();

                  businessList.sort((a, b) => (a['distance'] as double)
                      .compareTo(b['distance'] as double));
                }

                return ListView.builder(
                  itemCount: businessList.length,
                  itemBuilder: (context, index) {
                    final business = businessList[index];
                    final avgRating = (business['averageRating'] ?? 0).toDouble();
                    final isFavorite = _user.favorites.contains(business['id']);

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.image, size: 30),
                        ),
                        title: Text(business['name'] ?? 'Unnamed'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(business['category'] ?? 'No category'),
                            const SizedBox(height: 4),
                            Row(
                              children: List.generate(5, (i) {
                                if (i < avgRating.floor()) {
                                  return const Icon(Icons.star, size: 16, color: Colors.orange);
                                } else if (i < avgRating && avgRating - i >= 0.5) {
                                  return const Icon(Icons.star_half, size: 16, color: Colors.orange);
                                } else {
                                  return const Icon(Icons.star_border, size: 16, color: Colors.orange);
                                }
                              }),
                            ),
                            if (_selectedTab == 'Near you' && business['distance'] != null)
                              Text(
                                '${business['distance'].toStringAsFixed(2)} km away',
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : Colors.grey,
                          ),
                          onPressed: () => _toggleFavorite(business['id']),
                        ),
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/business/${business['id']}',
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}