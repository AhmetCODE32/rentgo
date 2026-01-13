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
    } else if (diff.inDays > 0) {
      return '${diff.inDays} gündür üye';
    } else {
      return 'Bugün katıldı';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _firestoreService.getUserProfileStream(widget.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: Text('Kullanıcı bulunamadı.', style: TextStyle(color: Colors.white)));

          final userData = snapshot.data!.data()!;
          final bool isPremium = userData['isPremium'] ?? false;
          final String? photoURL = userData['photoURL'];
          final String city = userData['city'] ?? 'Belirtilmemiş';
          final bool isVerified = userData['isPhoneVerified'] ?? false;
          final String bio = userData['bio'] ?? '';
          final Timestamp? createdAt = userData['createdAt'] as Timestamp?;

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 380,
                  floating: false,
                  pinned: true,
                  backgroundColor: const Color(0xFF1E293B),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildHeaderBackground(isPremium),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 60),
                            _buildAvatar(photoURL, widget.userName, isPremium),
                            const SizedBox(height: 16),
                            _buildNameSection(widget.userName, isVerified, isPremium),
                            const SizedBox(height: 4),
                            Text(
                              _getMemberSince(createdAt),
                              style: TextStyle(
                                color: isPremium ? Colors.amber.withOpacity(0.8) : Colors.white60, 
                                fontSize: 13, 
                                fontWeight: FontWeight.w500
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildLocationBadge(city, isPremium),
                            const SizedBox(height: 20),
                            _buildStatsBar(widget.userId, isVerified, isPremium),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (bio.isNotEmpty)
                  SliverToBoxAdapter(
                    child: FadeInUp(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(Icons.format_quote_rounded, color: isPremium ? Colors.amber : Colors.blueAccent, size: 28),
                            const SizedBox(height: 8),
                            Text(
                              bio,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      controller: _tabController,
                      labelColor: isPremium ? Colors.amber : Colors.blueAccent,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: isPremium ? Colors.amber : Colors.blueAccent,
                      indicatorSize: TabBarIndicatorSize.label,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      tabs: const [
                        Tab(text: 'İlanlar', icon: Icon(Icons.directions_car_filled_rounded, size: 20)),
                        Tab(text: 'Yorumlar', icon: Icon(Icons.star_rounded, size: 20)),
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

  Widget _buildHeaderBackground(bool isPremium) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isPremium 
            ? [const Color(0xFFB8860B), const Color(0xFF78350F), const Color(0xFF0F172A)]
            : [const Color(0xFF2563EB), const Color(0xFF1E40AF), const Color(0xFF0F172A)],
          stops: const [0.0, 0.4, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: 40,
            child: Opacity(
              opacity: 0.1,
              child: Icon(
                isPremium ? Icons.workspace_premium : Icons.person,
                size: 200,
                color: Colors.white,
              ),
            ),
          ),
          if (isPremium)
            Positioned.fill(
              child: CustomPaint(
                painter: _SparklePainter(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? photoURL, String name, bool isPremium) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (isPremium)
          ZoomIn(
            child: Container(
              width: 115,
              height: 115,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const SweepGradient(
                  colors: [Colors.amber, Colors.orange, Colors.amber],
                ),
                boxShadow: [
                  BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 15, spreadRadius: 2),
                ],
              ),
            ),
          ),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF0F172A),
          ),
          child: CircleAvatar(
            radius: isPremium ? 52 : 50,
            backgroundColor: const Color(0xFF1E293B),
            backgroundImage: photoURL != null ? CachedNetworkImageProvider(photoURL) : null,
            child: photoURL == null 
              ? Text(name[0].toUpperCase(), 
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)) 
              : null,
          ),
        ),
        if (isPremium)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.amber,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
              child: const Icon(Icons.workspace_premium, color: Colors.white, size: 16),
            ),
          ),
      ],
    );
  }

  Widget _buildNameSection(String name, bool isVerified, bool isPremium) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          name, 
          style: const TextStyle(
            fontSize: 24, 
            fontWeight: FontWeight.bold, 
            color: Colors.white,
            shadows: [Shadow(color: Colors.black45, offset: Offset(0, 2), blurRadius: 4)],
          )
        ),
        if (isPremium) ...[
          const SizedBox(width: 8),
          const Icon(Icons.verified, color: Colors.amber, size: 22),
        ] else if (isVerified) ...[
          const SizedBox(width: 8),
          const Icon(Icons.verified, color: Colors.greenAccent, size: 20),
        ],
      ],
    );
  }

  Widget _buildLocationBadge(String city, bool isPremium) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on_rounded, size: 12, color: isPremium ? Colors.amber : Colors.blueAccent),
          const SizedBox(width: 4),
          Text(
            city, 
            style: TextStyle(
              color: Colors.white.withOpacity(0.8), 
              fontSize: 13, 
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar(String uid, bool isVerified, bool isPremium) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isPremium ? Colors.amber.withOpacity(0.3) : Colors.white.withAlpha(10),
          width: isPremium ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isPremium ? Colors.amber.withOpacity(0.05) : Colors.black12,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Puan', '⭐', isRating: true, uid: uid, isPremium: isPremium),
          _buildDivider(),
          _buildStatItem('İlan', '📄', isListingCount: true, uid: uid, isPremium: isPremium),
          _buildDivider(),
          _buildTrustItem(uid, isVerified, isPremium),
        ],
      ),
    );
  }

  Widget _buildDivider() => Container(height: 25, width: 1, color: Colors.white10);

  Widget _buildStatItem(String label, String icon, {bool isRating = false, bool isListingCount = false, String? uid, bool isPremium = false}) {
    return Column(
      children: [
        if (isRating)
          StreamBuilder<QuerySnapshot<Review>>(
            stream: _firestoreService.getUserReviews(uid!),
            builder: (context, snapshot) {
              final reviews = snapshot.data?.docs ?? [];
              double avg = reviews.isEmpty ? 0.0 : reviews.fold(0.0, (p, e) => p + e.data().rating) / reviews.length;
              return Text(
                avg == 0.0 ? '0.0' : avg.toStringAsFixed(1), 
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  color: isPremium ? Colors.amber : Colors.white, 
                  fontSize: 18
                )
              );
            },
          )
        else if (isListingCount)
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('vehicles').where('userId', isEqualTo: uid).snapshots(),
            builder: (context, snapshot) => Text(
              '${snapshot.data?.docs.length ?? 0}', 
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                color: isPremium ? Colors.amber : Colors.white, 
                fontSize: 18
              )
            ),
          )
        else
          Text('Yeni', style: TextStyle(fontWeight: FontWeight.bold, color: isPremium ? Colors.amber : Colors.white, fontSize: 18)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildTrustItem(String uid, bool isVerified, bool isPremium) {
    return StreamBuilder<QuerySnapshot<Booking>>(
      stream: _firestoreService.getOwnerBookings(uid),
      builder: (context, snapshot) {
        final completed = snapshot.data?.docs.where((b) => b.data().status == BookingStatus.completed).length ?? 0;
        String label = 'Yeni'; Color color = Colors.grey;
        if (isVerified && completed > 5) { label = 'Yüksek'; color = Colors.greenAccent; }
        else if (isVerified || completed > 0) { label = 'Orta'; color = Colors.blueAccent; }
        return Column(
          children: [
            Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 18)),
            const SizedBox(height: 4),
            const Text('Güven', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        );
      },
    );
  }

  Widget _buildListingsTab(String uid) {
    return StreamBuilder<QuerySnapshot<Vehicle>>(
      stream: FirebaseFirestore.instance.collection('vehicles').where('userId', isEqualTo: uid).withConverter<Vehicle>(fromFirestore: (s, _) => Vehicle.fromMap(s), toFirestore: (v, _) => v.toMap()).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final vehicles = snapshot.data!.docs.map((d) => d.data()).toList();
        if (vehicles.isEmpty) return const Center(child: Text('Henüz ilan verilmemiş.', style: TextStyle(color: Colors.grey)));
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          itemCount: vehicles.length,
          itemBuilder: (context, index) => FadeInUp(
            delay: Duration(milliseconds: index * 100),
            child: VehicleCard(vehicle: vehicles[index]),
          ),
        );
      },
    );
  }

  Widget _buildReviewsTab(String uid) {
    return StreamBuilder<QuerySnapshot<Review>>(
      stream: _firestoreService.getUserReviews(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final reviews = snapshot.data!.docs.map((d) => d.data()).toList();
        if (reviews.isEmpty) return const Center(child: Text('Henüz yorum yapılmamış.', style: TextStyle(color: Colors.grey)));
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          itemCount: reviews.length,
          itemBuilder: (context, index) => FadeInUp(
            delay: Duration(milliseconds: index * 100),
            child: _ReviewCard(review: reviews[index]),
          ),
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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), 
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(review.reviewerName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
              Row(children: List.generate(5, (index) => Icon(Icons.star_rounded, size: 14, color: index < review.rating ? Colors.amber : Colors.white10))),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            review.comment, 
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 12),
          Text(
            DateFormat('dd MMM yyyy').format(review.createdAt), 
            style: TextStyle(color: Colors.white.withAlpha(40), fontSize: 10, fontWeight: FontWeight.w500),
          ),
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
    return Container(
      color: const Color(0xFF0F172A), 
      child: Column(
        children: [
          _tabBar,
          const Divider(height: 1, color: Colors.white10),
        ],
      ),
    );
  }
  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}

class _SparklePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.3);
    final random = math.Random(42);
    for (var i = 0; i < 30; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final s = random.nextDouble() * 2;
      canvas.drawCircle(Offset(x, y), s, paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
