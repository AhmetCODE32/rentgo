import 'package:flutter/material.dart';

// BU DOSYA ARTIK KULLANILMAMAKTADIR. 
// HARİTA ÖZELLİĞİ KALDIRILDIĞI İÇİN BOŞ BIRAKILMIŞTIR.
class MapSelectionScreen extends StatelessWidget {
  const MapSelectionScreen({super.key, dynamic initialLocation});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Harita Devre Dışı')),
      body: const Center(
        child: Text('Harita özelliği bu sürümde kaldırılmıştır.'),
      ),
    );
  }
}
