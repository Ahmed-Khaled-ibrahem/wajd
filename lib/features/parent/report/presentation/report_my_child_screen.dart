import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:wajd/models/child_model.dart';
import 'package:wajd/models/report_model.dart';
import 'package:wajd/services/supabase_cleint.dart';
import '../../../../app/const/colors.dart';
import '../../../../providers/cheldren_provider.dart';
import '../../../../providers/report_provider.dart';

class ReportMyChildScreen extends ConsumerStatefulWidget {
  const ReportMyChildScreen({super.key});

  @override
  ConsumerState<ReportMyChildScreen> createState() =>
      _ReportMyChildScreenState();
}

class _ReportMyChildScreenState extends ConsumerState<ReportMyChildScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _additionalNotesController = TextEditingController();
  final _lastSeenLocationController = TextEditingController();

  Child? _selectedChild;
  XFile? _recentPhoto;
  Position? _currentPosition;
  DateTime _lastSeenTime = DateTime.now();
  bool _isLoadingLocation = false;
  bool _isSubmitting = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChildren();
      _getCurrentLocation();
    });
  }

  Future<void> _loadChildren() async {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      await ref.read(childrenProvider.notifier).fetchUserChildren(user.id);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _additionalNotesController.dispose();
    _lastSeenLocationController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        final enableService = await _showLocationServiceDialog();
        if (enableService == true) {
          await Geolocator.openLocationSettings();
          serviceEnabled = await Geolocator.isLocationServiceEnabled();
        }
        if (!serviceEnabled) {
          _showSnackBar('Location services are required', isError: true);
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar('Location permissions are required', isError: true);
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        final openSettings = await _showPermissionDialog();
        if (openSettings == true) {
          await Geolocator.openAppSettings();
        }
        setState(() => _isLoadingLocation = false);
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _lastSeenLocationController.text =
              'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}';
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error getting location: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  Future<bool?> _showLocationServiceDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.location_off_rounded,
                color: Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Location Services')),
          ],
        ),
        content: const Text(
          'Please enable location services to report your missing child.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor:AppColors.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showPermissionDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Permission Required')),
          ],
        ),
        content: const Text(
          'Location permission is required to report a missing child. Please enable it in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final source = await _showImageSourceDialog();
    if (source == null) return;

    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1200,
    );

    if (pickedFile != null) {
      setState(() {
        _recentPhoto = pickedFile;
      });
    }
  }

  Future<ImageSource?> _showImageSourceDialog() {
    return showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Choose Photo Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildImageSourceOption(
              icon: Icons.camera_alt_rounded,
              title: 'Camera',
              subtitle: 'Take a recent photo',
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

  Future<void> _selectLastSeenTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _lastSeenTime,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme:  ColorScheme.light(
              primary: AppColors.primaryColor,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_lastSeenTime),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme:  ColorScheme.light(
                primary: AppColors.primaryColor,
                onPrimary: Colors.white,
              ),
            ),
            child: child!,
          );
        },
      );

      if (time != null) {
        setState(() {
          _lastSeenTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedChild == null) {
      _showSnackBar('Please select a child', isError: true);
      return;
    }

    // if (_recentPhoto == null) {
    //   _showSnackBar('Please take a recent photo', isError: true);
    //   return;
    // }

    if (_currentPosition == null) {
      _showSnackBar(
        'Location is required. Please enable location services.',
        isError: true,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('User not logged in');

      final reportId = const Uuid().v4();

      // Upload recent photo
      String? imageUrl;
      if (_recentPhoto != null) {
        imageUrl = await ref
            .read(reportsProvider.notifier)
            .uploadReportImage(reportId, File(_recentPhoto!.path));
      }

      // Create report
      final report = Report(
        id: reportId,
        reporterId: user.id,
        childId: _selectedChild!.id,
        status: ReportStatus.open,
        childName: _selectedChild!.name,
        childAge: _selectedChild!.age,
        childGender: _selectedChild!.gender,
        childDescription: _descriptionController.text.trim(),
        lastSeenLocation: _lastSeenLocationController.text.trim(),
        lastSeenTime: _lastSeenTime,
        childImageUrl: imageUrl ?? _selectedChild!.imageUrl,
        reporterPhone: user.phone ?? '',
        reporterEmail: user.email,
        additionalNotes: _additionalNotesController.text.trim().isNotEmpty
            ? _additionalNotesController.text.trim()
            : null,
        isChildRegistered: true,
        createdAt: DateTime.now(),
        metadata: {
          'latitude': _currentPosition!.latitude,
          'longitude': _currentPosition!.longitude,
          'accuracy': _currentPosition!.accuracy,
        },
      );

      final result = await ref
          .read(reportsProvider.notifier)
          .createReport(report);

      if (result != null && mounted) {
        _showSnackBar('Report submitted successfully');

        // Show success dialog
        await _showSuccessDialog(result);

        if (mounted) {
          context.pop(true);
        }
      } else {
        throw Exception('Failed to create report');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to submit report: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _showSuccessDialog(Report report) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient:  LinearGradient(
                  colors: AppColors.gradientColor,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Report Submitted',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Report ID: ${report.id.substring(0, 8)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your report has been submitted. Our team will start searching immediately.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
    final childrenAsync = ref.watch(childrenProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('Report Missing Child'),
        centerTitle: true,
      ),
      body: childrenAsync.when(
        loading: () =>  Center(
          child: CircularProgressIndicator(color: AppColors.primaryColor),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Color(0xFFEF4444),
              ),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadChildren,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (children) {
          if (children.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryColor.withOpacity(0.1),
                            AppColors.primaryColor.withOpacity(0.05),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child:  Icon(
                        Icons.child_care_rounded,
                        size: 64,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No Children Registered',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please add your children first before reporting',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/add-child'),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add Child'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Warning Banner
                  _buildWarningBanner(isSmallScreen),

                  const SizedBox(height: 24),

                  // Child Selection
                  _buildSectionHeader('Select Child', isSmallScreen),
                  const SizedBox(height: 16),
                  _buildChildSelector(children, isSmallScreen, isDark),

                  const SizedBox(height: 24),

                  // Recent Photo
                  _buildSectionHeader('Recent Photo *', isSmallScreen),
                  const SizedBox(height: 16),
                  _buildPhotoSection(isSmallScreen, isDark),

                  const SizedBox(height: 24),

                  // Last Seen Information
                  _buildSectionHeader('Last Seen Information', isSmallScreen),
                  const SizedBox(height: 16),
                  _buildLastSeenTimeField(isSmallScreen, isDark),
                  const SizedBox(height: 16),
                  _buildLocationField(isSmallScreen, isDark),

                  const SizedBox(height: 24),

                  // Description
                  _buildSectionHeader('Description *', isSmallScreen),
                  const SizedBox(height: 16),
                  _buildDescriptionField(isSmallScreen, isDark),

                  const SizedBox(height: 24),

                  // Additional Notes
                  _buildSectionHeader('Additional Notes', isSmallScreen),
                  const SizedBox(height: 16),
                  _buildAdditionalNotesField(isSmallScreen, isDark),

                  const SizedBox(height: 32),

                  // Submit Button
                  _buildSubmitButton(isSmallScreen),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWarningBanner(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'URGENT',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 13 : 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Time is critical. Please provide accurate information.',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 11 : 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
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

  Widget _buildChildSelector(
    List<Child> children,
    bool isSmallScreen,
    bool isDark,
  ) {
    return SizedBox(
      height: isSmallScreen ? 140 : 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: children.length,
        itemBuilder: (context, index) {
          final child = children[index];
          final isSelected = _selectedChild?.id == child.id;

          return GestureDetector(
            onTap: () => setState(() => _selectedChild = child),
            child: Container(
              width: isSmallScreen ? 120 : 140,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                gradient: isSelected
                    ?  LinearGradient(
                        colors: AppColors.gradientColor,
                      )
                    : null,
                color: isSelected
                    ? null
                    : (isDark ? const Color(0xFF1F2937) : Colors.white),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : AppColors.primaryColor.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: AppColors.primaryColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: isSmallScreen ? 28 : 32,
                    backgroundImage: child.imageUrl != null
                        ? NetworkImage(child.imageUrl!)
                        : null,
                    backgroundColor: isSelected
                        ? Colors.white.withOpacity(0.2)
                        : AppColors.primaryColor.withOpacity(0.1),
                    child: child.imageUrl == null
                        ? Icon(
                            Icons.child_care_rounded,
                            size: isSmallScreen ? 24 : 28,
                            color: isSelected
                                ? Colors.white
                                : AppColors.primaryColor,
                          )
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    child.name,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 13 : 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : AppColors.primaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${child.age} years',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 11 : 12,
                      color: isSelected
                          ? Colors.white.withOpacity(0.9)
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhotoSection(bool isSmallScreen, bool isDark) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: isSmallScreen ? 180 : 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primaryColor.withOpacity(0.3),
            width: 2,
          ),
          color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF9FAFB),
        ),
        child: _recentPhoto != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(
                      File(_recentPhoto!.path),
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        onPressed: () => setState(() => _recentPhoto = null),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient:  LinearGradient(
                        colors: AppColors.gradientColor,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_a_photo_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tap to add recent photo',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Photo helps identify your child',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLastSeenTimeField(bool isSmallScreen, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: ListTile(
        onTap: _selectLastSeenTime,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient:  LinearGradient(
              colors: AppColors.gradientColor,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.access_time_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        title: const Text(
          'Last Seen Time',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          DateFormat('MMM dd, yyyy - hh:mm a').format(_lastSeenTime),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
        trailing:  Icon(
          Icons.edit_calendar_rounded,
          color: AppColors.primaryColor,
        ),
      ),
    );
  }

  Widget _buildLocationField(bool isSmallScreen, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          TextFormField(
            controller: _lastSeenLocationController,
            decoration: InputDecoration(
              labelText: 'Last Seen Location *',
              hintText: 'e.g., Near City Mall, Main Street',
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
                  Icons.location_on_rounded,
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
                return 'Please enter last seen location';
              }
              return null;
            },
          ),
          if (_isLoadingLocation)
             Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Getting current location...',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            )
          else if (_currentPosition != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
              ),
              child: Row(
                children: [
                   Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: AppColors.primaryColor,
                  ),
                  const SizedBox(width: 8),
                   Expanded(
                    child: Text(
                      'Location captured',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _getCurrentLocation,
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDescriptionField(bool isSmallScreen, bool isDark) {
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
        decoration: InputDecoration(
          labelText: 'What was the child wearing? Any distinctive features?',
          hintText: 'e.g., Blue shirt, red shoes, carrying a backpack...',
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
            return 'Please provide a description';
          }
          if (value.trim().length < 10) {
            return 'Please provide more details (min 10 characters)';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildAdditionalNotesField(bool isSmallScreen, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: TextFormField(
        controller: _additionalNotesController,
        maxLines: 3,
        decoration: InputDecoration(
          labelText: 'Any other information (optional)',
          hintText: 'Additional details that might help...',
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
              Icons.notes_rounded,
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

  Widget _buildSubmitButton(bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitReport,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 16 : 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isSubmitting
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
                  const Icon(Icons.report_problem_rounded, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    'SUBMIT URGENT REPORT',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 15 : 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
