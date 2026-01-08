import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rentgo/models/vehicle.dart';
import 'package:rentgo/screens/vehicle_detail_screen.dart';

class VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  const VehicleCard({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final priceFormatter = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);
    String formattedPrice = vehicle.listingType == ListingType.rent
        ? "${priceFormatter.format(vehicle.price)}/gün"
        : priceFormatter.format(vehicle.price);

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VehicleDetailScreen(vehicle: vehicle))),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            _buildImage(context, colorScheme),
            Positioned(top: 12, right: 12, child: _PriceBadge(price: formattedPrice)),
            Positioned(bottom: 0, left: 0, right: 0, child: _InfoGradientLayer(textTheme: textTheme, vehicle: vehicle)),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context, ColorScheme colorScheme) {
    return vehicle.images.isNotEmpty
        ? Semantics(
            label: '${vehicle.title} için resim',
            child: CachedNetworkImage(
              imageUrl: vehicle.images.first,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(height: 220, color: colorScheme.surface, child: const Center(child: CircularProgressIndicator())),
              errorWidget: (context, url, error) => _buildPlaceholderImage(context, colorScheme),
            ),
          )
        : _buildPlaceholderImage(context, colorScheme);
  }

  Widget _buildPlaceholderImage(BuildContext context, ColorScheme colorScheme) {
    return Container(
      height: 220,
      color: colorScheme.surface,
      child: Center(child: Icon(vehicle.isCar ? Icons.directions_car : Icons.motorcycle, size: 60, color: colorScheme.primary.withOpacity(0.5))),
    );
  }
}

class _PriceBadge extends StatelessWidget {
  final String price;
  const _PriceBadge({required this.price});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(price, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}

class _InfoGradientLayer extends StatelessWidget {
  final TextTheme textTheme;
  final Vehicle vehicle;
  const _InfoGradientLayer({required this.textTheme, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black54, Colors.black87],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(vehicle.title, style: textTheme.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Row(children: [Icon(Icons.location_on, size: 14, color: textTheme.bodySmall?.color), const SizedBox(width: 4), Text(vehicle.city, style: textTheme.bodySmall)])
        ],
      ),
    );
  }
}
