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
          backgroundColor: const Color(0xFF0F172A),
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                stretch: true,
                backgroundColor: const Color(0xFF1E293B),
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildHeaderBackground(isPremium),
                      _buildProfileInfo(displayName, photoURL, city, isVerified, isPremium),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                      child: const Icon(Icons.settings_outlined, color: Colors.white, size: 20),
                    ),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen(userData: userData))),
                  ),
                  const SizedBox(width: 8),
                ],
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        child: _buildStatsGrid(firestoreService, user.uid, isVerified, isPremium),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      if (bio.isNotEmpty)
                        FadeInUp(
                          delay: const Duration(milliseconds: 200),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            margin: const EdgeInsets.only(bottom: 32),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF0F172A)]),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: isPremium ? Colors.amber.withOpacity(0.2) : Colors.white.withOpacity(0.05)),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.format_quote_rounded, color: isPremium ? Colors.amber : Colors.blueAccent, size: 32),
                                const SizedBox(height: 8),
                                Text(
                                  bio,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 15, fontStyle: FontStyle.italic, height: 1.5),
                                ),
                              ],
                            ),
                          ),
                        ),

                      _buildMenuSection(context, unreadCount, isPremium),
                      
                      const SizedBox(height: 40),
                      
                      _buildLogoutButton(context),
                      
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderBackground(bool isPremium) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isPremium 
            ? [const Color(0xFFB8860B), const Color(0xFF78350F), const Color(0xFF0F172A)]
            : [const Color(0xFF2563EB), const Color(0xFF1E40AF), const Color(0xFF0F172A)],
        ),
      ),
      child: Opacity(
        opacity: 0.1,
        child: isPremium 
          ? const Icon(Icons.workspace_premium, size: 300, color: Colors.white)
          : const Icon(Icons.directions_car_filled, size: 300, color: Colors.white),
      ),
    );
  }

  Widget _buildProfileInfo(String name, String? photo, String city, bool verified, bool premium) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        Hero(
          tag: 'profile_pic',
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: premium ? Colors.amber : Colors.white24, width: 2),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20, spreadRadius: 5)],
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFF1E293B),
              backgroundImage: photo != null ? NetworkImage(photo) : null,
              child: photo == null ? Text(name[0].toUpperCase(), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)) : null,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
            if (premium) ...[
              const SizedBox(width: 8),
              const Icon(Icons.verified, color: Colors.amber, size: 22),
            ] else if (verified) ...[
              const SizedBox(width: 8),
              const Icon(Icons.verified, color: Colors.greenAccent, size: 20),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_on_rounded, size: 14, color: premium ? Colors.amber.withOpacity(0.7) : Colors.blueAccent),
            const SizedBox(width: 4),
            Text(city, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsGrid(FirestoreService service, String uid, bool verified, bool premium) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: premium ? Colors.amber.withOpacity(0.2) : Colors.white.withOpacity(0.05)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard('Puan', '⭐', isRating: true, uid: uid, service: service, premium: premium),
          _buildDivider(),
          _buildStatCard('İlan', '📄', isRating: false, uid: uid, service: service, premium: premium),
          _buildDivider(),
          _buildTrustCard(service, uid, verified, premium),
        ],
      ),
    );
  }

  Widget _buildDivider() => Container(height: 30, width: 1, color: Colors.white10);

  Widget _buildStatCard(String label, String icon, {required bool isRating, required String uid, required FirestoreService service, required bool premium}) {
    return Column(
      children: [
        if (isRating)
          StreamBuilder<QuerySnapshot<Review>>(
            stream: service.getUserReviews(uid),
            builder: (context, snapshot) {
              final reviews = snapshot.data?.docs ?? [];
              double avg = reviews.isEmpty ? 0.0 : reviews.fold(0.0, (p, e) => p + e.data().rating) / reviews.length;
              return Text(avg == 0.0 ? '0.0' : avg.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18));
            },
          )
        else
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('vehicles').where('userId', isEqualTo: uid).snapshots(),
            builder: (context, snapshot) => Text('${snapshot.data?.docs.length ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
          ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTrustCard(FirestoreService service, String uid, bool verified, bool premium) {
    return StreamBuilder<QuerySnapshot<Booking>>(
      stream: service.getOwnerBookings(uid),
      builder: (context, snapshot) {
        final completed = snapshot.data?.docs.where((b) => b.data().status == BookingStatus.completed).length ?? 0;
        String label = 'Yeni'; Color color = Colors.grey;
        if (verified && completed > 5) { label = 'Yüksek'; color = Colors.greenAccent; }
        else if (verified || completed > 0) { label = 'Orta'; color = Colors.blueAccent; }
        return Column(
          children: [
            Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 18)),
            const SizedBox(height: 4),
            Text('Güven', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        );
      },
    );
  }

  Widget _buildMenuSection(BuildContext context, int unreadCount, bool premium) {
    return Column(
      children: [
        _ProfileMenuTile(icon: Icons.directions_car_rounded, title: 'İlanlarım', desc: 'İlanlarını yönet', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyListingsScreen()))),
        _ProfileMenuTile(icon: Icons.favorite_rounded, title: 'Favorilerim', desc: 'Beğendiğin araçlar', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen()))),
        _ProfileMenuTile(icon: Icons.history_edu_rounded, title: 'Rezervasyonlarım', desc: 'Geçmiş ve aktif işlemler', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ActiveBookingsScreen()))),
        _ProfileMenuTile(icon: Icons.chat_bubble_rounded, title: 'Mesajlarım', desc: 'Sohbetlerini kontrol et', badgeCount: unreadCount, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListScreen()))),
        const SizedBox(height: 12),
        if (premium)
          _ProfileMenuTile(icon: Icons.workspace_premium_rounded, title: 'Üyelik Ayarları', desc: 'Vroomy Pro avantajları', color: Colors.amber, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen())))
        else
          _ProfileMenuTile(icon: Icons.star_rounded, title: 'Pro\'ya Geç', desc: 'Ayrıcalıkların tadını çıkar', color: Colors.amber, isSpecial: true, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen()))),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return InkWell(
      onTap: () => context.read<AuthService>().signOut(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.redAccent.withOpacity(0.2))),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
            SizedBox(width: 8),
            Text('Oturumu Kapat', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  final IconData icon; final String title; final String desc; final VoidCallback onTap; final int badgeCount; final Color? color; final bool isSpecial;
  const _ProfileMenuTile({required this.icon, required this.title, required this.desc, required this.onTap, this.badgeCount = 0, this.color, this.isSpecial = false});

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? Colors.blueAccent;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSpecial ? Colors.amber.withOpacity(0.3) : Colors.white.withOpacity(0.03)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: themeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
          child: Icon(icon, color: themeColor, size: 24),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(desc, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
        trailing: badgeCount > 0 
          ? Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle), child: Text('$badgeCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))
          : const Icon(Icons.chevron_right_rounded, color: Colors.white24),
        onTap: onTap,
      ),
    );
  }
}
