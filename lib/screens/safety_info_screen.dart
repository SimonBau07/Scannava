import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../config/routes.dart';

class SafetyInfoScreen extends StatelessWidget {
  const SafetyInfoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          children: [
            Text('Safety Information'),
            Text(
              'Cyanide Toxicity & Prevention',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Critical Warning
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red, width: 2),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CRITICAL WARNING',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Bitter cassava contains high levels of cyanogenic glucosides. Consuming improperly processed bitter cassava can cause SEVERE cyanide poisoning, which can be FATAL. ALWAYS ensure proper processing before consumption.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red[900],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildSection(
              icon: Icons.shield,
              iconColor: Colors.purple,
              title: 'Understanding Cyanide Poisoning',
              content: const Text(
                'What is Cyanide?\n\n'
                'Cyanogenic glucosides (primarily linamarin and lotaustralin) in cassava break down into hydrogen cyanide (HCN) when the plant tissue is damaged. This chemical prevents cells from using oxygen, leading to tissue death and potentially fatal poisoning.',
                style: TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 16),
            _buildSection(
              icon: Icons.health_and_safety,
              iconColor: Colors.red,
              title: 'Emergency Response',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'If you suspect cyanide poisoning:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildBulletPoint(
                      'Contact emergency services immediately (call emergency number)'),
                  _buildBulletPoint(
                      'Induce vomiting ONLY if instructed by medical professionals'),
                  _buildBulletPoint(
                      'Move to fresh air if exposed to cyanide gas'),
                  _buildBulletPoint(
                      'Do NOT give anything by mouth if person is unconscious'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildSection(
              icon: Icons.tips_and_updates,
              iconColor: Colors.green,
              title: 'Prevention Guidelines',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.safeGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Safe Consumption Practices',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildBulletPoint('Always peel cassava before processing'),
                        _buildBulletPoint(
                            'Never eat raw cassava of any variety'),
                        _buildBulletPoint(
                            'Ensure adequate cooking/processing for bitter varieties'),
                        _buildBulletPoint(
                            'Discard cooking water (contains cyanide)'),
                        _buildBulletPoint(
                            'Store cassava properly to prevent deterioration'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildSection(
              icon: Icons.list_alt,
              iconColor: Colors.orange,
              title: 'What NOT To Do',
              content: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warningYellow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBulletPoint('Do NOT eat raw cassava under any circumstances'),
                    _buildBulletPoint(
                        'Do NOT consume inadequately processed bitter cassava'),
                    _buildBulletPoint(
                        "Do NOT reuse water used for soaking/cooking cassava"),
                    _buildBulletPoint(
                        'Do NOT consume cassava as sole dietary staple'),
                    _buildBulletPoint(
                        "Do NOT ignore symptoms of cyanide poisoning"),
                    _buildBulletPoint(
                        'Do NOT consume cassava as sole dietary staple'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildSection(
              icon: Icons.warning_amber,
              iconColor: Colors.purple,
              title: 'High-Risk Groups',
              content: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'The following groups are more susceptible to cyanide poisoning:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildRiskGroupBadge(Icons.child_care, 'Children'),
                        const SizedBox(width: 8),
                        _buildRiskGroupBadge(Icons.pregnant_woman, 'Pregnant Women'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildRiskGroupBadge(Icons.elderly, 'Malnourished'),
                        const SizedBox(width: 8),
                        _buildRiskGroupBadge(Icons.favorite, 'Chronic Illness'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Call to action
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.smartphone,
                    color: Colors.white,
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Stay Safe with this App',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Use Scanava AI to identify cassava types and follow proper preparation guidelines',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.camera);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentOrange,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Scan Cassava Now',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskGroupBadge(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.purple),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: Colors.purple),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}