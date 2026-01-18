import 'dart:math' as math;
import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rentgo/core/firestore_service.dart';
import 'package:rentgo/models/vehicle.dart';
import 'package:rentgo/models/review.dart';
import 'package:rentgo/models/booking.dart';
import 'package:rentgo/widgets/vehicle_card.dart';
import 'package:intl/intl.dart';

class OtherUserProfileScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const OtherUserProfileScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<OtherUserProfileScreen> createState() => _OtherUserProfileScreenState();
}

class _OtherUserProfileScreenState extends State<OtherUserProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getMemberSince(Timestamp? createdAt) {
    if (createdAt == null) return 'Yeni Üye';
    final diff = DateTime.now().difference(createdAt.toDate());
    if (diff.inDays > 365) {
      return '${(diff.inDays / 365).floor()} yıldır üye';
    } else if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()} aydır üye';
    } else {
      return '${diff.inDays} gündür üye';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // TAM SİYAH
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _firestoreService.getUserProfileStream(widget.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.white10));
          if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: Text('Kullanıcı bulunamadı.', style: TextStyle(color: Colors.white24)));

          final userData = snapshot.data!.data()!;
          final String? photoURL = userData['photoURL'];
          final String city = userData['city'] ?? 'Belirtilmemiş';
          final bool isVerified = userData['isPhoneVerified'] ?? false;
          final String bio = userData['bio'] ?? '';
          final Timestamp? createdAt = userData['createdAt'] as Timestamp?;

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 320,
                  floating: false,
                  pinned: true,
                  backgroundColor: Colors.black, // TAM SİYAH
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      alignment: Alignment.center,
                      children: [
                        _buildBackgroundGlow(),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            _buildAvatar(photoURL, widget.userName),
                            const SizedBox(height: 16),
                            _buildNameSection(widget.userName, isVerified),
                            const SizedBox(height: 4),
                            Text(
                              _getMemberSince(createdAt).toUpperCase(),
                              style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2),
                            ),
                            const SizedBox(height: 12),
                            _buildLocationBadge(city),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (bio.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
                      child: Text(
                        bio,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14, height: 1.6, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildModernStats(widget.userId),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      controller: _tabController,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white24,
                      indicatorColor: Colors.white,
                      indicatorSize: TabBarIndicatorSize.label,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.5),
                      tabs: const [
                        Tab(text: 'İLANLAR'),
                        Tab(text: 'YORUMLAR'),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildListingsTab(widget.userId),
                _buildReviewsTab(widget.userId),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBackgroundGlow() {
    return Positioned(
      top: -100,
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.white.withOpacity(0.03), blurRadius: 100, spreadRadius: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String? photoURL, String name) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: CircleAvatar(
        radius: 42,
        backgroundColor: const Color(0xFF111111),
        backgroundImage: photoURL != null ? CachedNetworkImageProvider(photoURL) : null,
        child: photoURL == null 
          ? Text(name[0].toUpperCase(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)) 
          : null,
      ),
    );
  }

  Widget _buildNameSection(String name, bool isVerified) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
        if (isVerified) ...[
          const SizedBox(width: 8),
          const Icon(Icons.verified_rounded, color: Colors.blueAccent, size: 20),
        ],
      ],
    );
  }

  Widget _buildLocationBadge(String city) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on_rounded, size: 12, color: Colors.white.withOpacity(0.2)),
          const SizedBox(width: 4),
          Text(city, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildModernStats(String uid) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A), // LUXURY BLACK CARD
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('PUAN', isRating: true, uid: uid),
          _buildStatItem('İLAN', isListingCount: true, uid: uid),
          _buildTrustItem(uid),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, {bool isRating = false, bool isListingCount = false, String? uid}) {
    return Column(
      children: [
        if (isRating)
          StreamBuilder<QuerySnapshot<Review>>(
            stream: _firestoreService.getUserReviews(uid!),
            builder: (context, snapshot) {
              final reviews = snapshot.data?.docs ?? [];
              double avg = reviews.isEmpty ? 0.0 : reviews.fold(0.0, (p, e) => p + e.data().rating) / reviews.length;
              return Text(avg == 0.0 ? '0.0' : avg.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18));
            },
          )
        else if (isListingCount)
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('vehicles').where('userId', isEqualTo: uid).snapshots(),
            builder: (context, snapshot) => Text('${snapshot.data?.docs.length ?? 0}', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18)),
          )
        else
          const Text('...', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
      ],
    );
  }

  Widget _buildTrustItem(String uid) {
    return StreamBuilder<QuerySnapshot<Booking>>(
      stream: _firestoreService.getOwnerBookings(uid),
      builder: (context, snapshot) {
        final completed = snapshot.data?.docs.where((b) => b.data().status == BookingStatus.completed).length ?? 0;
        return Column(
          children: [
            Text(completed > 5 ? 'A+' : (completed > 0 ? 'B' : 'S'), style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white38, fontSize: 18)),
            const SizedBox(height: 4),
            const Text('GÜVEN', style: TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          ],
        );
      },
    );
  }

  Widget _buildListingsTab(String uid) {
    return StreamBuilder<QuerySnapshot<Vehicle>>(
      stream: FirebaseFirestore.instance.collection('vehicles').where('userId', isEqualTo: uid).withConverter<Vehicle>(fromFirestore: (s, _) => Vehicle.fromMap(s), toFirestore: (v, _) => v.toMap()).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white10));
        final vehicles = snapshot.data!.docs.map((d) => d.data()).toList();
        if (vehicles.isEmpty) return const Center(child: Text('Henüz ilan verilmemiş.', style: TextStyle(color: Colors.white10, fontWeight: FontWeight.bold)));
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: vehicles.length,
          itemBuilder: (context, index) => FadeInUp(child: VehicleCard(vehicle: vehicles[index])),
        );
      },
    );
  }

  Widget _buildReviewsTab(String uid) {
    return StreamBuilder<QuerySnapshot<Review>>(
      stream: _firestoreService.getUserReviews(uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white10));
        final reviews = snapshot.data!.docs.map((d) => d.data()).toList();
        if (reviews.isEmpty) return const Center(child: Text('Henüz yorum yapılmamış.', style: TextStyle(color: Colors.white10, fontWeight: FontWeight.bold)));
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: reviews.length,
          itemBuilder: (context, index) => FadeInUp(child: _ReviewCard(review: reviews[index])),
        );
      },
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;
  const _ReviewCard({required this.review});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A), // LUXURY BLACK CARD
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(review.reviewerName, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 14)),
              Row(children: List.generate(5, (index) => Icon(Icons.star_rounded, size: 12, color: index < review.rating ? Colors.amber : Colors.white10))),
            ],
          ),
          const SizedBox(height: 8),
          Text(review.comment, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14, height: 1.5)),
          const SizedBox(height: 12),
          Text(DateFormat('dd.MM.yyyy').format(review.createdAt), style: TextStyle(color: Colors.white.withOpacity(0.1), fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;
  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Colors.black, child: _tabBar);
  }
  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
