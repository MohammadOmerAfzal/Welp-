import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../../controllers/review_controller.dart';
import '../../models/review_model.dart';
import '../../models/user_session.dart';

class BusinessDetailScreen extends StatefulWidget {
  final String businessId;

  const BusinessDetailScreen({required this.businessId});

  @override
  _BusinessDetailScreenState createState() => _BusinessDetailScreenState();
}

class _BusinessDetailScreenState extends State<BusinessDetailScreen> {
  late DatabaseReference _businessRef;
  Map<String, dynamic>? _business;
  final TextEditingController _reviewController = TextEditingController();
  double _rating = 0.0;
  List<Review> _reviews = [];
  final ReviewController _reviewControllerLogic = ReviewController();

  @override
  void initState() {
    super.initState();
    _businessRef = FirebaseDatabase.instance.ref().child('businesses').child(widget.businessId);
    _loadBusiness();
    _loadReviews();
  }

  Future<void> _loadBusiness() async {
    final snapshot = await _businessRef.get();
    if (snapshot.exists) {
      setState(() {
        _business = Map<String, dynamic>.from(snapshot.value as Map);
      });
    }
  }

  Future<void> _loadReviews() async {
    final reviews = await _reviewControllerLogic.fetchReviews(widget.businessId);
    setState(() {
      _reviews = reviews.reversed.toList();
    });
  }

  Future<void> _submitReview() async {
    final comment = _reviewController.text.trim();

    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter review text')));
      return;
    }

    final userId = UserSession.userId;
    final userName = UserSession.userName;

    final review = Review(
      comment: comment,
      rating: _rating,
      userId: userId,
      userName: userName,
      timestamp: DateTime.now().toIso8601String(),
      id: '',
    );

    await _reviewControllerLogic.addReview(widget.businessId, userId, review);
    _reviewController.clear();
    setState(() => _rating = 3.0);
    await _loadReviews();
    await _updateAverageRating();

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ Review submitted')));

    Navigator.pushNamed(context, '/home');
  }

  Future<void> _updateAverageRating() async {
    double total = 0.0;
    int count = _reviews.length;

    for (final review in _reviews) {
      total += review.rating;
    }

    double avgRating = count > 0 ? total / count : 0.0;
    await _businessRef.update({'averageRating': avgRating});
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return 'Unknown date';

    try {
      final date = DateTime.parse(timestamp).toLocal();
      return '${date.year}-${_twoDigits(date.month)}-${_twoDigits(date.day)}';
    } catch (e) {
      print('Invalid timestamp format: $timestamp');
      return 'Unknown date';
    }
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    if (_business == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Business Detail')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final name = _business!['name'] ?? 'Unnamed';
    final category = _business!['category'] ?? 'Unknown';
    final description = _business!['description'] ?? '';
    final images = List<String>.from(_business!['images'] ?? []);
    final latitude = _business!['latitude'];
    final longitude = _business!['longitude'];

    return Scaffold(
      appBar: AppBar(
        title: Text(name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          )),
        backgroundColor: Colors.deepPurple,

        // actions: [Icon(Icons.business_center)],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: images.isNotEmpty
                  ? Image.network(
                images.first,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              )
                  : Container(
                height: 200,
                color: Colors.deepPurple,
                child: Icon(Icons.image_not_supported, size: 100, color: Colors.white),
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.storefront, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text(name, style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.category, size: 18, color: Colors.deepPurpleAccent),
                SizedBox(width: 4),
                Text('Category: $category', style: TextStyle(color: Colors.deepPurpleAccent))
              ],
            ),
            SizedBox(height: 8),
            Text(description, style: TextStyle(fontSize: 16)),
            SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text('Location', style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Colors.deepPurple))
              ],
            ),
            SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 200,
                child: latitude != null && longitude != null
                    ? GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(latitude, longitude),
                    zoom: 14,
                  ),
                  markers: {
                    Marker(
                      markerId: MarkerId('business'),
                      position: LatLng(latitude, longitude),
                    ),
                  },
                  onMapCreated: (_) {},
                )
                    : Center(child: Text('Location not available')),
              ),
            ),
            SizedBox(height: 24),
            Divider(),
            Row(
              children: [
                Icon(Icons.rate_review, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text('Write a Review', style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Colors.deepPurple))
              ],
            ),
            SizedBox(height: 8),
            RatingBar.builder(
              initialRating: _rating,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemSize: 30,
              itemBuilder: (context, _) => Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: (rating) => setState(() => _rating = rating),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _reviewController,
              decoration: InputDecoration(
                hintText: 'Enter your review...',
                filled: true,
                fillColor: Colors.purple[50],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
              onPressed: _submitReview,
              icon: Icon(Icons.send, color: Colors.white,),
              label: Text('Submit Review', style:TextStyle(color: Colors.white,fontWeight: FontWeight.bold,)),
            ),
            SizedBox(height: 30),
            Divider(),
            Row(
              children: [
                Icon(Icons.comment, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text('Reviews', style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Colors.deepPurple))
              ],
            ),
            SizedBox(height: 8),
            _reviews.isEmpty
                ? Text('No reviews yet.')
                : ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _reviews.length,
              itemBuilder: (context, index) {
                final r = _reviews[index];
                final rating = r.rating ?? 0.0;
                final formattedDate = _formatTimestamp(r.timestamp);

                return Card(
                  margin: EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person, size: 20, color: Colors.deepPurple),
                            SizedBox(width: 6),
                            Text('${r.userName ?? 'Anonymous'} • $formattedDate',
                                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.deepPurple)),
                          ],
                        ),
                        SizedBox(height: 6),
                        Text(r.comment ?? '', style: TextStyle(fontWeight: FontWeight.w600)),
                        SizedBox(height: 4),
                        RatingBarIndicator(
                          rating: rating,
                          itemCount: 5,
                          itemSize: 20,
                          itemBuilder: (context, _) => Icon(Icons.star, color: Colors.amber),
                        ),
                        SizedBox(height: 4),
                        Text("\nOwner's Reply:\n${ (r.reply == '') ? 'No replies yet' : r.reply! }",
                            style: const TextStyle(color: Colors.deepPurpleAccent)),
                      ],
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
}