import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;

class CassavaClassifier {
  static const String _modelPath = 'assets/models/cassava_model.tflite';

  late final tfl.Interpreter _interpreter;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _interpreter = await tfl.Interpreter.fromAsset(_modelPath);
    _initialized = true;
  }

  bool get isInitialized => _initialized;

  Future<List<double>> classifyImage(img.Image image) async {
    if (!_initialized) {
      throw StateError('CassavaClassifier not initialized. Call init() first.');
    }

    // TODO: change these to match your real model input
    const int inputSize = 224;
    const double mean = 127.5;
    const double std = 127.5;

    final resized = img.copyResize(image, width: inputSize, height: inputSize);

    final input = List.generate(
      1,
      (_) => List.generate(
        inputSize,
        (y) => List.generate(
          inputSize,
          (x) {
            final pixel = resized.getPixel(x, y);
            final r = img.getRed(pixel).toDouble();
            final g = img.getGreen(pixel).toDouble();
            final b = img.getBlue(pixel).toDouble();
            return [
              (r - mean) / std,
              (g - mean) / std,
              (b - mean) / std,
            ];
          },
        ),
      ),
    );

    final outputTensor = _interpreter.getOutputTensor(0);
    final outputShape = outputTensor.shape; // [1, numClasses]
    final output = List.generate(
      outputShape[0],
      (_) => List<double>.filled(outputShape[1], 0),
    );

    _interpreter.run(input, output);
    return output[0];
  }

  void close() {
    if (_initialized) {
      _interpreter.close();
      _initialized = false;
    }
  }
}
