import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../providers/listing_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/listing_card.dart';
import '../widgets/category_filter.dart';
import 'listing_form_screen.dart';

class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key});

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Refresh when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ListingProvider>(context, listen: false).refreshAllListings();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Debug function to check Firestore data
  Future<void> _debugFirestore() async {
    print('🔍 DEBUGGING FIRESTORE...');
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('listings')
          .get();

      print('📊 Total documents: ${snapshot.docs.length}');

      if (snapshot.docs.isEmpty) {
        print('⚠️ No documents found in "listings" collection');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No listings found in Firestore'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      String dialogContent = '';
      for (var doc in snapshot.docs) {
        final data = doc.data();
        print('📄 Document: ${doc.id}');
        print('   name: ${data['name']}');
        print('   category: ${data['category']}');
        print('   createdBy: ${data['createdBy']}');
        print('   timestamp: ${data['timestamp']}');

        dialogContent += '• ${data['name']} (${data['category']})\n';
      }

      // Show dialog with all listings
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Firestore Listings (${snapshot.docs.length})'),
          content: Container(
            width: double.maxFinite,
            height: 300,
            child: SingleChildScrollView(child: Text(dialogContent)),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('OK')),
          ],
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Found ${snapshot.docs.length} listings in Firestore'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('❌ Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // Show all listings from provider (including filtered ones)
  void _showAllListings() {
    final provider = Provider.of<ListingProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'All Listings in Provider (${provider.allListings.length})',
        ),
        content: Container(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: provider.allListings.length,
            itemBuilder: (ctx, index) {
              final listing = provider.allListings[index];
              final isVisible = provider.listings.contains(listing);
              return ListTile(
                title: Text(
                  listing.name,
                  style: TextStyle(
                    fontWeight: isVisible ? FontWeight.bold : FontWeight.normal,
                    color: isVisible ? Colors.black : Colors.grey,
                  ),
                ),
                subtitle: Text('Category: ${listing.category}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isVisible)
                      const Icon(
                        Icons.visibility,
                        color: Colors.green,
                        size: 16,
                      ),
                    Text(
                      ' ${listing.id.substring(0, 4)}',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Close')),
        ],
      ),
    );
  }

  // Clear all filters
  void _clearFilters() {
    final provider = Provider.of<ListingProvider>(context, listen: false);
    _searchController.clear();
    provider.resetFilters();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All filters cleared'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kigali Directory'),
        actions: [
          // Show all listings button
          IconButton(
            icon: const Icon(Icons.list, color: Colors.purple),
            onPressed: _showAllListings,
            tooltip: 'Show All Listings',
          ),
          // Clear filters button
          IconButton(
            icon: const Icon(Icons.filter_alt_off, color: Colors.red),
            onPressed: _clearFilters,
            tooltip: 'Clear Filters',
          ),
          // Debug button
          IconButton(
            icon: const Icon(Icons.bug_report, color: Colors.orange),
            onPressed: _debugFirestore,
            tooltip: 'Debug Firestore',
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blue),
            onPressed: () {
              Provider.of<ListingProvider>(
                context,
                listen: false,
              ).refreshAllListings();
            },
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
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              await authProvider.signOut();
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search listings...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          Provider.of<ListingProvider>(
                            context,
                            listen: false,
                          ).searchListings('');
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                Provider.of<ListingProvider>(
                  context,
                  listen: false,
                ).searchListings(value);
              },
            ),
          ),

          // Category filter chips
          const CategoryFilter(),

          // Current filter status
          Consumer<ListingProvider>(
            builder: (context, provider, child) {
              if (provider.selectedCategory != 'All' ||
                  provider.searchQuery.isNotEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: Colors.blue.shade50,
                  child: Text(
                    'Active Filters: ${provider.selectedCategory != 'All' ? 'Category: ${provider.selectedCategory}' : ''}${provider.searchQuery.isNotEmpty ? '${provider.selectedCategory != 'All' ? ' | ' : ''}Search: "${provider.searchQuery}"' : ''}',
                    style: TextStyle(color: Colors.blue.shade800),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Listings
          Expanded(
            child: Consumer<ListingProvider>(
              builder: (context, listingProvider, child) {
                print(
                  '🔄 DirectoryScreen building with ${listingProvider.listings.length} listings',
                );
                print(
                  '📊 Total in provider: ${listingProvider.allListings.length}',
                );
                print(
                  '📊 Selected category: ${listingProvider.selectedCategory}',
                );
                print('📊 Search query: "${listingProvider.searchQuery}"');
                print('📊 isLoading: ${listingProvider.isLoading}');

                if (listingProvider.isLoading) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading listings...'),
                      ],
                    ),
                  );
                }

                if (listingProvider.allListings.isEmpty) {
                  return Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_off,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No listings in database',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add your first listing!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  Provider.of<ListingProvider>(
                                    context,
                                    listen: false,
                                  ).refreshAllListings();
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('Refresh'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ListingFormScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Add Listing'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: _debugFirestore,
                            icon: const Icon(Icons.bug_report),
                            label: const Text('Debug Firestore'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (listingProvider.listings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.filter_alt_off,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No listings match your filters',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Total listings: ${listingProvider.allListings.length}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _clearFilters,
                          icon: const Icon(Icons.filter_alt_off),
                          label: const Text('Clear Filters'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: listingProvider.listings.length,
                  itemBuilder: (context, index) {
                    final listing = listingProvider.listings[index];
                    print('📋 Building card for: ${listing.name}');
                    return ListingCard(listing: listing);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ListingFormScreen()),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Add Listing',
      ),
    );
  }
}
