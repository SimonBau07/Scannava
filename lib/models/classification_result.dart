class ClassificationResult {
  final String id;
  final String type; // 'Sweet Cassava', 'Bitter Cassava', or 'Not Cassava'
  final double confidence;
  final List<String> recommendations;
  final String? processingSteps;
  final DateTime timestamp;
  final String imagePath;
  final bool isSaved;

  ClassificationResult({
    required this.id,
    required this.type,
    required this.confidence,
    required this.recommendations,
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
      processingSteps: processingSteps ?? this.processingSteps,
      timestamp: timestamp ?? this.timestamp,
      imagePath: imagePath ?? this.imagePath,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}