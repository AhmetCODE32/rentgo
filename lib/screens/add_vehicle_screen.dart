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
  final _addressController = TextEditingController();

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
    final user = Provider.of<User?>(context, listen: false);
    if (user == null) return;

    if (!_formKey.currentState!.validate()) {
      _showError('Lütfen tüm zorunlu alanları doldurun.');
      return;
    }
    if (_images.isEmpty) {
      _showError('Lütfen en az bir fotoğraf ekleyin.');
      return;
    }

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
      final userData = userDoc.data() ?? {};
      final userCity = userData['city'];

      if (userCity == null || userCity.isEmpty) throw 'Lütfen önce profilinizden şehrinizi seçin.';

      final List<String> imageUrls = await _storageService.uploadVehicleImages(_images);

      if(!mounted) return;
      setState(() => _loadingText = 'İlan oluşturuluyor...');

      final newVehicle = Vehicle(
        userId: user.uid,
        sellerName: userData['displayName'] ?? 'Satıcı',
        phoneNumber: userPhone, 
        title: _titleController.text,
        description: _descriptionController.text,
        city: userCity,
        pickupAddress: _addressController.text,
        price: double.tryParse(_priceController.text) ?? 0,
        category: _selectedCategory,
        listingType: _listingType,
        images: imageUrls,
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('İLAN VER', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.w900, fontSize: 16)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: AbsorbPointer(
        absorbing: _isLoading,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SectionTitle(title: 'ARAÇ TİPİ'),
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
                
                const SizedBox(height: 32),
                const _SectionTitle(title: 'FOTOĞRAFLAR'),
                if (_images.isNotEmpty) ...[
                  SizedBox(height: 100, child: _buildImageListView()),
                  const SizedBox(height: 12),
                ],
                if (_images.length < 5) _buildImagePicker(),
                
                const SizedBox(height: 32),
                const _SectionTitle(title: 'GENEL BİLGİLER'),
                _buildInput(controller: _titleController, hint: 'İlan Başlığı', icon: Icons.title_rounded),
                const SizedBox(height: 16),
                _buildInput(controller: _priceController, hint: 'Günlük Fiyat (₺)', icon: Icons.sell_rounded, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                const SizedBox(height: 16),
                _buildInput(controller: _descriptionController, hint: 'Açıklama', icon: Icons.description_rounded, maxLines: 4),
                
                const SizedBox(height: 32),
                const _SectionTitle(title: 'KONUM VE İLETİŞİM'),
                _buildInput(controller: _addressController, hint: 'Teslimat Adresi', icon: Icons.location_on_rounded, maxLines: 2),
                
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0A), 
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isPhoneVerified ? Colors.green.withOpacity(0.2) : Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Icon(isPhoneVerified ? Icons.verified_rounded : Icons.info_outline_rounded, color: isPhoneVerified ? Colors.greenAccent : Colors.white24, size: 24),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(isPhoneVerified ? 'KİMLİK DOĞRULANDI' : 'DOĞRULAMA GEREKLİ', style: TextStyle(color: isPhoneVerified ? Colors.greenAccent : Colors.white24, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                            const SizedBox(height: 4),
                            Text(isPhoneVerified ? 'Telefon: ${user?.phoneNumber}' : 'İlan vermek için telefon numaranızı doğrulamalısınız.', style: const TextStyle(fontSize: 13, color: Colors.white70)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                const _SectionTitle(title: 'DETAYLI ÖZELLİKLER'),
                _DropdownInput<String>(hint: 'Model Yılı', icon: Icons.calendar_today_rounded, value: _selectedYear, items: List.generate(31, (i) => (DateTime.now().year - i).toString()), onChanged: (val) => setState(() => _selectedYear = val)),
                
                if (_selectedCategory != 'Bisiklet' && _selectedCategory != 'Scooter') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _DropdownInput<String>(hint: 'Vites', icon: Icons.settings_rounded, value: _selectedTransmission, items: const ['Otomatik', 'Manuel'], onChanged: (val) => setState(() => _selectedTransmission = val))),
                      if (fuelOptions.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Expanded(child: _DropdownInput<String>(hint: 'Yakıt', icon: Icons.local_gas_station_rounded, value: _selectedFuel, items: fuelOptions, onChanged: (val) => setState(() => _selectedFuel = val))),
                      ],
                    ],
                  ),
                ] else if (_selectedCategory == 'Scooter') ...[
                  const SizedBox(height: 16),
                  _DropdownInput<String>(hint: 'Yakıt', icon: Icons.local_gas_station_rounded, value: _selectedFuel, items: fuelOptions, onChanged: (val) => setState(() => _selectedFuel = val)),
                ],
                
                const SizedBox(height: 60),
                ElevatedButton(
                  onPressed: _isLoading ? null : _addVehicle,
                  child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : const Text('İLANINI YAYINLA'),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageListView() => ListView.builder(scrollDirection: Axis.horizontal, itemCount: _images.length, itemBuilder: (context, index) => Stack(children: [Container(width: 100, height: 100, margin: const EdgeInsets.only(right: 12), decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), image: DecorationImage(image: FileImage(_images[index]), fit: BoxFit.cover), border: Border.all(color: Colors.white10))), Positioned(top: 4, right: 16, child: GestureDetector(onTap: () => setState(() => _images.removeAt(index)), child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle), child: const Icon(Icons.close, size: 14, color: Colors.white))))]));
  Widget _buildImagePicker() => InkWell(onTap: _pickImages, borderRadius: BorderRadius.circular(20), child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 32), decoration: BoxDecoration(color: const Color(0xFF0A0A0A), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.05))), child: const Column(children: [Icon(Icons.add_a_photo_rounded, color: Colors.white, size: 32), SizedBox(height: 12), Text('FOTOĞRAF EKLE', style: TextStyle(color: Colors.white24, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1))])));

  Widget _buildInput({required TextEditingController controller, required String hint, required IconData icon, int maxLines = 1, TextInputType keyboardType = TextInputType.text, List<TextInputFormatter>? inputFormatters}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: const TextStyle(color: Colors.white24, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.white24, size: 20),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String label; final IconData icon; final bool selected; final VoidCallback onTap;
  const _CategoryCard({required this.label, required this.icon, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: selected ? Colors.white : const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: selected ? Colors.white : Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: selected ? Colors.black : Colors.white24, size: 28),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: selected ? Colors.black : Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        ],
      ),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 16), child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white24, letterSpacing: 2)));
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
      dropdownColor: const Color(0xFF0A0A0A),
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: hint, 
        labelStyle: const TextStyle(color: Colors.white24, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.white24, size: 20)
      ),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item.toString()))).toList(),
      onChanged: onChanged,
    );
  }
}
