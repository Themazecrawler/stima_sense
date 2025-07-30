import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stima_sense/src/components/shared/bottom_nav_bar.dart';
import 'package:stima_sense/src/components/shared/gradient_button.dart';
import 'package:stima_sense/src/services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  int _currentIndex = 4;
  bool _isLoading = false;
  bool _isEditing = false;

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _regionController = TextEditingController();

  String? _profileImagePath;
  String? _profileImageFileName; // Store filename only
  Map<String, dynamic> _userProfile = {};

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await FirebaseService.getCurrentUserProfile();
      final currentUser = FirebaseAuth.instance.currentUser;

      if (user != null) {
        setState(() {
          _userProfile = user;
          _usernameController.text = user['username'] ?? '';
          _emailController.text = user['email'] ?? currentUser?.email ?? '';
          _regionController.text = user['region'] ?? '';
          _profileImageFileName = user['profileImageFileName'];
        });

        // Load profile image if exists
        if (_profileImageFileName != null) {
          await _loadProfileImagePath();
        }

        // Clean up orphaned images
        await _cleanupOrphanedImages();
      } else if (currentUser != null) {
        // If no profile exists, create one with current user info
        setState(() {
          _usernameController.text = currentUser.displayName ??
              currentUser.email?.split('@')[0] ??
              'User';
          _emailController.text = currentUser.email ?? '';
          _regionController.text = '';
        });
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cleanupOrphanedImages() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final directory = Directory(appDir.path);
      final files = directory.listSync();

      for (final file in files) {
        if (file is File && file.path.contains('profile_')) {
          // Check if this file is still referenced in any user profile
          final fileName = file.path.split('/').last;
          if (fileName != _profileImageFileName) {
            // This is an orphaned file, delete it
            await file.delete();
            debugPrint('Deleted orphaned profile image: $fileName');
          }
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up orphaned images: $e');
    }
  }

  Future<void> _loadProfileImagePath() async {
    if (_profileImageFileName != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final imageFile = File('${appDir.path}/$_profileImageFileName');
      if (await imageFile.exists()) {
        setState(() {
          _profileImagePath = imageFile.path;
        });
      }
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
    setState(() {
      _isLoading = true;
    });

    try {
      final profileData = {
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'region': _regionController.text.trim(),
        'profileImageFileName': _profileImageFileName,
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      await FirebaseService.updateCurrentUserProfile(profileData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _isEditing = false;
        });
        await _loadUserProfile(); // Reload to ensure persistence
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
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

  Future<void> _signOut() async {
    try {
      // Delete profile image before signing out
      await _deleteOldProfileImage();

      await FirebaseService.signOut();

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/dashboard');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/reports');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/map');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/history');
        break;
      case 4:
        // Already on account
        break;
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';

    DateTime dateTime;
    if (date is String) {
      dateTime = DateTime.parse(date);
    } else if (date is DateTime) {
      dateTime = date;
    } else {
      return 'N/A';
    }

    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Account',
          style: TextStyle(
            color: Color(0xFF8B2192),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            )
          else
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: _isLoading ? null : _saveProfile,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                    });
                    _loadUserProfile(); // Reset to original values
                  },
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile Picture
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage: _profileImagePath != null
                              ? FileImage(File(_profileImagePath!))
                              : null,
                          child: _profileImagePath == null
                              ? const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.grey,
                                )
                              : null,
                        ),
                        if (_isEditing)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              backgroundColor: const Color(0xFF8B2192),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                ),
                                onPressed: _pickImage,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Profile Information
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Profile Information',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Username
                          TextFormField(
                            controller: _usernameController,
                            enabled: _isEditing,
                            decoration: const InputDecoration(
                              labelText: 'Username',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Email
                          TextFormField(
                            controller: _emailController,
                            enabled: _isEditing,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.email),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Region
                          TextFormField(
                            controller: _regionController,
                            enabled: _isEditing,
                            decoration: const InputDecoration(
                              labelText: 'Region',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_on),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Member Since
                          ListTile(
                            title: const Text('Member Since'),
                            subtitle: Text(_formatDate(
                                _userProfile['createdAt'] ??
                                    _userProfile['lastUpdated'])),
                            leading: const Icon(Icons.calendar_today),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Account Actions
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Account Actions',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ListTile(
                            title: const Text('Change Password'),
                            subtitle: const Text('Update your password'),
                            leading: const Icon(Icons.lock),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () {
                              Navigator.pushNamed(context, '/forgot-password');
                            },
                          ),
                          ListTile(
                            title: const Text('Privacy Settings'),
                            subtitle: const Text('Manage your privacy'),
                            leading: const Icon(Icons.privacy_tip),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () {
                              // TODO: Navigate to privacy settings
                            },
                          ),
                          ListTile(
                            title: const Text('Help & Support'),
                            subtitle:
                                const Text('Get help and contact support'),
                            leading: const Icon(Icons.help),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () {
                              // TODO: Navigate to help screen
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sign Out Button
                  GradientButton(
                    onPressed: _signOut,
                    child: const Text(
                      'Sign Out',
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
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
