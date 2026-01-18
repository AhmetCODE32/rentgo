import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rentgo/core/firestore_service.dart';
import 'package:rentgo/screens/chat_screen.dart';
import 'package:rentgo/screens/other_user_profile_screen.dart';
import 'package:url_launcher/url_launcher.dart'; 
import 'package:share_plus/share_plus.dart'; 
import '../models/vehicle.dart';
import '../models/review.dart';

final Set<String> _viewedVehicles = {};

class VehicleDetailScreen extends StatefulWidget {
  final Vehicle vehicle;

  const VehicleDetailScreen({super.key, required this.vehicle});

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  final _pageController = PageController();
  int _activePage = 0;

  @override
  void initState() {
    super.initState();
    if (!_viewedVehicles.contains(widget.vehicle.id)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<FirestoreService>().incrementVehicleViews(widget.vehicle.id!);
        _viewedVehicles.add(widget.vehicle.id!);
      });
    }

    _pageController.addListener(() {
      if(_pageController.hasClients) {
        setState(() => _activePage = _pageController.page!.round());
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _shareVehicle() async {
    try {
      final priceFormatter = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);
      final String shareText = 'Vroomy\'de harika bir araç buldum! 🚗\n\n'
          '${widget.vehicle.title}\n'
          'Fiyat: ${priceFormatter.format(widget.vehicle.price)}\n'
          'Şehir: ${widget.vehicle.city}\n\n'
          'Hemen incelemek için Vroomy uygulamasını indir!';
      
      await Share.share(shareText);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paylaşım penceresi açılamadı.'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _startChat() async {
    final user = Provider.of<User?>(context, listen: false);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Soru sormak için giriş yapmalısınız.')));
      return;
    }

    if (user.uid == widget.vehicle.userId) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kendi ilanınıza mesaj gönderemezsiniz.')));
      return;
    }

    final String roomId = '${widget.vehicle.id}_${user.uid}';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          roomId: roomId,
          vehicleId: widget.vehicle.id!,
          vehicleTitle: widget.vehicle.title,
          vehicleImage: widget.vehicle.images.isNotEmpty ? widget.vehicle.images.first : '',
          ownerId: widget.vehicle.userId,
          otherUserId: widget.vehicle.userId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    final isMyVehicle = user != null && user.uid == widget.vehicle.userId;
    final firestoreService = context.read<FirestoreService>();
    
    final hasImages = widget.vehicle.images.isNotEmpty;
    final priceFormatter = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('DETAYLAR', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.w900, fontSize: 16)),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            onPressed: _shareVehicle,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 350,
            child: Stack(
              children: [
                Hero(
                  tag: 'vehicle_image_${widget.vehicle.id}',
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: hasImages ? widget.vehicle.images.length : 1,
                    itemBuilder: (context, index) {
                      if (hasImages) return _PhotoBox(imageUrl: widget.vehicle.images[index]);
                      return const _PhotoBox(icon: Icons.directions_car);
                    },
                  ),
                ),
                if (hasImages && widget.vehicle.images.length > 1)
                  Positioned(
                    bottom: 30,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        widget.vehicle.images.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _activePage == index ? 24 : 8,
                          height: 4,
                          decoration: BoxDecoration(
                            color: _activePage == index ? Colors.white : Colors.white24,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.vehicle.title, 
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1)
                        )
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      const Icon(Icons.visibility_rounded, size: 14, color: Colors.white24),
                      const SizedBox(width: 6),
                      Text(
                        '${widget.vehicle.views} görüntülenme',
                        style: const TextStyle(color: Colors.white24, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      priceFormatter.format(widget.vehicle.price), 
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(children: [const Icon(Icons.location_on_rounded, size: 14, color: Colors.white24), const SizedBox(width: 4), Text(widget.vehicle.city, style: const TextStyle(color: Colors.white24, fontWeight: FontWeight.bold))]),
                  
                  const SizedBox(height: 40),
                  const _SectionTitle(title: 'HAKKINDA'),
                  Text(widget.vehicle.description, style: TextStyle(color: Colors.white.withOpacity(0.6), height: 1.7, fontSize: 15)),

                  const SizedBox(height: 40),
                  const _SectionTitle(title: 'ÖZELLİKLER'),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _SpecChip(icon: Icons.calendar_today_rounded, label: widget.vehicle.specs['year'] ?? '-'),
                        _SpecChip(icon: Icons.settings_rounded, label: widget.vehicle.specs['transmission'] ?? '-'),
                        _SpecChip(icon: Icons.local_gas_station_rounded, label: widget.vehicle.specs['fuel'] ?? '-'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                  const _SectionTitle(title: 'SAHİBİ'),
                  _buildSellerCard(context, firestoreService),
                  
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildActionButtons(isMyVehicle),
    );
  }

  Widget _buildSellerCard(BuildContext context, FirestoreService service) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: service.getUserProfileStream(widget.vehicle.userId),
      builder: (context, snapshot) {
        final userData = snapshot.data?.data() ?? {};
        final String? photoURL = userData['photoURL'];
        final String displayName = userData['displayName'] ?? widget.vehicle.sellerName;
        
        return InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OtherUserProfileScreen(userId: widget.vehicle.userId, userName: displayName))),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0A), 
              borderRadius: BorderRadius.circular(24), 
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24, 
                  backgroundColor: const Color(0xFF111111), 
                  backgroundImage: photoURL != null ? NetworkImage(photoURL) : null,
                  child: photoURL == null ? Text(displayName[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white)),
                      const SizedBox(height: 2),
                      const Text(
                        'Doğrulanmış Üye', 
                        style: TextStyle(color: Colors.white24, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.white24),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildActionButtons(bool isMyVehicle) {
    if (isMyVehicle) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      decoration: const BoxDecoration(
        color: Colors.black, 
        border: Border(top: BorderSide(color: Colors.white10))
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _startChat,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('MESAJ GÖNDER', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16), 
    child: Text(
      title, 
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white24, letterSpacing: 2)
    )
  );
}

class _SpecChip extends StatelessWidget {
  final IconData icon; final String label;
  const _SpecChip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(right: 12),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), 
    decoration: BoxDecoration(
      color: const Color(0xFF0A0A0A), 
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withOpacity(0.05)),
    ), 
    child: Row(
      mainAxisSize: MainAxisSize.min, 
      children: [
        Icon(icon, size: 16, color: Colors.white), 
        const SizedBox(width: 10), 
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))
      ]
    )
  );
}

class _PhotoBox extends StatelessWidget {
  final IconData? icon; final String? imageUrl;
  const _PhotoBox({this.icon, this.imageUrl});
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(color: Color(0xFF0A0A0A)), 
    child: imageUrl != null 
      ? CachedNetworkImage(imageUrl: imageUrl!, fit: BoxFit.cover) 
      : Center(child: Icon(icon, size: 80, color: Colors.white10))
  );
}
