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
    final user = Provider.of<User?>(context);
    final firestoreService = FirestoreService();

    final priceFormatter = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);
    String formattedPrice = vehicle.listingType == ListingType.rent
        ? "${priceFormatter.format(vehicle.price)}/gün"
        : priceFormatter.format(vehicle.price);

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VehicleDetailScreen(vehicle: vehicle))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Hero(
              tag: 'vehicle_image_${vehicle.id}',
              child: _buildImage(context),
            ),
            
            // Favori Butonu
            if (user != null)
              Positioned(
                top: 12,
                left: 12,
                child: StreamBuilder<bool>(
                  stream: firestoreService.isFavoriteStream(user.uid, vehicle.id!),
                  builder: (context, snapshot) {
                    final isFav = snapshot.data ?? false;
                    return GestureDetector(
                      onTap: () => firestoreService.toggleFavorite(user.uid, vehicle.id!),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? Colors.redAccent : Colors.white,
                          size: 20,
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Fiyat Rozeti
            Positioned(
              top: 12, 
              right: 12, 
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.circular(10)
                ),
                child: Text(
                  formattedPrice, 
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13)
                ),
              )
            ),

            // Bilgi Katmanı (Gradient)
            Positioned(
              bottom: 0, 
              left: 0, 
              right: 0, 
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, 
                    end: Alignment.bottomCenter, 
                    colors: [Colors.transparent, Colors.black.withOpacity(0.8), Colors.black]
                  )
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            vehicle.title, 
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5), 
                            maxLines: 1, 
                            overflow: TextOverflow.ellipsis
                          )
                        ),
                        const SizedBox(width: 8),
                        _CategoryBadge(category: vehicle.category),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 12, color: Colors.white24), 
                        const SizedBox(width: 4), 
                        Text(
                          vehicle.city, 
                          style: const TextStyle(color: Colors.white24, fontSize: 12, fontWeight: FontWeight.bold)
                        )
                      ]
                    )
                  ],
                ),
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    return vehicle.images.isNotEmpty
        ? CachedNetworkImage(
            imageUrl: vehicle.images.first,
            height: 240,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(height: 240, color: const Color(0xFF111111), child: const Center(child: CircularProgressIndicator(color: Colors.white24))),
            errorWidget: (context, url, error) => _buildPlaceholderImage(),
          )
        : _buildPlaceholderImage();
  }

  Widget _buildPlaceholderImage() {
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
      height: 240,
      width: double.infinity,
      color: const Color(0xFF111111),
      child: Center(child: Icon(icon, size: 60, color: Colors.white10)),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String category;
  const _CategoryBadge({required this.category});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.05), 
      borderRadius: BorderRadius.circular(8), 
      border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5)
    ),
    child: Text(
      category.toUpperCase(), 
      style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)
    ),
  );
}
