import '../../main.dart';
import 'package:flutter/material.dart';
import '../../controllers/restaurant_controller.dart';
import '../../controllers/review_controller.dart';
import '../../models/restaurant_model.dart';
import '../../models/review_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:io';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final String restaurantId;
  RestaurantDetailScreen({required this.restaurantId});

  @override
  _RestaurantDetailScreenState createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  final RestaurantController restaurantController = RestaurantController();
  final ReviewController reviewController = ReviewController();
  final TextEditingController commentController = TextEditingController();

  File? _imageFile;
  LatLng? _location;
  String? _restaurantName;
  String? _restaurantImagePath;

  late Future<List<Review>> reviewFuture;

  @override
  void initState() {
    super.initState();
    reviewFuture = reviewController.fetchReviews(widget.restaurantId);
    _fetchRestaurantData();
  }

  Future<void> _fetchRestaurantData() async {
    final snapshot = await FirebaseDatabase.instance
        .ref()
        .child('restaurants/${widget.restaurantId}')
        .get();

    final data = snapshot.value as Map?;
    if (data != null) {
      setState(() {
        _restaurantName = data['name'];
        _restaurantImagePath = data['imagePath'];
        if (data['latitude'] != null && data['longitude'] != null) {
          _location = LatLng(
            data['latitude'] * 1.0, // Ensures double type
            data['longitude'] * 1.0,
          );
        }
      });
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<String?> _uploadImage(File file) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref =
    FirebaseStorage.instance.ref().child('review_images/$fileName');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> _submitReview() async {
    String? imageUrl;
    if (_imageFile != null) {
      imageUrl = await _uploadImage(_imageFile!);
    }

    final review = Review(
      id: '',
      userId: currentUserId,
      userName: currentUserName,
      rating: 5.0,
      comment: commentController.text,
      imageUrl: imageUrl ?? '',
    );

    await reviewController.addReview(widget.restaurantId, review);

    setState(() {
      reviewFuture = reviewController.fetchReviews(widget.restaurantId);
      commentController.clear();
      _imageFile = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Restaurant Details')),
      body: Column(
        children: [
          if (_restaurantImagePath != null && File(_restaurantImagePath!).existsSync())
            Image.file(File(_restaurantImagePath!), height: 200, width: double.infinity, fit: BoxFit.cover)
          else
            Container(height: 200, color: Colors.grey[300], child: Center(child: Icon(Icons.image, size: 50))),

          if (_restaurantName != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _restaurantName!,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),

          if (_location != null)
            Container(
              height: 200,
              margin: EdgeInsets.symmetric(vertical: 8),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(target: _location!, zoom: 15),
                markers: {Marker(markerId: MarkerId('loc'), position: _location!)},
              ),
            ),

          Expanded(
            child: FutureBuilder<List<Review>>(
              future: reviewFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                final reviews = snapshot.data!;
                if (reviews.isEmpty) {
                  return Center(child: Text("No reviews yet."));
                }
                return ListView.builder(
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final r = reviews[index];
                    return ListTile(
                      title: Text(r.userName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.comment),
                          if (r.imageUrl.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Image.network(r.imageUrl, height: 150),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          Divider(),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                if (_imageFile != null)
                  Image.file(_imageFile!, height: 100),
                Row(
                  children: [
                    IconButton(icon: Icon(Icons.photo), onPressed: _pickImage),
                    Expanded(
                      child: TextField(
                        controller: commentController,
                        decoration: InputDecoration(labelText: 'Write a review'),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _submitReview,
                      child: Text('Post'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
