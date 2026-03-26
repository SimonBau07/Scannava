import 'dart:async';
import 'package:flutter/material.dart';
import '../config/theme.dart';

class VarietyCatalogScreen extends StatefulWidget {
  const VarietyCatalogScreen({Key? key}) : super(key: key);

  @override
  State<VarietyCatalogScreen> createState() => _VarietyCatalogScreenState();
}

class _VarietyCatalogScreenState extends State<VarietyCatalogScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Local Variety Catalog"),
        backgroundColor: AppTheme.primaryGreen,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _VarietyAutoScrollCard(
            title: "Lakan 1 (Industrial/Bitter)",
            desc: "Commonly used for starch production. Features dark bark and high cyanide content.",
            images: ["assets/images/l1.png", "assets/images/l2.png", "assets/images/l3.png"],
            tagColor: Colors.redAccent,
          ),
          _VarietyAutoScrollCard(
            title: "Golden Yellow (Sweet/Makaon)",
            desc: "Favorite for 'Nilaga' or 'Suman'. Yellowish flesh, low cyanide.",
            images: ["assets/images/gy1.jpeg", "assets/images/gy2.png", "assets/images/gy3.png"],
            tagColor: Colors.orangeAccent,
          ),
          
          
          SizedBox(height: 20),
          Divider(),
          Text(
            "Regional Terms (Waray-Waray)",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          ListTile(
            leading: Icon(Icons.label, color: AppTheme.primaryGreen),
            title: Text("Balanghoy"),
            subtitle: Text("General term for Cassava in Eastern Visayas."),
          ),
          ListTile(
            leading: Icon(Icons.warning_amber, color: Colors.red),
            title: Text("Matalas / Mapait"),
            subtitle: Text("Local term for Bitter varieties (High Cyanide)."),
          ),
        ],
      ),
    );
  }
}

class _VarietyAutoScrollCard extends StatefulWidget {
  final String title;
  final String desc;
  final List<String> images;
  final Color tagColor;

  const _VarietyAutoScrollCard({
    required this.title,
    required this.desc,
    required this.images,
    required this.tagColor,
  });

  @override
  State<_VarietyAutoScrollCard> createState() => _VarietyAutoScrollCardState();
}

class _VarietyAutoScrollCardState extends State<_VarietyAutoScrollCard> {
  late PageController _pageController;
  int _fakePageValue = 1000; // Start at a high number for infinite left/right scroll
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Starting in the middle of a large number allows "infinite" looping
    _pageController = PageController(initialPage: _fakePageValue);
    
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      _fakePageValue++;
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _fakePageValue,
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 200,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: PageView.builder(
                controller: _pageController,
                // Do not set itemCount to make it infinite
                onPageChanged: (index) => setState(() => _fakePageValue = index),
                itemBuilder: (context, index) {
                  // The % operator ensures we cycle through our 3 images
                  final imageIndex = index % widget.images.length;
                  return Image.asset(
                    widget.images[imageIndex],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: widget.tagColor, borderRadius: BorderRadius.circular(5)),
                  child: Text(widget.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),
                Text(widget.desc, style: const TextStyle(color: Colors.black87, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}