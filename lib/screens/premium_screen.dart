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
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Luxury Background Glow
              Positioned(
                top: -150,
                left: -100,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.amber.withOpacity(0.08),
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
            'VROOMY PRO', 
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
            border: Border.all(color: Colors.amber.withOpacity(0.3)),
            boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.1), blurRadius: 40, spreadRadius: 5)],
          ),
          child: Icon(isPremium ? Icons.workspace_premium_rounded : Icons.bolt_rounded, size: 64, color: Colors.amber),
        ),
        const SizedBox(height: 32),
        Text(
          isPremium ? 'PRO ÜYELİK AKTİF' : 'SINIRLARI ZORLAYIN',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            isPremium ? 'Tüm pro ayrıcalıklara sahipsiniz.' : 'İlanlarınız en tepede görünsün, komisyonsuz kiralayın.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 16, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureList() {
    final features = [
      {'icon': Icons.bolt_rounded, 'title': 'Hızlı Listeleme', 'desc': 'İlanlarınız her zaman en üstte'},
      {'icon': Icons.verified_rounded, 'title': 'Altın Rozet', 'desc': 'Güvenilir satıcı statüsü'},
      {'icon': Icons.analytics_rounded, 'title': 'Detaylı Analiz', 'desc': 'İlan performansını takip edin'},
      {'icon': Icons.support_agent_rounded, 'title': 'VIP Destek', 'desc': '7/24 öncelikli müşteri hattı'},
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
    if (data['premiumExpiryDate'] == null) return const SizedBox.shrink();
    final expiry = (data['premiumExpiryDate'] as Timestamp).toDate();
    final diff = expiry.difference(DateTime.now()).inDays;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, color: Colors.amber, size: 18),
          const SizedBox(width: 10),
          Text('Yenilenmeye $diff gün kaldı', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                const Text('₺199', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
                Text('.99', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 18, fontWeight: FontWeight.w900)),
                Text(' / AY', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ],
            ),
            const SizedBox(height: 24),
          ],
          SizedBox(
            width: double.infinity,
            height: 64,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : () => isPremium ? _handleCancel(uid) : _handleUpgrade(uid),
              style: ElevatedButton.styleFrom(
                backgroundColor: isPremium ? Colors.transparent : Colors.white,
                foregroundColor: isPremium ? Colors.redAccent : Colors.black,
                elevation: 0,
                side: isPremium ? const BorderSide(color: Colors.redAccent, width: 2) : BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: _isProcessing 
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3))
                : Text(
                    isPremium ? 'ÜYELİĞİ İPTAL ET' : 'HEMEN BAŞLA',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1.5),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
