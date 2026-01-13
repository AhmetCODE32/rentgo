import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentgo/core/app_state.dart';
import 'package:rentgo/core/firestore_service.dart';
import 'package:rentgo/models/vehicle.dart';
import 'package:rentgo/screens/edit_vehicle_screen.dart';
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
          backgroundColor: Colors.black,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 140,
                pinned: true,
                backgroundColor: Colors.black,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
                  title: const Text('İLANLARIM', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2)),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF111111), Colors.black],
                      ),
                    ),
                  ),
                ),
                actions: [
                  if (isPremium)
                    Padding(
                      padding: const EdgeInsets.only(right: 16, top: 12),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1), 
                            borderRadius: BorderRadius.circular(10), 
                            border: Border.all(color: Colors.amber.withOpacity(0.3))
                          ),
                          child: Text('$boostCount BOOST', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
                        ),
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
                            Icon(Icons.directions_car_filled_rounded, size: 80, color: Colors.white.withOpacity(0.05)),
                            const SizedBox(height: 16),
                            const Text('HENÜZ BİR İLANINIZ YOK', style: TextStyle(color: Colors.white24, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 12)),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final vehicle = myListings[index];
                          return FadeInUp(
                            duration: const Duration(milliseconds: 400),
                            delay: Duration(milliseconds: index * 100),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 24),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0A0A0A),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: vehicle.isBoosted ? Colors.amber.withOpacity(0.2) : Colors.white.withOpacity(0.05)
                                ),
                              ),
                              child: Column(
                                children: [
                                  Stack(
                                    children: [
                                      VehicleCard(vehicle: vehicle),
                                      if (vehicle.isBoosted)
                                        Positioned(
                                          top: 12,
                                          left: 12,
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                                            child: const Icon(Icons.bolt_rounded, color: Colors.black, size: 16),
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
                                            icon: Icons.bolt_rounded,
                                            label: vehicle.isBoosted ? 'BOOSTED' : 'BOOST ET',
                                            color: Colors.amber,
                                            onTap: vehicle.isBoosted ? null : () => _showBoostConfirm(context, firestoreService, user.uid, vehicle),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        Expanded(
                                          child: _ListingButton(
                                            icon: Icons.edit_note_rounded,
                                            label: 'DÜZENLE',
                                            color: Colors.white,
                                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditVehicleScreen(vehicle: vehicle))),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        _ListingButton(
                                          icon: Icons.delete_outline_rounded,
                                          label: '',
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
        backgroundColor: const Color(0xFF0A0A0A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24), 
          side: BorderSide(color: Colors.amber.withOpacity(0.2)),
        ),
        title: const Row(
          children: [
            Icon(Icons.bolt_rounded, color: Colors.amber),
            SizedBox(width: 12),
            Text('İLAN BOOST EDİLSİN Mİ?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ],
        ),
        content: const Text('Bu işlem 1 boost hakkınızı kullanacak ve ilanınız 24 saat boyunca en üstte görünecektir.', style: TextStyle(color: Colors.white70, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İPTAL', style: TextStyle(color: Colors.white24, fontWeight: FontWeight.w900))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber, 
              foregroundColor: Colors.black,
              minimumSize: const Size(100, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
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
            child: const Text('ONAYLA', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0A0A0A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24), 
          side: const BorderSide(color: Colors.white10),
        ),
        title: const Text('İLAN SİLİNSİN Mİ?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1)),
        content: Text('${vehicle.title} ilanınız kalıcı olarak silinecektir. Emin misiniz?', style: const TextStyle(color: Colors.white70, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İPTAL', style: TextStyle(color: Colors.white24, fontWeight: FontWeight.w900))),
          TextButton(
            onPressed: () async {
              await context.read<AppState>().deleteVehicle(vehicle.id!);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('SİL', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900)),
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
    final bool isIconOnly = label.isEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isIconOnly ? 12 : 16, vertical: 12),
        decoration: BoxDecoration(
          color: onTap == null ? Colors.white.withOpacity(0.02) : color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: onTap == null ? Colors.white.withOpacity(0.05) : color.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: onTap == null ? Colors.white10 : color),
            if (!isIconOnly) ...[
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: onTap == null ? Colors.white10 : color, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            ],
          ],
        ),
      ),
    );
  }
}
