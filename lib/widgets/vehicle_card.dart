import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../screens/vehicle_detail_screen.dart';

class VehicleCard extends StatelessWidget {
  final Vehicle vehicle;

  const VehicleCard({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    // Resim varsa, Image.network ile göster
    if (vehicle.images.isNotEmpty) {
      imageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          vehicle.images.first, // URL (String)
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          // Yüklenirken veya hata durumunda ne gösterileceği
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.broken_image, size: 56);
          },
        ),
      );
    } else {
      // Resim yoksa, varsayılan ikonu göster
      imageWidget = CircleAvatar(
        radius: 28,
        backgroundColor: Colors.blueAccent.withOpacity(0.2),
        child: Icon(
          vehicle.isCar ? Icons.directions_car : Icons.motorcycle,
          color: Colors.blueAccent,
        ),
      );
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
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      vehicle.city,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Text(
                vehicle.price,
                style: const TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
