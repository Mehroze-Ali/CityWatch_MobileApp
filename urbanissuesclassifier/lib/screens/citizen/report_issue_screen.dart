import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:urbanissuesclassifier/models/complaint_model.dart';
import 'package:urbanissuesclassifier/services/image_picker_service.dart';
import 'package:urbanissuesclassifier/services/api_service.dart';
import 'package:urbanissuesclassifier/theme/app_theme.dart';
import 'package:urbanissuesclassifier/widgets/curved_background_scaffold.dart';
import 'package:urbanissuesclassifier/screens/citizen/location_picker_screen.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  bool _imageSelected = false;
  File? _selectedImageFile;
  ComplaintType _predictedType = ComplaintType.pothole;
  double _confidenceScore = 0.0;
  bool _isAnalyzing = false;
  bool _isLowConfidence = false;
  bool _isAmbiguous = false;
  bool _isDualLabelMode = false;
  double _secondaryConfidenceScore = 0.0;
  String _secondaryLabel = '';

  static const double _confidenceThreshold = 0.75;
  // static const double _ambiguityThreshold = 0.15; // Unused now

  // Controllers and Services
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final ImagePickerService _imagePickerService = ImagePickerService();
  final ApiService _apiService = ApiService();

  // Location data
  double? _latitude;
  double? _longitude;

  // AI Model variables
  Interpreter? _interpreter;
  List<String>? _labels;
  bool _modelLoaded = false;

  bool _isSubmitting = false;

  // Viva Feature: Top 2 Candidates & Debug Mode
  List<MapEntry<String, double>> _topCandidates = [];
  bool _isDebugMode = false;

  // ... (initState, dispose, _loadModel remain same)

  // Run inference on the selected image
  Future<void> _runInference(File imageFile) async {
    if (_interpreter == null || _labels == null || !_modelLoaded) {
      print('Model not loaded yet');
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _isDualLabelMode = false;
      // _isLowConfidence = false;
      // _isAmbiguous = false;
    });

    try {
      // Read and decode image
      final imageBytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize image to model input size
      final inputSize = 224;
      img.Image resizedImage = img.copyResize(
        image,
        width: inputSize,
        height: inputSize,
      );

      // Convert image to input tensor (normalize to 0-1 range)
      var input = List.generate(
        inputSize,
        (y) => List.generate(inputSize, (x) {
          final pixel = resizedImage.getPixel(x, y);
          return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
        }),
      );

      // Prepare output buffer
      var output = List.filled(
        _labels!.length,
        0.0,
      ).reshape([1, _labels!.length]);

      // Run inference
      _interpreter!.run([input], output);

      // Get results
      final scores = output[0] as List<double>;

      // Create a list of (index, score) pairs and sort descending
      List<MapEntry<int, double>> sortedScores = [];
      for (int i = 0; i < scores.length; i++) {
        sortedScores.add(MapEntry(i, scores[i]));
      }
      sortedScores.sort((a, b) => b.value.compareTo(a.value));

      // Top 1
      double maxScore = sortedScores[0].value;
      int maxIndex = sortedScores[0].key;

      // Top 2 (if available)
      double secondScore = sortedScores.length > 1
          ? sortedScores[1].value
          : 0.0;

      // Map label to ComplaintType
      final detectedLabel = _labels![maxIndex].toLowerCase();
      ComplaintType detectedType = _mapLabelToComplaintType(detectedLabel);

      setState(() {
        _confidenceScore = maxScore;
        _isAnalyzing = false;
        _predictedType = detectedType;

        // Populate Top 2 Candidates (keeping for debug, but UI might not use them as Overlay anymore)
        // Populate Top 2 Candidates (Disabled to remove Overlay)
        _topCandidates = [];
        /* Previous logic for reference:
        _topCandidates = [
          MapEntry(_labels![maxIndex], maxScore),
          if (sortedScores.length > 1)
            MapEntry(_labels![sortedScores[1].key], secondScore),
        ]; 
        */

        // Dual-Label Logic for Pothole vs Unpainted Hump
        String topLabel = _labels![maxIndex].toLowerCase();
        bool isPotholeOrHump =
            topLabel == 'pothole' || topLabel == 'unpainted_hump';

        if (isPotholeOrHump) {
          _isDualLabelMode = true;

          double potholeScore = 0.0;
          double humpScore = 0.0;

          // Find specific scores
          for (int i = 0; i < scores.length; i++) {
            String l = _labels![i].toLowerCase();
            if (l == 'pothole') {
              potholeScore = scores[i];
            } else if (l == 'unpainted_hump')
              humpScore = scores[i];
          }

          if (topLabel == 'pothole') {
            _confidenceScore = potholeScore;
            _secondaryConfidenceScore = humpScore;
            _secondaryLabel = 'Unpainted Hump';
          } else {
            _confidenceScore = humpScore;
            _secondaryConfidenceScore = potholeScore;
            _secondaryLabel = 'Pothole';
          }
        } else {
          _isDualLabelMode = false;
          _secondaryConfidenceScore = 0.0;
          _secondaryLabel = '';
        }

        // Filtering Logic Removed:
        // _isLowConfidence = false;
        // _isAmbiguous = false;
      });

      if (_isDebugMode) {
        print('--- Debug Mode: Raw Confidence Scores ---');
        for (var entry in sortedScores) {
          print(
            '${_labels![entry.key]}: ${(entry.value * 100).toStringAsFixed(2)}%',
          );
        }
      }

      print(
        'Detected: ${_labels![maxIndex]} ($maxScore), Second: ${_labels!.length > 1 ? _labels![sortedScores[1].key] : "None"} ($secondScore)',
      );
    } catch (e) {
      print('Error running inference: $e');
      setState(() {
        _isAnalyzing = false;
        _predictedType = ComplaintType.pothole;
        _confidenceScore = 0.0;
        // _isLowConfidence = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error analyzing image: $e'),
            backgroundColor: AppTheme.alertRed,
          ),
        );
      }
    }
  }

  // UI Helper Methods
  Widget _buildStatusBadge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, {IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, color: AppTheme.primaryTeal) : null,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.primaryTeal, width: 2),
      ),
      contentPadding: const EdgeInsets.all(20),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    _interpreter?.close();
    super.dispose();
  }

  // Load the TFLite model and labels
  Future<void> _loadModel() async {
    try {
      // Load the model
      _interpreter = await Interpreter.fromAsset(
        'assets/ai_model/model.tflite',
      );

      // Load labels
      final labelsData = await rootBundle.loadString(
        'assets/ai_model/labels.txt',
      );
      _labels = labelsData
          .split('\n')
          .where((label) => label.isNotEmpty)
          .toList();

      setState(() {
        _modelLoaded = true;
      });

      print('Model loaded successfully with ${_labels?.length} labels');
    } catch (e) {
      print('Error loading model: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load AI model: $e'),
            backgroundColor: AppTheme.alertRed,
          ),
        );
      }
    }
  }

  // Map the AI label to ComplaintType enum
  ComplaintType _mapLabelToComplaintType(String label) {
    final lowerLabel = label.toLowerCase().trim();

    switch (lowerLabel) {
      case 'pothole':
        return ComplaintType.pothole;

      case 'garbage':
        return ComplaintType.garbage;

      case 'painted_hump':
        return ComplaintType.paintedHump;

      case 'unpainted_hump':
        return ComplaintType.unpaintedHump;

      default:
        return ComplaintType.other;
    }
  }

  Future<void> _openImageSourceSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Add photo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Choose how you want to add an image for this issue.',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE0F2F1),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    color: AppTheme.primaryTeal,
                  ),
                ),
                title: const Text(
                  'Take photo',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                subtitle: const Text(
                  'Use your camera to capture the issue now.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                ),
                onTap: () async {
                  Navigator.of(bottomSheetContext).pop();
                  final picked = await _imagePickerService.pickFromCamera();
                  if (!mounted || picked == null) return;
                  setState(() {
                    _selectedImageFile = File(picked.path);
                    _imageSelected = true;
                  });
                  await _runInference(_selectedImageFile!);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE3F2FD),
                  child: Icon(
                    Icons.photo_library_rounded,
                    color: AppTheme.primaryTeal,
                  ),
                ),
                title: const Text(
                  'Choose from gallery',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                subtitle: const Text(
                  'Select an existing photo from your device.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                ),
                onTap: () async {
                  Navigator.of(bottomSheetContext).pop();
                  final picked = await _imagePickerService.pickFromGallery();
                  if (!mounted || picked == null) return;
                  setState(() {
                    _selectedImageFile = File(picked.path);
                    _imageSelected = true;
                  });
                  await _runInference(_selectedImageFile!);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _simulateImagePicker() {
    _openImageSourceSheet();
  }

  Future<void> _openLocationPicker() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LocationPickerScreen()),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _locationController.text = result['address'];
        _latitude = result['latitude'];
        _longitude = result['longitude'];
      });
    }
  }

  Future<void> _submitReport() async {
    // Removed Filtering Logic as per request
    // _isLowConfidence and _isAmbiguous checks are gone.

    // Basic Validation
    if (!_imageSelected || _selectedImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image first'),
          backgroundColor: AppTheme.alertRed,
        ),
      );
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a description'),
          backgroundColor: AppTheme.alertRed,
        ),
      );
      return;
    }

    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a phone number'),
          backgroundColor: AppTheme.alertRed,
        ),
      );
      return;
    }

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a location'),
          backgroundColor: AppTheme.alertRed,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Generate title based on complaint type
      String title = '${_predictedType.displayName} Report';

      // Submit complaint to backend
      final result = await _apiService.submitComplaint(
        imageFile: _selectedImageFile!,
        type: _predictedType,
        title: title,
        description: _descriptionController.text.trim(),
        latitude: _latitude!,
        longitude: _longitude!,
        confidenceScore: _confidenceScore,
        phone: _phoneController.text.trim(),
      );

      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Complaint submitted successfully!'),
            backgroundColor: AppTheme.statusResolved,
            duration: Duration(seconds: 2),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;

        Navigator.pushReplacementNamed(context, '/success');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to submit complaint'),
            backgroundColor: AppTheme.alertRed,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting complaint: $e'),
          backgroundColor: AppTheme.alertRed,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CurvedBackgroundScaffold(
      title: 'Report Issue',
      topHeightFactor: 0.35,
      actions: [
        IconButton(
          icon: Icon(
            _isDebugMode ? Icons.bug_report : Icons.bug_report_outlined,
            color: Colors.white,
          ),
          onPressed: () {
            setState(() {
              _isDebugMode = !_isDebugMode;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _isDebugMode ? 'Debug Mode Enabled' : 'Debug Mode Disabled',
                ),
                duration: const Duration(seconds: 1),
              ),
            );
          },
        ),
      ],
      topContent: Text(
        'Snap a photo to automatically detect the issue type',
        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 15),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
            padding: const EdgeInsets.only(bottom: 24),
            child: SafeArea(
              top: false,
              bottom: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Picker
                  GestureDetector(
                    onTap: _simulateImagePicker,
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.primaryTealLight.withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: _imageSelected && _selectedImageFile != null
                          ? Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                border: _isLowConfidence
                                    ? Border.all(
                                        color: AppTheme.alertRed,
                                        width: 3,
                                      )
                                    : Border.all(
                                        color: AppTheme.statusResolved,
                                        width: 3,
                                      ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  15,
                                ), // Adjusted for border
                                child: Stack(
                                  children: [
                                    // Image
                                    Image.file(
                                      _selectedImageFile!,
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                    // Analyzing overlay
                                    if (_isAnalyzing)
                                      Container(
                                        color: Colors.black.withOpacity(0.5),
                                        child: const Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              CircularProgressIndicator(
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
                                              ),
                                              SizedBox(height: 12),
                                              Text(
                                                'Analyzing image...',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    // Edit button overlay
                                    if (!_isAnalyzing)
                                      Positioned(
                                        top: 12,
                                        right: 12,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(
                                              0.6,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: _simulateImagePicker,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              child: const Padding(
                                                padding: EdgeInsets.all(8),
                                                child: Icon(
                                                  Icons.edit_rounded,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    // Analytics Overlay (Top 2 Results)
                                    if (_topCandidates.isNotEmpty &&
                                        !_isAnalyzing)
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(
                                              0.7,
                                            ),
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                  bottom: Radius.circular(18),
                                                ),
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              for (
                                                var i = 0;
                                                i < _topCandidates.length;
                                                i++
                                              )
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        bottom: 4,
                                                      ),
                                                  child: Row(
                                                    children: [
                                                      SizedBox(
                                                        width: 30,
                                                        child: Text(
                                                          i == 0
                                                              ? '1st'
                                                              : '2nd',
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .white70,
                                                                fontSize: 10,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                      ),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceBetween,
                                                              children: [
                                                                Text(
                                                                  _topCandidates[i]
                                                                      .key
                                                                      .toUpperCase()
                                                                      .replaceAll(
                                                                        '_',
                                                                        ' ',
                                                                      ),
                                                                  style: const TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize:
                                                                        11,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                  ),
                                                                ),
                                                                Text(
                                                                  '${(_topCandidates[i].value * 100).toInt()}%',
                                                                  style: const TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize:
                                                                        11,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            const SizedBox(
                                                              height: 2,
                                                            ),
                                                            ClipRRect(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    2,
                                                                  ),
                                                              child: LinearProgressIndicator(
                                                                value:
                                                                    _topCandidates[i]
                                                                        .value,
                                                                backgroundColor:
                                                                    Colors
                                                                        .white24,
                                                                valueColor: AlwaysStoppedAnimation<Color>(
                                                                  i == 0
                                                                      ? AppTheme
                                                                            .primaryTeal
                                                                      : AppTheme
                                                                            .warningOrange,
                                                                ),
                                                                minHeight: 4,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                              // Manual Override for Pothole vs Hump
                                              if (_topCandidates.length >= 2 &&
                                                  ((_topCandidates[0].key ==
                                                              'pothole' &&
                                                          _topCandidates[1]
                                                                  .key ==
                                                              'unpainted_hump') ||
                                                      (_topCandidates[0].key ==
                                                              'unpainted_hump' &&
                                                          _topCandidates[1]
                                                                  .key ==
                                                              'pothole')))
                                                Container(
                                                  margin: const EdgeInsets.only(
                                                    top: 8,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white10,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceEvenly,
                                                    children: [
                                                      const Text(
                                                        'Manual Selection:',
                                                        style: TextStyle(
                                                          color: Colors.white70,
                                                          fontSize: 10,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      InkWell(
                                                        onTap: () {
                                                          setState(() {
                                                            _predictedType =
                                                                _mapLabelToComplaintType(
                                                                  _topCandidates[1]
                                                                      .key,
                                                                );
                                                            // Swap candidates visually for feedback
                                                            final temp =
                                                                _topCandidates[0];
                                                            _topCandidates[0] =
                                                                _topCandidates[1];
                                                            _topCandidates[1] =
                                                                temp;
                                                            _confidenceScore =
                                                                _topCandidates[0]
                                                                    .value;

                                                            // Reset validation based on new top
                                                            _isLowConfidence =
                                                                _confidenceScore <
                                                                _confidenceThreshold;
                                                            _isAmbiguous =
                                                                false; // Manually selected, so we clear ambiguity
                                                          });
                                                        },
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 4,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: AppTheme
                                                                .primaryTeal,
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12,
                                                                ),
                                                          ),
                                                          child: Text(
                                                            'Switch to ${_topCandidates[1].key.replaceAll('_', ' ')}',
                                                            style:
                                                                const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 10,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryTeal.withOpacity(
                                        0.05,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.add_photo_alternate_rounded,
                                      size: 40,
                                      color: AppTheme.primaryTeal,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Tap to select image',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Camera or Gallery',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),

                  // AI Analysis Section
                  if (_imageSelected && !_isAnalyzing) ...[
                    const SizedBox(height: 32),
                    const Text(
                      'AI Analysis',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Detected Issue:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                              _buildStatusBadge(
                                _predictedType.displayName,
                                AppTheme.statusResolved,
                                Icons.check_circle_outline_rounded,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Confidence Display (Standard vs Dual-Label)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: const Text(
                                  'Confidence:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Primary Prediction
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            child: LinearProgressIndicator(
                                              value: _confidenceScore,
                                              backgroundColor: Colors.grey[200],
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    AppTheme.statusResolved,
                                                  ),
                                              minHeight: 8,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          '${_predictedType.displayName}: ${(_confidenceScore * 100).toInt()}%',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.statusResolved,
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Dual-Label Secondary Prediction
                                    if (_isDualLabelMode) ...[
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              child: LinearProgressIndicator(
                                                value:
                                                    _secondaryConfidenceScore,
                                                backgroundColor:
                                                    Colors.grey[200],
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(
                                                      AppTheme.statusResolved
                                                          .withOpacity(0.6),
                                                    ),
                                                minHeight:
                                                    6, // Slightly smaller
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            '$_secondaryLabel: ${(_secondaryConfidenceScore * 100).toInt()}%',
                                            style: TextStyle(
                                              fontSize: 12, // Slightly smaller
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Details Input Section
                  const Text(
                    'Issue Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Description Field
                  TextField(
                    controller: _descriptionController,
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    enabled: !_isSubmitting,
                    decoration: _buildInputDecoration(
                      'Describe the issue in detail...',
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Phone Number Field
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    enabled: !_isSubmitting,
                    decoration: _buildInputDecoration(
                      'Phone Number',
                      icon: Icons.phone_rounded,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Location Field
                  GestureDetector(
                    onTap: _isSubmitting ? null : _openLocationPicker,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
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
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Location',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _locationController.text.isEmpty
                                      ? 'Tap to select location on map'
                                      : _locationController.text,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: _locationController.text.isEmpty
                                        ? Colors.grey[400]
                                        : const Color(0xFF111827),
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (_latitude != null &&
                                    _longitude != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Lat: ${_latitude!.toStringAsFixed(6)}, Lng: ${_longitude!.toStringAsFixed(6)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.grey[400],
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryTeal,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: AppTheme.primaryTeal.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        disabledBackgroundColor: Colors.grey[400],
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Submit Report',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading Overlay
          if (_isSubmitting)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryTeal,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Submitting complaint...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
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
}
