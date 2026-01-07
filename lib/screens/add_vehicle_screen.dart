import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:rentgo/core/storage_service.dart';
import '../core/app_state.dart';
import '../models/vehicle.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  bool isCar = true;
  String selectedCity = 'Kilis';
  bool _isLoading = false;
  String _loadingText = '';

  final titleController = TextEditingController();
  final priceController = TextEditingController();

  final ImagePicker picker = ImagePicker();
  final List<File> images = [];
  final StorageService _storageService = StorageService();

  Future<void> _addVehicle() async {
    final user = Provider.of<User?>(context, listen: false);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İlan eklemek için giriş yapmalısınız.')),
      );
      return;
    }

    if (images.isEmpty || titleController.text.isEmpty || priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları ve en az bir fotoğrafı doldurun.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingText = 'Resimler yükleniyor...';
    });

    try {
      List<String> imageUrls = [];
      for (int i = 0; i < images.length; i++) {
        setState(() {
          _loadingText = '${i + 1}/${images.length} resim yükleniyor...';
        });
        final imageUrl = await _storageService.uploadImage(images[i]);
        imageUrls.add(imageUrl);
      }

      setState(() => _loadingText = 'İlan oluşturuluyor...');

      final newVehicle = Vehicle(
        userId: user.uid,
        title: titleController.text,
        city: selectedCity,
        price: "${priceController.text}₺ / gün",
        isCar: isCar,
        images: imageUrls,
      );

      await context.read<AppState>().addVehicle(newVehicle);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İlanınız başarıyla yayınlandı!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İlan yayınlanamadı: ${e.toString()}')),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _loadingText = '';
      });
    }
  }

  // RESİM SEÇME OPTİMİZASYONU
  Future<void> pickImages() async {
    final picked = await picker.pickMultiImage(
      imageQuality: 80, // Kaliteyi %80'e ayarla
      maxWidth: 1080,   // Maksimum genişliği 1080px yap
    );

    if (picked.isNotEmpty) {
      setState(() {
        if (images.length + picked.length <= 5) {
          images.addAll(picked.map((e) => File(e.path)));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('En fazla 5 fotoğraf ekleyebilirsiniz.')),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İlan Ver'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             // ... (diğer widget'lar aynı kaldı) ...
            Row(
              children: [
                Expanded(
                  child: _TypeCard(
                    label: 'Araba',
                    icon: Icons.directions_car,
                    selected: isCar,
                    onTap: () => setState(() => isCar = true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _TypeCard(
                    label: 'Motor',
                    icon: Icons.motorcycle,
                    selected: !isCar,
                    onTap: () => setState(() => isCar = false),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            const Text(
              'Fotoğraflar (En fazla 5)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (images.isNotEmpty)
              SizedBox(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          margin: const EdgeInsets.only(right: 12, top: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: FileImage(images[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                images.removeAt(index);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

            const SizedBox(height: 8),

            if (images.length < 5)
              InkWell(
                onTap: pickImages,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.blueAccent.withOpacity(0.5),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.add_a_photo, color: Colors.blueAccent, size: 32),
                      SizedBox(height: 8),
                      Text('Fotoğraf Ekle', style: TextStyle(color: Colors.blueAccent)),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            const Text('Şehir', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF020617),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButton<String>(
                value: selectedCity,
                isExpanded: true,
                underline: const SizedBox(),
                dropdownColor: const Color(0xFF020617),
                items: ['Kilis', 'Gaziantep'].map((city) {
                  return DropdownMenuItem(value: city, child: Text(city));
                }).toList(),
                onChanged: (val) => setState(() => selectedCity = val!),
              ),
            ),

            const SizedBox(height: 24),

            _Input(
              controller: titleController,
              hint: isCar ? 'Marka / Model (Örn: BMW 320i)' : 'Marka / Model (Örn: Yamaha R25)',
              icon: Icons.title,
            ),
            const SizedBox(height: 16),
            _Input(
              controller: priceController,
              hint: 'Fiyat (Örn: 1200)',
              icon: Icons.sell,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _isLoading ? null : _addVehicle,
                child: _isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(color: Colors.white),
                          const SizedBox(width: 16),
                          Text(_loadingText, style: const TextStyle(color: Colors.white, fontSize: 16)),
                        ],
                      )
                    : const Text('İlanı Yayınla', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
            color: selected ? Colors.blueAccent : const Color(0xFF020617),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blueAccent, width: 2),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 1,
                    )
                  ]
                : []), // Gölge efekti
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final IconData icon;
  final List<TextInputFormatter>? inputFormatters;

  const _Input({
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    required this.icon,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        filled: true,
        fillColor: const Color(0xFF020617),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.white10),
        ),
      ),
    );
  }
}
