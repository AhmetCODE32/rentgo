import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentgo/core/constants.dart';
import 'package:rentgo/core/firestore_service.dart';
import 'package:rentgo/models/vehicle.dart';
import 'package:rentgo/screens/vehicle_detail_screen.dart';
import 'package:rentgo/widgets/vehicle_card.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animate_do/animate_do.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'Hepsi';
  String _selectedCity = 'Tüm Türkiye';
  String _sortBy = 'En Yeni';

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    final firestoreService = FirestoreService();
    
    return Scaffold(
      backgroundColor: Colors.black, // Luxury Dark Background
      body: SafeArea(
        child: Column(
          children: [
            if (user != null) 
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: firestoreService.getUserProfileStream(user.uid),
                builder: (context, snapshot) {
                  final userData = snapshot.data?.data();
                  return _buildHeader(userData);
                },
              )
            else
              _buildHeader(null),

            _buildSearchRow(),
            _buildCategories(),
            
            Expanded(
              child: StreamBuilder<QuerySnapshot<Vehicle>>(
                stream: firestoreService.getVehiclesStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return const Center(child: Text('Bir hata oluştu.', style: TextStyle(color: Colors.white24)));
                  if (snapshot.connectionState == ConnectionState.waiting) return _buildLoadingList();

                  final allVehicles = snapshot.data!.docs.map((d) => d.data()).toList();
                  
                  List<Vehicle> filtered = allVehicles.where((v) {
                    final matchesSearch = v.title.toLowerCase().contains(_searchQuery.toLowerCase());
                    final matchesCategory = _selectedCategory == 'Hepsi' || v.category == _selectedCategory;
                    final matchesCity = _selectedCity == 'Tüm Türkiye' || v.city == _selectedCity;
                    return matchesSearch && matchesCategory && matchesCity;
                  }).toList();

                  final boostedVehicles = filtered.where((v) => v.isBoosted).toList();
                  final normalVehicles = filtered.where((v) => !v.isBoosted).toList();

                  return CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      if (boostedVehicles.isNotEmpty && _searchQuery.isEmpty)
                        SliverToBoxAdapter(
                          child: FadeInDown(
                            child: _buildFeaturedSection(boostedVehicles),
                          ),
                        ),

                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                        sliver: SliverToBoxAdapter(
                          child: Text(
                            boostedVehicles.isNotEmpty ? 'Diğer İlanlar' : 'Tüm İlanlar', 
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5)
                          ),
                        ),
                      ),

                      if (filtered.isEmpty) 
                        SliverFillRemaining(child: _buildEmptyState())
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              child: VehicleCard(vehicle: normalVehicles[index]),
                            ),
                            childCount: normalVehicles.length,
                          ),
                        ),
                      const SliverToBoxAdapter(child: SizedBox(height: 100)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic>? userData) {
    final String displayName = userData?['displayName'] ?? 'Sürücü';
    final String? photoURL = userData?['photoURL'];
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
                      const Icon(Icons.location_on, color: Colors.white54, size: 14),
                      const SizedBox(width: 4),
                      Text(_selectedCity, style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.w600, fontSize: 13)),
                      const Icon(Icons.keyboard_arrow_down, color: Colors.white54, size: 14),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text('Selam, ${displayName.split(' ').first} 👋', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white10)),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFF111111),
              backgroundImage: photoURL != null ? NetworkImage(photoURL) : null,
              child: photoURL == null ? const Icon(Icons.person, color: Colors.white24) : null,
            ),
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
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A), 
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Hangi aracı arıyorsun?',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                  prefixIcon: const Icon(Icons.search, color: Colors.white24, size: 20),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _showSortPicker,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A), 
                borderRadius: BorderRadius.circular(16), 
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: const Icon(Icons.swap_vert_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    final categories = ['Hepsi', 'Araba', 'Motor', 'Karavan', 'Bisiklet', 'Scooter', 'Ticari'];
    final icons = [Icons.grid_view_rounded, Icons.directions_car_rounded, Icons.motorcycle_rounded, Icons.rv_hookup_rounded, Icons.pedal_bike_rounded, Icons.electric_scooter_rounded, Icons.local_shipping_rounded];
    return SizedBox(height: 50, child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: categories.length, itemBuilder: (context, index) => _buildCategoryItem(categories[index], icons[index])));
  }

  Widget _buildCategoryItem(String title, IconData icon) {
    final isSelected = _selectedCategory == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFF0A0A0A), 
          borderRadius: BorderRadius.circular(14), 
          border: Border.all(color: isSelected ? Colors.white : Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.black : Colors.white24), 
            const SizedBox(width: 8), 
            Text(title, style: TextStyle(color: isSelected ? Colors.black : Colors.white70, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5))
          ]
        ),
      ),
    );
  }

  Widget _buildFeaturedSection(List<Vehicle> boostedVehicles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.star_rounded, color: Colors.amber, size: 18),
              SizedBox(width: 8),
              Text('ÖNERİLENLER', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 11)),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: boostedVehicles.length,
            itemBuilder: (context, index) {
              return _FeaturedCard(vehicle: boostedVehicles[index]);
            },
          ),
        ),
      ],
    );
  }

  void _showSortPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A0A0A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        final options = ['En Yeni', 'Fiyat (Artan)', 'Fiyat (Azalan)', 'Yıl (En Yeni)'];
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(padding: EdgeInsets.all(20), child: Text('Sıralama', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))),
            const Divider(color: Colors.white10),
            ...options.map((opt) => ListTile(
              title: Text(opt, style: TextStyle(color: _sortBy == opt ? Colors.white : Colors.white24, fontWeight: _sortBy == opt ? FontWeight.bold : FontWeight.normal)), 
              trailing: _sortBy == opt ? const Icon(Icons.check, color: Colors.white) : null, 
              onTap: () { setState(() => _sortBy = opt); Navigator.pop(context); }
            )),
            const SizedBox(height: 30),
          ],
        );
      },
    );
  }

  void _showCityPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A0A0A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        final allCities = ['Tüm Türkiye', ...AppConstants.turkiyeSehirleri];
        return Column(children: [
          const Padding(padding: EdgeInsets.all(20), child: Text('Şehir Seçin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))), 
          const Divider(color: Colors.white10), 
          Expanded(child: ListView.builder(itemCount: allCities.length, itemBuilder: (context, index) { 
            final city = allCities[index]; 
            return ListTile(
              title: Text(city, style: TextStyle(color: _selectedCity == city ? Colors.white : Colors.white24, fontWeight: _selectedCity == city ? FontWeight.bold : FontWeight.normal)), 
              trailing: _selectedCity == city ? const Icon(Icons.check, color: Colors.white) : null, 
              onTap: () { setState(() => _selectedCity = city); Navigator.pop(context); }
            ); 
          }))
        ]);
      },
    );
  }

  Widget _buildLoadingList() => Shimmer.fromColors(baseColor: Colors.white.withOpacity(0.05), highlightColor: Colors.white.withOpacity(0.1), child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 20), itemCount: 3, itemBuilder: (context, index) => Container(height: 220, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)))));
  Widget _buildEmptyState() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.search_off_rounded, size: 80, color: Colors.white.withOpacity(0.05)), const SizedBox(height: 16), const Text('Aradığın araç bulunamadı.', style: TextStyle(color: Colors.white24, fontSize: 16))]));
}

class _FeaturedCard extends StatelessWidget {
  final Vehicle vehicle;
  const _FeaturedCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VehicleDetailScreen(vehicle: vehicle))),
      child: Container(
        width: 300,
        margin: const EdgeInsets.only(right: 16, left: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          image: DecorationImage(
            image: NetworkImage(vehicle.images.isNotEmpty ? vehicle.images[0] : 'https://via.placeholder.com/300'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.9)]),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(10)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt, size: 14, color: Colors.black),
                    SizedBox(width: 4),
                    Text('ÖNERİLEN', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(vehicle.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5), maxLines: 1, overflow: TextOverflow.ellipsis),
              Row(
                children: [
                  Text('₺${vehicle.price.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const Text(' / gün', style: TextStyle(color: Colors.white24, fontSize: 12)),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white24),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
