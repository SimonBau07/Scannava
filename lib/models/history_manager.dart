import '../models/classification_result.dart';

// This acts as a temporary "brain" for your app while it's running
class HistoryManager {
  static final List<ClassificationResult> savedResults = [];

  static void addResult(ClassificationResult result) {
    savedResults.insert(0, result); // Adds the newest scan to the top
  }
}