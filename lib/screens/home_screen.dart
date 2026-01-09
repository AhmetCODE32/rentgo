import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentgo/core/constants.dart';
import 'package:rentgo/core/firestore_service.dart';
import 'package:rentgo/models/vehicle.dart';
import 'package:rentgo/widgets/vehicle_card.dart';
import 'package:shimmer/shimmer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'Hepsi';
  String _selectedCity = 'Tüm Türkiye';
  String _sortBy = 'En Yeni'; // VARSAYILAN SIRALAMA

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    final firestoreService = FirestoreService();
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(user),
            _buildSearchRow(), // ARAMA VE SIRALAMA YAN YANA
            _buildCategories(),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Vehicle>>(
                stream: firestoreService.getVehiclesStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return const Center(child: Text('Bir hata oluştu.'));
                  if (snapshot.connectionState == ConnectionState.waiting) return _buildLoadingList();

                  final allVehicles = snapshot.data!.docs.map((d) => d.data()).toList();
                  
                  // 1. FİLTRELEME MANTIĞI
                  List<Vehicle> filteredVehicles = allVehicles.where((v) {
                    final matchesSearch = v.title.toLowerCase().contains(_searchQuery.toLowerCase());
                    final matchesCategory = _selectedCategory == 'Hepsi' || v.category == _selectedCategory;
                    final matchesCity = _selectedCity == 'Tüm Türkiye' || v.city == _selectedCity;
                    return matchesSearch && matchesCategory && matchesCity;
                  }).toList();

                  // 2. SIRALAMA MANTIĞI (YENİ)
                  if (_sortBy == 'Fiyat (Artan)') {
                    filteredVehicles.sort((a, b) => a.price.compareTo(b.price));
                  } else if (_sortBy == 'Fiyat (Azalan)') {
                    filteredVehicles.sort((a, b) => b.price.compareTo(a.price));
                  } else if (_sortBy == 'Yıl (En Yeni)') {
                    filteredVehicles.sort((a, b) => (b.specs['year'] ?? '').compareTo(a.specs['year'] ?? ''));
                  }

                  if (filteredVehicles.isEmpty) return _buildEmptyState();

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filteredVehicles.length,
                    itemBuilder: (context, index) => VehicleCard(vehicle: filteredVehicles[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(User? user) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _showCityPicker,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on, color: Colors.blueAccent, size: 16),
                      const SizedBox(width: 4),
                      Text(_selectedCity, style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                      const Icon(Icons.keyboard_arrow_down, color: Colors.blueAccent, size: 16),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user != null ? 'Selam, ${user.displayName?.split(' ').first ?? 'Sürücü'} 👋' : 'Hoş Geldin!',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.blueAccent.withAlpha(30),
            backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
            child: user?.photoURL == null ? const Icon(Icons.person, color: Colors.blueAccent) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Row(
        children: [
          // ARAMA ÇUBUĞU
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Ara...',
                  hintStyle: TextStyle(color: Colors.white.withAlpha(80)),
                  prefixIcon: const Icon(Icons.search, color: Colors.blueAccent, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // SIRALAMA BUTONU
          GestureDetector(
            onTap: _showSortPicker,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withAlpha(30),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blueAccent.withAlpha(50)),
              ),
              child: const Icon(Icons.swap_vert_rounded, color: Colors.blueAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    final categories = ['Hepsi', 'Araba', 'Motor', 'Karavan', 'Bisiklet', 'Scooter', 'Ticari'];
    final icons = [Icons.grid_view_rounded, Icons.directions_car_rounded, Icons.motorcycle_rounded, Icons.rv_hookup_rounded, Icons.pedal_bike_rounded, Icons.electric_scooter_rounded, Icons.local_shipping_rounded];

    return Column(
      children: [
        SizedBox(
          height: 45,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (context, index) => _buildCategoryItem(categories[index], icons[index]),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  void _showSortPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        final options = ['En Yeni', 'Fiyat (Artan)', 'Fiyat (Azalan)', 'Yıl (En Yeni)'];
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(padding: EdgeInsets.all(16), child: Text('Sıralama', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))),
            const Divider(color: Colors.white10),
            ...options.map((opt) => ListTile(
              title: Text(opt, style: TextStyle(color: _sortBy == opt ? Colors.blueAccent : Colors.white)),
              trailing: _sortBy == opt ? const Icon(Icons.check, color: Colors.blueAccent) : null,
              onTap: () {
                setState(() => _sortBy = opt);
                Navigator.pop(context);
              },
            )),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _buildCategoryItem(String title, IconData icon) {
    final isSelected = _selectedCategory == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = title),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: isSelected ? Colors.blueAccent : Colors.white10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.blueAccent),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showCityPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        final allCities = ['Tüm Türkiye', ...AppConstants.turkiyeSehirleri];
        return Column(
          children: [
            const Padding(padding: EdgeInsets.all(16), child: Text('Şehir Seçin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))),
            const Divider(color: Colors.white10),
            Expanded(
              child: ListView.builder(
                itemCount: allCities.length,
                itemBuilder: (context, index) {
                  final city = allCities[index];
                  return ListTile(
                    title: Text(city, style: TextStyle(color: _selectedCity == city ? Colors.blueAccent : Colors.white)),
                    trailing: _selectedCity == city ? const Icon(Icons.check, color: Colors.blueAccent) : null,
                    onTap: () {
                      setState(() => _selectedCity = city);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoadingList() {
    return Shimmer.fromColors(
      baseColor: Colors.white10,
      highlightColor: Colors.white24,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 3,
        itemBuilder: (context, index) => Container(
          height: 220,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.white.withAlpha(20)),
          const SizedBox(height: 16),
          const Text('Aradığın araç bulunamadı.', style: TextStyle(color: Colors.white70, fontSize: 16)),
        ],
      ),
    );
  }
}
