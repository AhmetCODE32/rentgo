import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Sayı formatlama için eklendi
import '../models/vehicle.dart';
import '../screens/vehicle_detail_screen.dart';

class VehicleCard extends StatelessWidget {
  final Vehicle vehicle;

  const VehicleCard({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (vehicle.images.isNotEmpty) {
      imageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          vehicle.images.first,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.broken_image, size: 56, color: Colors.grey);
          },
        ),
      );
    } else {
      imageWidget = CircleAvatar(
        radius: 28,
        backgroundColor: Colors.blueAccent.withOpacity(0.2),
        child: Icon(
          vehicle.isCar ? Icons.directions_car : Icons.motorcycle,
          color: Colors.blueAccent,
        ),
      );
    }

    // Fiyat formatlayıcı
    final priceFormatter = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);
    String formattedPrice;
    if (vehicle.listingType == ListingType.rent) {
      formattedPrice = "${priceFormatter.format(vehicle.price)} / gün";
    } else {
      formattedPrice = priceFormatter.format(vehicle.price);
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VehicleDetailScreen(vehicle: vehicle),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              imageWidget,
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      vehicle.city,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Text(
                formattedPrice, // DİNAMİK FİYAT GÖSTERİMİ
                style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
