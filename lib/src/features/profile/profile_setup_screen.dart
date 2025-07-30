import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:stima_sense/src/services/firebase_service.dart';
import 'package:stima_sense/src/components/shared/gradient_button.dart';
import 'dart:io'; // Added for File
import 'package:firebase_auth/firebase_auth.dart'; // Added for FirebaseAuth
import 'package:path_provider/path_provider.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _regionController = TextEditingController();

  String? _profileImagePath;
  String? _profileImageFileName; // Store filename only
  bool _isLoading = false;
  bool _locationPermissionGranted = false;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _initializeProfile();
    _checkLocationPermission();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  void _initializeProfile() {
    final user = FirebaseService.getCurrentUser();
    if (user != null) {
      _usernameController.text =
          user.displayName ?? user.email?.split('@')[0] ?? 'User';
    }
  }

  Future<void> _checkLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        setState(() {
          _locationPermissionGranted = true;
        });
        await _getCurrentLocation();
      }
    } catch (e) {
      debugPrint('Location permission error: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
      });

      // Get region from coordinates (simplified - you might want to use a geocoding service)
      _regionController.text = 'Nairobi'; // Default for now
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  Future<void> _deleteOldProfileImage() async {
    if (_profileImageFileName != null) {
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final oldImageFile = File('${appDir.path}/$_profileImageFileName');
        if (await oldImageFile.exists()) {
          await oldImageFile.delete();
          debugPrint('Deleted old profile image: $_profileImageFileName');
        }
      } catch (e) {
        debugPrint('Error deleting old profile image: $e');
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        // Delete old image first
        await _deleteOldProfileImage();

        // Copy new image to app's permanent storage
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedImage = File('${appDir.path}/$fileName');

        await savedImage.writeAsBytes(await image.readAsBytes());

        setState(() {
          _profileImagePath = savedImage.path;
          _profileImageFileName = fileName;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final profileData = {
        'username': _usernameController.text,
        'email': user?.email ?? '',
        'region': _regionController.text,
        'profileImageFileName': _profileImageFileName,
        'locationPermission': _locationPermissionGranted,
        'latitude': _currentPosition?.latitude,
        'longitude': _currentPosition?.longitude,
        'setupCompleted': true,
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      await FirebaseService.createUserProfile(profileData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile setup completed!')),
        );
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF8B2192),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text(
                    'Complete Your Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Help us personalize your experience',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            // Form
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Picture
                        Center(
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey.shade200,
                                    border: Border.all(
                                      color: const Color(0xFF8B2192),
                                      width: 3,
                                    ),
                                  ),
                                  child: _profileImagePath != null
                                      ? ClipOval(
                                          child: Image.file(
                                            File(_profileImagePath!),
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.person,
                                          size: 60,
                                          color: Colors.grey,
                                        ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: _pickImage,
                                child: const Text(
                                  'Add Profile Picture',
                                  style: TextStyle(
                                    color: Color(0xFF8B2192),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Username
                        const Text(
                          'Username',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Enter your username',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a username';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Region
                        const Text(
                          'Region',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _regionController,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: 'Enter your region',
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your region';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: _locationPermissionGranted
                                  ? _getCurrentLocation
                                  : _checkLocationPermission,
                              icon: const Icon(Icons.my_location),
                              label: const Text('Auto'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _locationPermissionGranted
                                    ? const Color(0xFF8B2192)
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Location Permission Info
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _locationPermissionGranted
                                    ? Icons.check_circle
                                    : Icons.info,
                                color: _locationPermissionGranted
                                    ? Colors.green
                                    : Colors.blue,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _locationPermissionGranted
                                      ? 'Location access granted. We\'ll use this to provide personalized alerts.'
                                      : 'Enable location access for personalized outage alerts in your area.',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Save Button
                        GradientButton(
                          onPressed: _isLoading ? null : _saveProfile,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Complete Setup',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
