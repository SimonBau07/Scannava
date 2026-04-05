import 'package:flutter/material.dart';
import 'dart:io';
import '../config/theme.dart';
import '../config/routes.dart';
import '../models/classification_result.dart';
import '../models/history_manager.dart'; // Ensure this is imported
import '../widgets/custom_button.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Catch the real data from the Analyzing Screen
    final result =
        ModalRoute.of(context)?.settings.arguments as ClassificationResult?;

    // Safety check: If navigation failed or data is missing
    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text("Error: No analysis data found.")),
      );
    }

    final bool isSafe = result.isSafe;
    final bool isNotCassava = result.isNotCassava;
    final Color borderColor = isNotCassava
        ? AppTheme.accentOrange
        : (isSafe ? AppTheme.primaryGreen : Colors.red);
    final Color resultColor = isNotCassava
        ? AppTheme.accentOrange
        : (isSafe ? Colors.green : Colors.red);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Result'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // DISPLAY THE REAL IMAGE FROM THE CAMERA/GALLERY
              Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: borderColor,
                    width: 3,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(17),
                  child: result.imagePath.isNotEmpty
                      ? LayoutBuilder(
                          builder: (context, constraints) {
                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(
                                  File(result.imagePath),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stack) =>
                                      const Icon(
                                    Icons.broken_image,
                                    size: 80,
                                    color: Colors.grey,
                                  ),
                                ),
                                // Box overlay intentionally removed for cleaner UX.
                              ],
                            );
                          },
                        )
                      : const Icon(
                          Icons.image_not_supported,
                          size: 80,
                          color: Colors.grey,
                        ),
                ),
              ),
              const SizedBox(height: 20),

              CustomButton(
                text: 'RETAKE',
                icon: Icons.camera_alt,
                onPressed: () => Navigator.pop(context),
                backgroundColor: AppTheme.accentOrange,
                width: double.infinity,
              ),
              const SizedBox(height: 24),

              // RESULT DATA CARD
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      // ignore: deprecated_member_use
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    )
                  ],
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.type.toUpperCase(),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: resultColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Confidence Score: ${result.confidencePercentage}',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const Divider(height: 32),
                    const Text(
                      'Usage Recommendations:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ...result.recommendations.map(
                      (rec) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              isNotCassava
                                  ? Icons.info_outline
                                  : Icons.check_circle,
                              size: 20,
                              color: resultColor,
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(rec)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // SAVE BUTTON - Logic integrated here
              CustomButton(
                text: 'Save to Result',
                icon: Icons.bookmark_add,
                onPressed: () {
                  // 1. Add the current result to the HistoryManager list
                  HistoryManager.addResult(result);

                  // 2. Show confirmation to the user
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Result saved successfully!'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );

                  // 3. Redirect to the Scan History screen
                  Navigator.pushReplacementNamed(
                      context, AppRoutes.scanHistory);
                },
                backgroundColor: AppTheme.primaryGreen,
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
