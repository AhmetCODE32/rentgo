import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:rentgo/core/constants.dart'; // ŞEHİR LİSTESİ İÇİN
import 'package:rentgo/core/firestore_service.dart';
import 'package:rentgo/core/storage_service.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  String? _selectedCity; // ŞEHİR SEÇİMİ İÇİN
  File? _selectedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData['displayName']);
    _bioController = TextEditingController(text: widget.userData['bio'] ?? '');
    _selectedCity = widget.userData['city']; // MEVCUT ŞEHRİ YÜKLE
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 50, maxWidth: 800);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen şehrinizi seçin.')));
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
        displayName: _nameController.text,
        photoURL: newPhotoURL,
        bio: _bioController.text.trim(),
        city: _selectedCity, // ŞEHİR KAYDEDİLİYOR
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil başarıyla güncellendi!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profil güncellenemedi: ${e.toString()}')));
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photoURL = widget.userData['photoURL'];

    return Scaffold(
      appBar: AppBar(title: const Text('Profili Düzenle')),
      body: AbsorbPointer(
        absorbing: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!)
                        : (photoURL != null ? NetworkImage(photoURL) : null) as ImageProvider?,
                    child: _selectedImage == null && photoURL == null && _nameController.text.isNotEmpty ? Text(_nameController.text[0].toUpperCase(), style: const TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.bold)) : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: IconButton.filled(
                      style: IconButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.8)),
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                      onPressed: _pickImage,
                    ),
                  )
                ],
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Adınız', prefixIcon: Icon(Icons.person_outline)),
              ),
              const SizedBox(height: 16),
              
              // ŞEHİR SEÇİM ALANI
              DropdownButtonFormField<String>(
                value: _selectedCity,
                decoration: const InputDecoration(
                  labelText: 'Şehriniz',
                  prefixIcon: Icon(Icons.location_city_outlined),
                ),
                items: AppConstants.turkiyeSehirleri.map((city) {
                  return DropdownMenuItem(value: city, child: Text(city));
                }).toList(),
                onChanged: (val) => setState(() => _selectedCity = val),
              ),
              
              const SizedBox(height: 16),
              TextField(
                controller: _bioController,
                maxLines: 3,
                maxLength: 150,
                decoration: const InputDecoration(
                  labelText: 'Hakkımda', 
                  prefixIcon: Icon(Icons.info_outline),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Kaydet'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
