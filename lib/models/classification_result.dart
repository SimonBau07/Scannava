class ClassificationResult {
  final String id;
  final String type; // 'Sweet Cassava', 'Bitter Cassava', or 'Not Cassava'
  final double confidence;
  final List<String> recommendations;
  final List<DetectionBox> boxes;
  final int? imageWidth;
  final int? imageHeight;
  final String? processingSteps;
  final DateTime timestamp;
  final String imagePath;
  final bool isSaved;

  ClassificationResult({
    required this.id,
    required this.type,
    required this.confidence,
    required this.recommendations,
    this.boxes = const <DetectionBox>[],
    this.imageWidth,
    this.imageHeight,
    this.processingSteps,
    required this.timestamp,
    required this.imagePath,
    this.isSaved = false,
  });

  bool get isSafe => type == 'Sweet Cassava';
  bool get isNotCassava => type == 'Not Cassava';
  
  String get confidencePercentage => '${(confidence * 100).toInt()}%';

  String get timeAgo {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} mins ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'confidence': confidence,
      'recommendations': recommendations,
      'boxes': boxes.map((b) => b.toJson()).toList(),
      'imageWidth': imageWidth,
      'imageHeight': imageHeight,
      'processingSteps': processingSteps,
      'timestamp': timestamp.toIso8601String(),
      'imagePath': imagePath,
      'isSaved': isSaved,
    };
  }

  factory ClassificationResult.fromJson(Map<String, dynamic> json) {
    return ClassificationResult(
      id: json['id'],
      type: json['type'],
      confidence: json['confidence'],
      recommendations: List<String>.from(json['recommendations']),
      boxes: (json['boxes'] as List<dynamic>? ?? const <dynamic>[])
          .map((e) => DetectionBox.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      imageWidth: json['imageWidth'],
      imageHeight: json['imageHeight'],
      processingSteps: json['processingSteps'],
      timestamp: DateTime.parse(json['timestamp']),
      imagePath: json['imagePath'],
      isSaved: json['isSaved'] ?? false,
    );
  }

  String? get varietyName => null;

  get label => null;

  ClassificationResult copyWith({
    String? id,
    String? type,
    double? confidence,
    List<String>? recommendations,
    List<DetectionBox>? boxes,
    int? imageWidth,
    int? imageHeight,
    String? processingSteps,
    DateTime? timestamp,
    String? imagePath,
    bool? isSaved,
  }) {
    return ClassificationResult(
      id: id ?? this.id,
      type: type ?? this.type,
      confidence: confidence ?? this.confidence,
      recommendations: recommendations ?? this.recommendations,
      boxes: boxes ?? this.boxes,
      imageWidth: imageWidth ?? this.imageWidth,
      imageHeight: imageHeight ?? this.imageHeight,
      processingSteps: processingSteps ?? this.processingSteps,
      timestamp: timestamp ?? this.timestamp,
      imagePath: imagePath ?? this.imagePath,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}

class DetectionBox {
  final double x1;
  final double y1;
  final double x2;
  final double y2;
  final int classId;
  final double confidence;

  const DetectionBox({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.classId,
    required this.confidence,
  });

  Map<String, dynamic> toJson() => {
        'x1': x1,
        'y1': y1,
        'x2': x2,
        'y2': y2,
        'classId': classId,
        'confidence': confidence,
      };

  factory DetectionBox.fromJson(Map<String, dynamic> json) => DetectionBox(
        x1: (json['x1'] as num).toDouble(),
        y1: (json['y1'] as num).toDouble(),
        x2: (json['x2'] as num).toDouble(),
        y2: (json['y2'] as num).toDouble(),
        classId: (json['classId'] as num).toInt(),
        confidence: (json['confidence'] as num).toDouble(),
      );
}