import 'dart:convert';
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

  late DatabaseReference _businessRef;
  Map<String, dynamic>? _business;
  final TextEditingController _reviewController = TextEditingController();
  double _rating = 3.0;
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
      _reviews = reviews.reversed.toList(); // latest first
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
    final base64Image = _business!['image'];
    final latitude = _business!['latitude'];
    final longitude = _business!['longitude'];

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            base64Image != null
                ? Image.memory(
              base64Decode(base64Image),
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            )
                : Container(height: 200, color: Colors.grey, child: Icon(Icons.image, size: 100)),

            SizedBox(height: 12),
            Text(name, style: Theme.of(context).textTheme.titleMedium),
            Text('Category: $category', style: TextStyle(color: Colors.grey[700])),
            SizedBox(height: 8),
            Text(description),

            SizedBox(height: 20),
            Text('Location', style: Theme.of(context).textTheme.titleMedium),
            SizedBox(
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

            SizedBox(height: 24),
            Divider(),
            Text('Write a Review', style: Theme.of(context).textTheme.titleMedium),

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
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),

            SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _submitReview,
              icon: Icon(Icons.send),
              label: Text('Submit Review'),
            ),

            SizedBox(height: 30),
            Divider(),
            Text('Reviews', style: Theme.of(context).textTheme.titleMedium),
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
                  child: ListTile(
                    title: Text(r.comment ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Reply: ${ (r.reply == '') ? 'No replies yet' : r.reply! }", style: const TextStyle(color: Colors.green)),

                        SizedBox(height: 4),
                        RatingBarIndicator(
                          rating: rating,
                          itemCount: 5,
                          itemSize: 20,
                          itemBuilder: (context, _) => Icon(Icons.star, color: Colors.amber),
                        ),
                        SizedBox(height: 4),
                        Text('By ${r.userName ?? 'Anonymous'} • $formattedDate',
                            style: TextStyle(fontSize: 12,fontStyle: FontStyle.italic , color: Colors.grey[600])),
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