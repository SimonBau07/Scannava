import 'package:flutter/material.dart';
import '../config/theme.dart';

class ClassificationGuideScreen extends StatefulWidget {
  const ClassificationGuideScreen({Key? key}) : super(key: key);

  @override
  State<ClassificationGuideScreen> createState() =>
      _ClassificationGuideScreenState();
}

class _ClassificationGuideScreenState extends State<ClassificationGuideScreen> {
  bool showSweet = true;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This catches the argument from the Home Screen to decide which tab to show
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args.containsKey('showSweet')) {
        setState(() {
          showSweet = args['showSweet'];
        });
      }
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          children: [
            Text('Classification Guide'),
            Text(
              'Understanding Cassava Types',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Info card explaining the importance of types
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.warningYellow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Why Classification Matters',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Cassava comes in two main varieties: sweet (low cyanide) and bitter (high cyanide). Proper identification is crucial for food safety and appropriate usage.',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            
            // Toggle buttons to switch between Sweet and Bitter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          showSweet = true;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            showSweet ? AppTheme.primaryGreen : Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Sweet Cassava'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          showSweet = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            !showSweet ? Colors.red[700] : Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Bitter Cassava'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Content based on selection
            if (showSweet) 
              _buildSweetCassavaContent() 
            else 
              _buildBitterCassavaContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildSweetCassavaContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoCard(
            icon: Icons.visibility,
            iconColor: Colors.green,
            title: 'Visual Characteristics',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Flesh Color', 'White to cream colored flesh when cut'),
                _buildInfoRow('Outer Skin', 'Light brown to tan colored peel'),
                _buildInfoRow('Texture', 'Smoother, less fibrous interior'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            icon: Icons.science,
            iconColor: Colors.green,
            title: 'Cyanide Content',
            content: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.safeGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Low Cyanide',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Safe for direct consumption after basic cooking',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '< 50 mg/kg',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            icon: Icons.restaurant,
            iconColor: Colors.green,
            title: 'Common Food Uses',
            content: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.safeGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildFoodUseItem(Icons.local_dining, 'Cassava Fries'),
                  _buildFoodUseItem(Icons.cake, 'Cassava Cake'),
                  _buildFoodUseItem(Icons.set_meal, 'Boiled/Steamed'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBitterCassavaContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoCard(
            icon: Icons.visibility,
            iconColor: Colors.red,
            title: 'Visual Characteristics',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Flesh Color', 'Slightly yellow or darker flesh tone'),
                _buildInfoRow('Outer Skin', 'Darker brown or reddish-brown peel'),
                _buildInfoRow('Texture', 'More fibrous, denser structure'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            icon: Icons.warning,
            iconColor: Colors.red,
            title: 'Cyanide Content',
            content: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.dangerRed,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'High Cyanide',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'REQUIRES extensive processing before consumption',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '> 50 mg/kg',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            icon: Icons.factory,
            iconColor: Colors.red,
            title: 'Primary Uses',
            content: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.dangerRed,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildFoodUseItem(Icons.grass, 'Starch\nProduction'),
                  _buildFoodUseItem(Icons.pets, 'Animal\nFeed'),
                  _buildFoodUseItem(Icons.science, 'Industrial\nStarch'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // UI Helpers (Cards, Rows, Items)
  Widget _buildInfoCard({
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
        border: Border.all(color: iconColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildFoodUseItem(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 32),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}