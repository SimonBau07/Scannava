import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../config/routes.dart';
import '../config/theme.dart';
import '../widgets/custom_button.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  // Instance of the ImagePicker to access hardware
  final ImagePicker _picker = ImagePicker();

  /// Handles both Camera and Gallery actions
  Future<void> _handleImageAction(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80, // Slight compression to help with future AI processing speed
      );

      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);
        
        // Ensure the widget is still mounted before navigating
        if (!mounted) return;

        // Navigate to the Analyzing Screen and pass the actual File object
        Navigator.pushNamed(
          context, 
          AppRoutes.analyzing, 
          arguments: imageFile,
        );
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      // Optional: Show a snackbar error to the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not access camera or gallery.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Cassava'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // 1. Visual Placeholder / Instructions Area
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.primaryGreen.withOpacity(0.3), 
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        size: 100,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          'Place the cassava root in the center of the frame.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              
              // 2. Helpful Tip Text
              const Text(
                'Tip: Bright natural light works best for AI accuracy.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13, 
                  fontStyle: FontStyle.italic,
                  color: AppTheme.textLight,
                ),
              ),
              
              const SizedBox(height: 30),

              // 3. Action Buttons
              CustomButton(
                text: 'TAKE A PHOTO',
                icon: Icons.camera_alt,
                onPressed: () => _handleImageAction(ImageSource.camera),
                backgroundColor: AppTheme.primaryGreen,
                width: double.infinity,
              ),
              
              const SizedBox(height: 16),
              
              CustomButton(
                text: 'UPLOAD FROM GALLERY',
                icon: Icons.photo_library,
                onPressed: () => _handleImageAction(ImageSource.gallery),
                isOutlined: true,
                textColor: AppTheme.primaryGreen,
                width: double.infinity,
              ),
              
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}