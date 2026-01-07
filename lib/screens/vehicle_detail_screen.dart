import 'package:flutter/material.dart';
import '../models/vehicle.dart';

class VehicleDetailScreen extends StatefulWidget {
  final Vehicle vehicle;

  const VehicleDetailScreen({super.key, required this.vehicle});

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  final _pageController = PageController();
  int _activePage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _activePage = _pageController.page!.round();
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasImages = widget.vehicle.images.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(widget.vehicle.title)),
      body: Column(
        children: [
          SizedBox(
            height: 250,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: hasImages ? widget.vehicle.images.length : 1,
                  itemBuilder: (context, index) {
                    if (hasImages) {
                      // RESİM GÖSTERİMİ Image.network KULLANACAK ŞEKİLDE GÜNCELLENDİ
                      return _PhotoBox(imageUrl: widget.vehicle.images[index]);
                    }
                    return _PhotoBox(icon: widget.vehicle.isCar ? Icons.directions_car : Icons.motorcycle);
                  },
                ),
                if (hasImages && widget.vehicle.images.length > 1)
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List<Widget>.generate(
                        widget.vehicle.images.length,
                        (index) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: InkWell(
                            onTap: () => _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeIn),
                            child: CircleAvatar(
                              radius: 4,
                              backgroundColor: _activePage == index ? Colors.white : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.vehicle.title,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  _InfoTile(icon: Icons.sell_outlined, title: 'Fiyat', subtitle: widget.vehicle.price),
                  _InfoTile(icon: Icons.location_on_outlined, title: 'Konum', subtitle: widget.vehicle.city),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {},
                      child: Text(
                        widget.vehicle.isCar ? 'Aracı Kirala' : 'Motoru Kirala',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.blueAccent, size: 28),
      title: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }
}

// FOTOĞRAF GÖSTERİM KUTUSU GÜNCELLENDİ
class _PhotoBox extends StatelessWidget {
  final IconData? icon;
  final String? imageUrl;

  const _PhotoBox({this.icon, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      clipBehavior: Clip.antiAlias, // Köşeleri yuvarlatılmış resim için
      decoration: BoxDecoration(
        color: const Color(0xFF020617),
        borderRadius: BorderRadius.circular(20),
      ),
      child: imageUrl != null
          ? Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 50));
              },
            )
          : (icon != null
              ? Center(child: Icon(icon, size: 100, color: Colors.blueAccent.withOpacity(0.5)))
              : null),
    );
  }
}
