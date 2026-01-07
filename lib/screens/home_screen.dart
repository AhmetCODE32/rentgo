import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../core/app_state.dart';
import '../widgets/vehicle_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>();
    _searchController = TextEditingController(text: appState.searchTerm);
    _searchController.addListener(() {
      appState.setSearchTerm(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('RentGo', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hayalindeki Aracı Bul', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('Kilis & Gaziantep bölgesinde kirala veya satın al', style: textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(hintText: 'Marka veya model ara...', prefixIcon: Icon(Icons.search)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _CategoryChip(icon: Icons.directions_car, label: 'Arabalar', selected: appState.showCars, onTap: () => appState.setShowCars(true)),
                const SizedBox(width: 10),
                _CategoryChip(icon: Icons.motorcycle, label: 'Motorlar', selected: !appState.showCars, onTap: () => appState.setShowCars(false)),
                const Spacer(),
                _CityDropdown(value: appState.city, onChanged: (v) => appState.setCity(v!)),
              ],
            ),
          ),

          // LİSTE (SHIMMER EFEKTİ İLE)
          Expanded(
            child: Consumer<AppState>(
              builder: (context, appState, child) {
                // Yükleniyorsa Shimmer göster
                if (appState.isLoading) {
                  return Shimmer.fromColors(
                    baseColor: Theme.of(context).colorScheme.surface,
                    highlightColor: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: 5, // Yer tutucu öğe sayısı
                      itemBuilder: (context, i) => const _VehicleCardPlaceholder(),
                    ),
                  );
                }

                // Veri geldiyse veya boşsa listeyi göster
                final vehicles = appState.filteredVehicles;
                if (vehicles.isEmpty) {
                  return Center(
                      child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text('Bu kriterlere uygun ilan bulunamadı.', textAlign: TextAlign.center, style: textTheme.bodyLarge?.copyWith(color: Colors.grey)),
                  ));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: vehicles.length,
                  itemBuilder: (context, i) => VehicleCard(vehicle: vehicles[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// YER TUTUCU KART (SHIMMER İÇİN)
class _VehicleCardPlaceholder extends StatelessWidget {
  const _VehicleCardPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(width: 56, height: 56, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: double.infinity, height: 20, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(width: 100, height: 14, color: Colors.white),
                ],
              ),
            ),
            Container(width: 60, height: 20, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final IconData icon; final String label; final bool selected; final VoidCallback onTap;
  const _CategoryChip({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primary : colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? colorScheme.primary : Colors.white24, width: 1),
        ),
        child: Row(children: [Icon(icon, size: 18, color: selected ? Colors.white : colorScheme.primary), const SizedBox(width: 8), Text(label, style: TextStyle(color: Colors.white, fontWeight: selected ? FontWeight.bold : FontWeight.normal))]),
      ),
    );
  }
}

class _CityDropdown extends StatelessWidget {
  final String value; final ValueChanged<String?> onChanged;
  const _CityDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: value,
      dropdownColor: Theme.of(context).colorScheme.surface,
      underline: const SizedBox(),
      icon: Icon(Icons.location_on_outlined, color: Theme.of(context).colorScheme.primary),
      items: const ['Tümü', 'Kilis', 'Gaziantep'].map((city) => DropdownMenuItem(value: city, child: Text(city))).toList(),
      onChanged: onChanged,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}
