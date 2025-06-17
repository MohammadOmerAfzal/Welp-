import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/review_controller.dart';
import '../../models/review_model.dart';

class ReviewScreen extends StatefulWidget {
  final String businessId;

  const ReviewScreen({Key? key, required this.businessId}) : super(key: key);

  @override
  _ReviewScreenState createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final ReviewController _reviewController = ReviewController();
  late Future<List<Review>> _reviewsFuture;
  final Map<String, TextEditingController> _replyControllers = {};

  @override
  void initState() {
    super.initState();
    _reviewsFuture = _reviewController.fetchReviews(widget.businessId);
  }

  @override
  void dispose() {
    for (var controller in _replyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submitReply(String reviewId) async {
    final reply = _replyControllers[reviewId]?.text.trim();
    if (reply != null && reply.isNotEmpty) {
      await _reviewController.addReplyToReview(widget.businessId, reviewId, reply);
      setState(() {
        _reviewsFuture = _reviewController.fetchReviews(widget.businessId);
      });
      _replyControllers[reviewId]?.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reply added')),
      );
    }
  }

  Widget _buildReviewCard(Review review) {
    _replyControllers.putIfAbsent(review.id, () => TextEditingController());

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              review.userName,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.star, color: Colors.orangeAccent, size: 18),
                const SizedBox(width: 4),
                Text(
                  '${review.rating}',
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              review.comment,
              style: GoogleFonts.poppins(fontSize: 15),
            ),
            if (review.reply != null && review.reply!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "Owner's Reply: ${review.reply!}",
                  style: GoogleFonts.poppins(color: Colors.green.shade800),
                ),
              ),
            ],
            const SizedBox(height: 14),
            TextField(
              controller: _replyControllers[review.id],
              decoration: InputDecoration(
                labelText: 'Add or Update Reply',
                labelStyle: GoogleFonts.poppins(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => _submitReply(review.id),
                icon: Icon(Icons.reply, size: 18),
                label: Text('Submit Reply', style: GoogleFonts.poppins()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F4FB),
      appBar: AppBar(
        title: const Text('Business Reviews'),
        backgroundColor: Colors.blueAccent,
      ),
      body: FutureBuilder<List<Review>>(
        future: _reviewsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading reviews'));
          }
          final reviews = snapshot.data ?? [];
          if (reviews.isEmpty) {
            return const Center(child: Text('No reviews yet.'));
          }
          return ListView.builder(
            itemCount: reviews.length,
            itemBuilder: (context, index) => _buildReviewCard(reviews[index]),
          );
        },
      ),
    );
  }
}
