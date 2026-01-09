import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentgo/core/firestore_service.dart';
import 'package:rentgo/models/vehicle.dart';
import 'package:rentgo/widgets/vehicle_card.dart';
import '../core/app_state.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    final firestoreService = FirestoreService();
    final appState = Provider.of<AppState>(context);

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Favorilerinizi görmek için giriş yapın.')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Favorilerim')),
      body: StreamBuilder<List<String>>(
        stream: firestoreService.getFavoriteVehicleIds(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final favoriteIds = snapshot.data ?? [];

          if (favoriteIds.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 80, color: Colors.white.withAlpha(30)),
                  const SizedBox(height: 16),
                  const Text('Henüz favori aracınız yok.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          // APPSTATE İÇİNDEKİ TÜM ARAÇLARDAN FAVORİ OLANLARI BUL
          final favoriteVehicles = appState.allVehicles.where((v) => favoriteIds.contains(v.id)).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favoriteVehicles.length,
            itemBuilder: (context, index) => VehicleCard(vehicle: favoriteVehicles[index]),
          );
        },
      ),
    );
  }
}
