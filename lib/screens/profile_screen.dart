import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentgo/core/auth_service.dart';
import 'package:rentgo/core/firestore_service.dart';
import 'package:rentgo/screens/active_bookings_screen.dart';
import 'package:rentgo/screens/chat_list_screen.dart';
import 'package:rentgo/screens/edit_profile_screen.dart';
import 'package:rentgo/screens/favorites_screen.dart';
import 'package:rentgo/screens/invoices_screen.dart';
import '../core/app_state.dart';
import '../models/review.dart';
import '../models/booking.dart';
import 'my_listings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    if (user == null) return const Scaffold(body: Center(child: Text('Lütfen giriş yapın.')));

    final firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: firestoreService.getUserProfileStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || !snapshot.data!.exists) {
            firestoreService.createUserProfile(user);
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data!.data()!;
          final displayName = userData['displayName'] ?? 'Kullanıcı';
          final photoURL = userData['photoURL'];
          final bio = userData['bio'] ?? '';
          final city = userData['city'] ?? 'Şehir Seçilmedi';
          final isVerified = userData['isPhoneVerified'] ?? false;

          return CustomScrollView(
            slivers: [
              // PREMIUM HEADER
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: const Color(0xFF1E293B),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF2563EB), Color(0xFF0F172A)],
                          ),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white.withAlpha(20),
                            child: CircleAvatar(
                              radius: 46,
                              backgroundImage: photoURL != null ? NetworkImage(photoURL) : null,
                              child: photoURL == null ? Text(displayName[0].toUpperCase(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)) : null,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(displayName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                              if (isVerified) const SizedBox(width: 8),
                              if (isVerified) const Icon(Icons.verified, color: Colors.greenAccent, size: 20),
                            ],
                          ),
                          Text(city, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.white),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen(userData: userData))),
                  ),
                ],
              ),

              // İSTATİSTİKLER VE MENÜ
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // İSTATİSTİK PANELI
                      FadeInUp(child: _buildStatsBar(firestoreService, user.uid, isVerified)),
                      
                      const SizedBox(height: 32),
                      
                      if (bio.isNotEmpty) ...[
                        FadeInUp(
                          delay: const Duration(milliseconds: 200),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
                            child: Text(bio, textAlign: TextAlign.center, style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.white70)),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // MENÜ LİSTESİ
                      _buildMenuSection(context, user),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsBar(FirestoreService service, String uid, bool isVerified) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Puan', '⭐', isRating: true, uid: uid, service: service),
          _buildStatItem('İlan', '📄', isListingCount: true, uid: uid, service: service),
          _buildTrustItem(service, uid, isVerified),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String icon, {bool isRating = false, bool isListingCount = false, required String uid, required FirestoreService service}) {
    return Column(
      children: [
        if (isRating)
          StreamBuilder<QuerySnapshot<Review>>(
            stream: service.getUserReviews(uid),
            builder: (context, snapshot) {
              final reviews = snapshot.data?.docs ?? [];
              double avg = reviews.isEmpty ? 0.0 : reviews.fold(0.0, (p, e) => p + e.data().rating) / reviews.length;
              return Text(avg == 0.0 ? '0.0' : avg.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16));
            },
          )
        else if (isListingCount)
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('vehicles').where('userId', isEqualTo: uid).snapshots(),
            builder: (context, snapshot) => Text('${snapshot.data?.docs.length ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
          ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }

  Widget _buildTrustItem(FirestoreService service, String uid, bool isVerified) {
    return StreamBuilder<QuerySnapshot<Booking>>(
      stream: service.getOwnerBookings(uid),
      builder: (context, snapshot) {
        final completed = snapshot.data?.docs.where((b) => b.data().status == BookingStatus.completed).length ?? 0;
        String label = 'Yeni'; Color color = Colors.grey;
        if (isVerified && completed > 5) { label = 'Yüksek'; color = Colors.greenAccent; }
        else if (isVerified || completed > 0) { label = 'Orta'; color = Colors.blueAccent; }
        return Column(
          children: [
            Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
            const SizedBox(height: 4),
            const Text('Güven', style: TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        );
      },
    );
  }

  Widget _buildMenuSection(BuildContext context, User user) {
    return FadeInUp(
      delay: const Duration(milliseconds: 400),
      child: Column(
        children: [
          _ProfileTile(icon: Icons.directions_car_outlined, title: 'İlanlarım', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyListingsScreen()))),
          _ProfileTile(icon: Icons.favorite_border, title: 'Favorilerim', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen()))),
          _ProfileTile(icon: Icons.sync_alt_outlined, title: 'İşlemlerim', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ActiveBookingsScreen()))),
          _ProfileTile(icon: Icons.chat_bubble_outline, title: 'Mesajlarım', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListScreen()))),
          _ProfileTile(icon: Icons.receipt_long_outlined, title: 'Faturalarım', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoicesScreen()))),
          const SizedBox(height: 12),
          _ProfileTile(icon: Icons.logout, title: 'Çıkış Yap', isDanger: true, onTap: () => context.read<AuthService>().signOut()),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon; final String title; final bool isDanger; final VoidCallback onTap;
  const _ProfileTile({required this.icon, required this.title, this.isDanger = false, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final color = isDanger ? Colors.redAccent : Colors.blueAccent;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withAlpha(5))),
      child: ListTile(
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 20)),
        title: Text(title, style: TextStyle(color: isDanger ? Colors.redAccent : Colors.white, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
