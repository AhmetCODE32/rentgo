import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentgo/core/firestore_service.dart';
import '../core/app_state.dart';
import 'home_screen.dart';
import 'add_vehicle_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

// WidgetsBindingObserver ile uygulamanın ön planda mı arka planda mı olduğunu anlıyoruz
class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  final FirestoreService _firestoreService = FirestoreService();

  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setStatus(true); // Uygulama açıldığında Online yap
  }

  @override
  void dispose() {
    _setStatus(false); // Uygulama tamamen kapanırken Offline yap (Mümkünse)
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Uygulama durumu değiştikçe Online/Offline durumunu güncelle
    if (state == AppLifecycleState.resumed) {
      _setStatus(true);
    } else {
      _setStatus(false);
    }
  }

  void _setStatus(bool isOnline) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _firestoreService.updateUserStatus(user.uid, isOnline);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      body: IndexedStack(
        index: appState.pageIndex,
        children: _widgetOptions,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddVehicleScreen()),
          );
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
        shape: const CircleBorder(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: const Color(0xFF020617),
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _buildNavItem(context, icon: Icons.directions_car, label: 'Araçlar', index: 0),
              const SizedBox(width: 48),
              _buildNavItem(context, icon: Icons.person, label: 'Profil', index: 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, {required IconData icon, required String label, required int index}) {
    final appState = context.watch<AppState>();
    final isSelected = appState.pageIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => context.read<AppState>().setPageIndex(index),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.blueAccent : Colors.grey),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: isSelected ? Colors.blueAccent : Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
