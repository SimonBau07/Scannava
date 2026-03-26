import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/classification_result.dart';

class SavedResultsScreen extends StatelessWidget {
  const SavedResultsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Catch the result passed from the History Screen
    final result = ModalRoute.of(context)?.settings.arguments as ClassificationResult?;

    if (result == null) {
      return const Scaffold(body: Center(child: Text("No Data Found")));
    }

    final String displayName = result.label ?? result.type;
    final bool isNotCassava = result.isNotCassava;
    final bool isSafe = result.isSafe;
    final Color themeColor = isNotCassava
        ? Colors.orange
        : (isSafe ? Colors.green : Colors.red);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assessment Report'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Top Status Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isNotCassava
                    ? AppTheme.warningYellow
                    : (isSafe ? AppTheme.safeGreen : AppTheme.dangerRed),
                borderRadius: BorderRadius.circular(24),
                // ignore: deprecated_member_use
                border: Border.all(color: themeColor.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Icon(
                    isNotCassava
                        ? Icons.info_outline
                        : (isSafe ? Icons.check_circle : Icons.warning_rounded),
                    color: themeColor,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    displayName, // Using the safe String variable here
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      // ignore: deprecated_member_use
                      color: themeColor.withOpacity(0.9),
                    ),
                  ),
                  Text(
                    'Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%',
                    // ignore: deprecated_member_use
                    style: TextStyle(color: themeColor.withOpacity(0.7)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Recommendations Section
            _buildInfoSection(
              title: isNotCassava
                  ? 'Note'
                  : (isSafe ? 'Usage Recommendations' : 'Required Processing Steps'),
              icon: isNotCassava
                  ? Icons.info_outline
                  : (isSafe ? Icons.restaurant : Icons.biotech),
              color: themeColor,
              content: isNotCassava
                  ? result.recommendations.map((r) => '• $r').join('\n')
                  : (isSafe
                      ? '• Safe for boiling, steaming, or frying.\n'
                        '• Can be processed into high-quality flour.\n'
                        '• Minimal soaking required.'
                      : '• MUST be peeled deeply to remove cyanogens.\n'
                        '• Soak in water for 3-5 days (fermentation).\n'
                        '• Sun-dry or heat-treat thoroughly before use.'),
            ),
            
            const SizedBox(height: 40),
            
            // Back Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Back to History'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required Color color,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        // ignore: deprecated_member_use
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 24),
          Text(
            content,
            style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}