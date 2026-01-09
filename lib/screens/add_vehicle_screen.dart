import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:rentgo/core/firestore_service.dart';
import 'package:rentgo/core/storage_service.dart';
import '../core/app_state.dart';
import '../models/vehicle.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();

  ListingType _listingType = ListingType.rent;
  String _selectedCategory = 'Araba'; 
  bool _isLoading = false;
  String _loadingText = '';

  String? _selectedYear;
  String? _selectedTransmission;
  String? _selectedFuel;

  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController(); // MANUEL ADRES İÇİN

  final ImagePicker _picker = ImagePicker();
  final List<File> _images = [];
  final StorageService _storageService = StorageService();

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Araba', 'icon': Icons.directions_car_rounded},
    {'name': 'Motor', 'icon': Icons.motorcycle_rounded},
    {'name': 'Karavan', 'icon': Icons.rv_hookup_rounded},
    {'name': 'Bisiklet', 'icon': Icons.pedal_bike_rounded},
    {'name': 'Scooter', 'icon': Icons.electric_scooter_rounded},
    {'name': 'Ticari', 'icon': Icons.local_shipping_rounded},
  ];

  List<String> _getFuelOptions() {
    if (_selectedCategory == 'Scooter') return ['Elektrik', 'Benzin'];
    if (_selectedCategory == 'Bisiklet') return [];
    return ['Benzin', 'Dizel', 'LPG', 'Hibrit', 'Elektrik'];
  }

  void _onCategoryChanged(String newCategory) {
    setState(() {
      _selectedCategory = newCategory;
      if (!_getFuelOptions().contains(_selectedFuel)) _selectedFuel = null;
      if (newCategory == 'Bisiklet' || newCategory == 'Scooter') _selectedTransmission = null;
    });
  }

  Future<void> _addVehicle() async {
    if (!_formKey.currentState!.validate()) {
      _showError('Lütfen tüm zorunlu alanları doldurun.');
      return;
    }
    if (_images.isEmpty) {
      _showError('Lütfen en az bir fotoğraf ekleyin.');
      return;
    }

    final user = Provider.of<User?>(context, listen: false);
    if (user == null) return;

    // GÜVENLİK KONTROLÜ: Telefon Numarası
    final String? userPhone = user.phoneNumber;
    if (userPhone == null || userPhone.isEmpty) {
      _showError('İlan vermek için hesabınızda doğrulanmış bir telefon numarası olmalıdır.');
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingText = 'Yükleniyor...';
    });

    try {
      final userDoc = await FirestoreService().getUserProfileStream(user.uid).first;
      final userData = userDoc.data();
      final userCity = userData?['city'];

      if (userCity == null || userCity.isEmpty) throw 'Lütfen önce profilinizden şehrinizi seçin.';

      final List<String> imageUrls = await _storageService.uploadVehicleImages(_images);

      if(!mounted) return;
      setState(() => _loadingText = 'İlan oluşturuluyor...');

      final newVehicle = Vehicle(
        userId: user.uid,
        sellerName: user.displayName ?? user.email?.split('@').first ?? 'Satıcı',
        phoneNumber: userPhone, 
        title: _titleController.text,
        description: _descriptionController.text,
        city: userCity,
        pickupAddress: _addressController.text, // MANUEL ADRES KAYDEDİLDİ
        price: double.tryParse(_priceController.text) ?? 0,
        category: _selectedCategory,
        listingType: _listingType,
        images: imageUrls,
        // HARİTA KOORDİNATLARI KALDIRILDI
        specs: {
          'year': _selectedYear ?? '',
          'transmission': _selectedTransmission ?? '',
          'fuel': _selectedFuel ?? '',
        },
      );

      await context.read<AppState>().addVehicle(newVehicle);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İlanınız başarıyla yayınlandı!')));
        Navigator.pop(context);
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if(!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 4)));
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 50, maxWidth: 1080);
    if (picked.isNotEmpty) {
      setState(() {
        if (_images.length + picked.length <= 5) _images.addAll(picked.map((e) => File(e.path)));
        else _showError('En fazla 5 fotoğraf ekleyebilirsiniz.');
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fuelOptions = _getFuelOptions();
    final user = Provider.of<User?>(context);
    final bool isPhoneVerified = user?.phoneNumber != null && user!.phoneNumber!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('İlan Ver')),
      body: AbsorbPointer(
        absorbing: _isLoading,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Araç Tipini Seçin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 90,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      return _CategoryCard(
                        label: cat['name'],
                        icon: cat['icon'],
                        selected: _selectedCategory == cat['name'],
                        onTap: () => _onCategoryChanged(cat['name']),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 24),
                const Text('Fotoğraflar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (_images.isNotEmpty) SizedBox(height: 100, child: _buildImageListView()),
                if (_images.length < 5) _buildImagePicker(),
                
                const SizedBox(height: 24),
                const _SectionTitle(title: 'İlan Bilgileri'),
                _Input(controller: _titleController, hint: 'İlan Başlığı (Örn: BMW 320i)', icon: Icons.title, validator: (v) => v!.isEmpty ? 'Başlık boş olamaz' : null),
                const SizedBox(height: 16),
                _Input(controller: _priceController, hint: 'Günlük Fiyat (₺)', icon: Icons.sell_outlined, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], validator: (v) => v!.isEmpty ? 'Fiyat boş olamaz' : null),
                const SizedBox(height: 16),
                _Input(controller: _descriptionController, hint: 'Açıklama', icon: Icons.description_outlined, maxLines: 4, validator: (v) => v!.isEmpty ? 'Açıklama boş olamaz' : null),
                
                const SizedBox(height: 24),
                const _SectionTitle(title: 'Teslimat & İletişim'),
                
                // HARİTA BUTONU KALDIRILDI, SADECE MANUEL ADRES VAR
                _Input(controller: _addressController, hint: 'Teslimat Adresi (Mahalle, Sokak vb.)', icon: Icons.location_on_outlined, maxLines: 2, validator: (v) => v!.isEmpty ? 'Adres boş olamaz' : null),
                
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: isPhoneVerified ? Colors.green.withAlpha(20) : Colors.red.withAlpha(20), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Icon(isPhoneVerified ? Icons.verified_user : Icons.shield_outlined, color: isPhoneVerified ? Colors.greenAccent : Colors.redAccent, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(isPhoneVerified ? 'Hesap Onaylı' : 'Güvenlik Uyarısı', style: TextStyle(color: isPhoneVerified ? Colors.greenAccent : Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                            Text(isPhoneVerified ? 'İletişim: ${user?.phoneNumber}' : 'İlan vermek için telefon doğrulaması şarttır.', style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                const _SectionTitle(title: 'Araç Özellikleri'),
                _DropdownInput<String>(hint: 'Yıl', icon: Icons.calendar_today_outlined, value: _selectedYear, items: List.generate(31, (i) => (DateTime.now().year - i).toString()), onChanged: (val) => setState(() => _selectedYear = val)),
                
                if (_selectedCategory != 'Bisiklet' && _selectedCategory != 'Scooter') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _DropdownInput<String>(hint: 'Vites', icon: Icons.settings_input_svideo_outlined, value: _selectedTransmission, items: const ['Otomatik', 'Manuel'], onChanged: (val) => setState(() => _selectedTransmission = val))),
                      if (fuelOptions.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Expanded(child: _DropdownInput<String>(hint: 'Yakıt', icon: Icons.local_gas_station_outlined, value: _selectedFuel, items: fuelOptions, onChanged: (val) => setState(() => _selectedFuel = val))),
                      ],
                    ],
                  ),
                ] else if (_selectedCategory == 'Scooter') ...[
                  const SizedBox(height: 16),
                  _DropdownInput<String>(hint: 'Yakıt', icon: Icons.local_gas_station_outlined, value: _selectedFuel, items: fuelOptions, onChanged: (val) => setState(() => _selectedFuel = val)),
                ],
                
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _isLoading ? null : _addVehicle,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('İlanı Yayınla', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageListView() => ListView.builder(scrollDirection: Axis.horizontal, itemCount: _images.length, itemBuilder: (context, index) => Stack(children: [Container(width: 100, height: 100, margin: const EdgeInsets.only(right: 12, top: 8), decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), image: DecorationImage(image: FileImage(_images[index]), fit: BoxFit.cover))), Positioned(top: 0, right: 4, child: GestureDetector(onTap: () => setState(() => _images.removeAt(index)), child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.close, size: 14, color: Colors.white))))]));
  Widget _buildImagePicker() => InkWell(onTap: _pickImages, child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 24), decoration: BoxDecoration(color: Colors.blueAccent.withAlpha(25), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blueAccent.withAlpha(127), style: BorderStyle.solid)), child: const Column(children: [Icon(Icons.add_a_photo, color: Colors.blueAccent, size: 32), SizedBox(height: 8), Text('Fotoğraf Ekle', style: TextStyle(color: Colors.blueAccent))])));
}

class _CategoryCard extends StatelessWidget {
  final String label; final IconData icon; final bool selected; final VoidCallback onTap;
  const _CategoryCard({required this.label, required this.icon, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: selected ? Colors.blueAccent : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueAccent, width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: selected ? Colors.white : Colors.blueAccent, size: 28),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: selected ? Colors.white : Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(top: 8, bottom: 12), child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)));
}

class _Input extends StatelessWidget {
  final TextEditingController controller; final String hint; final IconData icon; final int maxLines; final TextInputType keyboardType; final List<TextInputFormatter>? inputFormatters; final String? Function(String?)? validator;
  const _Input({required this.controller, required this.hint, required this.icon, this.maxLines = 1, this.keyboardType = TextInputType.text, this.inputFormatters, this.validator});
  @override
  Widget build(BuildContext context) => TextFormField(controller: controller, maxLines: maxLines, keyboardType: keyboardType, inputFormatters: inputFormatters, validator: validator, decoration: InputDecoration(labelText: hint, prefixIcon: Icon(icon)));
}

class _DropdownInput<T> extends StatelessWidget {
  final String hint;
  final IconData icon;
  final T? value;
  final List<T> items;
  final ValueChanged<T?> onChanged;

  const _DropdownInput({
    required this.hint,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      validator: (val) => val == null ? 'Lütfen $hint seçin' : null,
      decoration: InputDecoration(labelText: hint, prefixIcon: Icon(icon)),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item.toString()))).toList(),
      onChanged: onChanged,
    );
  }
}
