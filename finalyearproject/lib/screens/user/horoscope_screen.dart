import 'package:flutter/material.dart';
import '../../config/theme.dart';

class HoroscopeScreen extends StatefulWidget {
  final List<dynamic> horoscopes;
  final int initialIndex;

  const HoroscopeScreen({
    super.key,
    required this.horoscopes,
    this.initialIndex = 0,
  });

  @override
  State<HoroscopeScreen> createState() => _HoroscopeScreenState();
}

class _HoroscopeScreenState extends State<HoroscopeScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _getZodiacEmoji(String sign) {
    final Map<String, String> emojis = {
      'मेष': '♈', 'वृष': '♉', 'मिथुन': '♊', 'कर्कट': '♋',
      'सिंह': '♌', 'कन्या': '♍', 'तुला': '♎', 'वृश्चिक': '♏',
      'धनु': '♐', 'मकर': '♑', 'कुम्भ': '♒', 'मीन': '♓',
    };
    return emojis[sign] ?? '✨';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryPurple,
      appBar: AppBar(
        title: const Text('Daily Rashifal', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Sign Selector (horizontal thumbnails)
          Container(
            height: 70,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.horoscopes.length,
              itemBuilder: (context, index) {
                final h = widget.horoscopes[index];
                final isSelected = _currentIndex == index;
                return GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.gold : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        h['sign'],
                        style: TextStyle(
                          color: isSelected ? AppTheme.primaryDark : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Main Carousel
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemCount: widget.horoscopes.length,
              itemBuilder: (context, index) {
                final h = widget.horoscopes[index];
                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(30),
                      child: Column(
                        children: [
                          Text(
                            _getZodiacEmoji(h['sign']),
                            style: const TextStyle(fontSize: 80),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            h['sign'],
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryDark,
                            ),
                          ),
                          const Divider(height: 40),
                          Text(
                            h['content'],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              height: 1.8,
                              color: Color(0xFF444444),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Page Indicators
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.horoscopes.length,
                (index) => Container(
                  width: _currentIndex == index ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: _currentIndex == index ? AppTheme.gold : Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
