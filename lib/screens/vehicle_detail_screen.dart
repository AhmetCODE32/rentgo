import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final hasImages = widget.vehicle.images.isNotEmpty;

    final priceFormatter = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);
    String formattedPrice;
    if (widget.vehicle.listingType == ListingType.rent) {
      formattedPrice = "${priceFormatter.format(widget.vehicle.price)} / gün";
    } else {
      formattedPrice = priceFormatter.format(widget.vehicle.price);
    }

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
                            child: CircleAvatar(radius: 4, backgroundColor: _activePage == index ? colorScheme.primary : Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.vehicle.title, style: textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Row(children: [Icon(Icons.location_on_outlined, size: 16, color: textTheme.bodySmall?.color), const SizedBox(width: 4), Text(widget.vehicle.city, style: textTheme.bodySmall)]),
                  const SizedBox(height: 24),
                  
                  _SectionTitle(title: 'Fiyat'),
                  Text(formattedPrice, style: textTheme.titleLarge?.copyWith(color: colorScheme.primary, fontSize: 24)),
                  
                  const SizedBox(height: 24),
                  if (widget.vehicle.description.isNotEmpty) ...[
                    _SectionTitle(title: 'Açıklama'),
                    Text(widget.vehicle.description, style: textTheme.bodyLarge?.copyWith(height: 1.5)),
                    const SizedBox(height: 24),
                  ],

                  _SectionTitle(title: 'Özellikler'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      if(widget.vehicle.specs['year']?.isNotEmpty ?? false) _SpecChip(icon: Icons.calendar_today_outlined, label: widget.vehicle.specs['year']!),
                      if(widget.vehicle.specs['transmission']?.isNotEmpty ?? false) _SpecChip(icon: Icons.settings_input_svideo_outlined, label: widget.vehicle.specs['transmission']!),
                      if(widget.vehicle.specs['fuel']?.isNotEmpty ?? false) _SpecChip(icon: Icons.local_gas_station_outlined, label: widget.vehicle.specs['fuel']!),
                    ],
                  ),

                  const SizedBox(height: 24),
                  _SectionTitle(title: 'İletişim ve Teslimat'),
                  const SizedBox(height: 8),
                  _InfoTile(icon: Icons.person_outline, title: 'Satıcı', subtitle: widget.vehicle.sellerName),
                  _InfoTile(icon: Icons.phone_outlined, title: 'Telefon', subtitle: widget.vehicle.phoneNumber),
                  _InfoTile(icon: Icons.delivery_dining_outlined, title: 'Teslimat Adresi', subtitle: widget.vehicle.pickupAddress),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    String buttonText = widget.vehicle.listingType == ListingType.rent ? 'Hemen Kirala' : 'Satın Al';
    return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: const Border(top: BorderSide(color: Colors.white10, width: 0.5)),
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {},
            child: Text(buttonText),
          ),
        ));
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _SpecChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SpecChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
      label: Text(label),
      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 0.5),
      labelStyle: Theme.of(context).textTheme.bodyMedium,
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _InfoTile({required this.icon, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
      title: Text(title, style: Theme.of(context).textTheme.labelMedium),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
    );
}

class _PhotoBox extends StatelessWidget {
  final IconData? icon;
  final String? imageUrl;
  const _PhotoBox({this.icon, this.imageUrl});
  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: imageUrl != null
          ? Image.network(imageUrl!, fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) => loadingProgress == null ? child : Center(child: CircularProgressIndicator(value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null)),
              errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 50)),
            )
          : (icon != null ? Center(child: Icon(icon, size: 100, color: Theme.of(context).colorScheme.primary.withOpacity(0.5))) : null),
    );
}
