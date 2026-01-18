import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rentgo/core/firestore_service.dart';
import '../models/vehicle.dart';

class AppState extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  
  List<Vehicle> _allVehicles = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  final int _limit = 10;

  // Durum Değişkenleri
  String _city = 'Tüm Türkiye';
  String _selectedCategory = 'Hepsi';
  String _searchTerm = '';
  String _sortBy = 'En Yeni'; // YENİ: Sıralama durumu
  int _pageIndex = 0;

  // Getter'lar
  List<Vehicle> get allVehicles => _allVehicles;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String get city => _city;
  String get selectedCategory => _selectedCategory;
  String get searchTerm => _searchTerm;
  String get sortBy => _sortBy;
  int get pageIndex => _pageIndex;

  AppState() {
    fetchVehicles();
  }

  // SAYFALAMA VE SIRALAMA İLE VERİ ÇEKME
  Future<void> fetchVehicles({bool isRefresh = false}) async {
    if (_isLoading || (!_hasMore && !isRefresh)) return;

    _isLoading = true;
    if (isRefresh) {
      _allVehicles = [];
      _lastDocument = null;
      _hasMore = true;
    }
    notifyListeners();

    try {
      Query query = FirebaseFirestore.instance.collection('vehicles');

      // FİLTRELER
      if (_selectedCategory != 'Hepsi') {
        query = query.where('category', isEqualTo: _selectedCategory);
      }
      if (_city != 'Tüm Türkiye') {
        query = query.where('city', isEqualTo: _city);
      }

      // SIRALAMA MANTIĞI
      switch (_sortBy) {
        case 'Fiyat (Artan)':
          query = query.orderBy('price', descending: false);
          break;
        case 'Fiyat (Azalan)':
          query = query.orderBy('price', descending: true);
          break;
        case 'Yıl (En Yeni)':
          query = query.orderBy('specs.year', descending: true);
          break;
        default: // En Yeni
          query = query.orderBy('createdAt', descending: true);
      }

      query = query.limit(_limit);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();

      if (snapshot.docs.length < _limit) {
        _hasMore = false;
      }

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        final newVehicles = snapshot.docs.map((doc) => Vehicle.fromMap(doc as DocumentSnapshot<Map<String, dynamic>>)).toList();
        
        // Arama filtresi (Client side search for simplicity)
        if (_searchTerm.isNotEmpty) {
          final searchFiltered = newVehicles.where((v) => v.title.toLowerCase().contains(_searchTerm.toLowerCase())).toList();
          _allVehicles.addAll(searchFiltered);
        } else {
          _allVehicles.addAll(newVehicles);
        }
      }
    } catch (e) {
      debugPrint("Veri çekme hatası: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Setter'lar
  void setSortBy(String value) { _sortBy = value; fetchVehicles(isRefresh: true); }
  void setCity(String value) { _city = value; fetchVehicles(isRefresh: true); }
  void setCategory(String value) { _selectedCategory = value; fetchVehicles(isRefresh: true); }
  void setSearchTerm(String value) { _searchTerm = value; fetchVehicles(isRefresh: true); }
  void setPageIndex(int index) { _pageIndex = index; notifyListeners(); }

  Future<void> addVehicle(Vehicle vehicle) async {
    await _firestoreService.addVehicle(vehicle);
    fetchVehicles(isRefresh: true);
  }

  Future<void> deleteVehicle(String vehicleId) async {
    await _firestoreService.deleteVehicle(vehicleId);
    _allVehicles.removeWhere((v) => v.id == vehicleId);
    notifyListeners();
  }
}
