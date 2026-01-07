import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
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

  final titleController = TextEditingController();
  final priceController = TextEditingController();

  final ImagePicker picker = ImagePicker();
  final List<File> images = [];

  // Fotoğraf Seçme Fonksiyonu
  Future<void> pickImages() async {
    final picked = await picker.pickMultiImage(imageQuality: 70);

    if (picked.isNotEmpty) {
      setState(() {
        // Toplamda en fazla 5 resim olmasına izin ver
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
            // ARAÇ TİPİ SEÇİMİ
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

            // FOTOĞRAF ALANI
            const Text(
              'Fotoğraflar (En fazla 5)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Seçilen Resimleri Yatayda Gösteren Liste
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
                              fit: BoxFit.cover, // Resmi kutuya tam yayar
                            ),
                          ),
                        ),
                        // SİLME BUTONU (Kırmızı Çarpı)
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

            // Fotoğraf Ekleme Butonu
            if (images.length < 5)
              InkWell(
                onTap: pickImages,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.blueAccent.withValues(alpha: 0.5),
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

            // ŞEHİR SEÇİMİ
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

            // BİLGİ GİRİŞLERİ
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
            ),

            const SizedBox(height: 40),

            // İLANI YAYINLA BUTONU
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  if (images.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lütfen en az bir fotoğraf ekleyin!')),
                    );
                    return;
                  }
                  
                  if (titleController.text.isEmpty || priceController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lütfen boş alan bırakmayın!')),
                    );
                    return;
                  }

                  // 1. Yeni Araç Nesnesi Oluştur
                  final newVehicle = Vehicle(
                    title: titleController.text,
                    city: selectedCity,
                    price: "${priceController.text}₺ / gün",
                    isCar: isCar,
                    images: images,
                  );

                  // 2. AppState (Provider) üzerinden listeye ekle
                  // Not: AppState içinde addVehicle metodunun olduğundan emin olun.
                  Provider.of<AppState>(context, listen: false).addVehicle(newVehicle);

                  // 3. Başarılı Mesajı ve Geri Dönüş
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('İlanınız başarıyla yayınlandı!')),
                  );

                  // Siyah ekranı önlemek için kontrol ederek geri dön
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
                child: const Text('İlanı Yayınla', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// YARDIMCI BİLEŞEN: ARAÇ TİPİ KARTI
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
        ),
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

// YARDIMCI BİLEŞEN: GİRİŞ ALANI (TEXTFIELD)
class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final IconData icon;

  const _Input({
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
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