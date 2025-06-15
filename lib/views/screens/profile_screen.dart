import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../models/review_model.dart';
import '../../models/user_session.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<List<Review>> userReviews;

  @override
  void initState() {
    super.initState();
    userReviews = _fetchUserReviews();
  }

  Future<List<Review>> _fetchUserReviews() async {
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

          if (parsedReview.userId == UserSession.userId) {
            allReviews.add(parsedReview);
          }
        });
      });
    }

    return allReviews;
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Your Profile')),
      body: Column(
        children: [
          ListTile(
            title: Text(UserSession.userName),
            subtitle: Text(UserSession.userEmail),
            trailing: IconButton(
              icon: Icon(Icons.logout),
              onPressed: _logout,
            ),
          ),
          Divider(),
          Expanded(
            child: FutureBuilder<List<Review>>(
              future: userReviews,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No reviews yet.'));
                } else {
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final review = snapshot.data![index];
                      return ListTile(
                        title: Text("${review.rating} ★"),
                        subtitle: Text(review.comment),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
