import 'package:flutter/material.dart';
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
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(review.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Rating: ${review.rating} ★'),
            const SizedBox(height: 4),
            Text('comment:${review.comment}'),
            if (review.reply != null) ...[
              const SizedBox(height: 8),
              Text('Reply: ${review.reply!}', style: const TextStyle(color: Colors.green)),
            ],
            const SizedBox(height: 8),
            TextField(
              controller: _replyControllers[review.id],
              decoration: const InputDecoration(
                labelText: 'Add/Update Reply',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _submitReply(review.id),
              child: const Text('Submit Reply'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Business Reviews')),
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
