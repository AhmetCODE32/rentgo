import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rentgo/core/firestore_service.dart';
import 'package:rentgo/models/vehicle.dart';
import 'package:rentgo/screens/vehicle_detail_screen.dart';

class VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  const VehicleCard({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final user = Provider.of<User?>(context);
    final firestoreService = FirestoreService();

    final priceFormatter = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);
    String formattedPrice = vehicle.listingType == ListingType.rent
        ? "${priceFormatter.format(vehicle.price)}/gün"
        : priceFormatter.format(vehicle.price);

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VehicleDetailScreen(vehicle: vehicle))),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Stack(
          children: [
            Hero(
              tag: 'vehicle_image_${vehicle.id}',
              child: _buildImage(context, colorScheme),
            ),
            
            // FAVORİ BUTONU (YENİ)
            if (user != null)
              Positioned(
                top: 8,
                left: 8,
                child: StreamBuilder<bool>(
                  stream: firestoreService.isFavoriteStream(user.uid, vehicle.id!),
                  builder: (context, snapshot) {
                    final isFav = snapshot.data ?? false;
                    return GestureDetector(
                      onTap: () => firestoreService.toggleFavorite(user.uid, vehicle.id!),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(50),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? Colors.redAccent : Colors.white,
                          size: 22,
                        ),
                      ),
                    );
                  },
                ),
              ),

            Positioned(top: 12, right: 12, child: _PriceBadge(price: formattedPrice)),
            Positioned(bottom: 0, left: 0, right: 0, child: _InfoGradientLayer(textTheme: textTheme, vehicle: vehicle)),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context, ColorScheme colorScheme) {
    return vehicle.images.isNotEmpty
        ? CachedNetworkImage(
            imageUrl: vehicle.images.first,
            height: 220,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(height: 220, color: colorScheme.surface, child: const Center(child: CircularProgressIndicator())),
            errorWidget: (context, url, error) => _buildPlaceholderImage(context, colorScheme),
          )
        : _buildPlaceholderImage(context, colorScheme);
  }

  Widget _buildPlaceholderImage(BuildContext context, ColorScheme colorScheme) {
    IconData icon;
    switch (vehicle.category) {
      case 'Motor': icon = Icons.motorcycle_rounded; break;
      case 'Karavan': icon = Icons.rv_hookup_rounded; break;
      case 'Bisiklet': icon = Icons.pedal_bike_rounded; break;
      case 'Scooter': icon = Icons.electric_scooter_rounded; break;
      case 'Ticari': icon = Icons.local_shipping_rounded; break;
      default: icon = Icons.directions_car_rounded;
    }
    return Container(
      height: 220,
      width: double.infinity,
      color: colorScheme.surface,
      child: Center(child: Icon(icon, size: 60, color: colorScheme.primary.withAlpha(127))),
    );
  }
}

class _PriceBadge extends StatelessWidget {
  final String price;
  const _PriceBadge({required this.price});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withAlpha(230), borderRadius: BorderRadius.circular(12)),
    child: Text(price, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
  );
}

class _InfoGradientLayer extends StatelessWidget {
  final TextTheme textTheme;
  final Vehicle vehicle;
  const _InfoGradientLayer({required this.textTheme, required this.vehicle});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
    decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withAlpha(180), Colors.black.withAlpha(230)])),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(vehicle.title, style: textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            _CategorySmallBadge(category: vehicle.category),
          ],
        ),
        const SizedBox(height: 6),
        Row(children: [const Icon(Icons.location_on, size: 14, color: Colors.blueAccent), const SizedBox(width: 4), Text(vehicle.city, style: textTheme.bodySmall?.copyWith(color: Colors.white70))])
      ],
    ),
  );
}

class _CategorySmallBadge extends StatelessWidget {
  final String category;
  const _CategorySmallBadge({required this.category});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.white24, width: 0.5)),
    child: Text(category, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
  );
}
