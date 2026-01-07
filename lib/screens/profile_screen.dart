import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentgo/core/auth_service.dart';
import '../core/app_state.dart';
import 'my_listings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Merkezi provider'dan anlık kullanıcıyı DOĞRU şekilde al
    final user = Provider.of<User?>(context);
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // PROFİL HEADER
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF020617),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blueAccent,
                    child: Icon(Icons.person, size: 34, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hatalı .data kullanımı düzeltildi
                      Text(
                        user?.email ?? 'Kullanıcı',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Hesabım',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // MENÜ
            Consumer<AppState>(
              builder: (context, appState, child) {
                return _ProfileTile(
                  icon: Icons.directions_car_outlined,
                  title: 'İlanlarım',
                  badge: appState.allVehicles.length.toString(),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyListingsScreen()),
                  ),
                );
              },
            ),
            _ProfileTile(
              icon: Icons.favorite_border,
              title: 'Favoriler',
              onTap: () {},
            ),
            _ProfileTile(
              icon: Icons.settings_outlined,
              title: 'Ayarlar',
              onTap: () {},
            ),
            const SizedBox(height: 16),
            _ProfileTile(
              icon: Icons.logout,
              title: 'Çıkış Yap',
              isDanger: true,
              // Çıkış yapma fonksiyonunu çağır
              onTap: () async {
                await authService.signOut();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// YARDIMCI WIDGET: PROFİL MENÜ SATIRI
class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? badge;
  final bool isDanger;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.icon,
    required this.title,
    this.badge,
    this.isDanger = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDanger ? Colors.redAccent : Colors.blueAccent;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(color: isDanger ? color : Colors.white)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badge != null && badge != '0')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
