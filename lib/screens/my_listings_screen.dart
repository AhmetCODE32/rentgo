import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_state.dart';
import '../widgets/vehicle_card.dart';

class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İlanlarım'),
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          final myVehicles = appState.allVehicles;

          if (myVehicles.isEmpty) {
            return const Center(
              child: Text(
                'Henüz hiç ilan yayınlamadınız.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: myVehicles.length,
            itemBuilder: (context, index) {
              return VehicleCard(vehicle: myVehicles[index]);
            },
          );
        },
      ),
    );
  }
}
