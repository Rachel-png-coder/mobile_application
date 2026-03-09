import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/listing_provider.dart';

class CategoryFilter extends StatelessWidget {
  const CategoryFilter({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ListingProvider>(
      builder: (context, provider, child) {
        // Get all unique categories from actual listings
        final allListings = provider.listings;
        final Set<String> availableCategories = {};

        for (var listing in allListings) {
          availableCategories.add(listing.category);
        }

        // Convert to list and sort
        final categories = ['All', ...availableCategories.toList()..sort()];

        return Container(
          height: 50,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = provider.selectedCategory == category;

              // Count listings in this category
              final count = category == 'All'
                  ? allListings.length
                  : allListings.where((l) => l.category == category).length;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text('$category ($count)'),
                  selected: isSelected,
                  onSelected: (selected) {
                    provider.filterByCategory(category);
                  },
                  backgroundColor: Colors.grey.shade100,
                  selectedColor: Colors.blue,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  showCheckmark: false,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
