import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/listing_provider.dart';
import '../models/listing_model.dart';
import '../widgets/listing_card.dart';
import 'listing_form_screen.dart';

class MyListingsScreen extends StatefulWidget {
  // This class name MUST be exactly this
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  String _selectedCategory = 'All';
  List<Listing> _filteredListings = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ListingProvider>(
        context,
        listen: false,
      ).forceRefreshUserListings();
    });
  }

  Future<void> _refreshListings() async {
    await Provider.of<ListingProvider>(
      context,
      listen: false,
    ).forceRefreshUserListings();
  }

  void _filterByCategory(String category, List<Listing> allListings) {
    setState(() {
      _selectedCategory = category;
      if (category == 'All') {
        _filteredListings = allListings;
      } else {
        _filteredListings = allListings
            .where((listing) => listing.category == category)
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Listings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blue),
            onPressed: _refreshListings,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.green),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ListingFormScreen(),
                ),
              );
            },
            tooltip: 'Add Listing',
          ),
        ],
      ),
      body: Consumer<ListingProvider>(
        builder: (context, listingProvider, child) {
          final allUserListings = listingProvider.userListings;

          // Apply filter
          if (_selectedCategory == 'All') {
            _filteredListings = allUserListings;
          } else {
            _filteredListings = allUserListings
                .where((listing) => listing.category == _selectedCategory)
                .toList();
          }

          return Column(
            children: [
              // User info banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  border: Border(
                    bottom: BorderSide(color: Colors.blue.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.blue,
                      child: Text(
                        user?.email?[0].toUpperCase() ?? '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.email ?? 'Not logged in',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade900,
                            ),
                          ),
                          Text(
                            'Total Listings: ${allUserListings.length}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Category Filter Chips
              if (allUserListings.isNotEmpty)
                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: _buildCategoryChips(allUserListings),
                ),

              // Listings
              Expanded(
                child: _buildListingsContent(listingProvider, allUserListings),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryChips(List<Listing> allUserListings) {
    Map<String, int> categoryCounts = {};
    for (var category in Listing.categories) {
      categoryCounts[category] = 0;
    }

    for (var listing in allUserListings) {
      categoryCounts[listing.category] =
          (categoryCounts[listing.category] ?? 0) + 1;
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: Listing.categories.length,
      itemBuilder: (context, index) {
        final category = Listing.categories[index];
        final count = categoryCounts[category] ?? 0;

        if (category != 'All' && count == 0) {
          return const SizedBox.shrink();
        }

        final isSelected = _selectedCategory == category;

        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FilterChip(
            label: Text(
              category == 'All' ? 'All ($count)' : '$category ($count)',
            ),
            selected: isSelected,
            onSelected: (selected) {
              _filterByCategory(category, allUserListings);
            },
            backgroundColor: Colors.grey.shade100,
            selectedColor: Colors.blue,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            showCheckmark: false,
          ),
        );
      },
    );
  }

  Widget _buildListingsContent(
    ListingProvider listingProvider,
    List<Listing> allUserListings,
  ) {
    if (listingProvider.isLoading && allUserListings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading your listings...'),
          ],
        ),
      );
    }

    if (allUserListings.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'No listings found',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('You haven\'t added any listings yet'),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ListingFormScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Add New Listing'),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredListings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.filter_alt_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No $_selectedCategory listings'),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedCategory = 'All';
                });
              },
              child: const Text('Show All Categories'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredListings.length,
      itemBuilder: (context, index) {
        final listing = _filteredListings[index];
        return ListingCard(listing: listing, showOwnerActions: true);
      },
    );
  }
}
