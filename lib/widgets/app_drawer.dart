import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/routes.dart';
import '../config/theme.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String _selectedLanguage = 'English';
  String _userName = 'Loading...';

  final List<Map<String, String>> _languages = [
    {'name': 'English', 'code': 'en'},
    {'name': 'Filipino', 'code': 'tl'},
    {'name': 'Waray-Waray', 'code': 'war'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'Scanava Farmer';
    });
  }

  @override
  Widget build(BuildContext context) {
    final String localUserName = _userName;

    return Drawer(
      child: Container(
        color: const Color(0xFFF8F9FA),
        child: Column(
          children: [
            // Removed _farmerID from the parameters here
            _buildProfileHeader(localUserName), 
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                children: [
                  const SizedBox(height: 10), 
                  _buildNavigationCard(context, Icons.history, 'Saved Results', AppRoutes.scanHistory),
                  _buildNavigationCard(context, Icons.menu_book, 'Classification Guide', AppRoutes.classificationGuide),
                  _buildNavigationCard(context, Icons.security, 'Safety Protocol', AppRoutes.safetyInfo),
                  _buildNavigationCard(context, Icons.library_books, 'Local Variety Catalog', AppRoutes.varietyCatalog),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Divider(),
                  ),
                  _buildLanguageSelector(),
                ],
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPER METHODS ---

  // Removed 'String id' parameter
  Widget _buildProfileHeader(String name) {
    return Container(
      padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20, right: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryGreen, Color(0xFF1B5E20)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
                ),
                child: const Icon(Icons.person, size: 45, color: AppTheme.primaryGreen),
              ),
              const Spacer(),
              IconButton(
                onPressed: () { /* Future: Logic to change name locally */ },
                icon: const Icon(Icons.edit_note, color: Colors.white70),
              )
            ],
          ),
          const SizedBox(height: 15),
          Text(
            name,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
          ),
          // The Row containing the ID and the blue check icon has been removed from here
        ],
      ),
    );
  }

  Widget _buildNavigationCard(BuildContext context, IconData icon, String title, String route) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryGreen),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF2E7D32),
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: () {
          Navigator.pop(context);
          if (route != '#') Navigator.pushNamed(context, route);
        },
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Language / Pinulongan", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 5),
          DropdownButton<String>(
            isExpanded: true,
            value: _selectedLanguage,
            icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.primaryGreen),
            underline: Container(),
            onChanged: (String? newValue) => setState(() => _selectedLanguage = newValue!),
            items: _languages.map<DropdownMenuItem<String>>((Map<String, String> lang) {
              return DropdownMenuItem<String>(
                value: lang['name'],
                child: Text(lang['name']!, style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.w500)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: 10),
          Text(
            'SCANAVA AI v1.0.0',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '© 2026 Scanava Solutions. All rights reserved.',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
          ),
        ],
      ),
    );
  }
}