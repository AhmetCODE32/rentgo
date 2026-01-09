import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rentgo/core/firestore_service.dart';
import 'package:rentgo/models/booking.dart'; // EKLENDİ
import '../models/vehicle.dart';

class CheckoutScreen extends StatefulWidget {
  final Vehicle vehicle;
  final int days;
  final double totalPrice;

  const CheckoutScreen({
    super.key,
    required this.vehicle,
    required this.days,
    required this.totalPrice,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isProcessing = false;

  Future<void> _completeBooking() async {
    final user = Provider.of<User?>(context, listen: false);
    if (user == null) return;

    setState(() => _isProcessing = true);

    try {
      // 1. ÖDEME SİMÜLASYONU
      await Future.delayed(const Duration(seconds: 2));

      // 2. REZERVASYON MODELİNİ OLUŞTUR (Düzeltildi)
      final booking = Booking(
        vehicleId: widget.vehicle.id!,
        vehicleTitle: widget.vehicle.title,
        vehicleImage: widget.vehicle.images.isNotEmpty ? widget.vehicle.images.first : null,
        ownerId: widget.vehicle.userId,
        customerId: user.uid,
        customerName: user.displayName ?? user.email?.split('@').first ?? 'Müşteri',
        days: widget.days,
        totalPrice: widget.totalPrice,
        status: BookingStatus.pendingDelivery,
        createdAt: DateTime.now(),
      );

      // 3. FIREBASE'E KAYDET
      await FirestoreService().createBooking(booking);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Column(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 64),
                SizedBox(height: 16),
                Text('Ödeme Başarılı!', textAlign: TextAlign.center),
              ],
            ),
            content: const Text(
              'Paranız Güvenli Havuz\'a alındı.\nŞimdi araç sahibiyle iletişime geçip aracı teslim alabilirsiniz.',
              textAlign: TextAlign.center,
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text('Ana Sayfaya Dön'),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata oluştu: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final priceFormatter = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(title: const Text('Ödeme Özeti')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16), 
                side: const BorderSide(color: Colors.white10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (widget.vehicle.images.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(widget.vehicle.images.first, width: 80, height: 80, fit: BoxFit.cover),
                      ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.vehicle.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          const SizedBox(height: 4),
                          Text('${widget.vehicle.city}', style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text('Kiralama Bilgileri', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildPriceRow('Günlük Ücret', priceFormatter.format(widget.vehicle.price)),
            _buildPriceRow('Süre', '${widget.days} Gün'),
            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
            _buildPriceRow('Toplam Tutar', priceFormatter.format(widget.totalPrice), isTotal: true),
            
            SizedBox(height: size.height * 0.15),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blueAccent.withOpacity(0.2))),
              child: const Row(
                children: [
                  Icon(Icons.security, color: Colors.blueAccent),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Güvenli Havuz Sistemi: Ödemeniz bizde saklanır. Aracı teslim aldığınızda onay verirseniz para araç sahibine aktarılır.',
                      style: TextStyle(fontSize: 12, color: Colors.blueAccent),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _completeBooking,
                child: _isProcessing 
                  ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)), SizedBox(width: 16), Text('İşlem Yapılıyor...')]) 
                  : const Text('Ödemeyi Onayla ve Kirala'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: isTotal ? 18 : 16, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: isTotal ? 22 : 16, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, color: isTotal ? Colors.blueAccent : null)),
        ],
      ),
    );
  }
}
