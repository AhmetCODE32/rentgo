import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentgo/core/firestore_service.dart';
import 'package:rentgo/models/vehicle.dart';
import 'package:rentgo/widgets/vehicle_card.dart';
import 'package:animate_do/animate_do.dart';
import '../core/app_state.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    final firestoreService = FirestoreService();
    final appState = Provider.of<AppState>(context);

    if (user == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: Text('Favorilerinizi görmek için giriş yapın.', style: TextStyle(color: Colors.white24))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('FAVORİLER', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.w900, fontSize: 16)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<List<String>>(
        stream: firestoreService.getFavoriteVehicleIds(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white10));
          }

          final favoriteIds = snapshot.data ?? [];

          if (favoriteIds.isEmpty) {
            return Center(
              child: FadeIn(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite_outline_rounded, size: 80, color: Colors.white.withOpacity(0.05)),
                    const SizedBox(height: 16),
                    const Text('HENÜZ FAVORİNİZ YOK', style: TextStyle(color: Colors.white24, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 12)),
                  ],
                ),
              ),
            );
          }

          final favoriteVehicles = appState.allVehicles.where((v) => favoriteIds.contains(v.id)).toList();

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            itemCount: favoriteVehicles.length,
            itemBuilder: (context, index) => FadeInUp(
              duration: const Duration(milliseconds: 400),
              delay: Duration(milliseconds: index * 100),
              child: VehicleCard(vehicle: favoriteVehicles[index]),
            ),
          );
        },
      ),
    );
  }
}
