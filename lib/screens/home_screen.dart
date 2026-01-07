import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_state.dart';
import '../models/vehicle.dart';
import '../widgets/vehicle_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  bool showCars = true;

  @override
  void initState() {
    super.initState();
    // Arama alanındaki her değişikliği dinle ve arayüzü güncelle
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RentGo')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HERO
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0), // Alt padding kaldırıldı
            color: const Color(0xFF020617),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Araç Kirala / Satın Al',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Kilis & Gaziantep',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                // ARAMA ALANI
                _SearchInput(
                  controller: _searchController,
                  hint: 'Marka veya model ara...',
                ),
              ],
            ),
          ),

          // KATEGORİ + ŞEHİR
          Consumer<AppState>(
            builder: (context, appState, child) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    _CategoryChip(
                      icon: Icons.directions_car,
                      label: 'Arabalar',
                      selected: showCars,
                      onTap: () => setState(() => showCars = true),
                    ),
                    const SizedBox(width: 10),
                    _CategoryChip(
                      icon: Icons.motorcycle,
                      label: 'Motorlar',
                      selected: !showCars,
                      onTap: () => setState(() => showCars = false),
                    ),
                    const Spacer(),
                    _CityDropdown(
                      value: appState.city,
                      onChanged: (v) => appState.setCity(v),
                    ),
                  ],
                ),
              );
            },
          ),

          // LİSTE
          Expanded(
            child: Consumer<AppState>(
              builder: (context, appState, child) {
                final searchTerm = _searchController.text.toLowerCase();
                final vehicles = appState.allVehicles.where((v) {
                  final typeMatch = v.isCar == showCars;
                  final cityMatch = appState.city == 'Tümü' || v.city == appState.city;
                  final searchMatch = searchTerm.isEmpty || v.title.toLowerCase().contains(searchTerm);
                  return typeMatch && cityMatch && searchMatch;
                }).toList();

                // Eğer filtrelenen araç listesi boş ise mesaj göster
                if (vehicles.isEmpty) {
                  return const Center(
                    child: Text(
                      'Bu kriterlere uygun ilan bulunamadı.',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: vehicles.length,
                  itemBuilder: (context, i) {
                    return VehicleCard(vehicle: vehicles[i]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- WIDGETS ----------

// ARAMA GİRİŞİ
class _SearchInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const _SearchInput({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
        filled: true,
        fillColor: const Color(0xFF0F172A), // Arka plan rengiyle aynı
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? Colors.blueAccent
              : Colors.blueAccent.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : Colors.blueAccent,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CityDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _CityDropdown({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: value,
      dropdownColor: const Color(0xFF020617),
      underline: const SizedBox(),
      icon: const Icon(Icons.location_on, color: Colors.blueAccent),
      items: const [
        DropdownMenuItem(value: 'Tümü', child: Text('Tümü')),
        DropdownMenuItem(value: 'Kilis', child: Text('Kilis')),
        DropdownMenuItem(value: 'Gaziantep', child: Text('Gaziantep')),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
