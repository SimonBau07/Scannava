import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/routes.dart';
import '../config/theme.dart';

// Ensure these files exist and are imported correctly
import 'scan_history_screen.dart';
import 'classification_guide_screen.dart';
import 'variety_catalog_screen.dart';
import 'safety_info_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  // Initialize immediately to prevent "Late Initialization Error"
  final PageController _pageController = PageController(initialPage: 0);
  
  String _userName = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'Scanava Farmer';
    });
  }

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String displayUserName = args?['name'] ?? _userName;
    final bool isGuest = args?['isGuest'] ?? false;

    return Scaffold(
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onNavTap,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.primaryGreen,
          unselectedItemColor: Colors.black45,
          selectedFontSize: 11,
          unselectedFontSize: 10,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
            BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Guide'),
            BottomNavigationBarItem(icon: Icon(Icons.library_books), label: 'Catalog'),
            BottomNavigationBarItem(icon: Icon(Icons.security), label: 'Safety'),
          ],
        ),
      ),
      
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        children: [
          _buildHomeBody(displayUserName, isGuest),
          const ScanHistoryScreen(),
          const ClassificationGuideScreen(),
          const VarietyCatalogScreen(),
          const SafetyInfoScreen(),
        ],
      ),
    );
  }

  Widget _buildHomeBody(String userName, bool isGuest) {
    return Column(
      children: [
        _buildHeader(userName, isGuest),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMainActionCard(context),
                const SizedBox(height: 25),
                const Text('Variety Reference', 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                Row(
                  children: [
                    _buildVarietyCard(
                      context: context,
                      title: 'Sweet',
                      toxin: 'Low Cyanide',
                      icon: Icons.check_circle,
                      color: AppTheme.primaryGreen,
                      desc: 'Safe for immediate cooking',
                      showSweetTab: true,
                    ),
                    const SizedBox(width: 12),
                    _buildVarietyCard(
                      context: context,
                      title: 'Bitter',
                      toxin: 'High Cyanide',
                      icon: Icons.warning_rounded,
                      color: Colors.redAccent,
                      desc: 'Requires heavy processing',
                      showSweetTab: false,
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                _buildRecommendationCard(
                  title: "Safety Pro-Tip",
                  subtitle: "Always peel cassava deeply. The skin contains the highest concentration of toxins.",
                  icon: Icons.tips_and_updates_outlined,
                ),
                const SizedBox(height: 25),
                if (isGuest) _buildGuestWarning(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- HEADER WITHOUT NOTIFICATION ICON ---
  Widget _buildHeader(String userName, bool isGuest) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryGreen, Color(0xFF1B5E20)],
        ),
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: SafeArea(
        child: Padding(
          // Adjusted top padding to 40 for a clean, centered look
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 30), 
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Container
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                child: Container(
                  width: 85,
                  height: 85,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: ClipOval(
                      child: Image.asset('assets/images/logo2.png',
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => const Icon(Icons.eco,
                              color: AppTheme.primaryGreen, size: 45))),
                ),
              ),
              const SizedBox(height: 15),
              const Text('SCANAVA AI',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2)),
              Text(isGuest ? 'Guest Mode' : 'Welcome back $userName',
                  style: const TextStyle(color: Colors.white70, fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainActionCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.pushNamed(context, AppRoutes.camera),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15)),
                  child: const Icon(Icons.camera_enhance,
                      color: AppTheme.primaryGreen, size: 35),
                ),
                const SizedBox(width: 15),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Start Edibility Scan',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('Identify sweet or bitter varieties',
                          style: TextStyle(color: Colors.grey, fontSize: 14)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVarietyCard({
    required BuildContext context,
    required String title,
    required String toxin,
    required IconData icon,
    required Color color,
    required String desc,
    required bool showSweetTab,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, AppRoutes.classificationGuide,
            arguments: {'showSweet': showSweetTab}),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color,
                          fontSize: 16)),
                ],
              ),
              const SizedBox(height: 8),
              Text(toxin,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
              const SizedBox(height: 4),
              Text(desc,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(
      {required String title, required String subtitle, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.blueGrey.shade50,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.blueGrey.shade100)),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey),
          const SizedBox(width: 15),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                Text(subtitle,
                    style: TextStyle(color: Colors.blueGrey.shade700, fontSize: 13)),
              ])),
        ],
      ),
    );
  }

  Widget _buildGuestWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.amber.shade200)),
      child: const Row(children: [
        Icon(Icons.info_outline, color: Colors.amber),
        SizedBox(width: 12),
        Expanded(
            child: Text('Sign in to track your scans and safety reports.',
                style: TextStyle(color: Colors.brown, fontSize: 13))),
      ]),
    );
  }
}