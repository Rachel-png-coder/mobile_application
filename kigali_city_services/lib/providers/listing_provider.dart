import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/listing_model.dart';
import '../services/firestore_service.dart';

class ListingProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  List<Listing> _allListings = [];
  List<Listing> _filteredListings = [];
  List<Listing> _userListings = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  StreamSubscription<List<Listing>>? _allListingsSubscription;
  StreamSubscription<List<Listing>>? _userListingsSubscription;

  // GETTERS
  List<Listing> get listings => _filteredListings;
  List<Listing> get userListings => _userListings;
  List<Listing> get allListings => _allListings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  ListingProvider() {
    print('🟢 ListingProvider initialized');
    _initializeListings();

    _auth.authStateChanges().listen((firebase_auth.User? user) {
      print('🟢 Auth state changed: ${user?.uid}');
      _initializeListings();
    });
  }

  // Method to initialize both streams
  Future<void> _initializeListings() async {
    _listenToListings();
    _listenToUserListings();

    await refreshAllListings();
    if (_auth.currentUser != null) {
      await forceRefreshUserListings();
    }
  }

  void _listenToListings() {
    print('🟢 Setting up getAllListings listener');

    _allListingsSubscription?.cancel();

    _allListingsSubscription = _firestoreService.getAllListings().listen(
      (listings) {
        print('🟢 Received ${listings.length} listings from Firestore');
        _allListings = listings;
        _applyFilters();
        notifyListeners();
      },
      onError: (error) {
        print('🔴 Error in listings stream: $error');
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  void _listenToUserListings() {
    final userId = _auth.currentUser?.uid;
    print('🟢 Setting up getUserListings listener for user: $userId');

    if (userId == null) {
      print('⚠️ No user logged in');
      _userListings = [];
      notifyListeners();
      return;
    }

    _userListingsSubscription?.cancel();

    _userListingsSubscription = _firestoreService.getUserListings().listen(
      (listings) {
        print('🟢 Received ${listings.length} user listings for user $userId');

        // Debug: Print each listing's details
        for (var listing in listings) {
          print('   📄 User Listing: ${listing.name} (ID: ${listing.id})');
        }

        _userListings = listings;
        notifyListeners();
      },
      onError: (error) {
        print('🔴 Error in user listings stream: $error');
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  void _applyFilters() {
    print(
      '🟢 Applying filters - Search: "$_searchQuery", Category: "$_selectedCategory"',
    );
    print('📊 Total listings before filter: ${_allListings.length}');

    // Start with all listings
    var filtered = List<Listing>.from(_allListings);

    // Apply category filter
    if (_selectedCategory != 'All') {
      filtered = filtered
          .where((l) => l.category == _selectedCategory)
          .toList();
      print('📊 After category filter: ${filtered.length} listings');
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (l) => l.name.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
      print('📊 After search filter: ${filtered.length} listings');
    }

    _filteredListings = filtered;
    print('🟢 Final filtered listings count: ${_filteredListings.length}');
    notifyListeners();
  }

  Future<bool> createListing(Listing listing) async {
    _setLoading(true);
    print('🟢 Creating listing: ${listing.name}');
    print('🟢 Created by user: ${listing.createdBy}');

    final result = await _firestoreService.createListing(listing);

    _setLoading(false);

    if (!result['success']) {
      print('🔴 Create failed: ${result['error']}');
      _errorMessage = result['error'];
      notifyListeners();
      return false;
    }

    print('🟢 Create successful, ID: ${result['id']}');

    // Force refresh both listings after creating
    await refreshAllListings();
    await forceRefreshUserListings();

    return true;
  }

  Future<bool> updateListing(String id, Map<String, dynamic> data) async {
    _setLoading(true);
    print('🟢 Updating listing: $id');

    final result = await _firestoreService.updateListing(id, data);

    _setLoading(false);

    if (!result['success']) {
      print('🔴 Update failed: ${result['error']}');
      _errorMessage = result['error'];
      notifyListeners();
      return false;
    }

    print('🟢 Update successful');

    // Force refresh both listings after updating
    await refreshAllListings();
    await forceRefreshUserListings();

    return true;
  }

  Future<bool> deleteListing(String id) async {
    _setLoading(true);
    print('🟢 Deleting listing: $id');

    final result = await _firestoreService.deleteListing(id);

    _setLoading(false);

    if (!result['success']) {
      print('🔴 Delete failed: ${result['error']}');
      _errorMessage = result['error'];
      notifyListeners();
      return false;
    }

    print('🟢 Delete successful');

    // Force refresh both listings after deleting
    await refreshAllListings();
    await forceRefreshUserListings();

    return true;
  }

  // PUBLIC method to force refresh user listings (can be called from UI)
  Future<void> forceRefreshUserListings() async {
    final userId = _auth.currentUser?.uid;
    print('🔄 Force refreshing user listings for user: $userId');

    if (userId == null) {
      print('⚠️ No user logged in');
      _userListings = [];
      notifyListeners();
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('listings')
          .where('createdBy', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      print('📥 Firestore query returned ${snapshot.docs.length} docs');

      final listings = snapshot.docs.map((doc) {
        final data = doc.data();
        print(
          '   📄 Doc ${doc.id}: ${data['name']} - createdBy=${data['createdBy']}',
        );
        return Listing.fromMap(doc.id, data);
      }).toList();

      print('🔄 Manual refresh found ${listings.length} user listings');
      _userListings = listings;
      notifyListeners();
    } catch (e) {
      print('🔴 Error refreshing user listings: $e');
      _errorMessage = e.toString();
    }
  }

  // Method to refresh all listings
  Future<void> refreshAllListings() async {
    print('🔄 Refreshing all listings');

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('listings')
          .orderBy('timestamp', descending: true)
          .get();

      print('📥 Found ${snapshot.docs.length} total listings');

      if (snapshot.docs.isEmpty) {
        print('⚠️ No listings found in Firestore');
        _allListings = [];
        _applyFilters();
        notifyListeners();
        return;
      }

      final listings = snapshot.docs.map((doc) {
        final data = doc.data();
        return Listing.fromMap(doc.id, data);
      }).toList();

      _allListings = listings;
      print('✅ Loaded ${_allListings.length} listings into provider');

      // Print all listing names for debugging
      for (var listing in _allListings) {
        print('   📋 Loaded: ${listing.name} (Category: ${listing.category})');
      }

      _applyFilters();
    } catch (e) {
      print('🔴 Error refreshing all listings: $e');
      _errorMessage = e.toString();
    }
  }

  // Reset all filters
  void resetFilters() {
    print('🟢 Resetting all filters');
    _searchQuery = '';
    _selectedCategory = 'All';
    _applyFilters();
  }

  void searchListings(String query) {
    print('🟢 Search query changed to: "$query"');
    _searchQuery = query;
    _applyFilters();
  }

  void filterByCategory(String category) {
    print('🟢 Category filter changed to: "$category"');
    _selectedCategory = category;
    _applyFilters();
  }

  bool canModifyListing(Listing listing) {
    final userId = _auth.currentUser?.uid;
    final canModify = userId != null && listing.createdBy == userId;
    print(
      '🔍 Can modify ${listing.name}: $canModify (User: $userId, Owner: ${listing.createdBy})',
    );
    return canModify;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) {
      _errorMessage = null;
    }
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    // Clean up subscriptions
    _allListingsSubscription?.cancel();
    _userListingsSubscription?.cancel();
    super.dispose();
  }
}
