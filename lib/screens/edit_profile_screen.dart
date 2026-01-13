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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil başarıyla güncellendi!')));
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('PROFİLİ DÜZENLE', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.w900, fontSize: 16)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: AbsorbPointer(
        absorbing: _isLoading,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              Center(
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.05), width: 1)),
                      child: CircleAvatar(
                        radius: 65,
                        backgroundColor: const Color(0xFF111111),
                        backgroundImage: _selectedImage != null ? FileImage(_selectedImage!) : (photoURL != null ? NetworkImage(photoURL) : null) as ImageProvider?,
                        child: _selectedImage == null && photoURL == null ? Text(_nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : '?', style: const TextStyle(fontSize: 48, color: Colors.white12, fontWeight: FontWeight.w900)) : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0, 
                      right: 0, 
                      child: GestureDetector(
                        onTap: _pickImage, 
                        child: Container(
                          padding: const EdgeInsets.all(12), 
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), 
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.black, size: 20)
                        )
                      )
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              
              _buildInputSectionTitle('TEMEL BİLGİLER'),
              _buildModernInput(controller: _nameController, hint: 'Ad Soyad', icon: Icons.person_rounded),
              const SizedBox(height: 16),
              _buildModernInput(controller: _bioController, hint: 'Hakkımda', icon: Icons.info_rounded, maxLines: 3),
              
              const SizedBox(height: 40),
              _buildInputSectionTitle('KONUM VE DOĞRULAMA'),
              
              DropdownButtonFormField<String>(
                value: _selectedCity,
                dropdownColor: const Color(0xFF0A0A0A),
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  labelText: 'Şehir Seçin',
                  labelStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                  prefixIcon: const Icon(Icons.location_city_rounded, color: Colors.white24, size: 20),
                ),
                items: AppConstants.turkiyeSehirleri.map((city) => DropdownMenuItem(value: city, child: Text(city))).toList(),
                onChanged: (val) => setState(() => _selectedCity = val),
              ),
              
              const SizedBox(height: 24),

              if (_isLocallyVerified)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0A), 
                    borderRadius: BorderRadius.circular(20), 
                    border: Border.all(color: Colors.green.withOpacity(0.2))
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_rounded, color: Colors.greenAccent, size: 24),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('NUMARA DOĞRULANDI', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
                            const SizedBox(height: 4),
                            Text(_verifiedPhoneNumber ?? '', style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else if (!_isOtpSent)
                Row(
                  children: [
                    Expanded(child: _buildModernInput(controller: _phoneController, hint: '5XX XXX XX XX', icon: Icons.phone_android_rounded, keyboardType: TextInputType.phone)),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _sendSms,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(100, 56), 
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      child: const Text('KOD AL', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    _buildModernInput(controller: _otpController, hint: '6 Haneli Kod', icon: Icons.lock_open_rounded, keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _verifyAndLink,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(56)),
                      child: const Text('DOĞRULA VE BAĞLA', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ),
                  ],
                ),
              
              const SizedBox(height: 80),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile, 
                child: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) 
                  : const Text('DEĞİŞİKLİKLERİ KAYDET')
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputSectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 16), 
    child: Align(
      alignment: Alignment.centerLeft, 
      child: Text(
        title, 
        style: const TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2)
      )
    )
  );

  Widget _buildModernInput({
    required TextEditingController controller, 
    required String hint, 
    required IconData icon, 
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: const TextStyle(color: Colors.white24, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.white24, size: 20),
      ),
    );
  }
}
