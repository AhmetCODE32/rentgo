import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentgo/core/firestore_service.dart';
import 'package:rentgo/models/review.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animate_do/animate_do.dart';

class AddReviewScreen extends StatefulWidget {
  final String targetUserId;
  final String targetUserName;
  final String vehicleTitle;

  const AddReviewScreen({
    super.key,
    required this.targetUserId,
    required this.targetUserName,
    required this.vehicleTitle,
  });

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  double _rating = 5.0;
  final _commentController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitReview() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir yorum yazın.')),
      );
      return;
    }

    final user = Provider.of<User?>(context, listen: false);
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final review = Review(
        reviewerId: user.uid,
        reviewerName: user.displayName ?? 'Bir Kullanıcı',
        targetUserId: widget.targetUserId,
        bookingId: 'chat_based_review',
        rating: _rating,
        comment: _commentController.text.trim(),
        createdAt: DateTime.now(),
      );

      await context.read<FirestoreService>().addReview(review);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yorumunuz başarıyla paylaşıldı!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // TAM SİYAH
      appBar: AppBar(
        title: const Text('YORUM YAP', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.w900, fontSize: 16)),
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            FadeInDown(
              child: Column(
                children: [
                  Text(
                    widget.targetUserName.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.vehicleTitle} ilanı için değerlendir',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            
            // STAR RATING - YELLOW
            FadeIn(
              delay: const Duration(milliseconds: 200),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: () => setState(() => _rating = index + 1.0),
                    icon: Icon(
                      index < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: index < _rating ? Colors.amber : Colors.white10,
                      size: 40,
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${_rating.toInt()} / 5',
              style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.w900, fontSize: 18),
            ),
            
            const SizedBox(height: 48),
            
            // COMMENT INPUT
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              child: TextFormField(
                controller: _commentController,
                maxLines: 5,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Deneyiminizi buraya yazın...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.1)),
                  filled: true,
                  fillColor: const Color(0xFF0A0A0A), // LUXURY BLACK CARD
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(24),
                ),
              ),
            ),
            
            const SizedBox(height: 64),
            
            FadeInUp(
              delay: const Duration(milliseconds: 600),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(64),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.black) 
                  : const Text('YORUMU GÖNDER', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
