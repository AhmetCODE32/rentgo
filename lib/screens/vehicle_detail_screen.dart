import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rentgo/core/firestore_service.dart';
import 'package:rentgo/screens/checkout_screen.dart';
import 'package:rentgo/screens/chat_screen.dart';
import 'package:rentgo/screens/other_user_profile_screen.dart';
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
  int _rentalDays = 1;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      if(_pageController.hasClients) {
        setState(() {
          _activePage = _pageController.page!.round();
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _changeRentalDays(int change) {
    setState(() {
      _rentalDays = (_rentalDays + change).clamp(1, 30);
    });
  }

  void _startChat() async {
    final user = Provider.of<User?>(context, listen: false);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Soru sormak için giriş yapmalısınız.')));
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

  void _showReportDialog() {
    final user = Provider.of<User?>(context, listen: false);
    if (user == null) {
      _showError('Şikayet etmek için giriş yapmalısınız.');
      return;
    }

    String selectedReason = 'Alakasız / Uygunsuz Fotoğraf';
    final detailsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İlanı Şikayet Et'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedReason,
              items: const [
                DropdownMenuItem(value: 'Alakasız / Uygunsuz Fotoğraf', child: Text('Alakasız Fotoğraf')),
                DropdownMenuItem(value: 'Yanlış Bilgi', child: Text('Yanlış Bilgi')),
                DropdownMenuItem(value: 'Dolandırıcılık Şüphesi', child: Text('Dolandırıcılık')),
                DropdownMenuItem(value: 'Fiyat Hatası', child: Text('Fiyat Hatası')),
                DropdownMenuItem(value: 'Diğer', child: Text('Diğer')),
              ],
              onChanged: (v) => selectedReason = v!,
              decoration: const InputDecoration(labelText: 'Neden?'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: detailsController,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Eklemek istediğiniz detaylar (isteğe bağlı)', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () async {
              await FirestoreService().reportVehicle(
                vehicleId: widget.vehicle.id!,
                reporterId: user.uid,
                reason: selectedReason,
                details: detailsController.text,
              );
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Şikayetiniz alındı.')));
              }
            },
            child: const Text('Gönder'),
          ),
        ],
      ),
    );
  }

  void _showError(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    final isMyVehicle = user != null && user.uid == widget.vehicle.userId;
    final firestoreService = FirestoreService();
    
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final hasImages = widget.vehicle.images.isNotEmpty;

    final priceFormatter = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);
    
    String displayPrice;
    double totalPrice = widget.vehicle.price * _rentalDays;
    String buttonText = 'Hemen Kirala';

    if (widget.vehicle.listingType == ListingType.rent) {
      displayPrice = "${priceFormatter.format(widget.vehicle.price)} / gün";
      buttonText = isMyVehicle ? "İlanım" : "${priceFormatter.format(totalPrice)} için Kirala";
    } else {
      displayPrice = priceFormatter.format(widget.vehicle.price);
      buttonText = isMyVehicle ? "İlanım" : 'Satın Al';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.vehicle.title),
        actions: [
          if (!isMyVehicle)
            IconButton(
              icon: const Icon(Icons.report_problem_outlined, color: Colors.redAccent),
              tooltip: 'İlanı Şikayet Et',
              onPressed: _showReportDialog,
            ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 250,
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
                      children: List<Widget>.generate(
                        widget.vehicle.images.length,
                        (index) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: InkWell(
                            onTap: () => _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeIn),
                            child: CircleAvatar(radius: 4, backgroundColor: _activePage == index ? colorScheme.primary : Colors.grey),
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
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.vehicle.title, style: textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Row(children: [const Icon(Icons.location_on_outlined, size: 16, color: Colors.blueAccent), const SizedBox(width: 4), Text(widget.vehicle.city, style: textTheme.bodySmall)]),
                  
                  const SizedBox(height: 24),

                  if (widget.vehicle.listingType == ListingType.rent)
                    _RentalDurationSelector(
                      days: _rentalDays,
                      pricePerDay: displayPrice,
                      onChanged: isMyVehicle ? null : _changeRentalDays,
                    ),
                  
                  if (widget.vehicle.description.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const _SectionTitle(title: 'Açıklama'),
                    Text(widget.vehicle.description, style: textTheme.bodyLarge?.copyWith(height: 1.5)),
                  ],

                  const SizedBox(height: 24),
                  const _SectionTitle(title: 'İletişim ve Teslimat'),
                  const SizedBox(height: 8),
                  
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OtherUserProfileScreen(
                            userId: widget.vehicle.userId,
                            userName: widget.vehicle.sellerName,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(backgroundColor: Colors.blueAccent, child: Text(widget.vehicle.sellerName[0].toUpperCase(), style: const TextStyle(color: Colors.white))),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(widget.vehicle.sellerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                                      ],
                                    ),
                                    StreamBuilder<QuerySnapshot<Review>>(
                                      stream: firestoreService.getUserReviews(widget.vehicle.userId),
                                      builder: (context, reviewSnapshot) {
                                        final reviews = reviewSnapshot.data?.docs ?? [];
                                        double avg = reviews.isEmpty ? 0.0 : reviews.fold(0.0, (prev, element) => prev + element.data().rating) / reviews.length;
                                        return Row(
                                          children: [
                                            const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                            const SizedBox(width: 4),
                                            Text(avg == 0.0 ? 'Yeni Üye' : '${avg.toStringAsFixed(1)} (${reviews.length} Değerlendirme)', style: const TextStyle(fontSize: 12, color: Colors.amber, fontWeight: FontWeight.bold)),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24, color: Colors.white10),
                          _InfoTile(icon: Icons.phone_outlined, title: 'Telefon', subtitle: widget.vehicle.phoneNumber),
                          _InfoTile(icon: Icons.delivery_dining_outlined, title: 'Teslimat Adresi', subtitle: widget.vehicle.pickupAddress),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const _SectionTitle(title: 'Araç Özellikleri'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      if(widget.vehicle.specs['year']?.isNotEmpty ?? false) _SpecChip(icon: Icons.calendar_today_outlined, label: widget.vehicle.specs['year']!),
                      if(widget.vehicle.specs['transmission']?.isNotEmpty ?? false) _SpecChip(icon: Icons.settings_input_svideo_outlined, label: widget.vehicle.specs['transmission']!),
                      if(widget.vehicle.specs['fuel']?.isNotEmpty ?? false) _SpecChip(icon: Icons.local_gas_station_outlined, label: widget.vehicle.specs['fuel']!),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context, buttonText, totalPrice, isMyVehicle),
    );
  }

  Widget _buildBottomBar(BuildContext context, String buttonText, double totalPrice, bool isMyVehicle) {
    return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: const Border(top: BorderSide(color: Colors.white10, width: 0.5)),
        ),
        child: Row(
          children: [
            if (!isMyVehicle) ...[
              IconButton.filledTonal(
                onPressed: _startChat,
                icon: const Icon(Icons.chat_bubble_outline),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: SizedBox(
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isMyVehicle ? Colors.grey : null,
                  ),
                  onPressed: isMyVehicle ? null : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CheckoutScreen(
                          vehicle: widget.vehicle,
                          days: _rentalDays,
                          totalPrice: totalPrice,
                        ),
                      ),
                    );
                  },
                  child: Text(buttonText),
                ),
              ),
            ),
          ],
        ));
  }
}

class _RentalDurationSelector extends StatelessWidget {
  final int days;
  final String pricePerDay;
  final Function(int)? onChanged;

  const _RentalDurationSelector({
    required this.days,
    required this.pricePerDay,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Kiralama Süresi'),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(pricePerDay, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary)),
            if (onChanged != null)
              Row(
                children: [
                  IconButton(onPressed: () => onChanged!(-1), icon: const Icon(Icons.remove_circle_outline)),
                  Text('$days gün', style: Theme.of(context).textTheme.titleLarge),
                  IconButton(onPressed: () => onChanged!(1), icon: const Icon(Icons.add_circle_outline)),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _SpecChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SpecChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
      label: Text(label),
      backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(25),
      side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 0.5),
      labelStyle: Theme.of(context).textTheme.bodyMedium,
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _InfoTile({required this.icon, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
      title: Text(title, style: Theme.of(context).textTheme.labelMedium),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
    );
}

class _PhotoBox extends StatelessWidget {
  final IconData? icon;
  final String? imageUrl;
  const _PhotoBox({this.icon, this.imageUrl});
  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: imageUrl != null
          ? CachedNetworkImage(
              imageUrl: imageUrl!,
              fit: BoxFit.cover,
              placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 50)),
            )
          : (icon != null ? Center(child: Icon(icon, size: 100, color: Theme.of(context).colorScheme.primary.withAlpha(127))) : null),
    );
}
