import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rentgo/core/firestore_service.dart';
import 'package:rentgo/models/booking.dart';
import 'package:rentgo/models/review.dart'; // EKLENDİ

class ActiveBookingsScreen extends StatelessWidget {
  const ActiveBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('İşlemlerim'),
          bottom: const TabBar(
            indicatorColor: Colors.blueAccent,
            tabs: [
              Tab(text: 'Kiraladıklarım'),
              Tab(text: 'Kiraya Verdiklerim'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _BookingsList(isCustomer: true),
            _BookingsList(isCustomer: false),
          ],
        ),
      ),
    );
  }
}

class _BookingsList extends StatelessWidget {
  final bool isCustomer;
  const _BookingsList({required this.isCustomer});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    if (user == null) return const Center(child: Text('Lütfen giriş yapın.'));

    final firestoreService = FirestoreService();
    final stream = isCustomer 
        ? firestoreService.getCustomerBookings(user.uid)
        : firestoreService.getOwnerBookings(user.uid);

    return StreamBuilder(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_late_outlined, size: 64, color: Colors.white.withAlpha(30)),
                const SizedBox(height: 16),
                Text(isCustomer ? 'Henüz bir kiralama yapmadınız.' : 'Henüz aracınızı kiralayan kimse yok.', style: const TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        final bookings = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index].data();
            return _BookingCard(booking: booking, isCustomer: isCustomer);
          },
        );
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final bool isCustomer;
  const _BookingCard({required this.booking, required this.isCustomer});

  @override
  Widget build(BuildContext context) {
    final priceFormatter = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);
    final firestoreService = FirestoreService();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.white10, width: 0.5)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                if (booking.vehicleImage != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(imageUrl: booking.vehicleImage!, width: 60, height: 60, fit: BoxFit.cover),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(booking.vehicleTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(isCustomer ? 'Satıcı ID: ${booking.ownerId.substring(0, 8)}...' : 'Müşteri: ${booking.customerName}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                _StatusBadge(status: booking.status),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${booking.days} Günlük Kiralama', style: const TextStyle(fontSize: 13)),
                Text(priceFormatter.format(booking.totalPrice), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent, fontSize: 16)),
              ],
            ),
            
            if (booking.status != BookingStatus.completed && booking.status != BookingStatus.cancelled) ...[
              const SizedBox(height: 16),
              if (!isCustomer && booking.status == BookingStatus.pendingDelivery)
                SizedBox(width: double.infinity, height: 48, child: ElevatedButton(onPressed: () => firestoreService.updateBookingStatus(booking.id!, BookingStatus.delivered), child: const Text('Aracı Teslim Ettim'))),
              if (isCustomer && booking.status == BookingStatus.delivered)
                SizedBox(width: double.infinity, height: 48, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green), onPressed: () => _showCompletionDialog(context, booking, firestoreService), child: const Text('Aracı Teslim Aldım (Onayla)'))),
            ],

            // YENİ: YORUM VE PUANLAMA BUTONU
            if (booking.status == BookingStatus.completed && isCustomer)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.star_rate_rounded, color: Colors.amber),
                    label: const Text('Deneyimi Puanla'),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.amber)),
                    onPressed: () => _showReviewDialog(context, booking, firestoreService),
                  ),
                ),
              ),

            if (booking.status == BookingStatus.completed && !isCustomer)
              const Padding(padding: EdgeInsets.only(top: 12), child: Text('İşlem Tamamlandı. Kazanç havuzunuzda!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12))),
          ],
        ),
      ),
    );
  }

  void _showReviewDialog(BuildContext context, Booking booking, FirestoreService service) {
    double selectedRating = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Puanla ve Yorum Yap'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => IconButton(
                  icon: Icon(index < selectedRating ? Icons.star_rounded : Icons.star_outline_rounded, color: Colors.amber, size: 32),
                  onPressed: () => setDialogState(() => selectedRating = index + 1.0),
                )),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Araç ve satıcı hakkındaki düşünceleriniz...', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
            ElevatedButton(
              onPressed: () async {
                final user = Provider.of<User?>(context, listen: false);
                if (user == null) return;

                final review = Review(
                  reviewerId: user.uid,
                  reviewerName: user.displayName ?? 'Müşteri',
                  targetUserId: booking.ownerId,
                  bookingId: booking.id!,
                  rating: selectedRating,
                  comment: commentController.text.trim(),
                  createdAt: DateTime.now(),
                );

                await service.addReview(review);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yorumunuz için teşekkürler!')));
                }
              },
              child: const Text('Gönder'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCompletionDialog(BuildContext context, Booking booking, FirestoreService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Kiralama Onayı'),
        content: const Text('Aracı eksiksiz teslim aldığınızı onaylıyor musunuz?\n\nBu işlemden sonra ödeme araç sahibine aktarılacaktır.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () async {
              await service.updateBookingStatus(booking.id!, BookingStatus.completed);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Onayla'),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final BookingStatus status;
  const _StatusBadge({required this.status});
  @override
  Widget build(BuildContext context) {
    Color color; String text;
    switch (status) {
      case BookingStatus.pendingDelivery: color = Colors.orange; text = 'Beklemede'; break;
      case BookingStatus.delivered: color = Colors.blue; text = 'Teslim Edildi'; break;
      case BookingStatus.completed: color = Colors.green; text = 'Bitti'; break;
      case BookingStatus.cancelled: color = Colors.red; text = 'İptal'; break;
    }
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withAlpha(127))), child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)));
  }
}
