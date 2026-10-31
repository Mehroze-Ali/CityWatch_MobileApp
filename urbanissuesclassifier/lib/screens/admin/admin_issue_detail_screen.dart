import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:map_launcher/map_launcher.dart' as map_launcher;
import 'package:urbanissuesclassifier/theme/app_theme.dart';
import 'package:urbanissuesclassifier/models/complaint_model.dart';
import 'package:urbanissuesclassifier/services/api_service.dart';
import 'package:urbanissuesclassifier/widgets/status_badge.dart';
import 'package:urbanissuesclassifier/widgets/curved_background_scaffold.dart';
import 'package:intl/intl.dart';

class AdminIssueDetailScreen extends StatefulWidget {
  const AdminIssueDetailScreen({super.key});

  @override
  State<AdminIssueDetailScreen> createState() => _AdminIssueDetailScreenState();
}

class _AdminIssueDetailScreenState extends State<AdminIssueDetailScreen> {
  final ApiService _apiService = ApiService();
  ComplaintModel? _issue;
  bool _isLoading = true;
  String? _errorMessage;

  // Map State
  GoogleMapController? _mapController;
  Position? _currentPosition;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
        _updateMapData();
      });
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  void _updateMapData() {
    if (_issue == null) return;

    final issueLatLng = LatLng(_issue!.latitude, _issue!.longitude);

    // Markers
    Set<Marker> markers = {};

    // Issue Marker
    markers.add(
      Marker(
        markerId: const MarkerId('issue_location'),
        position: issueLatLng,
        infoWindow: InfoWindow(title: _issue!.title),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );

    // Admin Location Marker
    if (_currentPosition != null) {
      final adminLatLng = LatLng(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      markers.add(
        Marker(
          markerId: const MarkerId('admin_location'),
          position: adminLatLng,
          infoWindow: const InfoWindow(title: 'Your Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );

      // Polyline (Simple straight line for visual path)
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: [adminLatLng, issueLatLng],
          color: AppTheme.primaryTeal,
          width: 4,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      };
    }

    setState(() {
      _markers = markers;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_issue == null) {
      final initialIssue =
          ModalRoute.of(context)?.settings.arguments as ComplaintModel?;
      if (initialIssue != null) {
        _issue = initialIssue;
        _fetchLatestDetails();
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Complaint not found';
        });
      }
    }
  }

  Future<void> _fetchLatestDetails() async {
    if (_issue == null) return;

    try {
      final result = await _apiService.getComplaintById(_issue!.id);
      if (mounted) {
        if (result['success']) {
          setState(() {
            _issue = result['complaint'];
            _isLoading = false;
          });
        } else {
          // If we already have initial data, don't override with error unless critical
          if (_issue == null) {
            setState(() {
              _errorMessage = result['message'];
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted && _issue == null) {
        setState(() {
          _errorMessage = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _makeProfessionalCall() async {
    final complaint = _issue;
    if (complaint == null) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryTeal),
      ),
    );

    try {
      // Fetch fresh contact details
      final result = await _apiService.getComplaintContact(complaint.id);

      // Close loading dialog
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (!result['success'] ||
          result['phone'] == null ||
          (result['phone'] as String).isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ??
                    'No phone number available for this reporter',
              ),
              backgroundColor: AppTheme.alertRed,
            ),
          );
        }
        return;
      }

      final rawPhone = result['phone'] as String;
      final formattedPhone = _formatPhoneNumber(rawPhone);
      final Uri launchUri = Uri(scheme: 'tel', path: formattedPhone);

      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot launch dialer.'),
              backgroundColor: AppTheme.alertRed,
            ),
          );
        }
      }
    } catch (e) {
      // Ensure dialog is closed on error
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to make call. Please check internet connection.',
            ),
            backgroundColor: AppTheme.alertRed,
          ),
        );
      }
    }
  }

  String _formatPhoneNumber(String phone) {
    // Remove all non-numeric characters
    final digits = phone.replaceAll(RegExp(r'\D'), '');

    // Format as NANP: +1 (XXX) XXX-XXXX
    if (digits.length == 10) {
      return '+1 (${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
    } else if (digits.length == 11 && digits.startsWith('1')) {
      return '+1 (${digits.substring(1, 4)}) ${digits.substring(4, 7)}-${digits.substring(7)}';
    }

    return phone;
  }

  Future<void> _openMapLauncher() async {
    if (_issue == null) return;

    try {
      final availableMaps = await map_launcher.MapLauncher.installedMaps;

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return SafeArea(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 5),
                      height: 5,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Start Navigation',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkBackground,
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ...availableMaps.map((map) {
                      return ListTile(
                        onTap: () {
                          map.showMarker(
                            coords: map_launcher.Coords(
                              _issue!.latitude,
                              _issue!.longitude,
                            ),
                            title: _issue!.title,
                            description: _issue!.description,
                          );
                          Navigator.pop(context);
                        },
                        title: Text(
                          map.mapName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        leading: Image.asset(
                          map.icon, // This comes from the package asset
                          height: 30,
                          width: 30,
                          errorBuilder: (ctx, err, stack) =>
                              const Icon(Icons.map),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: Colors.grey,
                        ),
                      );
                    }),
                    if (availableMaps.isEmpty)
                      ListTile(
                        onTap: () async {
                          // Fallback to browser
                          final url =
                              'https://www.google.com/maps/search/?api=1&query=${_issue!.latitude},${_issue!.longitude}';
                          if (await canLaunchUrl(Uri.parse(url))) {
                            await launchUrl(Uri.parse(url));
                          }
                          Navigator.pop(context);
                        },
                        title: const Text('Open in Browser'),
                        leading: const Icon(
                          Icons.public,
                          color: AppTheme.primaryTeal,
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } catch (e) {
      print(e);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error launching maps: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _issue == null) {
      return const CurvedBackgroundScaffold(
        title: 'Loading',
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryTeal),
        ),
      );
    }

    if (_errorMessage != null && _issue == null) {
      return CurvedBackgroundScaffold(
        title: 'Error',
        body: Center(child: Text(_errorMessage!)),
      );
    }

    final issue = _issue!;

    return CurvedBackgroundScaffold(
      topHeightFactor: 0.42,
      title: 'Complaint Detail',
      topContent: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildTypeBadge(issue.type),
                  const SizedBox(width: 8),
                  StatusBadge(status: issue.status),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                issue.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Reporter ID: ${issue.userId}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchLatestDetails,
        color: AppTheme.primaryTeal,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AI Confidence Score Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryTeal.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppTheme.primaryTeal,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AI Analysis Confidence',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryTeal,
                            ),
                          ),
                          Text(
                            '${(issue.confidenceScore * 100).toInt()}% match for ${issue.type.displayName}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Complaint Image
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  height: 240,
                  width: double.infinity,
                  color: Colors.grey[200],
                  child: issue.imageUrl != null && issue.imageUrl!.isNotEmpty
                      ? Image.network(
                          '${ApiService.baseUrl.replaceAll('/api', '')}${issue.imageUrl}',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                                child: Icon(
                                  Icons.broken_image_rounded,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                              ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.image_rounded,
                            size: 64,
                            color: Colors.grey,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Details Section
              const Text(
                'Complaint Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                Icons.calendar_today_rounded,
                'Reported Date',
                DateFormat(
                  'MMMM dd, yyyy • hh:mm a',
                ).format(issue.reportedDate),
              ),
              _buildInfoRow(
                Icons.location_on_rounded,
                'Coordinates',
                '${issue.latitude.toStringAsFixed(4)}, ${issue.longitude.toStringAsFixed(4)}',
              ),
              const Divider(height: 32),

              // Location & Route Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Location & Route',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _openMapLauncher,
                    icon: const Icon(Icons.navigation_rounded, size: 16),
                    label: const Text('Start Navigation'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        issue.latitude,
                        issue.longitude,
                      ), // Default to issue
                      zoom: 14,
                    ),
                    onMapCreated: (controller) => _mapController = controller,
                    markers: _markers,
                    polylines: _polylines,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                issue.description,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _makeProfessionalCall,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppTheme.primaryTeal),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.phone_rounded,
                            size: 20,
                            color: AppTheme.primaryTeal,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Call Reporter',
                            style: TextStyle(color: AppTheme.primaryTeal),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showStatusUpdateDialog(context, issue),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppTheme.primaryTeal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Update Status'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStatusUpdateDialog(BuildContext context, ComplaintModel issue) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [ComplaintStatus.pending, ComplaintStatus.resolved].map((
            status,
          ) {
            return ListTile(
              title: Text(status.displayName),
              onTap: () async {
                final result = await _apiService.updateComplaintStatus(
                  complaintId: issue.id,
                  status: status,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  if (result['success']) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Status updated successfully'),
                      ),
                    );
                    _fetchLatestDetails(); // Refresh details after update
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          result['message'] ?? 'Failed to update status',
                        ),
                      ),
                    );
                  }
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTypeBadge(ComplaintType type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        type.displayName,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
