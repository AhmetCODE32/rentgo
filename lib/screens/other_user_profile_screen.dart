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

  // ÜYELİK SÜRESİ HESAPLAMA FONKSİYONU
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
          final Timestamp? createdAt = userData['createdAt'] as Timestamp?;

          final bgGradient = isPremium 
              ? const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFB8860B), Color(0xFF0F172A)])
              : const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2563EB), Color(0xFF0F172A)]);

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 380, // Biraz daha yükselttim
                  floating: false,
                  pinned: true,
                  backgroundColor: const Color(0xFF1E293B),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(decoration: BoxDecoration(gradient: bgGradient)),
                        if (isPremium) Positioned(top: 60, right: -20, child: Icon(Icons.star_rounded, size: 200, color: Colors.amber.withOpacity(0.1))),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 60),
                            _buildAvatar(photoURL, widget.userName, isPremium),
                            const SizedBox(height: 16),
                            _buildNameSection(widget.userName, isVerified, isPremium),
                            const SizedBox(height: 8),
                            
                            // ÜYELİK SÜRESİ ETİKETİ
                            Text(
                              _getMemberSince(createdAt),
                              style: TextStyle(color: isPremium ? Colors.amber.shade200 : Colors.white60, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            
                            const SizedBox(height: 12),
                            if (isPremium) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.amber.withOpacity(0.5))),
                                child: const Text('VROOMY PRO ÜYESİ', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 10)),
                              ),
                              const SizedBox(height: 8),
                            ],
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.location_on, size: 16, color: Colors.blueAccent),
                                const SizedBox(width: 4),
                                Text(city, style: const TextStyle(color: Colors.white70)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildStatsBar(widget.userId, isVerified, isPremium),
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
                      labelColor: isPremium ? Colors.amber : Colors.blueAccent,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: isPremium ? Colors.amber : Colors.blueAccent,
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

  Widget _buildAvatar(String? photoURL, String name, bool isPremium) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isPremium ? Colors.amber : Colors.transparent, width: 2)),
      child: CircleAvatar(
        radius: 55,
        backgroundColor: Colors.white.withAlpha(20),
        child: CircleAvatar(
          radius: 50,
          backgroundImage: photoURL != null ? CachedNetworkImageProvider(photoURL) : null,
          child: photoURL == null ? Text(name[0].toUpperCase(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)) : null,
        ),
      ),
    );
  }

  Widget _buildNameSection(String name, bool isVerified, bool isPremium) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        if (isVerified || isPremium) const SizedBox(width: 8),
        if (isPremium) const Icon(Icons.workspace_premium, color: Colors.amber, size: 24)
        else if (isVerified) const Icon(Icons.verified, color: Colors.greenAccent, size: 20),
      ],
    );
  }

  Widget _buildStatsBar(String uid, bool isVerified, bool isPremium) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30),
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withAlpha(150),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isPremium ? Colors.amber.withOpacity(0.3) : Colors.white.withAlpha(10)),
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
