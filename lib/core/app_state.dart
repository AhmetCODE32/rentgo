import 'package:flutter/material.dart';
import '../models/vehicle.dart';

class AppState extends ChangeNotifier {
  String _city = 'Gaziantep';
  final List<Vehicle> _allVehicles = [
    Vehicle(title: 'BMW 320i', city: 'Gaziantep', price: '1200₺ / gün', isCar: true),
    Vehicle(title: 'Yamaha R25', city: 'Kilis', price: '600₺ / gün', isCar: false),
  ];

  List<Vehicle> get allVehicles => _allVehicles;
  String get city => _city;

  void addVehicle(Vehicle vehicle) {
    _allVehicles.insert(0, vehicle);
    notifyListeners();
  }

  void setCity(String value) {
    _city = value;
    notifyListeners();
  }
}