import 'dart:io';

class Vehicle {
  final String title;
  final String city;
  final String price;
  final bool isCar;
  final List<File>? images;

  Vehicle({
    required this.title,
    required this.city,
    required this.price,
    required this.isCar,
    this.images,
  });
}