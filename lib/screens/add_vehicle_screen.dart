import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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

  Future<void> pickImages() async {
    final picked = await picker.pickMultiImage(imageQuality: 70);

    if (picked.isNotEmpty) {
      setState(() {
        images.addAll(
          picked.take(5).map((e) => File(e.path)),
        );
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
        title: const Text('Araç Ekle'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            /// FOTO BÖLÜMÜ
            GestureDetector(
              onTap: pickImages,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF2563EB),
                      const Color(0xFF020617),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: images.isEmpty
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.add_photo_alternate,
                        size: 48, color: Colors.white),
                    SizedBox(height: 8),
                    Text(
                      'Araç Fotoğrafları Ekle (max 5)',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                )
                    : ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.all(12),
                    itemBuilder: (_, i) => Image.file(
                      images[i],
                      width: 160,
                      fit: BoxFit.cover,
                    ),
                    separatorBuilder: (_, __) =>
                    const SizedBox(width: 12),
                    itemCount: images.length,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            /// ARAÇ TÜRÜ
            _Section(
              title: 'Araç Türü',
              child: Row(
                children: [
                  _TypeButton(
                    icon: Icons.directions_car,
                    label: 'Araba',
                    selected: isCar,
                    onTap: () => setState(() => isCar = true),
                  ),
                  const SizedBox(width: 12),
                  _TypeButton(
                    icon: Icons.motorcycle,
                    label: 'Motor',
                    selected: !isCar,
                    onTap: () => setState(() => isCar = false),
                  ),
                ],
              ),
            ),

            /// ARAÇ BİLGİLERİ
            _Section(
              title: 'Araç Bilgileri',
              child: Column(
                children: [
                  _Input(
                    controller: titleController,
                    hint: 'BMW 320i',
                    icon: Icons.directions_car,
                  ),
                  const SizedBox(height: 14),
                  _Input(
                    controller: priceController,
                    hint: '1200 ₺ / gün',
                    keyboardType: TextInputType.number,
                    icon: Icons.payments,
                  ),
                ],
              ),
            ),

            /// ŞEHİR
            _Section(
              title: 'Şehir',
              child: DropdownButtonFormField<String>(
                value: selectedCity,
                items: const [
                  DropdownMenuItem(value: 'Kilis', child: Text('Kilis')),
                  DropdownMenuItem(
                      value: 'Gaziantep', child: Text('Gaziantep')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => selectedCity = v);
                },
                decoration: _inputDecoration(),
                dropdownColor: const Color(0xFF020617),
              ),
            ),

            const SizedBox(height: 36),

            /// KAYDET BUTONU
            Container(
              height: 56,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF2563EB),
                    Color(0xFF1E40AF),
                  ],
                ),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
                onPressed: () {
                  if (images.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('En az 1 fotoğraf ekleyin')),
                    );
                    return;
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Araç başarıyla eklendi')),
                  );
                },
                child: const Text(
                  'Kaydet',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------- COMPONENTS ----------

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF020617),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? Colors.blueAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blueAccent),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(height: 6),
              Text(label),
            ],
          ),
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
      decoration: _inputDecoration(
        hint: hint,
        icon: icon,
      ),
    );
  }
}

InputDecoration _inputDecoration({String? hint, IconData? icon}) {
  return InputDecoration(
    hintText: hint,
    prefixIcon: icon != null ? Icon(icon) : null,
    filled: true,
    fillColor: const Color(0xFF020617),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
  );
}
