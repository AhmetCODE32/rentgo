import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_state.dart';
import 'home_screen.dart';
import 'add_vehicle_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  // EKRANLARI GÖSTERMEK İÇİN KULLANILACAK WIDGET LİSTESİ
  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    AddVehicleScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Merkezi AppState'den sayfa indeksini dinle
    final appState = context.watch<AppState>();

    return Scaffold(
      body: IndexedStack(
        index: appState.pageIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: appState.pageIndex,
        // Butona basıldığında AppState'i güncelle
        onTap: (index) => context.read<AppState>().setPageIndex(index),
        backgroundColor: const Color(0xFF020617),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'Araçlar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Ekle',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
