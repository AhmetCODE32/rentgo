import 'dart:ui';
import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentgo/core/auth_service.dart';
import 'package:rentgo/core/firestore_service.dart';
import 'package:rentgo/screens/chat_list_screen.dart';
import 'package:rentgo/screens/edit_profile_screen.dart';
import 'package:rentgo/screens/favorites_screen.dart';
import 'package:rentgo/screens/invoices_screen.dart';
import 'package:rentgo/screens/notifications_screen.dart';
import 'package:rentgo/screens/premium_screen.dart';
import '../models/review.dart';
import '../models/booking.dart';
import 'my_listings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    if (user == null) return const Scaffold(body: Center(child: Text('Lütfen giriş yapın.')));

    final firestoreService = context.read<FirestoreService>();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: firestoreService.getUserProfileStream(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        
        final userData = snapshot.data?.data() ?? {};
        final bool isPremium = userData['isPremium'] ?? false;
        final displayName = userData['displayName'] ?? 'Kullanıcı';
        final photoURL = userData['photoURL'];
        final bio = userData['bio'] ?? '';
        final city = userData['city'] ?? 'Şehir Seçilmedi';
        final isVerified = userData['isPhoneVerified'] ?? false;
        final int unreadCount = userData['unreadCount'] ?? 0;

        return Scaffold(
          backgroundColor: Colors.black, // PROJE TASARIMINA UYGUN TAM SİYAH
          body: Stack(
            children: [
              _buildBackgroundGlow(isPremium),
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    expandedHeight: 0,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    pinned: true,
                    title: FadeInLeft(child: const Text('VROOMY', style: TextStyle(letterSpacing: 4, fontWeight: FontWeight.w900, fontSize: 18))),
                    actions: [
                      IconButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen(userData: userData))),
                        icon: const Icon(Icons.more_vert_rounded),
                      ),
                    ],
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          _buildProfileHero(displayName, photoURL, isPremium, isVerified),
                          const SizedBox(height: 30),
                          _buildBioSection(city, bio),
                          const SizedBox(height: 40),
                          _buildModernStats(firestoreService, user.uid, isPremium),
                          const SizedBox(height: 40),
                          _buildPremiumStatusCard(context, isPremium),
                          const SizedBox(height: 32),
                          const Text('KONTROL MERKEZİ', style: TextStyle(color: Colors.white24, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
                          const SizedBox(height: 16),
                          _buildActionCards(context, unreadCount, isPremium),
                          const SizedBox(height: 40),
                          Center(
                            child: GestureDetector(
                              onTap: () => context.read<AuthService>().signOut(),
                              child: Text(
                                'OTURUMU KAPAT',
                                style: TextStyle(
                                  color: Colors.redAccent.withOpacity(0.6),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBackgroundGlow(bool isPremium) {
    return Positioned(
      top: -100,
      left: -50,
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (isPremium ? Colors.amber : Colors.blueAccent).withOpacity(0.15),
              blurRadius: 100,
              spreadRadius: 50,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHero(String name, String? photo, bool isPremium, bool isVerified) {
    return Row(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            if (isPremium)
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.amber.withOpacity(0.5), width: 1),
                ),
              ),
            Container(
              width: 75,
              height: 75,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white10,
                image: photo != null ? DecorationImage(image: NetworkImage(photo), fit: BoxFit.cover) : null,
              ),
              child: photo == null ? Center(child: Text(name[0], style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold))) : null,
            ),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      name,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isVerified) const Icon(Icons.verified, color: Colors.blueAccent, size: 20),
                ],
              ),
              if (isPremium)
                const Text('VROOMY PRO DRIVER', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBioSection(String city, String bio) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.location_on_rounded, color: Colors.white24, size: 14),
            const SizedBox(width: 4),
            Text(city, style: const TextStyle(color: Colors.white24, fontSize: 14)),
          ],
        ),
        if (bio.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            bio,
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 15, height: 1.5),
          ),
        ],
      ],
    );
  }

  Widget _buildModernStats(FirestoreService service, String uid, bool isPremium) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatBlock(
            'PUAN',
            StreamBuilder<QuerySnapshot<Review>>(
              stream: service.getUserReviews(uid),
              builder: (context, snapshot) {
                final reviews = snapshot.data?.docs ?? [];
                double avg = reviews.isEmpty ? 0.0 : reviews.fold(0.0, (p, e) => p + e.data().rating) / reviews.length;
                return Text(avg == 0.0 ? '0.0' : avg.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900));
              },
            ),
          ),
          _buildStatBlock(
            'İLAN',
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('vehicles').where('userId', isEqualTo: uid).snapshots(),
              builder: (context, snapshot) => Text('${snapshot.data?.docs.length ?? 0}', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
            ),
          ),
          _buildStatBlock(
            'GÜVEN',
            StreamBuilder<QuerySnapshot<Booking>>(
              stream: service.getOwnerBookings(uid),
              builder: (context, snapshot) {
                final completed = snapshot.data?.docs.where((b) => b.data().status == BookingStatus.completed).length ?? 0;
                return Text(completed > 5 ? 'A+' : (completed > 0 ? 'B' : 'S'), style: const TextStyle(color: Colors.blueAccent, fontSize: 22, fontWeight: FontWeight.w900));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBlock(String label, Widget value) {
    return Column(
      children: [
        value,
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ],
    );
  }

  Widget _buildPremiumStatusCard(BuildContext context, bool isPremium) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen())),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isPremium ? Colors.amber.withOpacity(0.05) : Colors.blueAccent.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: (isPremium ? Colors.amber : Colors.blueAccent).withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(isPremium ? Icons.verified : Icons.star_outline_rounded, color: isPremium ? Colors.amber : Colors.blueAccent),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                isPremium ? 'PRO ÜYELİĞİNİZ AKTİF' : 'PRO\'YA GEÇİŞ YAPIN',
                style: TextStyle(
                  color: isPremium ? Colors.amber : Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCards(BuildContext context, int unreadCount, bool isPremium) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildActionCard(context, Icons.directions_car_filled, 'İLANLARIM', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyListingsScreen())))),
            const SizedBox(width: 12),
            Expanded(child: _buildActionCard(context, Icons.notifications_rounded, 'BİLDİRİMLER', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildActionCard(context, Icons.chat_bubble_rounded, 'MESAJLAR', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListScreen())), badge: unreadCount)),
            const SizedBox(width: 12),
            Expanded(child: _buildActionCard(context, Icons.favorite_rounded, 'FAVORİLER', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen())))),
          ],
        ),
        const SizedBox(height: 12),
        if (isPremium)
          FadeInUp(
            child: _buildActionCard(
              context, 
              Icons.receipt_long_rounded, 
              'FATURALARIM', 
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoicesScreen())),
              isWide: true
            ),
          ),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, IconData icon, String title, VoidCallback onTap, {int badge = 0, bool isWide = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isWide ? double.infinity : null,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.03)),
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: Colors.white, size: 22),
                if (badge > 0)
                  Positioned(
                    top: -5,
                    right: -5,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                      child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          ],
        ),
      ),
    );
  }
}
