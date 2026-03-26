import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'config/routes.dart';
import 'config/theme.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ScanaVaAIApp());
}

class ScanaVaAIApp extends StatelessWidget {
  const ScanaVaAIApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scanava AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: AppRoutes.home,
      routes: AppRoutes.getRoutes(),
    );
  }
}