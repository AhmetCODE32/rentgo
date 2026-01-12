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
    // KONTROL: İlan görüntülendiğinde izlenme sayısını artır
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FirestoreService>().incrementVehicleViews(widget.vehicle.id!);
    });

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
          const SnackBar(content: Text('Paylaşım penceresi açılamadı. Lütfen uygulamayı baştan başlatın.'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
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
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('İlan Detayı'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            onPressed: _shareVehicle,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 300,
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
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        widget.vehicle.images.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _activePage == index ? 20 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _activePage == index ? Colors.blueAccent : Colors.grey.withAlpha(127),
                            borderRadius: BorderRadius.circular(4),
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
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(widget.vehicle.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white))),
                      Text(priceFormatter.format(widget.vehicle.price), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.blueAccent)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(children: [const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey), const SizedBox(width: 4), Text(widget.vehicle.city, style: const TextStyle(color: Colors.grey))]),
                  
                  const SizedBox(height: 32),
                  const _SectionTitle(title: 'Açıklama'),
                  Text(widget.vehicle.description, style: TextStyle(color: Colors.white.withAlpha(200), height: 1.6, fontSize: 15)),

                  const SizedBox(height: 32),
                  const _SectionTitle(title: 'Özellikler'),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _SpecChip(icon: Icons.calendar_today, label: widget.vehicle.specs['year'] ?? 'Belirtilmemiş'),
                      _SpecChip(icon: Icons.settings, label: widget.vehicle.specs['transmission'] ?? 'Belirtilmemiş'),
                      _SpecChip(icon: Icons.local_gas_station, label: widget.vehicle.specs['fuel'] ?? 'Belirtilmemiş'),
                    ],
                  ),

                  const SizedBox(height: 32),
                  const _SectionTitle(title: 'Satıcı Bilgileri'),
                  _buildSellerCard(context, firestoreService),
                  
                  const SizedBox(height: 100),
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
        final bool isPremium = userData['isPremium'] ?? false;
        final String? photoURL = userData['photoURL'];
        final String displayName = userData['displayName'] ?? widget.vehicle.sellerName;
        final Timestamp? createdAt = userData['createdAt'] as Timestamp?;
        
        // GÜVEN: Üyelik Süresi Hesaplama
        String memberSince = 'Yeni Üye';
        if (createdAt != null) {
          final diff = DateTime.now().difference(createdAt.toDate());
          if (diff.inDays > 365) {
            memberSince = '${(diff.inDays / 365).floor()} yıldır üye';
          } else if (diff.inDays > 30) {
            memberSince = '${(diff.inDays / 30).floor()} aydır üye';
          } else {
            memberSince = '${diff.inDays} gündür üye';
          }
        }

        return InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OtherUserProfileScreen(userId: widget.vehicle.userId, userName: displayName))),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B), 
              borderRadius: BorderRadius.circular(20), 
              border: Border.all(color: isPremium ? Colors.amber.withOpacity(0.3) : Colors.white.withAlpha(10)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isPremium ? Colors.amber : Colors.transparent, width: 2)),
                  child: CircleAvatar(
                    radius: 25, 
                    backgroundColor: Colors.blueAccent, 
                    backgroundImage: photoURL != null ? NetworkImage(photoURL) : null,
                    child: photoURL == null ? Text(displayName[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)) : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                          if (isPremium) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(4)),
                              child: const Text('PRO', style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        isPremium ? 'Vroomy Pro Satıcı • $memberSince' : 'Doğrulanmış Satıcı • $memberSince', 
                        style: TextStyle(color: isPremium ? Colors.amber : Colors.blueAccent, fontSize: 12, fontWeight: isPremium ? FontWeight.bold : FontWeight.normal),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
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
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(color: Color(0xFF0F172A), border: Border(top: BorderSide(color: Colors.white10))),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _startChat,
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              label: const Text('Soru Sor'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E293B), 
                foregroundColor: Colors.white, 
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _makePhoneCall(widget.vehicle.phoneNumber),
              icon: const Icon(Icons.phone_in_talk_rounded),
              label: const Text('Satıcıyı Ara'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent, 
                foregroundColor: Colors.white, 
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
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
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)));
}

class _SpecChip extends StatelessWidget {
  final IconData icon; final String label;
  const _SpecChip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 16, color: Colors.blueAccent), const SizedBox(width: 8), Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13))]));
}

class _PhotoBox extends StatelessWidget {
  final IconData? icon; final String? imageUrl;
  const _PhotoBox({this.icon, this.imageUrl});
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), color: const Color(0xFF1E293B)), child: ClipRRect(borderRadius: BorderRadius.circular(24), child: imageUrl != null ? CachedNetworkImage(imageUrl: imageUrl!, fit: BoxFit.cover, placeholder: (c, u) => const Center(child: CircularProgressIndicator())) : Center(child: Icon(icon, size: 80, color: Colors.white10))));
}
