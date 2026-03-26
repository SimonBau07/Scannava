import 'package:flutter/material.dart';
import '../config/routes.dart';
import '../models/history_manager.dart'; 
import '../widgets/classification_card.dart';

class ScanHistoryScreen extends StatelessWidget {
  const ScanHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final historyResults = HistoryManager.savedResults;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history),
            SizedBox(width: 8),
            Text('Scan History'),
          ],
        ),
      ),
      body: historyResults.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_outlined,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No scan history yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Your saved scans will appear here.'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: historyResults.length,
              itemBuilder: (context, index) {
                final result = historyResults[index];
                return ClassificationCard(
                  result: result,
                  onTap: () {
                    // MODIFIED: Point this to savedResults instead of result
                    Navigator.pushNamed(
                      context,
                      AppRoutes.savedResults, 
                      arguments: result,
                    );
                  },
                );
              },
            ),
    );
  }
}