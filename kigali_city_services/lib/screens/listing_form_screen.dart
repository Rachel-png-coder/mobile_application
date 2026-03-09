import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // ADD THIS
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/listing_model.dart';
import '../providers/listing_provider.dart';

class ListingFormScreen extends StatefulWidget {
  final Listing? listing;

  const ListingFormScreen({super.key, this.listing});

  @override
  State<ListingFormScreen> createState() => _ListingFormScreenState();
}

class _ListingFormScreenState extends State<ListingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _contactController;
  late TextEditingController _descriptionController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  String _selectedCategory = Listing.categories[1];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.listing?.name ?? '');
    _addressController = TextEditingController(
      text: widget.listing?.address ?? '',
    );
    _contactController = TextEditingController(
      text: widget.listing?.contactNumber ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.listing?.description ?? '',
    );
    _latitudeController = TextEditingController(
      text: widget.listing?.latitude.toString() ?? '',
    );
    _longitudeController = TextEditingController(
      text: widget.listing?.longitude.toString() ?? '',
    );
    if (widget.listing != null) {
      _selectedCategory = widget.listing!.category;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    _descriptionController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  String _cleanCoordinate(String input) {
    String cleaned = input
        .replaceAll('°', '')
        .replaceAll(RegExp(r'[NSEWnsew]'), '')
        .trim();
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), '');
    return cleaned;
  }

  Future<void> _saveListing() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to save listings'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      // Clean the coordinate inputs
      String latitudeText = _cleanCoordinate(_latitudeController.text);
      String longitudeText = _cleanCoordinate(_longitudeController.text);

      double latitude = double.parse(latitudeText);
      double longitude = double.parse(longitudeText);

      final listing = Listing(
        id: widget.listing?.id ?? '',
        name: _nameController.text.trim(),
        category: _selectedCategory,
        address: _addressController.text.trim(),
        contactNumber: _contactController.text.trim(),
        description: _descriptionController.text.trim(),
        latitude: latitude,
        longitude: longitude,
        createdBy: user.uid,
        timestamp: widget.listing?.timestamp ?? DateTime.now(),
      );

      final listingProvider = Provider.of<ListingProvider>(
        context,
        listen: false,
      );

      bool success;
      if (widget.listing == null) {
        success = await listingProvider.createListing(listing);
      } else {
        success = await listingProvider.updateListing(
          widget.listing!.id,
          listing.toMap(),
        );
      }

      setState(() => _isLoading = false);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.listing == null
                  ? 'Listing created successfully!'
                  : 'Listing updated successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              listingProvider.errorMessage ?? 'Failed to save a listing',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.listing == null ? 'Add Listing' : 'Edit Listing'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Place/Service Name',
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category),
                ),
                items: Listing.categories.where((c) => c != 'All').map((
                  category,
                ) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(
                  labelText: 'Contact Number',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a contact number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latitudeController,
                      decoration: const InputDecoration(
                        labelText: 'Latitude',
                        prefixIcon: Icon(Icons.pin_drop),
                        hintText: 'e.g. -1.9441',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        String cleaned = _cleanCoordinate(value);
                        if (cleaned.isEmpty) {
                          return 'Invalid format';
                        }
                        if (double.tryParse(cleaned) == null) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _longitudeController,
                      decoration: const InputDecoration(
                        labelText: 'Longitude',
                        prefixIcon: Icon(Icons.pin_drop),
                        hintText: 'e.g. 30.0619',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        String cleaned = _cleanCoordinate(value);
                        if (cleaned.isEmpty) {
                          return 'Invalid format';
                        }
                        if (double.tryParse(cleaned) == null) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading ? null : _saveListing,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(
                        widget.listing == null
                            ? 'Create Listing'
                            : 'Update Listing',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
