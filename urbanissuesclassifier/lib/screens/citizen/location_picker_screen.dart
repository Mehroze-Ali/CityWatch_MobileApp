import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:urbanissuesclassifier/theme/app_theme.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final Completer<GoogleMapController> _controller = Completer();

  // Current user location
  LatLng? _currentPosition;

  // Center of map (what the fixed pin points to)
  LatLng _centerPosition = const LatLng(31.5204, 74.3587); // Default Lahore

  String _selectedAddress = 'Move map to select location';
  bool _isLoadingAddress = false;
  bool _isLoadingLocation = true;
  bool _isPinAnimating = false;

  // Debounce timer
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  // Initialize location with better error handling
  Future<void> _initializeLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _isLoadingLocation = false;
          });
          _showLocationServiceDialog();
        }
        return;
      }

      // Get current location
      await _getCurrentLocation();
    } catch (e) {
      print('Error initializing location: $e');
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  // Get user's current location
  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          _showPermissionDialog();
          setState(() {
            _isLoadingLocation = false;
          });
        }
        return;
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position =
            await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
              timeLimit: const Duration(seconds: 10),
            ).timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                throw TimeoutException('Location request timed out');
              },
            );

        if (mounted) {
          setState(() {
            _currentPosition = LatLng(position.latitude, position.longitude);
            _centerPosition = _currentPosition!;
            _isLoadingLocation = false;
          });

          // Move camera to current location
          final GoogleMapController controller = await _controller.future;
          await controller.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: _currentPosition!, zoom: 16.0),
            ),
          );

          // Get address for current location
          await _getAddressFromCoordinates(_currentPosition!);
        }
      }
    } catch (e) {
      print('Error getting current location: $e');
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  // Move to current location button
  Future<void> _moveToCurrentLocation() async {
    if (_currentPosition == null) {
      // Try to get location again
      setState(() {
        _isLoadingLocation = true;
      });
      await _getCurrentLocation();
      return;
    }

    // Move camera to current location
    final GoogleMapController controller = await _controller.future;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _currentPosition!, zoom: 16.0),
      ),
    );

    // Force address fetch for current location
    setState(() {
      _isLoadingAddress = true;
      _centerPosition = _currentPosition!;
    });

    // Cancel any pending debounce
    _debounceTimer?.cancel();

    // Fetch address immediately
    await _getAddressFromCoordinates(_currentPosition!);
  }

  // Get address from coordinates using reverse geocoding only
  Future<void> _getAddressFromCoordinates(LatLng position) async {
    if (!mounted) return;

    try {
      print(
        '🔍 Reverse geocoding for: ${position.latitude}, ${position.longitude}',
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 5));

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = <String>[];

        void addPart(String? value) {
          if (value == null) return;
          final trimmed = value.trim();
          if (trimmed.isEmpty) return;
          if (parts.contains(trimmed)) return;
          parts.add(trimmed);
        }

        String? street = place.street;
        if (street != null && _isPlusCode(street)) {
          // Ignore Plus Codes like "QQ78+78C"
          street = null;
        }

        addPart(street);
        addPart(place.subLocality);
        addPart(place.locality);
        addPart(place.subAdministrativeArea);
        addPart(place.administrativeArea);
        addPart(place.country);

        final address = parts.isNotEmpty
            ? parts.join(', ')
            : 'Location: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';

        if (!mounted) return;
        setState(() {
          _selectedAddress = address;
          _isLoadingAddress = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _selectedAddress =
              'Location: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      print('Reverse geocoding error: $e');
      if (!mounted) return;
      setState(() {
        _selectedAddress =
            'Location: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        _isLoadingAddress = false;
      });
    }
  }

  // Check for Plus Codes (used to filter out streets like "QQ78+78C")
  bool _isPlusCode(String address) {
    if (address.isEmpty) return false;
    return RegExp(r'^[A-Z0-9]{4,}\+[A-Z0-9]{2,}').hasMatch(address) ||
        (address.contains('+') && address.length < 15);
  }

  // Called when map camera moves
  void _onCameraMove(CameraPosition position) {
    if (mounted) {
      setState(() {
        _centerPosition = position.target;
        _isPinAnimating = true;
      });
    }
  }

  // Called when map camera stops moving
  void _onCameraIdle() {
    if (mounted) {
      setState(() {
        _isPinAnimating = false;
      });

      // Cancel previous timer
      _debounceTimer?.cancel();

      // Set loading state
      if (!_isLoadingAddress) {
        setState(() {
          _isLoadingAddress = true;
        });
      }

      // Debounce address lookup
      _debounceTimer = Timer(const Duration(milliseconds: 600), () {
        if (mounted) {
          _getAddressFromCoordinates(_centerPosition);
        }
      });
    }
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Location Services Disabled'),
        content: const Text(
          'Please enable location services to get your current location.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryTeal,
              foregroundColor: Colors.white,
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Location Permission Required'),
        content: const Text(
          'Please enable location permission in settings to use this feature.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryTeal,
              foregroundColor: Colors.white,
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _confirmLocation() {
    Navigator.pop(context, {
      'address': _selectedAddress,
      'latitude': _centerPosition.latitude,
      'longitude': _centerPosition.longitude,
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Google Map (Full Screen)
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(
              target: _centerPosition,
              zoom: 16.0,
            ),
            onMapCreated: (GoogleMapController controller) {
              if (!_controller.isCompleted) {
                _controller.complete(controller);
              }
            },
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
            markers: {},
          ),

          // Back Button (Top Left)
          Positioned(
            top: topPadding + 16,
            left: 16,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.grey[700],
                    size: 24,
                  ),
                ),
              ),
            ),
          ),

          // Center Pin (Fixed in center of screen)
          Center(
            child: Transform.translate(
              offset: Offset(0, _isPinAnimating ? -20 : -35),
              child: AnimatedScale(
                scale: _isPinAnimating ? 1.2 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.location_on,
                  size: 50,
                  color: AppTheme.primaryTeal,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Current Location Button
          Positioned(
            right: 16,
            bottom: screenHeight * 0.35,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: _moveToCurrentLocation,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.my_location_rounded,
                    color: _currentPosition != null
                        ? AppTheme.primaryTeal
                        : Colors.grey,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),

          // Address Card at Bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              margin: EdgeInsets.fromLTRB(
                16,
                0,
                16,
                bottomPadding > 0 ? bottomPadding : 16,
              ),
              padding: EdgeInsets.all(screenWidth * 0.05),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryTeal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: AppTheme.primaryTeal,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Selected Location',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 4),
                            _isLoadingAddress
                                ? Row(
                                    children: [
                                      SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                AppTheme.primaryTeal,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Getting address...',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    _selectedAddress,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF111827),
                                      height: 1.4,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoadingAddress ? null : _confirmLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryTeal,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Confirm Location',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading Overlay
          if (_isLoadingLocation)
            Container(
              color: Colors.white.withOpacity(0.9),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryTeal,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Getting your location...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
