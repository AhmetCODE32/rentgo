import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:rentgo/core/constants.dart';
import 'package:rentgo/core/firestore_service.dart';
import 'package:rentgo/core/storage_service.dart';
import 'package:rentgo/core/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  
  String? _selectedCity;
  File? _selectedImage;
  bool _isLoading = false;
  bool _isOtpSent = false;
  String? _verificationId;
  late bool _isLocallyVerified;
  String? _verifiedPhoneNumber;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData['displayName'] ?? '');
    _bioController = TextEditingController(text: widget.userData['bio'] ?? '');
    _selectedCity = widget.userData['city'];
    _isLocallyVerified = widget.userData['isPhoneVerified'] ?? false;
    _verifiedPhoneNumber = widget.userData['phoneNumber'];
    if (_isLocallyVerified && _verifiedPhoneNumber != null) {
      _phoneController.text = _verifiedPhoneNumber!.replaceAll('+90', '');
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 50, maxWidth: 800);
    if (picked != null) setState(() => _selectedImage = File(picked.path));
  }

  void _sendSms() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      _showError('Lütfen geçerli bir numara girin.');
      return;
    }

    setState(() => _isLoading = true);
    final authService = context.read<AuthService>();

    try {
      await authService.linkPhoneNumber(
        phoneNumber: '+90$phone',
        verificationFailed: (e) {
          if (mounted) {
            setState(() => _isLoading = false);
            _showError('Hata: ${e.message}');
          }
        },
        codeSent: (verId, _) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _isOtpSent = true;
              _verificationId = verId;
            });
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Onay kodu gönderildi.')));
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('SMS Gönderilemedi.');
      }
    }
  }

  void _verifyAndLink() async {
    final code = _otpController.text.trim();
    if (code.length < 6 || _verificationId == null) return;

    setState(() => _isLoading = true);
    try {
      final updatedUser = await context.read<AuthService>().verifyAndLinkSmsCode(_verificationId!, code);
      if (mounted && updatedUser != null) {
        setState(() {
          _isLoading = false;
          _isOtpSent = false;
          _isLocallyVerified = true; 
          _verifiedPhoneNumber = updatedUser.phoneNumber;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Telefon numaranız başarıyla bağlandı!')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Geçersiz kod veya numara kullanımda.');
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_selectedCity == null) {
      _showError('Lütfen şehrinizi seçin.');
      return;
    }

    setState(() => _isLoading = true);
    final user = Provider.of<User?>(context, listen: false);
    if (user == null) return;

    try {
      String? newPhotoURL;
      if (_selectedImage != null) {
        newPhotoURL = await StorageService().uploadProfileImage(_selectedImage!, user.uid);
      }

      await FirestoreService().updateUserProfile(
        user.uid,
        displayName: _nameController.text.trim(),
        photoURL: newPhotoURL,
        bio: _bioController.text.trim(),
        city: _selectedCity,
        isPhoneVerified: _isLocallyVerified,
        phoneNumber: _verifiedPhoneNumber,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil pırlanta gibi güncellendi!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _showError('Kaydedilemedi.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.redAccent));

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photoURL = widget.userData['photoURL'];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(title: const Text('Profili Düzenle'), backgroundColor: Colors.transparent, elevation: 0),
      body: AbsorbPointer(
        absorbing: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Center(
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.blueAccent.withAlpha(50), width: 4)),
                      child: CircleAvatar(
                        radius: 65,
                        backgroundColor: const Color(0xFF1E293B),
                        backgroundImage: _selectedImage != null ? FileImage(_selectedImage!) : (photoURL != null ? NetworkImage(photoURL) : null) as ImageProvider?,
                        child: _selectedImage == null && photoURL == null ? Text(_nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : '?', style: const TextStyle(fontSize: 48, color: Colors.blueAccent, fontWeight: FontWeight.bold)) : null,
                      ),
                    ),
                    Positioned(bottom: 0, right: 0, child: GestureDetector(onTap: _pickImage, child: Container(padding: const EdgeInsets.all(10), decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle), child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20)))),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              
              _buildInputLabel('Ad Soyad'),
              _Input(controller: _nameController, hint: 'Adınız', icon: Icons.person_outline_rounded),
              const SizedBox(height: 24),

              _buildInputLabel('Telefon Doğrulama'),
              if (_isLocallyVerified)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.green.withAlpha(20), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.green.withAlpha(50))),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user_rounded, color: Colors.greenAccent),
                      const SizedBox(width: 12),
                      Expanded(child: Text('Onaylı Numara: $_verifiedPhoneNumber', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold))),
                    ],
                  ),
                )
              else if (!_isOtpSent)
                Row(
                  children: [
                    Expanded(child: _Input(controller: _phoneController, hint: '5XX XXX XX XX', icon: Icons.phone_android_rounded)),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _sendSms,
                      style: ElevatedButton.styleFrom(minimumSize: const Size(80, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      child: const Text('Kod Al'),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    _Input(controller: _otpController, hint: '6 Haneli Onay Kodu', icon: Icons.lock_open_rounded),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _verifyAndLink,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size.fromHeight(50)),
                      child: const Text('Doğrula'),
                    ),
                  ],
                ),
              
              const SizedBox(height: 24),
              _buildInputLabel('Şehir'),
              DropdownButtonFormField<String>(
                value: _selectedCity,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(prefixIcon: const Icon(Icons.location_city_rounded, color: Colors.blueAccent), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), filled: true, fillColor: const Color(0xFF1E293B)),
                items: AppConstants.turkiyeSehirleri.map((city) => DropdownMenuItem(value: city, child: Text(city))).toList(),
                onChanged: (val) => setState(() => _selectedCity = val),
              ),
              const SizedBox(height: 24),
              
              _buildInputLabel('Hakkımda'),
              _Input(controller: _bioController, hint: 'Kendinden bahset...', icon: Icons.info_outline_rounded, maxLines: 3),
              
              const SizedBox(height: 50),
              ElevatedButton(onPressed: _isLoading ? null : _saveProfile, child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Değişiklikleri Kaydet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) => Padding(padding: const EdgeInsets.only(left: 4, bottom: 8), child: Align(alignment: Alignment.centerLeft, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold))));
}

class _Input extends StatelessWidget {
  final TextEditingController controller; final String hint; final IconData icon; final int maxLines;
  const _Input({required this.controller, required this.hint, required this.icon, this.maxLines = 1});
  @override
  Widget build(BuildContext context) => TextField(controller: controller, maxLines: maxLines, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: Colors.white.withAlpha(30)), prefixIcon: Icon(icon, color: Colors.blueAccent, size: 22), filled: true, fillColor: const Color(0xFF1E293B), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), contentPadding: const EdgeInsets.all(18)));
}
