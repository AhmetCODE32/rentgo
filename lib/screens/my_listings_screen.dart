import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentgo/core/app_state.dart';
import 'package:rentgo/core/firestore_service.dart';
import 'package:rentgo/models/vehicle.dart';
import 'package:rentgo/widgets/vehicle_card.dart';
import 'package:animate_do/animate_do.dart';

class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    if (user == null) return const Scaffold(body: Center(child: Text('Giriş yapmalısınız.')));

    final firestoreService = context.read<FirestoreService>();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: firestoreService.getUserProfileStream(user.uid),
      builder: (context, userSnapshot) {
        final userData = userSnapshot.data?.data() ?? {};
        final bool isPremium = userData['isPremium'] ?? false;
        final int boostCount = userData['boostCount'] ?? 0;

        return Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                pinned: true,
                backgroundColor: const Color(0xFF1E293B),
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text('İlanlarım', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: isPremium ? [const Color(0xFFB8860B), const Color(0xFF0F172A)] : [const Color(0xFF2563EB), const Color(0xFF0F172A)],
                      ),
                    ),
                  ),
                ),
                actions: [
                  if (isPremium)
                    Padding(
                      padding: const EdgeInsets.only(right: 16, top: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.amber.withOpacity(0.5))),
                        child: Text('$boostCount Boost Hakkı', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                ],
              ),

              Consumer<AppState>(
                builder: (context, appState, child) {
                  final myListings = appState.allVehicles.where((v) => v.userId == user.uid).toList();

                  if (myListings.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.directions_car_outlined, size: 80, color: Colors.white.withAlpha(20)),
                            const SizedBox(height: 16),
                            const Text('Henüz bir ilanınız bulunmuyor.', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final vehicle = myListings[index];
                          return FadeInUp(
                            duration: const Duration(milliseconds: 400),
                            delay: Duration(milliseconds: index * 100),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: vehicle.isBoosted ? Colors.amber.withOpacity(0.3) : Colors.white.withAlpha(5)),
                              ),
                              child: Column(
                                children: [
                                  Stack(
                                    children: [
                                      VehicleCard(vehicle: vehicle),
                                      if (vehicle.isBoosted)
                                        Positioned(
                                          top: 12,
                                          right: 12,
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                                            child: const Icon(Icons.bolt, color: Colors.black, size: 16),
                                          ),
                                        ),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                    child: Row(
                                      children: [
                                        if (isPremium) ...[
                                          _ListingButton(
                                            icon: Icons.bolt,
                                            label: vehicle.isBoosted ? 'Boost Edildi' : 'Boost Et',
                                            color: Colors.amber,
                                            onTap: vehicle.isBoosted ? null : () => _showBoostConfirm(context, firestoreService, user.uid, vehicle),
                                          ),
                                          const Spacer(),
                                        ],
                                        _ListingButton(
                                          icon: Icons.edit_outlined,
                                          label: 'Düzenle',
                                          color: Colors.blueAccent,
                                          onTap: () { /* Düzenle */ },
                                        ),
                                        const SizedBox(width: 12),
                                        _ListingButton(
                                          icon: Icons.delete_outline_rounded,
                                          label: 'Sil',
                                          color: Colors.redAccent,
                                          onTap: () => _showDeleteConfirm(context, vehicle),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: myListings.length,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBoostConfirm(BuildContext context, FirestoreService service, String uid, Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Row(
          children: [
            Icon(Icons.bolt, color: Colors.amber),
            SizedBox(width: 8),
            Text('İlanı Boost Et?'),
          ],
        ),
        content: const Text('Bu işlem 1 boost hakkınızı kullanacak ve ilanınız 24 saat boyunca en üstte görünecektir.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
            onPressed: () async {
              final success = await service.boostVehicle(vehicle.id!, uid);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'İlan başarıyla boost edildi!' : 'Boost hakkınız kalmamış olabilir.'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Onayla'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('İlanı Sil?'),
        content: Text('${vehicle.title} ilanınız kalıcı olarak silinecektir. Emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          TextButton(
            onPressed: () async {
              await context.read<AppState>().deleteVehicle(vehicle.id!);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Sil', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

class _ListingButton extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback? onTap;
  const _ListingButton({required this.icon, required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: onTap == null ? Colors.grey.withAlpha(20) : color.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: onTap == null ? Colors.grey.withAlpha(50) : color.withAlpha(50)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: onTap == null ? Colors.grey : color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: onTap == null ? Colors.grey : color, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
