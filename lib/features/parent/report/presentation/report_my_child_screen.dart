import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';

class ReportMyChildScreen extends StatefulWidget {
  const ReportMyChildScreen({Key? key}) : super(key: key);

  @override
  _ReportMyChildScreenState createState() => _ReportMyChildScreenState();
}

class Child {
  final String name;
  final int age;
  final String? imageUrl;

  Child({required this.name, required this.age, this.imageUrl});
}

class _ReportMyChildScreenState extends State<ReportMyChildScreen> {
  final List<Child> children = [
    Child(name: 'Ahmed', age: 8, imageUrl: null),
    Child(name: 'Mariam', age: 10, imageUrl: null),
  ];

  int _currentIndex = 0;
  final TextEditingController _descriptionController = TextEditingController();
  File? _imageFile;
  Position? _currentPosition;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Show a dialog to enable location services
      bool? enableService = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Location Services Disabled'),
          content: const Text('Please enable location services to report a missing child.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('SETTINGS'),
            ),
          ],
        ),
      );

      if (enableService == true) {
        await Geolocator.openLocationSettings();
        // Re-check if service is enabled after returning from settings
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location services are still disabled')),
            );
          }
          return;
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location is required to report a missing child')),
          );
        }
        return;
      }
    }

    // Check location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are required')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // The user opted to never see the permission request dialog again
      if (mounted) {
        bool? openSettings = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Location Permission Required'),
            content: const Text(
              'Location permission is permanently denied. Please enable it in app settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('OPEN SETTINGS'),
              ),
            ],
          ),
        );

        if (openSettings == true) {
          await Geolocator.openAppSettings();
        }
      }
      return;
    }

    // If we reach here, permissions are granted and we can get the location
    try {
      Position position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _submitReport() {
    // TODO: Implement report submission
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please take a recent photo')),
      );
      return;
    }

    // TODO: Submit the report with all details
    print('Submitting report for ${children[_currentIndex].name}');
    print('Description: ${_descriptionController.text}');
    print('Location: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}');
    
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Missing Child'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Child Selection Carousel
            SizedBox(
              height: 200,
              child: PageView.builder(
                itemCount: children.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return Card(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: children[index].imageUrl != null
                              ? NetworkImage(children[index].imageUrl!)
                              : null,
                          child: children[index].imageUrl == null
                              ? const Icon(Icons.person, size: 40)
                              : null,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          children[index].name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          'Age: ${children[index].age} years',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            
            // Recent Photo Section
            const Text(
              'Recent Photo (Required)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _imageFile != null
                    ? Image.file(_imageFile!, fit: BoxFit.cover)
                    : const Center(child: Icon(Icons.add_a_photo, size: 50)),
              ),
            ),
            const SizedBox(height: 20),
            
            // Description
            const Text(
              'Description (Helpful for search)', 
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter any helpful details about when/where the child was last seen...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            
            // Location
            const Text(
              'Current Location',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: _currentPosition != null
                    ? Text(
                        'Latitude: ${_currentPosition!.latitude.toStringAsFixed(6)}\n'
                        'Longitude: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                      )
                    : const Text('Fetching location...'),
              ),
            ),
            const SizedBox(height: 30),
            
            // Submit Button
            ElevatedButton(
              onPressed: _submitReport,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'SUBMIT REPORT',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }
}
