import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentgo/models/vehicle.dart';
import 'package:rentgo/screens/edit_vehicle_screen.dart'; // EKLENDİ
import '../core/app_state.dart';
import '../widgets/vehicle_card.dart';

class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});

  Future<void> _showDeleteDialog(BuildContext context, Vehicle vehicle) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('İlanı Sil'),
          content: const Text('Bu ilanı kalıcı olarak silmek istediğinizden emin misiniz?'),
          actions: <Widget>[
            TextButton(child: const Text('İptal'), onPressed: () => Navigator.of(context).pop()),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: const Text('Sil'),
              onPressed: () {
                context.read<AppState>().deleteVehicle(vehicle.id!);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İlan başarıyla silindi.')));
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final currentUser = context.watch<User?>();

    final myVehicles = currentUser != null
        ? appState.allVehicles.where((v) => v.userId == currentUser.uid).toList()
        : <Vehicle>[];

    return Scaffold(
      appBar: AppBar(title: const Text('İlanlarım')),
      body: myVehicles.isEmpty
          ? const Center(child: Text('Henüz hiç ilan yayınlamadınız.', style: TextStyle(color: Colors.grey, fontSize: 16)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: myVehicles.length,
              itemBuilder: (context, index) {
                final vehicle = myVehicles[index];
                return Column(
                  children: [
                    VehicleCard(vehicle: vehicle),
                    // DÜZENLE VE SİL BUTONLARI
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            label: const Text('Düzenle'),
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditVehicleScreen(vehicle: vehicle))),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                            label: const Text('Sil', style: TextStyle(color: Colors.redAccent)),
                            onPressed: () => _showDeleteDialog(context, vehicle),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
