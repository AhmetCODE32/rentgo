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
        final displayName = userData['displayName'] ?? 'Kullanıcı';
        final photoURL = userData['photoURL'];
        final bio = userData['bio'] ?? '';
        final city = userData['city'] ?? 'Şehir Seçilmedi';
        final isVerified = userData['isPhoneVerified'] ?? false;
        final int unreadCount = userData['unreadCount'] ?? 0;

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: const Padding(
              padding: EdgeInsets.only(left: 20),
              child: Center(child: Text('VROOMY', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.w900, fontSize: 12, color: Colors.white24))),
            ),
            leadingWidth: 100,
            actions: [
              IconButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen(userData: userData))),
                icon: const Icon(Icons.tune_rounded, color: Colors.white70),
              ),
              const SizedBox(width: 12),
            ],
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // 1. CENTERED PROFILE HERO
                _buildCenteredHero(displayName, photoURL, isVerified, city),
                
                const SizedBox(height: 40),

                // 2. UNIFIED STATS BAR
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildUnifiedStats(firestoreService, user.uid, isVerified),
                ),

                const SizedBox(height: 40),

                // 3. SUPPORT ACTION
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildModernSupportTile(context),
                ),

                const SizedBox(height: 40),

                // 4. MODERN LIST ACTIONS
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('KONTROL PANELİ', style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
                      const SizedBox(height: 20),
                      _buildModernListTile(
                        context, 
                        icon: Icons.directions_car_filled_rounded, 
                        title: 'İlanlarımı Yönet', 
                        subtitle: 'Yayındaki araçlarını kontrol et',
                        color: Colors.blueAccent, 
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyListingsScreen()))
                      ),
                      _buildModernListTile(
                        context, 
                        icon: Icons.notifications_active_rounded, 
                        title: 'Bildirimler', 
                        subtitle: 'Sana gelen son aktiviteler',
                        color: Colors.orangeAccent, 
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))
                      ),
                      _buildModernListTile(
                        context, 
                        icon: Icons.chat_bubble_rounded, 
                        title: 'Mesajlar', 
                        subtitle: 'Kullanıcılarla olan sohbetlerin',
                        color: Colors.purpleAccent, 
                        badge: unreadCount,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListScreen()))
                      ),
                      _buildModernListTile(
                        context, 
                        icon: Icons.favorite_rounded, 
                        title: 'Favoriler', 
                        subtitle: 'Kaydettiğin özel ilanlar',
                        color: Colors.redAccent, 
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen()))
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 60),
                
                // LOGOUT
                TextButton(
                  onPressed: () => context.read<AuthService>().signOut(),
                  child: Text('OTURUMU KAPAT', style: TextStyle(color: Colors.redAccent.withOpacity(0.5), fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2)),
                ),
                
                const SizedBox(height: 100),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCenteredHero(String name, String? photo, bool isVerified, String city) {
    return FadeInDown(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFF111111),
                  backgroundImage: photo != null ? NetworkImage(photo) : null,
                  child: photo == null ? Text(name[0], style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)) : null,
                ),
              ),
              if (isVerified)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                  child: const Icon(Icons.verified_rounded, color: Colors.white, size: 18),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on_rounded, color: Colors.white24, size: 14),
              const SizedBox(width: 4),
              Text(city.toUpperCase(), style: const TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUnifiedStats(FirestoreService service, String uid, bool isVerified) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Row(
        children: [
          Expanded(child: _buildStatItem('PUAN', StreamBuilder<QuerySnapshot<Review>>(
            stream: service.getUserReviews(uid),
            builder: (context, snapshot) {
              final reviews = snapshot.data?.docs ?? [];
              double avg = reviews.isEmpty ? 0.0 : reviews.fold(0.0, (p, e) => p + e.data().rating) / reviews.length;
              return Text(avg == 0.0 ? '0.0' : avg.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900));
            },
          ))),
          Container(width: 1, height: 30, color: Colors.white.withOpacity(0.05)),
          Expanded(child: _buildStatItem('İLAN', StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('vehicles').where('userId', isEqualTo: uid).snapshots(),
            builder: (context, snapshot) => Text('${snapshot.data?.docs.length ?? 0}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          ))),
          Container(width: 1, height: 30, color: Colors.white.withOpacity(0.05)),
          Expanded(child: _buildStatItem('GÜVEN', StreamBuilder<QuerySnapshot<Review>>(
            stream: service.getUserReviews(uid),
            builder: (context, snapshot) {
              final reviewCount = snapshot.data?.docs.length ?? 0;
              final reviews = snapshot.data?.docs ?? [];
              double avg = reviews.isEmpty ? 0.0 : reviews.fold(0.0, (p, e) => p + e.data().rating) / reviews.length;
              String rank = 'S'; Color color = Colors.white24;
              if (isVerified) { rank = 'B'; color = Colors.blueAccent; if (reviewCount >= 3 && avg >= 4.0) { rank = 'A'; color = Colors.greenAccent; } if (reviewCount >= 10 && avg >= 4.5) { rank = 'A+'; color = Colors.amber; } }
              return Text(rank, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900));
            },
          ))),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, Widget value) {
    return Column(
      children: [
        value,
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
      ],
    );
  }

  Widget _buildModernSupportTile(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen())),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFDD00).withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFFDD00).withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFFFDD00).withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.coffee_rounded, color: Color(0xFFFFDD00), size: 20),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BİZE DESTEK OL', style: TextStyle(color: Color(0xFFFFDD00), fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)),
                  Text('Gönüllü bir kahve ısmarla', style: TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFFFDD00), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildModernListTile(BuildContext context, {required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap, int badge = 0}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.03)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: -0.2)),
                    Text(subtitle, style: const TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              if (badge > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(10)),
                  child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                )
              else
                const Icon(Icons.chevron_right_rounded, color: Colors.white10, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
