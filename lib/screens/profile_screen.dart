import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentgo/core/auth_service.dart';
import 'package:rentgo/core/firestore_service.dart';
import 'package:rentgo/screens/edit_profile_screen.dart';
import '../core/app_state.dart';
import 'my_listings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Lütfen giriş yapın.')));
    }

    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: firestoreService.getUserProfileStream(user.uid),
        builder: (context, snapshot) {
          // Yükleniyor durumu
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          // KENDİNİ İYİLEŞTİRME MEKANİZMASI
          // Eğer veri yoksa (eski kullanıcı) ama kullanıcı giriş yapmışsa, profili o an oluştur.
          if (!snapshot.hasData || !snapshot.data!.exists) {
            firestoreService.createUserProfile(user);
            // Profil oluşturulurken kısa bir yükleme ekranı göster.
            // StreamBuilder, döküman oluşturulduğunda otomatik olarak yeniden tetiklenecektir.
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Bir hata oluştu.'));
          }

          final userData = snapshot.data!.data()!;
          final displayName = userData['displayName'] ?? 'Kullanıcı';
          final photoURL = userData['photoURL'];

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        backgroundImage: photoURL != null ? NetworkImage(photoURL) : null,
                        child: photoURL == null && displayName.isNotEmpty ? Text(displayName[0].toUpperCase(), style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)) : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(displayName, style: Theme.of(context).textTheme.titleLarge, overflow: TextOverflow.ellipsis),
                            Text(userData['email'] ?? '', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey), overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen(userData: userData))))
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Consumer<AppState>(
                  builder: (context, appState, child) {
                    final myListingCount = appState.allVehicles.where((v) => v.userId == user.uid).length;
                    return _ProfileTile(icon: Icons.directions_car_outlined, title: 'İlanlarım', badge: myListingCount.toString(), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyListingsScreen())));
                  },
                ),
                _ProfileTile(icon: Icons.logout, title: 'Çıkış Yap', isDanger: true, onTap: () => context.read<AuthService>().signOut()),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon; final String title; final String? badge; final bool isDanger; final VoidCallback onTap;
  const _ProfileTile({required this.icon, required this.title, this.badge, this.isDanger = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = isDanger ? Colors.redAccent : Theme.of(context).colorScheme.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(color: isDanger ? Colors.redAccent : null)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [if (badge != null && badge != '0') Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)), child: Text(badge!, style: const TextStyle(color: Colors.white, fontSize: 12))), const SizedBox(width: 8), const Icon(Icons.arrow_forward_ios, size: 16)]),
        onTap: onTap,
      ),
    );
  }
}
