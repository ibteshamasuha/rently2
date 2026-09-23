import 'package:flutter/material.dart';
import '../../models/apartment_model.dart';
import '../../models/user_model.dart';
import '../../services/apartment_service.dart';
import '../../widgets/custom_text_field.dart';

class AddEditApartmentScreen extends StatefulWidget {
  final UserModel currentUser;
  final ApartmentModel? apartment;

  const AddEditApartmentScreen({
    super.key,
    required this.currentUser,
    this.apartment,
  });

  @override
  State<AddEditApartmentScreen> createState() => _AddEditApartmentScreenState();
}

class _AddEditApartmentScreenState extends State<AddEditApartmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apartmentService = ApartmentService();

  late final TextEditingController _titleController;
  late final TextEditingController _locationController;
  late final TextEditingController _rentController;
  late final TextEditingController _descController;
  late String _status;
  late final Set<String> _selectedFeatures;
  late final Set<String> _selectedAmenities;
  final TextEditingController _customFeatureController = TextEditingController();
  final TextEditingController _customAmenityController = TextEditingController();

  final List<String> _commonFeatures = const [
    'Balcony',
    'Tiles Fitting',
    'Furnished',
    'Dining Space',
    'Drawing Room',
    'CCTV Monitoring',
    'Rooftop Access',
    'South Facing',
  ];

  final List<String> _commonAmenities = const [
    'Wi-Fi',
    'Dedicated Parking',
    'Lift',
    'Generator Backup',
    '24/7 Security',
    'Gas Connection',
    '24/7 Water Supply',
    'AC',
  ];

  bool _isLoading = false;

  bool get _isEditing => widget.apartment != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.apartment?.title ?? '');
    _locationController = TextEditingController(text: widget.apartment?.location ?? '');
    _rentController = TextEditingController(
      text: widget.apartment != null ? widget.apartment!.rent.toString() : '',
    );
    _descController = TextEditingController(text: widget.apartment?.description ?? '');
    _status = widget.apartment?.status ?? 'available';
    _selectedFeatures = Set<String>.from(widget.apartment?.features ?? []);
    _selectedAmenities = Set<String>.from(widget.apartment?.amenities ?? []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _rentController.dispose();
    _descController.dispose();
    _customFeatureController.dispose();
    _customAmenityController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final rentVal = num.tryParse(_rentController.text.trim());
    if (rentVal == null || rentVal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid monthly rent amount.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isEditing) {
        final updatedApt = ApartmentModel(
          id: widget.apartment!.id,
          title: _titleController.text.trim(),
          location: _locationController.text.trim(),
          rent: rentVal,
          status: _status,
          description: _descController.text.trim(),
          landlordId: widget.apartment!.landlordId,
          bedrooms: widget.apartment!.bedrooms,
          bathrooms: widget.apartment!.bathrooms,
          areaSqFt: widget.apartment!.areaSqFt,
          images: widget.apartment!.images,
          features: _selectedFeatures.toList(),
          amenities: _selectedAmenities.toList(),
          createdAt: widget.apartment!.createdAt,
        );
        await _apartmentService.updateApartment(updatedApt);
      } else {
        final newApt = ApartmentModel(
          id: '',
          title: _titleController.text.trim(),
          location: _locationController.text.trim(),
          rent: rentVal,
          status: _status,
          description: _descController.text.trim(),
          landlordId: widget.currentUser.uid,
          features: _selectedFeatures.toList(),
          amenities: _selectedAmenities.toList(),
          createdAt: DateTime.now(),
        );
        await _apartmentService.createApartment(newApt);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Apartment updated!' : 'Apartment created!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Apartment' : 'Add New Apartment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                controller: _titleController,
                label: 'Apartment Title',
                hint: 'e.g. 2 Bedroom Apartment near RUET',
                prefixIcon: Icons.home_work_outlined,
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter a title' : null,
              ),
              const SizedBox(height: 14),

              CustomTextField(
                controller: _locationController,
                label: 'Location / Address',
                hint: 'e.g. Talaimari, Rajshahi',
                prefixIcon: Icons.location_on_outlined,
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter location' : null,
              ),
              const SizedBox(height: 14),

              CustomTextField(
                controller: _rentController,
                label: 'Monthly Rent (BDT ৳)',
                hint: 'e.g. 15000',
                prefixIcon: Icons.attach_money,
                keyboardType: TextInputType.number,
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter monthly rent' : null,
              ),
              const SizedBox(height: 14),

              // Status Dropdown
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: InputDecoration(
                  labelText: 'Availability Status',
                  prefixIcon: const Icon(Icons.toggle_on_outlined),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: const [
                  DropdownMenuItem(value: 'available', child: Text('Available for Rent')),
                  DropdownMenuItem(value: 'rented', child: Text('Currently Rented')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _status = val);
                },
              ),
              const SizedBox(height: 14),

              CustomTextField(
                controller: _descController,
                label: 'Description',
                hint: 'Overview and notes about this apartment...',
                prefixIcon: Icons.description_outlined,
                maxLines: 3,
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter a description' : null,
              ),
              const SizedBox(height: 18),

              // Apartment Specific Features
              const Text(
                'Apartment Features',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Select specific features that belong to this apartment:',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...{..._commonFeatures, ..._selectedFeatures}.map((feature) {
                    final isSelected = _selectedFeatures.contains(feature);
                    return FilterChip(
                      label: Text(feature),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedFeatures.add(feature);
                          } else {
                            _selectedFeatures.remove(feature);
                          }
                        });
                      },
                    );
                  }),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customFeatureController,
                      decoration: const InputDecoration(
                        hintText: 'Add custom feature (e.g. Master Bed Attached Bath)',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final text = _customFeatureController.text.trim();
                      if (text.isNotEmpty) {
                        setState(() {
                          _selectedFeatures.add(text);
                          _customFeatureController.clear();
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    ),
                    child: const Text('Add'),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Apartment Specific Amenities
              const Text(
                'Apartment Amenities',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Select specific amenities available for this apartment:',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...{..._commonAmenities, ..._selectedAmenities}.map((amenity) {
                    final isSelected = _selectedAmenities.contains(amenity);
                    return FilterChip(
                      label: Text(amenity),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedAmenities.add(amenity);
                          } else {
                            _selectedAmenities.remove(amenity);
                          }
                        });
                      },
                    );
                  }),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customAmenityController,
                      decoration: const InputDecoration(
                        hintText: 'Add custom amenity (e.g. Solar Power)',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final text = _customAmenityController.text.trim();
                      if (text.isNotEmpty) {
                        setState(() {
                          _selectedAmenities.add(text);
                          _customAmenityController.clear();
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    ),
                    child: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        _isEditing ? 'Save Changes' : 'Create Listing',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
