import 'dart:ui';
import 'package:flutter/material.dart';
import 'api_service.dart';

class ReviewsTab extends StatefulWidget {
  @override
  _ReviewsTabState createState() => _ReviewsTabState();
}

class _ReviewsTabState extends State<ReviewsTab> {
  final Color primaryGold = const Color(0xFFFFD700);
  final Color surfaceDark = const Color(0xFF1A1A1A);

  bool _isLoading = true;
  bool _isLoggedIn = false;
  bool _isSubmitting = false;
  List<dynamic> _reviews = [];
  int _selectedRating = 5;
  final TextEditingController _reviewController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; });
    String? userId = await ApiService.getUserId();
    var reviews = await ApiService.getReviews();
    if (mounted) {
      setState(() {
        _isLoggedIn = userId != null;
        _reviews = reviews;
        _isLoading = false;
      });
    }
  }

  Future<void> _submitReview() async {
    if (_reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write your review text!'), backgroundColor: Colors.orange),
      );
      return;
    }
    setState(() { _isSubmitting = true; });
    String? userId = await ApiService.getUserId();
    if (userId != null) {
      bool success = await ApiService.addReview(userId, _reviewController.text.trim(), _selectedRating);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for your review!'), backgroundColor: Colors.green),
        );
        _reviewController.clear();
        setState(() { _selectedRating = 5; });
        await _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Server error. Please try later.'), backgroundColor: Colors.redAccent),
        );
      }
    }

    if (mounted) {
      setState(() { _isSubmitting = false; });
    }
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate).toLocal();
      return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return isoDate;
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('Reviews', style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?q=80&w=2000',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(child: Container(color: Colors.black.withOpacity(0.85))),

          SafeArea(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: primaryGold))
                : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _isLoggedIn ? _buildReviewForm() : _buildLoginPrompt(),

                  const SizedBox(height: 40),
                  Text('Guest impressions', style: TextStyle(color: primaryGold, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  if (_reviews.isEmpty)
                    _buildGlassCard(
                      child: const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Column(
                            children: [
                              Icon(Icons.comment_outlined, color: Colors.white24, size: 60),
                              SizedBox(height: 16),
                              Text('It\'s empty here. Be the first!', style: TextStyle(color: Colors.white54, fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ..._reviews.map((review) => _buildReviewCard(review)).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewForm() {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('Leave a review', style: TextStyle(color: primaryGold, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < _selectedRating ? Icons.star : Icons.star_border,
                  color: primaryGold,
                  size: 32,
                ),
                onPressed: () {
                  setState(() { _selectedRating = index + 1; });
                },
              );
            }),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _reviewController,
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Share your impressions...',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.black.withOpacity(0.5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primaryGold)),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: _isSubmitting
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Text('SEND', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, color: primaryGold.withOpacity(0.5), size: 48),
          const SizedBox(height: 16),
          const Text('Want to leave a review?', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Only registered guests can leave reviews.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    int rating = review['rating'] ?? 5;
    String name = review['userName'] ?? 'Guest';
    String text = review['text'] ?? '';
    String date = _formatDate(review['createdAt'] ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: _buildGlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(name, style: TextStyle(color: primaryGold, fontSize: 18, fontWeight: FontWeight.bold))),
                Row(
                  children: List.generate(5, (index) => Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: primaryGold,
                    size: 16,
                  )),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(text, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5, fontStyle: FontStyle.italic)),
            const SizedBox(height: 12),
            Text(date, style: const TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: surfaceDark.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: child,
        ),
      ),
    );
  }
}