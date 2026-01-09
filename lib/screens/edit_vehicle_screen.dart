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
    // Mevcut verileri doldur
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
      appBar: AppBar(title: const Text('İlanı Düzenle')),
      body: AbsorbPointer(
        absorbing: _isLoading,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('İlan Bilgilerini Güncelle', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'İlan Başlığı', prefixIcon: Icon(Icons.title)),
                  validator: (v) => v!.isEmpty ? 'Başlık boş olamaz' : null,
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Fiyat (₺)', prefixIcon: Icon(Icons.sell_outlined)),
                  validator: (v) => v!.isEmpty ? 'Fiyat boş olamaz' : null,
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Açıklama', prefixIcon: Icon(Icons.description_outlined)),
                  validator: (v) => v!.isEmpty ? 'Açıklama boş olamaz' : null,
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Teslimat Adresi', prefixIcon: Icon(Icons.location_on_outlined)),
                  validator: (v) => v!.isEmpty ? 'Adres boş olamaz' : null,
                ),
                
                const SizedBox(height: 40),
                
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateVehicle,
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : const Text('Değişiklikleri Kaydet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
