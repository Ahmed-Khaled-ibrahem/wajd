import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wajd/features/parent/children/providers/children_provider.dart';
import 'package:wajd/models/child_model.dart';

class EditChildScreen extends ConsumerStatefulWidget {
  static const routeName = '/edit-child';

  const EditChildScreen({Key? key}) : super(key: key);

  @override
  _EditChildScreenState createState() => _EditChildScreenState();
}

class _EditChildScreenState extends ConsumerState<EditChildScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _medicalConditionsController = TextEditingController();
  final _identifyingFeaturesController = TextEditingController();
  
  late Child _editingChild;
  String? _selectedGender;
  String? _selectedBloodType;
  DateTime? _selectedDate;
  XFile? _pickedImage;
  bool _isLoading = false;
  bool _isSaving = false;
  final List<String> _identifyingFeatures = [];
  String? _currentImageUrl;

  final List<String> _bloodTypes = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  @override
  void initState() {
    super.initState();
    // Get the child data from the arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final child = ModalRoute.of(context)!.settings.arguments as Child;
      _editingChild = child;
      _currentImageUrl = child.imageUrl;
      _nameController.text = child.name;
      _ageController.text = child.age.toString();
      _descriptionController.text = child.description;
      _medicalConditionsController.text = child.medicalConditions ?? '';
      _selectedGender = child.gender;
      _selectedBloodType = child.bloodType;
      _selectedDate = child.birthDate;
      _identifyingFeatures.addAll(child.identifyingFeatures);
      
      setState(() {}); // Trigger a rebuild after setting all the data
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _descriptionController.dispose();
    _medicalConditionsController.dispose();
    _identifyingFeaturesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        // Update age based on birth date
        final age = (DateTime.now().difference(picked).inDays / 365).floor();
        _ageController.text = age.toString();
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );

    if (pickedImage != null) {
      setState(() {
        _pickedImage = pickedImage;
        _currentImageUrl = null; // Clear the current URL when a new image is picked
      });
    }
  }

  void _addIdentifyingFeature() {
    final feature = _identifyingFeaturesController.text.trim();
    if (feature.isNotEmpty && !_identifyingFeatures.contains(feature)) {
      setState(() {
        _identifyingFeatures.add(feature);
        _identifyingFeaturesController.clear();
      });
    }
  }

  void _removeIdentifyingFeature(String feature) {
    setState(() {
      _identifyingFeatures.remove(feature);
    });
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedGender == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a gender')),
        );
      }
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Create an updated child object
      final updatedChild = _editingChild.copyWith(
        name: _nameController.text,
        age: int.parse(_ageController.text),
        gender: _selectedGender!,
        bloodType: _selectedBloodType,
        medicalConditions: _medicalConditionsController.text.isNotEmpty 
            ? _medicalConditionsController.text 
            : null,
        description: _descriptionController.text,
        identifyingFeatures: _identifyingFeatures,
        birthDate: _selectedDate,
        updatedAt: DateTime.now(),
      );

      // Get the repository from Riverpod
      final repository = ref.read(childrenRepositoryProvider);
      
      // If there's a new image, upload it first
      String? imageUrl = _currentImageUrl;
      if (_pickedImage != null) {
        // TODO: Implement image upload logic
        // imageUrl = await repository.uploadImage(_pickedImage!);
      }
      
      // Update child with new image URL if available
      final childWithImage = imageUrl != null 
          ? updatedChild.copyWith(imageUrl: imageUrl)
          : updatedChild;
      
      // Update the child in the repository
      await repository.updateChild(_editingChild.id, childWithImage);
      
      // Invalidate the children provider to refresh the list
      ref.invalidate(childrenProvider);
      
      if (mounted) {
        Navigator.of(context).pop(true); // Return success
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update child: $error')),
        );
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Child Profile'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveForm,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Picture
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: _pickedImage != null
                              ? FileImage(File(_pickedImage!.path)) as ImageProvider
                              : _currentImageUrl != null
                                  ? NetworkImage(_currentImageUrl!)
                                  : null,
                          child: _pickedImage == null && _currentImageUrl == null
                              ? const Icon(
                                  Icons.camera_alt,
                                  size: 40,
                                  color: Colors.grey,
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Gender Radio Buttons
                    const Text('Gender', style: TextStyle(fontSize: 16)),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Male'),
                            value: 'Male',
                            groupValue: _selectedGender,
                            onChanged: (value) {
                              setState(() {
                                _selectedGender = value;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Female'),
                            value: 'Female',
                            groupValue: _selectedGender,
                            onChanged: (value) {
                              setState(() {
                                _selectedGender = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    // Birth Date and Age
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: TextEditingController(
                              text: _selectedDate != null
                                  ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                  : 'Select date',
                            ),
                            readOnly: true,
                            onTap: () => _selectDate(context),
                            decoration: const InputDecoration(
                              labelText: 'Birth Date',
                              prefixIcon: Icon(Icons.calendar_today),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Age',
                              prefixIcon: Icon(Icons.numbers),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter age';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Blood Type Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedBloodType,
                      decoration: const InputDecoration(
                        labelText: 'Blood Type (Optional)',
                        prefixIcon: Icon(Icons.bloodtype),
                        border: OutlineInputBorder(),
                      ),
                      items: _bloodTypes
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedBloodType = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Medical Conditions
                    TextFormField(
                      controller: _medicalConditionsController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Medical Conditions (Optional)',
                        hintText: 'Any allergies, conditions, or special needs',
                        prefixIcon: Icon(Icons.medical_services),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Tell us more about your child',
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Identifying Features
                    const Text('Identifying Features', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _identifyingFeaturesController,
                            decoration: InputDecoration(
                              labelText: 'Add identifying feature',
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: _addIdentifyingFeature,
                              ),
                            ),
                            onFieldSubmitted: (_) => _addIdentifyingFeature(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _identifyingFeatures
                          .map(
                            (feature) => Chip(
                              label: Text(feature),
                              onDeleted: () => _removeIdentifyingFeature(feature),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveForm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator()
                          : const Text('Save Changes'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
