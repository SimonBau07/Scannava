import 'package:flutter/material.dart';
import 'package:scanava_ai/screens/variety_catalog_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/home_screen.dart';
import '../screens/camera_screen.dart';
import '../screens/analyzing_screen.dart';
import '../screens/result_screen.dart';
import '../screens/scan_history_screen.dart';
import '../screens/saved_results_screen.dart';
import '../screens/classification_guide_screen.dart';
import '../screens/safety_info_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String home = '/home';
  static const String camera = '/camera';
  static const String analyzing = '/analyzing';
  static const String result = '/result';
  static const String scanHistory = '/scan-history';
  static const String savedResults = '/saved-results';
  static const String classificationGuide = '/classification-guide';
  static const String safetyInfo = '/safety-info';
  static const String varietyCatalog = '/variety-catalog';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      splash: (context) => const SplashScreen(),
      home: (context) => const HomeScreen(),
      camera: (context) => const CameraScreen(),
      analyzing: (context) => const AnalyzingScreen(),
      result: (context) => const ResultScreen(),
      scanHistory: (context) => const ScanHistoryScreen(),
      savedResults: (context) => const SavedResultsScreen(),
      classificationGuide: (context) => const ClassificationGuideScreen(),
      safetyInfo: (context) => const SafetyInfoScreen(),
      varietyCatalog: (context) => const VarietyCatalogScreen(),
    };
  }
}