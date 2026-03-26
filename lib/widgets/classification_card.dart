import 'package:flutter/material.dart';
import '../models/classification_result.dart';
import '../config/theme.dart';

class ClassificationCard extends StatelessWidget {
  final ClassificationResult result;
  final VoidCallback? onTap;

  const ClassificationCard({
    Key? key,
    required this.result,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isSafe = result.isSafe;
    final isNotCassava = result.isNotCassava;
    final bgColor = isNotCassava
        ? AppTheme.warningYellow
        : (isSafe ? AppTheme.safeGreen : AppTheme.dangerRed);
    final textColor = isNotCassava
        ? Colors.orange[900]
        : (isSafe ? Colors.green[900] : Colors.red[900]);
    final subtitleColor = isNotCassava
        ? Colors.orange[800]
        : (isSafe ? Colors.green[800] : Colors.red[800]);
    final subtitle = isNotCassava
        ? 'Not cassava — retake with cassava root'
        : (isSafe ? 'Safe to consume' : 'Requires Processing');

    return Card(
      color: bgColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Image placeholder
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.type,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Timestamp
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      result.timeAgo,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}