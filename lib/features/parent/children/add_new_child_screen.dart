import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:wajd/models/child_model.dart';
import 'package:wajd/services/supabase_cleint.dart';
import '../../../app/const/colors.dart';
import '../../../providers/cheldren_provider.dart';
import 'cross_platfprm_camera.dart';

class AddChildScreen extends ConsumerStatefulWidget {
  static const routeName = '/add-child';

  const AddChildScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends ConsumerState<AddChildScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _medicalConditionsController = TextEditingController();
  final _identifyingFeaturesController = TextEditingController();

  String? _selectedGender;
  String? _selectedBloodType;
  DateTime? _selectedDate;
  XFile? _pickedImage;
  bool _isSaving = false;
  final List<String> _identifyingFeatures = [];

  final List<String> _bloodTypes = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  final List<String> _genderOptions = ['Male', 'Female'];

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
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme:  ColorScheme.light(
              primary: AppColors.primaryColor,
              onPrimary: Colors.white,
              onSurface: Color(0xFF1F2937),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        final age = (DateTime.now().difference(picked).inDays / 365).floor();
        _ageController.text = age.toString();
      });
    }
  }

  Future<void> _pickImage() async {
    final imageFile = await CrossPlatformImagePicker.pickImage(context);

    if (imageFile != null) {
      setState(() {
        _pickedImage = imageFile as XFile?;
      });
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Choose Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildImageSourceOption(
              icon: Icons.camera_alt_rounded,
              title: 'Camera',
              subtitle: 'Take a new photo',
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const SizedBox(height: 12),
            _buildImageSourceOption(
              icon: Icons.photo_library_rounded,
              title: 'Gallery',
              subtitle: 'Choose from gallery',
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.primaryColor.withOpacity(0.2),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient:  LinearGradient(
                  colors: AppColors.gradientColor,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
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
      _showSnackBar('Please select a gender', isError: true);
      return;
    }

    if (_selectedDate == null) {
      _showSnackBar('Please select birth date', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('User not logged in');

      final childId = const Uuid().v4();

      String? imageUrl;
      if (_pickedImage != null) {
        imageUrl = await ref
            .read(childrenProvider.notifier)
            .uploadChildImage(childId, File(_pickedImage!.path));
      }


      final newChild = Child(
        id: childId,
        parentId: user.id,
        name: _nameController.text.trim(),
        age: int.parse(_ageController.text),
        gender: _selectedGender!,
        // bloodType: _selectedBloodType,
        medicalConditions: _medicalConditionsController.text.trim().isNotEmpty
            ? _medicalConditionsController.text.trim()
            : null,
        description: _descriptionController.text.trim(),
        identifyingFeatures: _identifyingFeatures,
        birthDate: _selectedDate!,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
      );

      final result = await ref
          .read(childrenProvider.notifier)
          .addChild(newChild);

      if (result != null && mounted) {
        _showSnackBar('Child added successfully');
        context.pop(true);
      } else {
        throw Exception('Failed to add child');
      }
    } catch (error) {
      if (mounted) {
        _showSnackBar('Failed to add child: $error', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError
            ? const Color(0xFFEF4444)
            : AppColors.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('Add New Child'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Picture Section
              _buildProfilePictureSection(isDark, isSmallScreen),

              SizedBox(height: isSmallScreen ? 24 : 32),

              // Basic Information Section
              _buildSectionHeader('Basic Information', isSmallScreen),
              const SizedBox(height: 16),
              _buildNameField(isDark, isSmallScreen),
              const SizedBox(height: 16),
              _buildGenderSelector(isDark, isSmallScreen),
              const SizedBox(height: 16),
              _buildDateAndAge(isDark, isSmallScreen),

              SizedBox(height: isSmallScreen ? 24 : 32),

              // Medical Information Section
              _buildSectionHeader('Medical Information', isSmallScreen),
              const SizedBox(height: 16),
              // _buildBloodTypeDropdown(isDark, isSmallScreen),
              const SizedBox(height: 16),
              _buildMedicalConditionsField(isDark, isSmallScreen),

              SizedBox(height: isSmallScreen ? 24 : 32),

              // Description Section
              _buildSectionHeader('Description', isSmallScreen),
              const SizedBox(height: 16),
              _buildDescriptionField(isDark, isSmallScreen),

              SizedBox(height: isSmallScreen ? 24 : 32),

              // Identifying Features Section
              _buildSectionHeader('Identifying Features', isSmallScreen),
              const SizedBox(height: 16),
              _buildIdentifyingFeaturesSection(isDark, isSmallScreen),

              SizedBox(height: isSmallScreen ? 32 : 40),

              // Save Button
              _buildSaveButton(isSmallScreen),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePictureSection(bool isDark, bool isSmallScreen) {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: isSmallScreen ? 140 : 160,
                height: isSmallScreen ? 140 : 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient:  LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AppColors.gradientColor,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(4),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? const Color(0xFF1F2937) : Colors.white,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: _pickedImage != null
                        ? Image.file(
                            File(_pickedImage!.path),
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: AppColors.primaryColor.withOpacity(0.1),
                            child: Icon(
                              Icons.child_care_rounded,
                              size: isSmallScreen ? 60 : 70,
                              color: AppColors.primaryColor,
                            ),
                          ),
                  ),
                ),
              ),
              Positioned(
                bottom: 4,
                right: 4,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient:  LinearGradient(
                        colors: AppColors.gradientColor,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF1F2937) : Colors.white,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryColor.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Tap to add photo',
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 13,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isSmallScreen) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            gradient:  LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: AppColors.gradientColor,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: isSmallScreen ? 17 : 19,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildNameField(bool isDark, bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:AppColors.primaryColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: TextFormField(
        controller: _nameController,
        style: TextStyle(
          fontSize: isSmallScreen ? 14 : 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: 'Full Name',
          hintText: 'Enter child\'s full name',
          prefixIcon: Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient:  LinearGradient(
                colors: AppColors.gradientColor,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter child\'s name';
          }
          if (value.trim().length < 2) {
            return 'Name must be at least 2 characters';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildGenderSelector(bool isDark, bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.wc_rounded,
                color: AppColors.primaryColor,
                size: isSmallScreen ? 20 : 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Gender *',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: _genderOptions.map((gender) {
              final isSelected = _selectedGender == gender;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () => setState(() => _selectedGender = gender),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ?  LinearGradient(
                                colors: AppColors.gradientColor,
                              )
                            : null,
                        color: isSelected ? null : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : AppColors.primaryColor.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            gender == 'Male'
                                ? Icons.male_rounded
                                : gender == 'Female'
                                ? Icons.female_rounded
                                : Icons.transgender_rounded,
                            color: isSelected
                                ? Colors.white
                                : AppColors.primaryColor,
                            size: isSmallScreen ? 18 : 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            gender,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 13 : 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateAndAge(bool isDark, bool isSmallScreen) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primaryColor.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: TextFormField(
              controller: TextEditingController(
                text: _selectedDate != null
                    ? DateFormat('MMM dd, yyyy').format(_selectedDate!)
                    : '',
              ),
              readOnly: true,
              onTap: () => _selectDate(context),
              decoration: InputDecoration(
                labelText: 'Birth Date *',
                hintText: 'Select date',
                prefixIcon: Container(
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient:  LinearGradient(
                      colors: AppColors.gradientColor,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.calendar_today_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primaryColor.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: TextFormField(
              controller: _ageController,
              readOnly: true,
              style: const TextStyle(fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Age',
                prefixIcon: Container(
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient:  LinearGradient(
                      colors: AppColors.gradientColor,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.cake_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                suffix: Text(
                  'years',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Widget _buildBloodTypeDropdown(bool isDark, bool isSmallScreen) {
  //   return Container(
  //     decoration: BoxDecoration(
  //       borderRadius: BorderRadius.circular(14),
  //       border: Border.all(
  //         color: AppColors.primaryColor.withOpacity(0.3),
  //         width: 1.5,
  //       ),
  //     ),
  //     child: DropdownButtonFormField<String>(
  //       value: _selectedBloodType,
  //       decoration: InputDecoration(
  //         labelText: 'Blood Type (Optional)',
  //         hintText: 'Select blood type',
  //         prefixIcon: Container(
  //           margin: const EdgeInsets.all(10),
  //           padding: const EdgeInsets.all(8),
  //           decoration: BoxDecoration(
  //             gradient: const LinearGradient(
  //               colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
  //             ),
  //             borderRadius: BorderRadius.circular(10),
  //           ),
  //           child: const Icon(
  //             Icons.bloodtype_rounded,
  //             color: Colors.white,
  //             size: 20,
  //           ),
  //         ),
  //         border: InputBorder.none,
  //         contentPadding: const EdgeInsets.symmetric(
  //           horizontal: 16,
  //           vertical: 16,
  //         ),
  //       ),
  //       items: _bloodTypes.map((type) {
  //         return DropdownMenuItem(value: type, child: Text(type));
  //       }).toList(),
  //       onChanged: (value) => setState(() => _selectedBloodType = value),
  //     ),
  //   );
  // }

  Widget _buildMedicalConditionsField(bool isDark, bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:AppColors.primaryColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: TextFormField(
        controller: _medicalConditionsController,
        maxLines: 3,
        decoration: InputDecoration(
          labelText: 'Medical Conditions (Optional)',
          hintText: 'Any allergies, conditions, or special needs',
          prefixIcon: Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.medical_services_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionField(bool isDark, bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: TextFormField(
        controller: _descriptionController,
        maxLines: 4,
        style: TextStyle(fontSize: isSmallScreen ? 14 : 15),
        decoration: InputDecoration(
          labelText: 'Description',
          hintText: 'Tell us more about your child...',
          prefixIcon: Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient:  LinearGradient(
                colors: AppColors.gradientColor,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.description_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter a description';
          }
          if (value.trim().length < 10) {
            return 'Description must be at least 10 characters';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildIdentifyingFeaturesSection(bool isDark, bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: TextFormField(
                    controller: _identifyingFeaturesController,
                    decoration: InputDecoration(
                      hintText: 'e.g., Birthmark on left arm',
                      hintStyle: TextStyle(
                        fontSize: isSmallScreen ? 13 : 14,
                        color: Colors.grey[400],
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onFieldSubmitted: (_) => _addIdentifyingFeature(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  gradient:  LinearGradient(
                    colors: AppColors.gradientColor,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: _addIdentifyingFeature,
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
          if (_identifyingFeatures.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _identifyingFeatures.map((feature) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient:  LinearGradient(
                      colors: AppColors.gradientColor,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryColor.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        feature,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 12 : 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _removeIdentifyingFeature(feature),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSaveButton(bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        gradient:  LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.gradientColor,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 16 : 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_circle_rounded, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Add Child',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
