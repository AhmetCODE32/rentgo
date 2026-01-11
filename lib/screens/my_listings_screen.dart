import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentgo/core/app_state.dart';
import 'package:rentgo/models/vehicle.dart';
import 'package:rentgo/widgets/vehicle_card.dart';
import 'package:animate_do/animate_do.dart';

class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    if (user == null) return const Scaffold(body: Center(child: Text('Giriş yapmalısınız.')));

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: CustomScrollView(
        slivers: [
          // PREMIUM BAŞLIK
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: const Color(0xFF1E293B),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('İlanlarım', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF2563EB), Color(0xFF0F172A)],
                  ),
                ),
              ),
            ),
          ),

          // İLAN LİSTESİ
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
                            border: Border.all(color: Colors.white.withAlpha(5)),
                          ),
                          child: Column(
                            children: [
                              VehicleCard(vehicle: vehicle),
                              // YÖNETİM BUTONLARI (ŞIK VE SADE)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    _ListingButton(
                                      icon: Icons.edit_outlined,
                                      label: 'Düzenle',
                                      color: Colors.blueAccent,
                                      onTap: () {
                                        // Düzenleme mantığı buraya
                                      },
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
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _ListingButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
