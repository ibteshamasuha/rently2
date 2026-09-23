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
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _rentController.dispose();
    _descController.dispose();
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
                label: 'Description & Features',
                hint: 'Details about bedrooms, balcony, tiles, generator, gas connection, etc.',
                prefixIcon: Icons.description_outlined,
                maxLines: 4,
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter a description' : null,
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
