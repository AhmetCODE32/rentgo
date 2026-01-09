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
          final photoURL = userData['photoURL'];
          final bio = userData['bio'] ?? '';
          final city = userData['city'] ?? 'Belirtilmemiş';
          final isVerified = userData['isPhoneVerified'] ?? false;

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 340,
                  floating: false,
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
                              radius: 55,
                              backgroundColor: Colors.white.withAlpha(20),
                              child: CircleAvatar(
                                radius: 50,
                                backgroundImage: photoURL != null ? CachedNetworkImageProvider(photoURL) : null,
                                child: photoURL == null ? Text(widget.userName[0].toUpperCase(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)) : null,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(widget.userName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                                if (isVerified) const SizedBox(width: 8),
                                if (isVerified) const Icon(Icons.verified, color: Colors.greenAccent, size: 20),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.location_on, size: 16, color: Colors.blueAccent),
                                const SizedBox(width: 4),
                                Text(city, style: const TextStyle(color: Colors.white70)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildStatsBar(widget.userId, isVerified),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      controller: _tabController,
                      labelColor: Colors.blueAccent,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.blueAccent,
                      indicatorSize: TabBarIndicatorSize.label,
                      tabs: const [
                        Tab(text: 'İlanlar', icon: Icon(Icons.directions_car_filled_rounded)),
                        Tab(text: 'Yorumlar', icon: Icon(Icons.star_rounded)),
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

  Widget _buildStatsBar(String uid, bool isVerified) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30),
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withAlpha(150),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Puan', '⭐', isRating: true, uid: uid),
          _buildStatItem('İlan', '📄', isListingCount: true, uid: uid),
          _buildTrustItem(uid, isVerified),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String icon, {bool isRating = false, bool isListingCount = false, String? uid}) {
    return Column(
      children: [
        if (isRating)
          StreamBuilder<QuerySnapshot<Review>>(
            stream: _firestoreService.getUserReviews(uid!),
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
          )
        else
          Text('Yeni', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }

  Widget _buildTrustItem(String uid, bool isVerified) {
    return StreamBuilder<QuerySnapshot<Booking>>(
      stream: _firestoreService.getOwnerBookings(uid),
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

  Widget _buildListingsTab(String uid) {
    return StreamBuilder<QuerySnapshot<Vehicle>>(
      stream: FirebaseFirestore.instance.collection('vehicles').where('userId', isEqualTo: uid).withConverter<Vehicle>(fromFirestore: (s, _) => Vehicle.fromMap(s), toFirestore: (v, _) => v.toMap()).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final vehicles = snapshot.data!.docs.map((d) => d.data()).toList();
        if (vehicles.isEmpty) return const Center(child: Text('İlan bulunmuyor.', style: TextStyle(color: Colors.grey)));
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: vehicles.length,
          itemBuilder: (context, index) => VehicleCard(vehicle: vehicles[index]),
        );
      },
    );
  }

  Widget _buildReviewsTab(String uid) {
    return StreamBuilder<QuerySnapshot<Review>>(
      stream: _firestoreService.getUserReviews(uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final reviews = snapshot.data!.docs.map((d) => d.data()).toList();
        if (reviews.isEmpty) return const Center(child: Text('Yorum yapılmamış.', style: TextStyle(color: Colors.grey)));
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: reviews.length,
          itemBuilder: (context, index) => _ReviewCard(review: reviews[index]),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(review.reviewerName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              Row(children: List.generate(5, (index) => Icon(Icons.star_rounded, size: 14, color: index < review.rating ? Colors.amber : Colors.white10))),
            ],
          ),
          const SizedBox(height: 8),
          Text(review.comment, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          Text(DateFormat('dd MMM yyyy').format(review.createdAt), style: TextStyle(color: Colors.white.withAlpha(40), fontSize: 10)),
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
    return Container(color: const Color(0xFF0F172A), child: _tabBar);
  }
  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
