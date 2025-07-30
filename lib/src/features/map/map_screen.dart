import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:stima_sense/src/components/shared/bottom_nav_bar.dart';
import 'package:stima_sense/src/services/firebase_service.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  int _currentIndex = 2;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  bool _isLoading = true;
  Map<String, dynamic> _statistics = {};
  Set<String> _selectedFilters = {'current', 'predicted', 'restored'};
  LatLng? _userLocation;
  bool _locationPermissionGranted = false;

  // Sample outage data - replace with real data from Firebase
  final List<Map<String, dynamic>> _outages = [
    {
      'id': '1',
      'type': 'current',
      'title': 'Current Outage',
      'description': 'Power outage in Westlands area',
      'position': const LatLng(-1.2921, 36.8219), // Nairobi coordinates
      'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
      'status': 'active',
    },
    {
      'id': '2',
      'type': 'predicted',
      'title': 'Predicted Outage',
      'description': 'High risk of outage in Kilimani area',
      'position': const LatLng(-1.3000, 36.8000),
      'timestamp': DateTime.now().add(const Duration(hours: 1)),
      'status': 'predicted',
      'confidence': 85,
    },
    {
      'id': '3',
      'type': 'restored',
      'title': 'Restored Power',
      'description': 'Power restored in Kileleshwa area',
      'position': const LatLng(-1.2800, 36.8200),
      'timestamp': DateTime.now().subtract(const Duration(hours: 1)),
      'status': 'restored',
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _loadOutages();
    _loadStatistics();
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
        _userLocation = LatLng(position.latitude, position.longitude);
      });

      // Move camera to user location
      if (_mapController != null && _userLocation != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_userLocation!, 15),
        );
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      // Fallback to Nairobi coordinates
      setState(() {
        _userLocation = const LatLng(-1.2921, 36.8219);
      });
    }
  }

  Future<void> _loadOutages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load real outages from Firebase
      final outagesStream = FirebaseService.getOutagesStream();
      outagesStream.listen((snapshot) {
        final markers = <Marker>{};

        // Add user location marker if available
        if (_userLocation != null) {
          markers.add(
            Marker(
              markerId: const MarkerId('user_location'),
              position: _userLocation!,
              infoWindow: const InfoWindow(
                title: 'Your Location',
                snippet: 'You are here',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueBlue),
            ),
          );
        }

        // Add sample markers for now
        for (final outage in _outages) {
          if (_selectedFilters.contains(outage['type'])) {
            final marker = Marker(
              markerId: MarkerId(outage['id']),
              position: outage['position'],
              infoWindow: InfoWindow(
                title: outage['title'],
                snippet: outage['description'],
              ),
              icon: _getMarkerIcon(outage['type']),
            );
            markers.add(marker);
          }
        }

        setState(() {
          _markers = markers;
          _isLoading = false;
        });
      });
    } catch (e) {
      debugPrint('Error loading outages: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStatistics() async {
    try {
      // Mock statistics - replace with real data
      setState(() {
        _statistics = {
          'totalOutages': 5,
          'activeOutages': 2,
          'predictedOutages': 1,
          'restoredOutages': 2,
          'affectedAreas': 3,
          'totalReports': 12,
        };
      });
    } catch (e) {
      debugPrint('Error loading statistics: $e');
    }
  }

  BitmapDescriptor _getMarkerIcon(String type) {
    switch (type) {
      case 'current':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case 'predicted':
        return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange);
      case 'restored':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      default:
        return BitmapDescriptor.defaultMarker;
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
        // Already on map
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/history');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/account');
        break;
    }
  }

  void _showOutageReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Outage'),
        content: const Text('Would you like to report an outage in this area?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/reports');
            },
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filter Outages'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    title: const Text('Current Outages'),
                    value: _selectedFilters.contains('current'),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedFilters.add('current');
                        } else {
                          _selectedFilters.remove('current');
                        }
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Predicted Outages'),
                    value: _selectedFilters.contains('predicted'),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedFilters.add('predicted');
                        } else {
                          _selectedFilters.remove('predicted');
                        }
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Restored Outages'),
                    value: _selectedFilters.contains('restored'),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedFilters.add('restored');
                        } else {
                          _selectedFilters.remove('restored');
                        }
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _applyFilters();
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  void _applyFilters() {
    setState(() {
      _markers = _markers.where((marker) {
        final outage = _outages.firstWhere(
          (o) => o['id'] == marker.markerId.value,
        );
        return _selectedFilters.contains(outage['type']);
      }).toSet();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Outage Map',
          style: TextStyle(
            color: Color(0xFF8B2192),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Map
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                GoogleMap(
                  onMapCreated: (controller) {
                    _mapController = controller;
                    // Move to user location if available
                    if (_userLocation != null) {
                      controller.animateCamera(
                        CameraUpdate.newLatLngZoom(_userLocation!, 15),
                      );
                    }
                  },
                  initialCameraPosition: CameraPosition(
                    target: _userLocation ??
                        const LatLng(
                            -1.2921, 36.8219), // Nairobi or user location
                    zoom: 12,
                  ),
                  markers: _markers,
                  onTap: (position) => _showOutageReportDialog(),
                  myLocationEnabled: _locationPermissionGranted,
                  myLocationButtonEnabled: _locationPermissionGranted,
                  zoomControlsEnabled: true,
                  mapType: MapType.normal,
                ),
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),

                // Custom Location Button
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton(
                    onPressed: _getCurrentLocation,
                    backgroundColor: const Color(0xFF8B2192),
                    child: const Icon(
                      Icons.my_location,
                      color: Colors.white,
                    ),
                  ),
                ),

                // Legend
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Legend',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildLegendItem('Current', Colors.red),
                        _buildLegendItem('Predicted', Colors.orange),
                        _buildLegendItem('Restored', Colors.green),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Statistics
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Regional Statistics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Active',
                        _statistics['activeOutages']?.toString() ?? '0',
                        Colors.red,
                        Icons.flash_off,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Predicted',
                        _statistics['predictedOutages']?.toString() ?? '0',
                        Colors.orange,
                        Icons.warning,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Restored',
                        _statistics['restoredOutages']?.toString() ?? '0',
                        Colors.green,
                        Icons.check_circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Areas Affected',
                        _statistics['affectedAreas']?.toString() ?? '0',
                        Colors.blue,
                        Icons.location_on,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Reports',
                        _statistics['totalReports']?.toString() ?? '0',
                        Colors.purple,
                        Icons.report,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
