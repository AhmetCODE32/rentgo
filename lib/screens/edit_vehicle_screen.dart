import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rentgo/core/firestore_service.dart';
import '../models/vehicle.dart';

class EditVehicleScreen extends StatefulWidget {
  final Vehicle vehicle;
  const EditVehicleScreen({super.key, required this.vehicle});

  @override
  State<EditVehicleScreen> createState() => _EditVehicleScreenState();
}

class _EditVehicleScreenState extends State<EditVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _addressController;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.vehicle.title);
    _priceController = TextEditingController(text: widget.vehicle.price.toInt().toString());
    _descriptionController = TextEditingController(text: widget.vehicle.description);
    _addressController = TextEditingController(text: widget.vehicle.pickupAddress);
  }

  Future<void> _updateVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirestoreService().updateVehicle(widget.vehicle.id!, {
        'title': _titleController.text.trim(),
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'description': _descriptionController.text.trim(),
        'pickupAddress': _addressController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İlan başarıyla güncellendi!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('İLAN DÜZENLE', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.w900, fontSize: 16)),
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
                const Text(
                  'İLAN BİLGİLERİNİ GÜNCELLE', 
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white24, letterSpacing: 2)
                ),
                const SizedBox(height: 32),
                
                _buildInput(
                  controller: _titleController,
                  label: 'İlan Başlığı',
                  icon: Icons.title_rounded,
                  validator: (v) => v!.isEmpty ? 'Başlık boş olamaz' : null,
                ),
                const SizedBox(height: 16),
                
                _buildInput(
                  controller: _priceController,
                  label: 'Fiyat (₺)',
                  icon: Icons.sell_rounded,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) => v!.isEmpty ? 'Fiyat boş olamaz' : null,
                ),
                const SizedBox(height: 16),
                
                _buildInput(
                  controller: _descriptionController,
                  label: 'Açıklama',
                  icon: Icons.description_rounded,
                  maxLines: 4,
                  validator: (v) => v!.isEmpty ? 'Açıklama boş olamaz' : null,
                ),
                const SizedBox(height: 16),
                
                _buildInput(
                  controller: _addressController,
                  label: 'Teslimat Adresi',
                  icon: Icons.location_on_rounded,
                  maxLines: 2,
                  validator: (v) => v!.isEmpty ? 'Adres boş olamaz' : null,
                ),
                
                const SizedBox(height: 60),
                
                ElevatedButton(
                  onPressed: _isLoading ? null : _updateVehicle,
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) 
                    : const Text('DEĞİŞİKLİKLERİ KAYDET'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white24, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.white24, size: 20),
      ),
    );
  }
}
