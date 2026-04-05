import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;

/// Single place for detector TFLite path and runtime options (camera + analyze screens).
///
/// The bundled detector must be exported from `Scanava_ai` (`export_yolo_tflite.py`, imgsz 640).
/// Class indices follow Roboflow `data.yaml`: 0 = bitter_casava, 1 = sweet_casava.
///
/// Two-stage pipeline: YOLO localizes cassava; [classifierTfliteAsset] (MobileNetV3, 224×224,
/// `include_preprocessing=True` export) classifies the crop only. Place your exported
/// `cassava_mobilenetv3.tflite` in `assets/models/` before building.
class DetectorSettings {
  DetectorSettings._();

  /// Default: Ultralytics `*_float32.tflite`. For INT8, export with `export_yolo_tflite.py --int8`,
  /// copy `best_int8.tflite` (or the generated name) into `assets/models/` and change this path.
  static const String tfliteAsset = 'assets/models/best_float32.tflite';

  /// Sweet/bitter classifier on the YOLO crop (not the full frame).
  static const String classifierTfliteAsset =
      'assets/models/cassava_mobilenetv3.tflite';

  /// Android: GPU may speed inference; on some devices it fails — keep false until you verify.
  static const bool tryAndroidGpuDelegate = false;

  /// XNNPack thread count; camera and analyze share one interpreter instance.
  static const int interpreterThreads = 4;

  /// Copy of the bundled asset on disk — required for [Interpreter.fromFile] in a worker isolate.
  static String? _cachedModelFilePath;
  static String? _cachedClassifierFilePath;

  static Future<String> ensureModelFilePath() async {
    if (_cachedModelFilePath != null) return _cachedModelFilePath!;
    final data = await rootBundle.load(tfliteAsset);
    final file =
        File('${Directory.systemTemp.path}/scanava_cassava_yolo.tflite');
    await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
    _cachedModelFilePath = file.path;
    return file.path;
  }

  static Future<String> ensureClassifierFilePath() async {
    if (_cachedClassifierFilePath != null) return _cachedClassifierFilePath!;
    final data = await rootBundle.load(classifierTfliteAsset);
    final file = File(
        '${Directory.systemTemp.path}/scanava_cassava_mobilenetv3.tflite');
    await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
    _cachedClassifierFilePath = file.path;
    return file.path;
  }

  static Future<tfl.Interpreter> loadInterpreter() async {
    final options = tfl.InterpreterOptions()
      ..threads = interpreterThreads
      // NNAPI can crash or mis-run some models on certain Android builds.
      ..useNnApiForAndroid = false;
    if (tryAndroidGpuDelegate &&
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android) {
      try {
        options.addDelegate(tfl.GpuDelegateV2());
      } catch (e) {
        debugPrint('DetectorSettings: GPU delegate skipped: $e');
      }
    }
    return tfl.Interpreter.fromAsset(tfliteAsset, options: options);
  }
}
