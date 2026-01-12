import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import 'package:rentgo/core/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool _isProcessing = false;

  void _handleUpgrade(String uid) async {
    setState(() => _isProcessing = true);
    await context.read<FirestoreService>().upgradeToPremium(uid);
    if (mounted) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vroomy Pro Aktif Edildi!'), backgroundColor: Colors.amber));
      Navigator.pop(context);
    }
  }

  void _handleCancel(String uid) async {
    setState(() => _isProcessing = true);
    await context.read<FirestoreService>().cancelPremium(uid);
    if (mounted) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Üyeliğiniz iptal edildi.'), backgroundColor: Colors.redAccent));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    final firestoreService = context.read<FirestoreService>();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: firestoreService.getUserProfileStream(user!.uid),
      builder: (context, snapshot) {
        final userData = snapshot.data?.data() ?? {};
        final bool isPremium = userData['isPremium'] ?? false;

        return Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          body: Stack(
            children: [
              // Gold Background Effect
              Positioned(
                top: -100,
                right: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.amber.withOpacity(0.05),
                  ),
                ),
              ),
              
              SafeArea(
                child: Column(
                  children: [
                    _buildAppBar(context),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            FadeInDown(
                              child: _buildHeader(isPremium),
                            ),
                            const SizedBox(height: 40),
                            _buildFeatureList(),
                            const SizedBox(height: 40),
                            if (isPremium) _buildPremiumInfo(userData),
                          ],
                        ),
                      ),
                    ),
                    _buildActionArea(user.uid, isPremium),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
          const Spacer(),
          const Text('ABONELİK YÖNETİMİ', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isPremium) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFB8860B)]),
            boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 20, spreadRadius: 5)],
          ),
          child: Icon(isPremium ? Icons.workspace_premium : Icons.star_rounded, size: 60, color: Colors.white),
        ),
        const SizedBox(height: 24),
        Text(
          isPremium ? 'VROOMY PRO ÜYESİSİNİZ' : 'VROOMY PRO\'YA GEÇİN',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          isPremium ? 'Tüm ayrıcalıkların tadını çıkarıyorsunuz.' : 'İlanlarınızı öne çıkarın, daha hızlı kiralayın.',
          style: const TextStyle(color: Colors.white54, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildFeatureList() {
    final features = [
      {'icon': Icons.bolt, 'title': 'Aylık 5 Adet İlan Boost', 'desc': 'İlanlarınızı en tepeye taşıyın'},
      {'icon': Icons.verified, 'title': 'Pro Rozeti', 'desc': 'Profilinizde altın onay ikonu'},
      {'icon': Icons.insights, 'title': 'Gelişmiş İstatistikler', 'desc': 'İlan görüntülenme analizi'},
      {'icon': Icons.support_agent, 'title': 'Öncelikli Destek', 'desc': '7/24 hızlı müşteri hizmetleri'},
    ];

    return Column(
      children: features.map((f) => FadeInLeft(
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Icon(f['icon'] as IconData, color: Colors.amber, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f['title'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text(f['desc'] as String, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildPremiumInfo(Map<String, dynamic> data) {
    final expiry = (data['premiumExpiryDate'] as Timestamp).toDate();
    final diff = expiry.difference(DateTime.now()).inDays;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_month, color: Colors.amber, size: 20),
          const SizedBox(width: 8),
          Text('Yenilenmeye $diff gün kaldı', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActionArea(String uid, bool isPremium) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isPremium) ...[
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('₺199.99', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                Text(' / ay', style: TextStyle(color: Colors.white54)),
              ],
            ),
            const SizedBox(height: 20),
          ],
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : () => isPremium ? _handleCancel(uid) : _handleUpgrade(uid),
              style: ElevatedButton.styleFrom(
                backgroundColor: isPremium ? Colors.transparent : Colors.amber,
                foregroundColor: isPremium ? Colors.redAccent : Colors.black,
                elevation: 0,
                side: isPremium ? const BorderSide(color: Colors.redAccent) : BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isProcessing 
                ? const CircularProgressIndicator()
                : Text(
                    isPremium ? 'ÜYELİĞİ İPTAL ET' : 'PRO\'YA GEÇ',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
