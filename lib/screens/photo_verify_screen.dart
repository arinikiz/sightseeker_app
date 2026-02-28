import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../services/genkit_service.dart';
import '../providers/challenge_provider.dart';
import '../widgets/photo_verification_widget.dart';

/// Screen for taking a photo and verifying it via Genkit AI.
/// Opened from the Challenge Hub "Take Photo" button.
class PhotoVerifyScreen extends StatefulWidget {
  final String challengeId;
  final String challengeTitle;

  const PhotoVerifyScreen({
    super.key,
    required this.challengeId,
    required this.challengeTitle,
  });

  @override
  State<PhotoVerifyScreen> createState() => _PhotoVerifyScreenState();
}

class _PhotoVerifyScreenState extends State<PhotoVerifyScreen> {
  final GenkitService _genkitService = GenkitService();
  final ImagePicker _picker = ImagePicker();

  File? _imageFile;
  bool _isVerifying = false;
  Map<String, dynamic>? _verificationResult;
  String? _error;

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _imageFile = File(photo.path);
          _verificationResult = null;
          _error = null;
        });
      }
    } catch (e) {
      setState(() => _error = 'Could not open camera: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _imageFile = File(photo.path);
          _verificationResult = null;
          _error = null;
        });
      }
    } catch (e) {
      setState(() => _error = 'Could not open gallery: $e');
    }
  }

  Future<void> _verifyPhoto() async {
    if (_imageFile == null) return;

    setState(() {
      _isVerifying = true;
      _error = null;
      _verificationResult = null;
    });

    try {
      // Get GPS location
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        setState(() {
          _error = 'Location permission is required for photo verification.';
          _isVerifying = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // Convert image to base64
      final bytes = await _imageFile!.readAsBytes();
      final base64Image = base64Encode(bytes);

      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

      // Call Genkit verifyPhoto flow
      final result = await _genkitService.verifyPhoto(
        challengeId: widget.challengeId,
        imageBase64: base64Image,
        userLatitude: position.latitude,
        userLongitude: position.longitude,
        userId: userId,
      );

      setState(() {
        _verificationResult = result;
        _isVerifying = false;
      });

      // If verified, update local state
      if (result['verified'] == true && mounted) {
        context.read<ChallengeProvider>().completeChallenge(widget.challengeId);
      }
    } catch (e) {
      setState(() {
        _error = 'Verification failed: ${e.toString().split(':').last.trim()}';
        _isVerifying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Verification'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Challenge title
            Text(
              widget.challengeTitle,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.secondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Take a photo to prove you visited this location',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Photo preview or placeholder
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _verificationResult != null
                      ? (_verificationResult!['verified'] == true
                          ? Colors.green
                          : Colors.red)
                      : Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: _imageFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(
                        _imageFile!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_outlined,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          'No photo taken yet',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 20),

            // Camera and gallery buttons
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isVerifying ? null : _takePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isVerifying ? null : _pickFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.secondaryColor,
                      side: const BorderSide(color: AppTheme.secondaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Verify button
            if (_imageFile != null && _verificationResult == null)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isVerifying ? null : _verifyPhoto,
                  icon: _isVerifying
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.verified),
                  label: Text(_isVerifying ? 'Verifying with AI...' : 'Verify Photo'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.secondaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Verification result
            if (_verificationResult != null)
              PhotoVerificationWidget(
                isVerified: _verificationResult!['verified'] as bool?,
                reason: _verificationResult!['reason'] as String?,
                funFact: _verificationResult!['funFact'] as String?,
              ),

            // GPS info
            if (_verificationResult != null &&
                _verificationResult!['gpsDistanceMeters'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _verificationResult!['gpsVerified'] == true
                          ? Icons.location_on
                          : Icons.location_off,
                      size: 16,
                      color: _verificationResult!['gpsVerified'] == true
                          ? Colors.green
                          : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'GPS: ${_verificationResult!['gpsDistanceMeters']}m from challenge',
                      style: TextStyle(
                        fontSize: 12,
                        color: _verificationResult!['gpsVerified'] == true
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),

            // Error message
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Success action
            if (_verificationResult != null &&
                _verificationResult!['verified'] == true)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                    icon: const Icon(Icons.celebration),
                    label: const Text('Back to Challenge'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
