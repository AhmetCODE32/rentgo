import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import 'package:rentgo/core/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  // BUY ME A COFFEE LINKINIZI BURAYA EKLEYIN
  final String _supportUrl = "https://www.buymeacoffee.com/alrha"; 

  Future<void> _launchSupportUrl() async {
    final Uri url = Uri.parse(_supportUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sayfa açılamadı, lütfen tekrar deneyin.')),
        );
      }
    }
  }

  void _handleManualActivation(String uid) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0A0A0A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Colors.white10)),
        title: const Text('DESTEK BİLDİRİMİ', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1)),
        content: const Text(
          'Desteğiniz için çok teşekkürler! Bildiriminiz bize ulaştı. Kontroller sonrası "Destekçi" statünüz 24 saat içinde aktif edilecektir.',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('TAMAM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
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
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Positioned(
                top: -150,
                left: -100,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFDD00).withOpacity(0.05),
                  ),
                ),
              ),
              
              SafeArea(
                child: Column(
                  children: [
                    _buildAppBar(context),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        child: Column(
                          children: [
                            FadeInDown(
                              child: _buildHeader(isPremium),
                            ),
                            const SizedBox(height: 48),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28), 
            onPressed: () => Navigator.pop(context)
          ),
          const Text(
            'DESTEK OL', 
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 3)
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isPremium) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF111111),
            border: Border.all(color: const Color(0xFFFFDD00).withOpacity(0.3)),
            boxShadow: [BoxShadow(color: const Color(0xFFFFDD00).withOpacity(0.1), blurRadius: 40, spreadRadius: 5)],
          ),
          child: const Icon(Icons.coffee_rounded, size: 64, color: Color(0xFFFFDD00)),
        ),
        const SizedBox(height: 32),
        Text(
          isPremium ? 'GÖNÜLDEN TEŞEKKÜRLER' : 'BİR KAHVE ISMARLA',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            isPremium 
              ? 'Desteğiniz sayesinde Vroomy büyümeye devam ediyor.' 
              : 'Vroomy tamamen ücretsiz bir platformdur. Gelişimimize katkıda bulunmak için bize bir kahve ısmarlayabilirsin.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 16, height: 1.6),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureList() {
    final features = [
      {'icon': Icons.favorite_rounded, 'title': 'Platformu Yaşat', 'desc': 'Sunucu ve geliştirme masraflarına katkıda bulun'},
      {'icon': Icons.stars_rounded, 'title': 'Destekçi Rozeti', 'desc': 'Profilinde şık bir Supporter ikonu kazanın'},
      {'icon': Icons.auto_awesome_rounded, 'title': 'Sıcak Teşekkür', 'desc': 'Topluluğumuzun en değerli parçası olun'},
      {'icon': Icons.volunteer_activism_rounded, 'title': 'Geleceği İnşa Et', 'desc': 'Yeni özelliklerin daha hızlı gelmesini sağla'},
    ];

    return Column(
      children: features.map((f) => FadeInUp(
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(16)),
                child: Icon(f['icon'] as IconData, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f['title'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(f['desc'] as String, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13)),
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFDD00).withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFDD00).withOpacity(0.1)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.stars_rounded, color: Color(0xFFFFDD00), size: 18),
          const SizedBox(width: 10),
          Text('DESTEKÇİ ÜYE', style: TextStyle(color: Color(0xFFFFDD00), fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildActionArea(String uid, bool isPremium) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isPremium) ...[
            SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                onPressed: _launchSupportUrl,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFDD00), 
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.coffee_rounded, size: 20),
                    SizedBox(width: 12),
                    Text('KAHVE ISMARLA', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1.5)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => _handleManualActivation(uid),
              child: Text(
                'ZATEN DESTEK OLDUM',
                style: TextStyle(color: Colors.white.withOpacity(0.3), fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1),
              ),
            ),
          ] else ...[
            const Text(
              'TEŞEKKÜRLER!',
              style: TextStyle(color: Color(0xFFFFDD00), fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2),
            ),
            const SizedBox(height: 8),
            const Text(
              'Desteğin bizim için paha biçilemez.',
              style: TextStyle(color: Colors.white24, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}
