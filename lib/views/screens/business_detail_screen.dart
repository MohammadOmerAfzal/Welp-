import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class BusinessDetailScreen extends StatefulWidget {
  final String businessId;

  const BusinessDetailScreen({required this.businessId});

  @override
  _BusinessDetailScreenState createState() => _BusinessDetailScreenState();
}

class _BusinessDetailScreenState extends State<BusinessDetailScreen> {
  late DatabaseReference _businessRef;
  late DatabaseReference _reviewsRef;
  Map<String, dynamic>? _business;
  final TextEditingController _reviewController = TextEditingController();
  double _rating = 0.0;
  List<Map<String, dynamic>> _reviews = [];

  @override
  void initState() {
    super.initState();
    _businessRef = FirebaseDatabase.instance.ref().child('businesses').child(widget.businessId);
    _reviewsRef = FirebaseDatabase.instance.ref().child('reviews').child(widget.businessId);
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
    final snapshot = await _reviewsRef.get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final list = data.entries.map((e) {
        final review = Map<String, dynamic>.from(e.value);
        review['id'] = e.key;
        return review;
      }).toList();

      setState(() {
        _reviews = list.reversed.toList(); // latest first
      });
    }
  }

  Future<void> _submitReview() async {
    final text = _reviewController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter review text')));
      return;
    }

    await _reviewsRef.push().set({
      'text': text,
      'rating': _rating,
      'timestamp': DateTime.now().toIso8601String(),
    });

    _reviewController.clear();
    setState(() => _rating = 3.0);
    _loadReviews();

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ Review submitted')));
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
                final timestamp = r['timestamp'] ?? '';
                final rating = r['rating']?.toDouble() ?? 0.0;
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    title: Text(r['text'] ?? ''),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RatingBarIndicator(
                          rating: rating,
                          itemCount: 5,
                          itemSize: 20,
                          itemBuilder: (context, _) => Icon(Icons.star, color: Colors.amber),
                        ),
                        SizedBox(height: 4),
                        Text(timestamp.toString(), style: TextStyle(fontSize: 12, color: Colors.grey)),
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
