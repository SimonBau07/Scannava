// Two-stage cassava pipeline (YOLO gate + MobileNet crop classifier) — isolate offload.
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;

import '../config/detector_settings.dart';
import '../models/classification_result.dart';

/// Matches `Scanava_ai/tflite_realtime_detect.decode_yolo_raw` (logits vs probabilities).
double _sigmoidClass(double x) {
  if (x > 50.0) return 1.0;
  if (x < -50.0) return 0.0;
  return 1.0 / (1.0 + math.exp(-x));
}

const int _yoloInputSize = 640;
const int _defaultNumPredictions = 8400;
const int _defaultNumClasses = 2;

/// Candidate generation (NMS) — match `Scanava_ai/predict.py` default `conf=0.25`.
/// Class order matches `datasets/.../data.yaml`: 0 = bitter_casava, 1 = sweet_casava.
const double _confThresholdBitter = 0.25;
const double _confThresholdSweet = 0.25;
const double _nmsIouThreshold = 0.45;
const double _minBoxSizePx = 32.0;

/// YOLO gatekeeper: reject if the best box is below this [max(pBitter, pSweet)].
const double _yoloGateMinConfidence = 0.5;

/// MobileNet on the crop: require clear winner (matches your defense thresholds).
const double _classifierMinMaxProb = 0.7;
const double _classifierMinMargin = 0.2;

/// Roots are rarely paper-thin slivers; laptops/panoramas often are.
const double _maxBoxAspectRatio = 4.15;

/// Default classifier spatial size (MobileNetV3 224 export); overridden from tensor shape.
const int _classifierDefaultSize = 224;

/// Matches Ultralytics letterbox + scale_boxes (training/preprocessing).
class _LetterboxParams {
  final double gain;
  final int padX;
  final int padY;
  final int newW;
  final int newH;

  const _LetterboxParams({
    required this.gain,
    required this.padX,
    required this.padY,
    required this.newW,
    required this.newH,
  });

  static _LetterboxParams fromSize(int w0, int h0) {
    final r = math.min(_yoloInputSize / h0, _yoloInputSize / w0);
    final newW = math.max(1, (w0 * r).round());
    final newH = math.max(1, (h0 * r).round());
    final padX = ((_yoloInputSize - w0 * r) / 2 - 0.1).round();
    final padY = ((_yoloInputSize - h0 * r) / 2 - 0.1).round();
    return _LetterboxParams(
      gain: r,
      padX: padX,
      padY: padY,
      newW: newW,
      newH: newH,
    );
  }
}

class _Detection {
  final int classId;
  final double confidence;

  /// Sigmoid probs: channel 0 = bitter, 1 = sweet (matches data.yaml order).
  final double pBitter;
  final double pSweet;
  final double x1;
  final double y1;
  final double x2;
  final double y2;

  _Detection({
    required this.classId,
    required this.confidence,
    required this.pBitter,
    required this.pSweet,
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
  });
}

class _CropEval {
  final _Detection? focus;
  final int classId;
  final double confidence;

  /// Weight in ensemble vote (full-frame weighted slightly higher).
  final double voteWeight;

  _CropEval({
    required this.focus,
    required this.classId,
    required this.confidence,
    this.voteWeight = 1.0,
  });
}

/// Serializable input for [Isolate.run] (no Flutter bindings in worker).
class CassavaYoloInput {
  CassavaYoloInput({
    required this.modelPath,
    required this.classifierModelPath,
    required this.rgbBytes,
    required this.width,
    required this.height,
  });

  final String modelPath;
  final String classifierModelPath;
  final Uint8List rgbBytes;
  final int width;
  final int height;
}

/// Runs TFLite + image work off the UI isolate.
Future<ClassificationResult> runCassavaYoloDetectionAsync(
    CassavaYoloInput input) {
  if (kIsWeb) {
    return Future.error(
        UnsupportedError('Cassava detection runs on mobile only.'));
  }
  return Isolate.run(() => _runCassavaYoloDetectionEntry(input));
}

ClassificationResult _runCassavaYoloDetectionEntry(CassavaYoloInput input) {
  final options = tfl.InterpreterOptions()
    ..threads = DetectorSettings.interpreterThreads
    ..useNnApiForAndroid = false;
  final yoloInterpreter =
      tfl.Interpreter.fromFile(File(input.modelPath), options: options);
  final classifierInterpreter =
      tfl.Interpreter.fromFile(File(input.classifierModelPath), options: options);
  try {
    final engine =
        _CassavaYoloEngine(yoloInterpreter, classifierInterpreter);
    final rawImage = img.Image.fromBytes(
      width: input.width,
      height: input.height,
      bytes: input.rgbBytes.buffer,
      bytesOffset: input.rgbBytes.offsetInBytes,
      format: img.Format.uint8,
      numChannels: 3,
      order: img.ChannelOrder.rgb,
    );
    return engine.runTwoStagePipeline(rawImage);
  } finally {
    yoloInterpreter.close();
    classifierInterpreter.close();
  }
}

class _CassavaYoloEngine {
  _CassavaYoloEngine(this._yoloInterpreter, this._classifierInterpreter) {
    final outShape = _yoloInterpreter.getOutputTensor(0).shape;
    if (outShape.length == 3 && outShape[0] == 1) {
      final d1 = outShape[1];
      final d2 = outShape[2];
      final ncPlus4First = d1 > 4 && d1 < 64;
      final ncPlus4Second = d2 > 4 && d2 < 64;
      if (ncPlus4First && !ncPlus4Second) {
        _outChannelsFirst = true;
        _numClasses = d1 - 4;
        _numPredictions = d2;
      } else if (ncPlus4Second && !ncPlus4First) {
        _outChannelsFirst = false;
        _numClasses = d2 - 4;
        _numPredictions = d1;
      }
    }

    final inShape = _classifierInterpreter.getInputTensor(0).shape;
    if (inShape.length == 4) {
      final h = inShape[1];
      final w = inShape[2];
      if (h == w && h > 0 && h < 4096) {
        _classifierInputSize = h;
      }
    }
  }

  final tfl.Interpreter _yoloInterpreter;
  final tfl.Interpreter _classifierInterpreter;
  bool _outChannelsFirst = true;
  int _numPredictions = _defaultNumPredictions;
  int _numClasses = _defaultNumClasses;
  int _classifierInputSize = _classifierDefaultSize;

  /// YOLO11 gate → crop ROI → MobileNetV3 sweet/bitter (never classifies full frame).
  ClassificationResult runTwoStagePipeline(img.Image rawImage) {
    final det = _evaluateSingleViewEngine(
      rawImage,
      offsetX: 0,
      offsetY: 0,
      originalW: rawImage.width,
      originalH: rawImage.height,
      voteWeight: 1.0,
    );

    final focus = det.focus;
    if (focus == null || focus.confidence < _yoloGateMinConfidence) {
      return ClassificationResult(
        id: DateTime.now().toString(),
        type: 'Not Cassava',
        confidence: 0.0,
        recommendations: const <String>[
          'No cassava detected in this photo.',
          'Center one cassava root in the frame and try again.',
        ],
        boxes: const <DetectionBox>[],
        imageWidth: rawImage.width,
        imageHeight: rawImage.height,
        timestamp: DateTime.now(),
        imagePath: '',
      );
    }

    double bx1 = focus.x1;
    double by1 = focus.y1;
    double bx2 = focus.x2;
    double by2 = focus.y2;

    if (_boxAspectTooExtremeEngine(bx1, by1, bx2, by2)) {
      return _notCassavaNonRootEngine(
        rawImage,
        reasonLines: const <String>[
          'The detected region does not look like a typical cassava root shape.',
          'Fill the frame with one root only.',
        ],
      );
    }

    final roi = _extractRoiRgb(rawImage, bx1, by1, bx2, by2);
    if (roi == null) {
      return ClassificationResult(
        id: DateTime.now().toString(),
        type: 'Not Cassava',
        confidence: 0.0,
        recommendations: const <String>[
          'Could not crop a valid cassava region.',
          'Try a closer, clearer photo of the root.',
        ],
        boxes: const <DetectionBox>[],
        imageWidth: rawImage.width,
        imageHeight: rawImage.height,
        timestamp: DateTime.now(),
        imagePath: '',
      );
    }

    final cls = _runMobileNetOnCrop(roi);
    final bitter = cls.$1;
    final sweet = cls.$2;

    final maxConf = math.max(bitter, sweet);
    final margin = (sweet - bitter).abs();

    if (maxConf < _classifierMinMaxProb || margin < _classifierMinMargin) {
      return ClassificationResult(
        id: DateTime.now().toString(),
        type: 'Not Cassava',
        confidence: 0.0,
        recommendations: const <String>[
          'The crop is not clearly sweet or bitter cassava.',
          'Retake with the root filling more of the frame and even lighting.',
        ],
        boxes: const <DetectionBox>[],
        imageWidth: rawImage.width,
        imageHeight: rawImage.height,
        timestamp: DateTime.now(),
        imagePath: '',
      );
    }

    final bool isBitter = bitter >= sweet;
    final String typeText =
        isBitter ? 'Bitter Cassava' : 'Sweet Cassava';
    final List<String> recs = isBitter
        ? <String>[
            'Potentially toxic; handle with care.',
            'Do not eat without proper processing and safety checks.',
          ]
        : <String>[
            'Safe for boiling and cooking.',
            'Ensure cassava is thoroughly cooked before eating.',
          ];

    final boxes = <DetectionBox>[
      DetectionBox(
        x1: bx1,
        y1: by1,
        x2: bx2,
        y2: by2,
        classId: isBitter ? 0 : 1,
        confidence: focus.confidence.clamp(0.0, 1.0),
      ),
    ];

    return ClassificationResult(
      id: DateTime.now().toString(),
      type: typeText,
      confidence: maxConf.clamp(0.0, 1.0),
      recommendations: recs,
      boxes: boxes,
      imageWidth: rawImage.width,
      imageHeight: rawImage.height,
      timestamp: DateTime.now(),
      imagePath: '',
    );
  }

  /// Returns (bitterProb, sweetProb) summing to ~1 when possible.
  (double, double) _runMobileNetOnCrop(img.Image crop) {
    final s = _classifierInputSize;
    final resized = img.copyResize(crop, width: s, height: s);
    final bytes = resized.getBytes(order: img.ChannelOrder.rgb);
    final n = s * s * 3;
    final inputFlat = List<double>.filled(n, 0.0);
    for (int i = 0; i < n; i++) {
      inputFlat[i] = bytes[i].toDouble();
    }

    final input = inputFlat.reshape<double>([1, s, s, 3]);
    final out = List.filled(2, 0.0).reshape<double>([1, 2]);

    _classifierInterpreter.run(input, out);

    var b = (out[0][0] as num).toDouble();
    var sw = (out[0][1] as num).toDouble();

    if (b > 1.05 || sw > 1.05 || b < -0.05 || sw < -0.05) {
      final m = math.max(b, sw);
      final eb = math.exp(b - m);
      final es = math.exp(sw - m);
      final sum = eb + es;
      b = eb / sum;
      sw = es / sum;
    } else {
      b = b.clamp(0.0, 1.0);
      sw = sw.clamp(0.0, 1.0);
      final t = b + sw;
      if (t > 1e-6) {
        b /= t;
        sw /= t;
      }
    }
    return (b, sw);
  }

  /// Crops [x1,y1,x2,y2] in full-image coordinates; returns null if too small.
  img.Image? _extractRoiRgb(
    img.Image src,
    double x1,
    double y1,
    double x2,
    double y2,
  ) {
    final w = src.width;
    final h = src.height;
    final ix1 = x1.floor().clamp(0, math.max(0, w - 1)).toInt();
    final iy1 = y1.floor().clamp(0, math.max(0, h - 1)).toInt();
    final ix2 = x2.ceil().clamp(0, w).toInt();
    final iy2 = y2.ceil().clamp(0, h).toInt();
    final cw = ix2 - ix1;
    final ch = iy2 - iy1;
    if (cw < 8 || ch < 8) return null;
    return img.copyCrop(src, x: ix1, y: iy1, width: cw, height: ch);
  }

  ClassificationResult _notCassavaNonRootEngine(
    img.Image rawImage, {
    required List<String> reasonLines,
  }) {
    return ClassificationResult(
      id: DateTime.now().toString(),
      type: 'Not Cassava',
      confidence: 0.0,
      recommendations: reasonLines,
      boxes: const <DetectionBox>[],
      imageWidth: rawImage.width,
      imageHeight: rawImage.height,
      timestamp: DateTime.now(),
      imagePath: '',
    );
  }

  bool _boxAspectTooExtremeEngine(double x1, double y1, double x2, double y2) {
    final bw = (x2 - x1).abs();
    final bh = (y2 - y1).abs();
    if (bw < 1.0 || bh < 1.0) return true;
    final ar = bw > bh ? bw / bh : bh / bw;
    return ar > _maxBoxAspectRatio;
  }

  img.Image _letterboxedViewEngine(img.Image src, _LetterboxParams lb) {
    final resized = img.copyResize(src, width: lb.newW, height: lb.newH);
    final canvas = img.Image(
        width: _yoloInputSize, height: _yoloInputSize, numChannels: 3);
    img.fill(canvas, color: img.ColorRgb8(114, 114, 114));
    final px = lb.padX.clamp(0, _yoloInputSize - 1);
    final py = lb.padY.clamp(0, _yoloInputSize - 1);
    img.compositeImage(canvas, resized, dstX: px, dstY: py);
    return canvas;
  }

  double _outAtEngine(List out, int anchor, int channel) {
    if (_outChannelsFirst) {
      return (out[0][channel][anchor] as num).toDouble();
    }
    return (out[0][anchor][channel] as num).toDouble();
  }

  _CropEval _evaluateSingleViewEngine(
    img.Image view, {
    required double offsetX,
    required double offsetY,
    required int originalW,
    required int originalH,
    double voteWeight = 1.0,
  }) {
    final lb = _LetterboxParams.fromSize(view.width, view.height);
    final letterboxed = _letterboxedViewEngine(view, lb);
    const int inputLen = _yoloInputSize * _yoloInputSize * 3;
    // Fast preprocessing: avoid slow getPixel() in nested loops.
    // getBytes() returns RGB bytes (length: 640*640*3).
    final bytes = letterboxed.getBytes(order: img.ChannelOrder.rgb);
    final List<double> inputFlat = List<double>.filled(inputLen, 0.0);
    for (int i = 0; i < inputLen; i++) {
      inputFlat[i] = bytes[i] / 255.0;
    }

    final input =
        inputFlat.reshape<double>([1, _yoloInputSize, _yoloInputSize, 3]);
    final outShape = _outChannelsFirst
        ? <int>[1, 4 + _numClasses, _numPredictions]
        : <int>[1, _numPredictions, 4 + _numClasses];
    final out = List.filled(
      1 * (4 + _numClasses) * _numPredictions,
      0.0,
    ).reshape<double>(outShape);
    _yoloInterpreter.run(input, out);

    var clsMax = -double.infinity;
    var clsMin = double.infinity;
    for (int i = 0; i < _numPredictions; i++) {
      for (int c = 0; c < _numClasses; c++) {
        final v = _outAtEngine(out, i, 4 + c);
        if (v > clsMax) clsMax = v;
        if (v < clsMin) clsMin = v;
      }
    }
    final classNeedSigmoid = clsMax > 1.5 || clsMin < -0.5;

    final candidates = <_Detection>[];

    for (int i = 0; i < _numPredictions; i++) {
      double cx = _outAtEngine(out, i, 0);
      double cy = _outAtEngine(out, i, 1);
      double w = _outAtEngine(out, i, 2);
      double h = _outAtEngine(out, i, 3);
      var c0 = _outAtEngine(out, i, 4);
      var c1 = _outAtEngine(out, i, 5);

      final maxVal = math.max(math.max(cx, cy), math.max(w, h));
      if (maxVal <= 1.5) {
        cx *= _yoloInputSize;
        cy *= _yoloInputSize;
        w *= _yoloInputSize;
        h *= _yoloInputSize;
      }

      // Ultralytics TFLite usually ships class scores in [0,1]; some graphs expose raw logits.
      final double p0 =
          classNeedSigmoid ? _sigmoidClass(c0) : c0.clamp(0.0, 1.0);
      final double p1 =
          classNeedSigmoid ? _sigmoidClass(c1) : c1.clamp(0.0, 1.0);
      final conf = math.max(p0, p1);
      final classId = p1 > p0 ? 1 : 0;
      final threshold =
          classId == 0 ? _confThresholdBitter : _confThresholdSweet;
      if (conf < threshold) continue;

      final x1 = (cx - (w / 2)).clamp(0.0, _yoloInputSize.toDouble());
      final y1 = (cy - (h / 2)).clamp(0.0, _yoloInputSize.toDouble());
      final x2 = (cx + (w / 2)).clamp(0.0, _yoloInputSize.toDouble());
      final y2 = (cy + (h / 2)).clamp(0.0, _yoloInputSize.toDouble());

      if (x2 <= x1 || y2 <= y1) continue;
      if ((x2 - x1) < _minBoxSizePx || (y2 - y1) < _minBoxSizePx) continue;

      final vx1 = ((x1 - lb.padX) / lb.gain).clamp(0.0, view.width.toDouble());
      final vy1 = ((y1 - lb.padY) / lb.gain).clamp(0.0, view.height.toDouble());
      final vx2 = ((x2 - lb.padX) / lb.gain).clamp(0.0, view.width.toDouble());
      final vy2 = ((y2 - lb.padY) / lb.gain).clamp(0.0, view.height.toDouble());

      final gx1 = (vx1 + offsetX).clamp(0.0, originalW.toDouble());
      final gy1 = (vy1 + offsetY).clamp(0.0, originalH.toDouble());
      final gx2 = (vx2 + offsetX).clamp(0.0, originalW.toDouble());
      final gy2 = (vy2 + offsetY).clamp(0.0, originalH.toDouble());

      candidates.add(_Detection(
        classId: classId,
        confidence: conf,
        pBitter: p0,
        pSweet: p1,
        x1: gx1,
        y1: gy1,
        x2: gx2,
        y2: gy2,
      ));
    }

    candidates.sort((a, b) => b.confidence.compareTo(a.confidence));
    final selected = <_Detection>[];
    for (final d in candidates) {
      bool keep = true;
      for (final k in selected) {
        if (d.classId == k.classId && _iouEngine(d, k) > _nmsIouThreshold) {
          keep = false;
          break;
        }
      }
      if (keep) selected.add(d);
      if (selected.length >= 10) break;
    }

    if (selected.isEmpty) {
      return _CropEval(
        focus: null,
        classId: 0,
        confidence: 0.0,
        voteWeight: voteWeight,
      );
    }

    selected.sort((a, b) {
      final sa = (a.x2 - a.x1) * (a.y2 - a.y1) * a.confidence;
      final sb = (b.x2 - b.x1) * (b.y2 - b.y1) * b.confidence;
      return sb.compareTo(sa);
    });
    final focus = selected.first;
    return _CropEval(
      focus: focus,
      classId: focus.classId,
      confidence: focus.confidence.clamp(0.0, 1.0),
      voteWeight: voteWeight,
    );
  }

  double _iouEngine(_Detection a, _Detection b) {
    final interX1 = math.max(a.x1, b.x1);
    final interY1 = math.max(a.y1, b.y1);
    final interX2 = math.min(a.x2, b.x2);
    final interY2 = math.min(a.y2, b.y2);

    final interW = math.max(0.0, interX2 - interX1);
    final interH = math.max(0.0, interY2 - interY1);
    final interArea = interW * interH;

    final areaA = (a.x2 - a.x1) * (a.y2 - a.y1);
    final areaB = (b.x2 - b.x1) * (b.y2 - b.y1);
    final union = areaA + areaB - interArea;
    if (union <= 0.0) return 0.0;
    return interArea / union;
  }
}
