import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'dart:math';
import '../../models/review_model.dart';
import '../../models/user_model.dart';
import '../../controllers/user_controller.dart';
import '../../models/user_session.dart';
import 'for_you_section.dart';
import '../../models/business_model.dart';


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

  void _toggleFavorite(String businessId) {
    final isCurrentlyFavorite = _user.favorites.contains(businessId);

    setState(() {
      _user = _user.copyWith(
        favorites: isCurrentlyFavorite
            ? _user.favorites.where((id) => id != businessId).toList()
            : [..._user.favorites, businessId],
      );
    });

    _performToggleFavorite(businessId, isCurrentlyFavorite);
  }

  Future<void> _performToggleFavorite(
      String businessId, bool isCurrentlyFavorite) async {
    try {
      await _userController.toggleFavorite(
          _user.userId, businessId, _user.favorites);
    } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        drawer: _buildDrawer(),
    appBar: AppBar(
    title: const Text('Welp',
    style: TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 24,
    color: Colors.white,
    )),
    centerTitle: false,
    flexibleSpace: Container(
    decoration: const BoxDecoration(
    gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.deepPurpleAccent,
      Colors.deepPurple,
      Color(0xFF6A1B9A),
    ],
    ),
    ),
    ),
    elevation: 0,
    iconTheme: const IconThemeData(color: Colors.white),
    actions: [
    IconButton(
    icon: const Icon(Icons.notifications_outlined),
    onPressed: () {},
    tooltip: 'Notifications',
    ),
    ],
    ),
    body: Container(
    decoration: const BoxDecoration(
    gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [

      Color(0xFFEDE7F6), // Light purple 50
      Color(0xFFD1C4E9), // Light purple 100
      // Color(0xFFB39DDB),
    ],
    stops: [0.1, 0.5],
    ),
    ),
    child: CustomScrollView(
    slivers: [
    // Search Section
    SliverToBoxAdapter(
    child: Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Container(
    decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
    BoxShadow(
    color: Colors.black.withOpacity(0.1),
    blurRadius: 6,
    offset: const Offset(0, 2),
    ),
    ],
    gradient: const LinearGradient(
    colors: [Colors.white, Color(0xFFEDE7F6), Color(0xFFD1C4E9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    ),
    ),
    child: TextField(
    decoration: InputDecoration(
    hintText: 'Search businesses...',
    prefixIcon: const Icon(Icons.search, color: Colors.deepPurpleAccent),
    filled: true,
    fillColor: Colors.transparent,
    border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(vertical: 12),
    suffixIcon: _selectedCategory != null
    ? IconButton(
    icon: const Icon(Icons.close, size: 20),
    onPressed: () => setState(() => _selectedCategory = null),
    )
        : null,
    ),
    onChanged: (val) => setState(() => _searchText = val.toLowerCase()),
    ),
    ),
    ),
    ),

    // Categories Section
    SliverToBoxAdapter(
    child: SizedBox(
    height: 50,
    child: ListView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    children: [
    _buildCategoryChip(null, 'All'),
    ..._availableCategories.map((category) =>
    _buildCategoryChip(category, category)),
    ],
    ),
    ),
    ),

    // Tabs Section
    SliverToBoxAdapter(
    child: Container(
    height: 50,
    decoration: BoxDecoration(
    gradient: const LinearGradient(
    colors: [Color(0xFFEDE7F6), Color(0xFFD1C4E9)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    ),
    boxShadow: [
    BoxShadow(
    color: Colors.grey.withOpacity(0.1),
    blurRadius: 4,
    offset: const Offset(0, 2),
    ),
    ],
    ),
    child: ListView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    children: [
    _buildTab('Our picks'),
    _buildTab('For you'),
    _buildTab('Near you'),
    _buildTab('Favorites'),
    ],
    ),
    ),
    ),

          // Business List Section
          StreamBuilder<DatabaseEvent>(
            stream: _businessRef.onValue,
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
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

              if (_selectedTab == 'Favorites') {
                businessList = businessList
                    .where((b) => _user.favorites.contains(b['id']))
                    .toList();
              }
              if (_selectedTab == 'For you') {
                // Convert snapshot businesses into Business objects
                final allBusinesses = businessList.map((b) {
                  return Business(
                    id: b['id'],
                    ownerid: b['ownerid'],
                    name: b['name'] ?? '',
                    category: b['category'] ?? '',
                    description: b['description'] ?? '',
                    location: b['location'] ?? '',
                    latitude: b['latitude']?.toDouble() ?? 0.0,
                    longitude: b['longitude']?.toDouble() ?? 0.0,
                    averageRating: b['averageRating']?.toDouble() ?? 0.0,
                    imageBase64List: (b['images'] as List?)?.map((img) => img.toString()).toList() ?? [],
                  );
                }).toList();

                // Show ForYouSection inside SliverToBoxAdapter
                return SliverToBoxAdapter(
                  child: ForYouSection(
                    user: _user,
                    allBusinesses: allBusinesses,
                    userLat: _currentPosition?.latitude,
                    userLong: _currentPosition?.longitude,
                  ),
                );
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

              if (businessList.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 60, color: Colors.deepPurple),
                        const SizedBox(height: 16),
                        Text(
                          'No businesses found',
                          style: TextStyle(
                            color: Colors.deepPurple,
                            fontSize: 18,
                          ),
                        ),
                        if (_selectedCategory != null || _searchText.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedCategory = null;
                                _searchText = '';
                              });
                            },
                            child: const Text('Clear filters'),
                          ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final business = businessList[index];
                      final avgRating = (business['averageRating'] ?? 0).toDouble();
                      final isFavorite = _user.favorites.contains(business['id']);

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
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/business/${business['id']}',
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Stack(
                                    children: [
                                      // Business Image
                                      AspectRatio(
                                        aspectRatio: 16 / 9,
                                        child: (business['images'] != null &&
                                            business['images'] is List &&
                                            business['images'].isNotEmpty)
                                            ? Image.network(
                                          business['images'][0],
                                          fit: BoxFit.cover,
                                        )
                                            : Container(
                                          color: Colors.grey[200],
                                          child: Center(
                                            child: Icon(
                                              Icons.image_not_supported,
                                              size: 50,
                                              color: Colors.deepPurple,
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Favorite Button


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
                                          mainAxisAlignment:
                                          MainAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    business['name'] ?? 'Unnamed',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 18,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  business['description'] ?? 'No category',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                ],
                                              )
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                isFavorite ? Icons.favorite : Icons.favorite_border,
                                                color: isFavorite ? Colors.red : Colors.black,
                                                size: 28,
                                              ),
                                              onPressed: () => _toggleFavorite(business['id']),
                                            ),
                                          ],
                                        ),

                                        if (_selectedTab == 'Near you' &&
                                            business['distance'] != null)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 8),
                                            child: Row(
                                              children: [
                                                Icon(Icons.location_on,
                                                    size: 16, color: Colors.deepPurple),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${business['distance'].toStringAsFixed(1)} km',
                                                  style: TextStyle(
                                                      color: Colors.grey[600]),
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
                    childCount: businessList.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          // Header
          Container(
            height: 200,
            decoration: const BoxDecoration(
              // color: Colors.blueAccent,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.deepPurple,
                  child: Text(
                    _user.username[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _user.username,
                  style: const TextStyle(
                    color: Colors.deepPurpleAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.business, color: Colors.deepPurpleAccent),
                  title: const Text('Register Business'),
                  onTap: _handleRegisterBusiness,
                ),
                const Divider(height: 1),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'YOUR REVIEWS',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurpleAccent,
                      fontSize: 12,
                    ),
                  ),
                ),
                FutureBuilder<List<Review>>(
                  future: _userReviewsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No reviews yet'),
                      );
                    }
                    return Column(
                      children: snapshot.data!.map((review) => ListTile(
                        leading: const Icon(Icons.star, color: Colors.amber),
                        title: Text("${review.rating} ★"),
                        subtitle: Text(
                          review.comment,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                      )).toList(),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info, color: Colors.deepPurpleAccent),
                  title: const Text('About Us'),
                  onTap: () {
                    Navigator.pushNamed(context, '/aboutus');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.deepPurpleAccent),
                  title: const Text('Logout'),
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/', (route) => false);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String? value, String label) {
    final isSelected = _selectedCategory == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedCategory = selected ? value : null);
        },
        backgroundColor: Colors.deepPurple,
        selectedColor: Colors.deepPurpleAccent,
        labelStyle: TextStyle(
          color: Colors.white ,
          fontWeight: FontWeight.w500,
        ),
        shape: StadiumBorder(
          side: BorderSide(
            color: isSelected ? Colors.deepPurpleAccent : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String label) {
    final isSelected = _selectedTab == label;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) setState(() => _selectedTab = label);
        },
        backgroundColor: Colors.deepPurple,
        selectedColor: Colors.deepPurpleAccent,
        labelStyle: TextStyle(
          color:  Colors.white ,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? Colors.transparent : Colors.blueGrey[300]!,
          ),
        ),
        elevation: isSelected ? 2 : 0,
      ),
    );
  }
}