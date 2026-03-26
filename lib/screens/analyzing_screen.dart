import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;

import '../config/routes.dart';
import '../config/theme.dart';
import '../models/classification_result.dart';

// MobileNet-style classifier constants.
const int _mobilenetInputSize = 224;

// If the best predicted score is below this, treat the image as "Not Cassava".
const double _confidenceThreshold = 0.70;

// Additional guard: if sweet vs bitter are too close, treat as "Not Cassava".
const double _classMarginThreshold = 0.15;

// If MobileNet is not confident enough, fall back to the YOLO model for better accuracy.
const double _mobilenetAcceptThreshold = 0.85;

class AnalyzingScreen extends StatefulWidget {
  const AnalyzingScreen({Key? key}) : super(key: key);

  @override
  State<AnalyzingScreen> createState() => _AnalyzingScreenState();
}

class _AnalyzingScreenState extends State<AnalyzingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  File? _passedImage;

  // Cache interpreters across scans to avoid reloading models each time.
  static tfl.Interpreter? _sharedMobileNetInterpreter;
  static tfl.Interpreter? _sharedYoloInterpreter;

  tfl.Interpreter? _mobileNetInterpreter;
  tfl.Interpreter? _yoloInterpreter;
  bool _analysisStarted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _initModels();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is File) {
      _passedImage = args;
      if (_mobileNetInterpreter != null && !_analysisStarted) {
        _analysisStarted = true;
        _analyzeImage();
      }
    }
  }

  Future<void> _initModels() async {
    try {
      // Load fast MobileNet classifier; keep it warm across scans.
      if (_sharedMobileNetInterpreter == null) {
        final options = tfl.InterpreterOptions()..threads = 4;
        _sharedMobileNetInterpreter = await tfl.Interpreter.fromAsset(
          'assets/models/cassava_mobilenetv3.tflite',
          options: options,
        );
      }
      _mobileNetInterpreter = _sharedMobileNetInterpreter;

      // Lazy-load YOLO model only when needed (fallback path).
      // Keeping it null by default preserves fast startup.

      // If the image is already available, start analysis now.
      if (mounted && _passedImage != null && !_analysisStarted) {
        _analysisStarted = true;
        _analyzeImage();
      }
    } catch (e) {
      debugPrint('Error loading models: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading AI models.')),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _analyzeImage() async {
    try {
      if (_passedImage == null || _mobileNetInterpreter == null) {
        throw Exception('Image or model not ready for analysis.');
      }
      // 1. Read and decode image
      final bytes = await _passedImage!.readAsBytes();
      img.Image? rawImage = img.decodeImage(bytes);
      if (rawImage == null) {
        throw Exception('Cannot decode image');
      }

      // 2. Resize to 224x224 for MobileNet input
      final img.Image resized = img.copyResize(
        rawImage,
        width: _mobilenetInputSize,
        height: _mobilenetInputSize,
      );

      // 3. Build input tensor [1, 224, 224, 3] float32, normalized 0–1
      final input = List.generate(
        1,
        (_) => List.generate(
          _mobilenetInputSize,
          (y) => List.generate(
            _mobilenetInputSize,
            (x) {
              final px = resized.getPixel(x, y);
              return <double>[
                px.r.toDouble() / 255.0,
                px.g.toDouble() / 255.0,
                px.b.toDouble() / 255.0,
              ];
            },
          ),
        ),
      );

      // 4. Output tensor [1, numClasses]
      final outputTensor = _mobileNetInterpreter!.getOutputTensor(0);
      final outputShape = outputTensor.shape;
      final int numClasses = outputShape.last;
      final output = List.generate(
        1,
        (_) => List<double>.filled(numClasses, 0.0),
      );

      _mobileNetInterpreter!.run(input, output);

      // 5. Find best class and confidence
      double bestConf = 0.0;
      int bestClassIdx = 0;
      for (int i = 0; i < numClasses; i++) {
        final score = output[0][i];
        if (score > bestConf) {
          bestConf = score;
          bestClassIdx = i;
        }
      }

      final double confidence = bestConf.clamp(0.0, 1.0);
      final double margin =
          numClasses >= 2 ? (output[0][0] - output[0][1]).abs() : confidence;

      final bool mobileNetSaysNotCassava =
          confidence < _confidenceThreshold || margin < _classMarginThreshold;

      // If MobileNet is uncertain, fall back to YOLO for a smarter decision.
      // This keeps the app fast on average while improving accuracy on hard images.
      final bool shouldFallbackToYolo =
          !mobileNetSaysNotCassava && confidence < _mobilenetAcceptThreshold;

      if (shouldFallbackToYolo) {
        final yoloResult = await _runYoloFallback(rawImage);
        if (!mounted) return;
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.result,
          arguments: yoloResult.copyWith(imagePath: _passedImage?.path ?? ''),
        );
        return;
      }

      final String typeText;
      final List<String> recs;
      if (mobileNetSaysNotCassava) {
        typeText = 'Not Cassava';
        recs = <String>[
          'No cassava detected.',
          'Try a clearer photo of the cassava root.',
        ];
      } else {
        // Labels in cassava_labels.txt:
        // 0 = sweet_cassava, 1 = bitter_cassava
        final bool isSweet = bestClassIdx == 0;
        typeText = isSweet ? 'Sweet Cassava' : 'Bitter Cassava';
        recs = isSweet
            ? <String>[
                'Safe for boiling and cooking.',
                'Ensure cassava is thoroughly cooked before eating.',
              ]
            : <String>[
                'Potentially toxic; handle with care.',
                'Do not eat without proper processing and safety checks.',
              ];
      }

      final result = ClassificationResult(
        id: DateTime.now().toString(),
        type: typeText,
        confidence: confidence,
        recommendations: recs,
        timestamp: DateTime.now(),
        imagePath: _passedImage?.path ?? '',
      );

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        AppRoutes.result,
        arguments: result,
      );
    } catch (e) {
      debugPrint('Error analyzing image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error analyzing image.')),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<ClassificationResult> _runYoloFallback(img.Image rawImage) async {
    // Lazy-load YOLO model only when we need higher accuracy.
    if (_sharedYoloInterpreter == null) {
      final options = tfl.InterpreterOptions()..threads = 4;
      _sharedYoloInterpreter = await tfl.Interpreter.fromAsset(
        'assets/models/cassava_yolov8.tflite',
        options: options,
      );
    }
    _yoloInterpreter = _sharedYoloInterpreter;

    // YOLO constants (match your export)
    const int yoloInputSize = 640;
    const int yoloDetectionRows = 38;
    const int yoloNumPredictions = 8400;
    const int yoloClassScoreStartRow = 4; // rows 4 & 5 are class scores

    final img.Image resized = img.copyResize(
      rawImage,
      width: yoloInputSize,
      height: yoloInputSize,
    );

    final int inputLen = 1 * yoloInputSize * yoloInputSize * 3;
    final List<double> inputFlat = List.filled(inputLen, 0.0);
    for (int y = 0; y < yoloInputSize; y++) {
      for (int x = 0; x < yoloInputSize; x++) {
        final px = resized.getPixel(x, y);
        final base = (y * yoloInputSize + x) * 3;
        inputFlat[base + 0] = px.r.toDouble();
        inputFlat[base + 1] = px.g.toDouble();
        inputFlat[base + 2] = px.b.toDouble();
      }
    }
    final input =
        inputFlat.reshape<double>([1, yoloInputSize, yoloInputSize, 3]);

    final out0 = List.filled(
      1 * yoloDetectionRows * yoloNumPredictions,
      0.0,
    ).reshape<double>([1, yoloDetectionRows, yoloNumPredictions]);
    final out1 = List.filled(
      1 * 160 * 160 * 32,
      0.0,
    ).reshape<double>([1, 160, 160, 32]);

    _yoloInterpreter!.runForMultipleInputs([input], {0: out0, 1: out1});

    double bestConf = 0.0;
    int bestClassIdx = 0;
    for (int j = 0; j < yoloNumPredictions; j++) {
      final score0 = (out0[0][yoloClassScoreStartRow + 0][j] as num).toDouble();
      final score1 = (out0[0][yoloClassScoreStartRow + 1][j] as num).toDouble();
      final conf = score0 > score1 ? score0 : score1;
      if (conf > bestConf) {
        bestConf = conf;
        bestClassIdx = score0 >= score1 ? 0 : 1;
      }
    }

    final double confidence = bestConf.clamp(0.0, 1.0);
    final bool noDetection = confidence < _confidenceThreshold;

    final String typeText;
    final List<String> recs;
    if (noDetection) {
      typeText = 'Not Cassava';
      recs = <String>[
        'No cassava detected.',
        'Try a clearer photo of the cassava root.',
      ];
    } else {
      // In this YOLO head: treat class 0 as bitter, class 1 as sweet.
      final bool isBitter = bestClassIdx == 0;
      typeText = isBitter ? 'Bitter Cassava' : 'Sweet Cassava';
      recs = isBitter
          ? <String>[
              'Potentially toxic; handle with care.',
              'Do not eat without proper processing and safety checks.',
            ]
          : <String>[
              'Safe for boiling and cooking.',
              'Ensure cassava is thoroughly cooked before eating.',
            ];
    }

    return ClassificationResult(
      id: DateTime.now().toString(),
      type: typeText,
      confidence: confidence,
      recommendations: recs,
      timestamp: DateTime.now(),
      imagePath: '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    // Keep the shared interpreter alive to speed up subsequent scans.
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
