import 'package:flutter/material.dart';

class CurvedBackgroundScaffold extends StatelessWidget {
  final String? title;
  final Widget? topContent;
  final Widget body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final double topHeightFactor;
  final List<Widget>? actions;

  const CurvedBackgroundScaffold({
    super.key,
    this.title,
    this.topContent,
    required this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.topHeightFactor = 0.45,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Handle keyboard insets natively
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFF08343A), // Refined Deep Teal
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenHeight = MediaQuery.of(context).size.height;
          final calculatedTop = (screenHeight * topHeightFactor) - 60;

          // Ensure the curve doesn't start below the available space
          // Leave at least 50px for the white area to prevent layout errors
          final safeTop = (calculatedTop > constraints.maxHeight - 50)
              ? constraints.maxHeight - 50
              : calculatedTop;

          return Stack(
            children: [
              // 1. Dark Background Content (Top)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: screenHeight * topHeightFactor,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0D3B40),
                        Color(0xFF126872),
                        Color(0xFF2A9D8F),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Standard Header if Title provided
                          if (title != null) ...[
                            Row(
                              children: [
                                if (Navigator.canPop(context))
                                  Padding(
                                    padding: const EdgeInsets.only(right: 16),
                                    child: InkWell(
                                      onTap: () => Navigator.pop(context),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.arrow_back_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                Expanded(
                                  child: Text(
                                    title!,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (actions != null) ...actions!,
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                          // Custom Top Content
                          if (topContent != null) Expanded(child: topContent!),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 2. White Curved Layout (Bottom)
              Positioned(
                top: safeTop,
                left: 0,
                right: 0,
                bottom: 0,
                child: RepaintBoundary(
                  child: ClipPath(
                    clipper: _StandardCurveClipper(),
                    child: Container(
                      color: const Color(0xFFF3F4F6), // Light Grey/White
                      child: AnimatedPadding(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        padding: const EdgeInsets.only(
                          top: 60,
                          // Bottom padding handled by resizeToAvoidBottomInset: true
                        ),
                        child: SafeArea(top: false, child: body),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation:
          floatingActionButtonLocation ??
          FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

class _StandardCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    // Start high on left (Top of the container)
    path.moveTo(0, 0);

    // Smooth S-Curve dropping down to right
    path.cubicTo(
      size.width * 0.45,
      0, // Keep high
      size.width * 0.55,
      80, // Drop
      size.width,
      60, // End point
    );

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
