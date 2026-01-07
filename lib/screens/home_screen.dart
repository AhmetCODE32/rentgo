import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../widgets/vehicle_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool showCars = true;
  String selectedCity = 'Tümü';

  final List<Vehicle> allVehicles = [
    Vehicle(
      title: 'BMW 320i',
      city: 'Gaziantep',
      price: '1200₺ / gün',
      isCar: true,
    ),
    Vehicle(
      title: 'Mercedes C200',
      city: 'Gaziantep',
      price: '1500₺ / gün',
      isCar: true,
    ),
    Vehicle(
      title: 'Yamaha R25',
      city: 'Kilis',
      price: '600₺ / gün',
      isCar: false,
    ),
    Vehicle(
      title: 'Honda CBR',
      city: 'Kilis',
      price: '750₺ / gün',
      isCar: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final vehicles = allVehicles.where((v) {
      final typeMatch = v.isCar == showCars;
      final cityMatch =
          selectedCity == 'Tümü' || v.city == selectedCity;
      return typeMatch && cityMatch;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('RentGo')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HERO
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: const Color(0xFF020617),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Araç Kirala / Satın Al',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Kilis & Gaziantep',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),

          // KATEGORİ + ŞEHİR
          Padding(
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
                  value: selectedCity,
                  onChanged: (v) {
                    setState(() => selectedCity = v);
                  },
                ),
              ],
            ),
          ),

          // LİSTE
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vehicles.length,
              itemBuilder: (context, i) {
                return VehicleCard(vehicle: vehicles[i]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- WIDGETS ----------

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
              : Colors.blueAccent.withValues(alpha: 0.15), // Burayı değiştirdik
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
              style: TextStyle( // Buradaki const uyarısı verirse başına ekleyebilirsin
                color: Colors.white,
                fontWeight:
                selected ? FontWeight.bold : FontWeight.normal,
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
