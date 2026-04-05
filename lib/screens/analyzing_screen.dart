import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../config/detector_settings.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../services/cassava_yolo_inference.dart';

class AnalyzingScreen extends StatefulWidget {
  const AnalyzingScreen({Key? key}) : super(key: key);

  @override
  State<AnalyzingScreen> createState() => _AnalyzingScreenState();
}

class _AnalyzingScreenState extends State<AnalyzingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  File? _passedImage;

  String? _modelFilePath;
  String? _classifierFilePath;
  bool _analysisStarted = false;
  bool _modelReady = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _prepareModel();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is File) {
      _passedImage = args;
      if (_modelReady && !_analysisStarted) {
        _analysisStarted = true;
        _analyzeImage();
      }
    }
  }

  Future<void> _prepareModel() async {
    try {
      _modelFilePath = await DetectorSettings.ensureModelFilePath();
      _classifierFilePath = await DetectorSettings.ensureClassifierFilePath();
      if (!mounted) return;
      setState(() => _modelReady = true);
      if (_passedImage != null && !_analysisStarted) {
        _analysisStarted = true;
        _analyzeImage();
      }
    } catch (e, st) {
      debugPrint('Error preparing model: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load AI model: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _analyzeImage() async {
    try {
      if (_passedImage == null ||
          _modelFilePath == null ||
          _classifierFilePath == null) {
        throw Exception('Image or model not ready for analysis.');
      }

      final bytes = await _passedImage!.readAsBytes();
      final img.Image? rawImage = img.decodeImage(bytes);
      if (rawImage == null) {
        throw Exception('Cannot decode image');
      }
      // Camera/gallery JPEGs often store pixels sideways; match upright preview for inference.
      final oriented = img.bakeOrientation(rawImage);
      final rgb = oriented.numChannels == 3
          ? oriented
          : oriented.convert(format: img.Format.uint8, numChannels: 3);

      final rgbBytes = Uint8List.fromList(
        rgb.getBytes(order: img.ChannelOrder.rgb),
      );

      // Heavy work runs in a background isolate so the UI thread stays responsive (no ANR).
      final result = await runCassavaYoloDetectionAsync(
        CassavaYoloInput(
          modelPath: _modelFilePath!,
          classifierModelPath: _classifierFilePath!,
          rgbBytes: rgbBytes,
          width: rgb.width,
          height: rgb.height,
        ),
      );

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        AppRoutes.result,
        arguments: result.copyWith(imagePath: _passedImage?.path ?? ''),
      );
    } catch (e, st) {
      debugPrint('Error analyzing image: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analysis failed: $e'),
            duration: const Duration(seconds: 5),
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (_passedImage != null)
            Positioned.fill(
              child: Opacity(
                opacity: 0.3,
                child: Image.file(_passedImage!, fit: BoxFit.cover),
              ),
            ),
          Container(
            color: AppTheme.primaryGreen.withValues(alpha: 0.7),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RotationTransition(
                    turns: _controller,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.eco,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Analyzing Cassava Root',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Our AI is checking for toxicity...',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 30),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
