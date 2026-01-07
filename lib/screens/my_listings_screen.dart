import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentgo/models/vehicle.dart';
import '../core/app_state.dart';
import '../widgets/vehicle_card.dart';

class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});

  // Silme Onay Diyaloğu
  Future<void> _showDeleteDialog(BuildContext context, Vehicle vehicle) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('İlanı Sil'),
          content: const SingleChildScrollView(
            child: Text('Bu ilanı kalıcı olarak silmek istediğinizden emin misiniz?'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('İptal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: const Text('Sil'),
              onPressed: () {
                // AppState üzerinden silme işlemini çağır
                context.read<AppState>().deleteVehicle(vehicle.id!);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('İlan başarıyla silindi.')),
                );
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

    // Sadece mevcut kullanıcının ilanlarını filtrele
    final myVehicles = currentUser != null
        ? appState.allVehicles.where((v) => v.userId == currentUser.uid).toList()
        : <Vehicle>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('İlanlarım'),
      ),
      body: Builder(
        builder: (context) {
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
              final vehicle = myVehicles[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: VehicleCard(vehicle: vehicle),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () => _showDeleteDialog(context, vehicle),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
