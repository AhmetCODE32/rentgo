import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rentgo/core/firestore_service.dart';
import '../models/vehicle.dart';

class AppState extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  StreamSubscription? _vehiclesSubscription;

  // Durum Değişkenleri
  bool _isLoading = true; // YENİ: Başlangıçta yükleniyor
  List<Vehicle> _allVehicles = [];
  String _city = 'Tümü';
  bool _showCars = true;
  String _searchTerm = '';
  int _pageIndex = 0;

  AppState() {
    _listenToVehicles();
  }

  // Getter'lar
  bool get isLoading => _isLoading; // YENİ
  String get city => _city;
  bool get showCars => _showCars;
  String get searchTerm => _searchTerm;
  List<Vehicle> get allVehicles => _allVehicles;
  int get pageIndex => _pageIndex;

  List<Vehicle> get filteredVehicles {
    return _allVehicles.where((v) {
      final typeMatch = v.isCar == _showCars;
      final cityMatch = _city == 'Tümü' || v.city == _city;
      final searchMatch = _searchTerm.isEmpty || v.title.toLowerCase().contains(_searchTerm.toLowerCase());
      return typeMatch && cityMatch && searchMatch;
    }).toList();
  }

  void _listenToVehicles() {
    _vehiclesSubscription = _firestoreService.getVehiclesStream().listen((snapshot) {
      _allVehicles = snapshot.docs.map((doc) => doc.data()).toList();
      if (_isLoading) {
        _isLoading = false; // İlk veri geldiğinde yükleme durumunu kapat
      }
      notifyListeners(); // Arayüzü güncelle
    });
  }

  Future<void> addVehicle(Vehicle vehicle) async {
    await _firestoreService.addVehicle(vehicle);
  }

  Future<void> deleteVehicle(String vehicleId) async {
    await _firestoreService.deleteVehicle(vehicleId);
  }

  // Setter'lar
  void setCity(String value) {
    _city = value;
    notifyListeners();
  }

  void setShowCars(bool value) {
    _showCars = value;
    notifyListeners();
  }

  void setSearchTerm(String value) {
    _searchTerm = value;
    notifyListeners();
  }

  void setPageIndex(int index) {
    _pageIndex = index;
    notifyListeners();
  }

  @override
  void dispose() {
    _vehiclesSubscription?.cancel();
    super.dispose();
  }
}
