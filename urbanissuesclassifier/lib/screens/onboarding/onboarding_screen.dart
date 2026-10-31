import 'package:flutter/material.dart';
import 'package:urbanissuesclassifier/widgets/glass_overlay.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      'title': 'Snap & Report',
      'description':
          'Capture urban issues instantly.\nHelp your city becoming cleaner and safer.',
      'image': 'assets/images/pothole_bg.jpg',
    },
    {
      'title': 'AI Analysis',
      'description':
          'Our smart AI automatically detects\npotholes, garbage, and humps.',
      'image': 'assets/images/garbage_bg.png',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Stack(
          children: [
            // Background PageView
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    // Background Image
                    Positioned.fill(
                      child: Image.asset(
                        _pages[index]['image']!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFF1A1A1A),
                            child: const Center(
                              child: Icon(
                                Icons.image,
                                size: 80,
                                color: Colors.white24,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Dark overlay for better glass visibility
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.3),
                              Colors.black.withOpacity(0.5),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            // Glass strip + content (outside the glass), responsive
            LayoutBuilder(
              builder: (context, constraints) {
                final double panelWidth = (constraints.maxWidth * 0.6).clamp(
                  240.0,
                  360.0,
                );
                final bool isCompact = panelWidth < 300;
                final double titleSize = isCompact ? 32 : 38;
                final double descSize = isCompact ? 15 : 17;

                return Stack(
                  children: [
                    // Left rectangular glass strip (full height)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: GlassOverlay(
                        blur: 15,
                        opacity: 0.12,
                        borderRadius: BorderRadius.zero,
                        enableBorder: false,
                        width: panelWidth,
                        padding: EdgeInsets.zero,
                        child: const SizedBox.shrink(),
                      ),
                    ),

                    // Content placed over/near the glass, not clipped to it
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 32, right: 24),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: panelWidth),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _pages[_currentPage]['title']!,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: titleSize,
                                  fontWeight: FontWeight.w700,
                                  height: 1.15,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              SizedBox(height: isCompact ? 16 : 20),
                              Text(
                                _pages[_currentPage]['description']!,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.95),
                                  fontSize: descSize,
                                  fontWeight: FontWeight.w400,
                                  height: 1.5,
                                  letterSpacing: 0.1,
                                ),
                              ),
                              const SizedBox(height: 28),
                              Row(
                                children: List.generate(
                                  _pages.length,
                                  (index) => AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    margin: const EdgeInsets.only(right: 8),
                                    width: _currentPage == index ? 28 : 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: _currentPage == index
                                          ? Colors.white
                                          : Colors.white.withOpacity(0.35),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            // Top-left branding
            Positioned(
              top: 16,
              left: 20,
              child: const Text(
                'URBAN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 3.5,
                ),
              ),
            ),

            // Skip button at top-right (outside the glass)
            Positioned(
              top: 8,
              right: 12,
              child: TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/get-started');
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),

            // Bottom-right arrow button (outside the glass) - direct Positioned
            Positioned(
              right: 12,
              bottom: 12,
              child: Builder(
                builder: (context) {
                  final double w = MediaQuery.of(context).size.width;
                  final bool compact = w < 360;
                  final double buttonSize = compact ? 56 : 68;
                  return GestureDetector(
                    onTap: () {
                      if (_currentPage < _pages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        Navigator.pushReplacementNamed(context, '/get-started');
                      }
                    },
                    child: Container(
                      width: buttonSize,
                      height: buttonSize,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Color(0xFF1A1A1A),
                        size: 28,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
