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
  // State Değişkenleri
  ListingType _listingType = ListingType.rent;
  bool _isCar = true;
  String _selectedCity = 'Kilis';
  bool _isLoading = false;
  String _loadingText = '';

  // Controller'lar
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _yearController = TextEditingController();
  final _transmissionController = TextEditingController();
  final _fuelController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final List<File> _images = [];
  final StorageService _storageService = StorageService();

  Future<void> _addVehicle() async {
    final user = Provider.of<User?>(context, listen: false);
    if (user == null) {
      _showError('İlan eklemek için giriş yapmalısınız.');
      return;
    }

    if (_images.isEmpty || _titleController.text.isEmpty || _priceController.text.isEmpty || _phoneController.text.isEmpty || _addressController.text.isEmpty) {
      _showError('Lütfen tüm zorunlu alanları ve en az bir fotoğrafı doldurun.');
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingText = 'Resimler yükleniyor...';
    });

    try {
      List<String> imageUrls = [];
      for (int i = 0; i < _images.length; i++) {
        setState(() => _loadingText = '${i + 1}/${_images.length} resim yükleniyor...');
        final imageUrl = await _storageService.uploadImage(_images[i]);
        imageUrls.add(imageUrl);
      }

      setState(() => _loadingText = 'İlan oluşturuluyor...');

      final newVehicle = Vehicle(
        userId: user.uid,
        sellerName: user.displayName ?? user.email ?? 'Bilinmeyen Satıcı',
        phoneNumber: _phoneController.text,
        title: _titleController.text,
        description: _descriptionController.text,
        city: _selectedCity,
        pickupAddress: _addressController.text,
        price: double.tryParse(_priceController.text) ?? 0,
        isCar: _isCar,
        listingType: _listingType,
        images: imageUrls,
        specs: {
          'year': _yearController.text,
          'transmission': _transmissionController.text,
          'fuel': _fuelController.text,
        },
      );

      await context.read<AppState>().addVehicle(newVehicle);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İlanınız başarıyla yayınlandı!')));
        Navigator.pop(context);
      }
    } catch (e) {
      _showError('İlan yayınlanamadı: ${e.toString()}');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _loadingText = '';
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 50, maxWidth: 1080);
    if (picked.isNotEmpty) {
      setState(() {
        if (_images.length + picked.length <= 5) {
          _images.addAll(picked.map((e) => File(e.path)));
        } else {
          _showError('En fazla 5 fotoğraf ekleyebilirsiniz.');
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _yearController.dispose();
    _transmissionController.dispose();
    _fuelController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('İlan Ver')),
      body: AbsorbPointer(
        absorbing: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // EKLENDİ: Araç Tipi Seçimi
              Row(
                children: [
                  Expanded(child: _TypeCard(label: 'Araba', icon: Icons.directions_car, selected: _isCar, onTap: () => setState(() => _isCar = true))),
                  const SizedBox(width: 16),
                  Expanded(child: _TypeCard(label: 'Motor', icon: Icons.motorcycle, selected: !_isCar, onTap: () => setState(() => _isCar = false))),
                ],
              ),
              const SizedBox(height: 24),
              // EKLENDİ: Fotoğraflar
              const Text('Fotoğraflar (En fazla 5)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (_images.isNotEmpty) SizedBox(height: 110, child: _buildImageListView()),
              const SizedBox(height: 8),
              if (_images.length < 5) _buildImagePicker(),
              
              const SizedBox(height: 24),
              _SectionTitle(text: 'İlan Bilgileri'),
              SwitchListTile(title: Text(_listingType == ListingType.rent ? 'Kiralık İlanı' : 'Satılık İlanı'), value: _listingType == ListingType.sale, onChanged: (val) => setState(() => _listingType = val ? ListingType.sale : ListingType.rent)),
              _Input(controller: _titleController, hint: 'İlan Başlığı (Örn: BMW 320i)', icon: Icons.title),
              const SizedBox(height: 16),
              _Input(controller: _priceController, hint: _listingType == ListingType.rent ? 'Günlük Fiyat (₺)' : 'Satış Fiyatı (₺)', icon: Icons.sell_outlined, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
              const SizedBox(height: 16),
              _Input(controller: _descriptionController, hint: 'Açıklama', icon: Icons.description_outlined, maxLines: 4),
              
              const SizedBox(height: 24),
              _SectionTitle(text: 'Teslimat & İletişim'),
              _buildCityDropdown(),
              const SizedBox(height: 16),
              _Input(controller: _addressController, hint: 'Teslimat Adresi (Mahalle, Sokak vb.)', icon: Icons.location_on_outlined, maxLines: 2),
              const SizedBox(height: 16),
              _Input(controller: _phoneController, hint: 'Telefon Numarası', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),

              const SizedBox(height: 24),
              _SectionTitle(text: 'Araç Özellikleri (İsteğe Bağlı)'),
              Row(children: [Expanded(child: _Input(controller: _yearController, hint: 'Yıl', icon: Icons.calendar_today_outlined, keyboardType: TextInputType.number)), const SizedBox(width: 16), Expanded(child: _Input(controller: _transmissionController, hint: 'Vites', icon: Icons.settings_input_svideo_outlined))]),
              const SizedBox(height: 16),
              _Input(controller: _fuelController, hint: 'Yakıt Tipi', icon: Icons.local_gas_station_outlined),

              const SizedBox(height: 40),
              SizedBox(
                height: 54,
                child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), onPressed: _isLoading ? null : _addVehicle, child: _isLoading ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [const CircularProgressIndicator(color: Colors.white), const SizedBox(width: 16), Text(_loadingText)]) : const Text('İlanı Yayınla', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageListView() => ListView.builder(scrollDirection: Axis.horizontal, itemCount: _images.length, itemBuilder: (context, index) => Stack(children: [Container(width: 100, height: 100, margin: const EdgeInsets.only(right: 12, top: 8), decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), image: DecorationImage(image: FileImage(_images[index]), fit: BoxFit.cover))), Positioned(top: 0, right: 4, child: GestureDetector(onTap: () => setState(() => _images.removeAt(index)), child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.close, size: 14, color: Colors.white))))]));
  Widget _buildImagePicker() => InkWell(onTap: _pickImages, child: Container(width: double.infinity, padding: const EdgeInsets.all(30), decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blueAccent.withOpacity(0.5), style: BorderStyle.solid)), child: const Column(children: [Icon(Icons.add_a_photo, color: Colors.blueAccent, size: 32), SizedBox(height: 8), Text('Fotoğraf Ekle', style: TextStyle(color: Colors.blueAccent))])));
  Widget _buildCityDropdown() => Container(padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(color: const Color(0xFF020617), borderRadius: BorderRadius.circular(12)), child: DropdownButton<String>(value: _selectedCity, isExpanded: true, underline: const SizedBox(), dropdownColor: const Color(0xFF020617), items: ['Kilis', 'Gaziantep'].map((city) => DropdownMenuItem(value: city, child: Text(city))).toList(), onChanged: (val) => setState(() => _selectedCity = val!)));
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle({required this.text});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(top: 8, bottom: 12), child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)));
}

class _TypeCard extends StatelessWidget {
  final String label; final IconData icon; final bool selected; final VoidCallback onTap;
  const _TypeCard({required this.label, required this.icon, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(vertical: 16), decoration: BoxDecoration(color: selected ? Colors.blueAccent : const Color(0xFF020617), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blueAccent, width: 2), boxShadow: selected ? [BoxShadow(color: Colors.blueAccent.withOpacity(0.5), blurRadius: 10, spreadRadius: 1)] : []), child: Column(children: [Icon(icon, color: Colors.white, size: 28), const SizedBox(height: 8), Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))])));
}

class _Input extends StatelessWidget {
  final TextEditingController controller; final String hint; final IconData icon; final int maxLines; final TextInputType keyboardType; final List<TextInputFormatter>? inputFormatters;
  const _Input({required this.controller, required this.hint, required this.icon, this.maxLines = 1, this.keyboardType = TextInputType.text, this.inputFormatters});
  @override
  Widget build(BuildContext context) => TextField(controller: controller, maxLines: maxLines, keyboardType: keyboardType, inputFormatters: inputFormatters, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon, color: Colors.blueAccent), filled: true, fillColor: const Color(0xFF020617), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)));
}
