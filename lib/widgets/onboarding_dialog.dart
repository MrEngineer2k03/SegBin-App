import 'package:flutter/material.dart';

class OnboardingDialog extends StatefulWidget {
  const OnboardingDialog({super.key});

  @override
  State<OnboardingDialog> createState() => _OnboardingDialogState();
}

class _OnboardingDialogState extends State<OnboardingDialog>
    with TickerProviderStateMixin {
  int currentScreen = 0;
  final int totalScreens = 5;

  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _scanController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _scanAnimation;
  late Animation<double> _pulseAnimation;

  final List<OnboardingScreen> screens = [
    OnboardingScreen(
      icon: Icons.recycling,
      title: 'WELCOME TO ECOSORT',
      subtitle: 'Quick tour for our Smart Waste Segregation App.',
      gradient: [Color(0xFF4CAF50), Color(0xFF45A049), Color(0xFF66BB6A)],
      illustration: 'recycle-bin',
    ),
    OnboardingScreen(
      icon: Icons.camera_alt,
      title: 'SCAN YOUR WASTE',
      subtitle: 'Identify the right bin using our AI-powered waste scanner.',
      gradient: [Color(0xFF45A049), Color(0xFF4CAF50), Color(0xFF81C784)],
      illustration: 'scan',
    ),
    OnboardingScreen(
      icon: Icons.view_module,
      title: 'SMART SORTING',
      subtitle:
          'Our intelligent system guides proper segregation effortlessly.',
      gradient: [Color(0xFF81C784), Color(0xFF4CAF50), Color(0xFF45A049)],
      illustration: 'bins',
    ),
    OnboardingScreen(
      icon: Icons.trending_up,
      title: 'TRACK YOUR IMPACT',
      subtitle: 'Monitor how your actions help reduce waste and pollution.',
      gradient: [Color(0xFF4CAF50), Color(0xFF45A049), Color(0xFF66BB6A)],
      illustration: 'stats',
    ),
    OnboardingScreen(
      icon: Icons.public,
      title: 'JOIN THE GREEN MOVEMENT',
      subtitle: 'Together, we can make a cleaner, greener future.',
      gradient: [Color(0xFF66BB6A), Color(0xFF4CAF50), Color(0xFF45A049)],
      illustration: 'globe',
    ),
  ];

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scanController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _scanAnimation = Tween<double>(begin: 0.1, end: 0.8).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start animations
    _fadeController.forward();
    _scaleController.forward();
    _scanController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Restart animations when screen changes
    _fadeController.forward(from: 0.0);
    _scaleController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _scanController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _handleNext() {
    if (currentScreen < totalScreens - 1) {
      setState(() => currentScreen++);
    }
  }

  void _handleSkip() {
    setState(() => currentScreen = totalScreens - 1);
  }

  void _handleGetStarted() {
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final screen = screens[currentScreen];
    final isLastScreen = currentScreen == totalScreens - 1;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: 400,
        height: 760,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(48),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(48),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: screen.gradient,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.recycling,
                          color: Colors.white,
                          size: 32,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'SEGBIN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            shadows: [
                              Shadow(color: Colors.black26, blurRadius: 4),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (!isLastScreen)
                      TextButton(
                        onPressed: _handleSkip,
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            color: Color(0xE6FFFFFF),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 32),

                // Illustration
                Expanded(
                  child: Center(
                    child: AnimatedBuilder(
                      animation: Listenable.merge([
                        _fadeAnimation,
                        _scaleAnimation,
                        _pulseAnimation,
                      ]),
                      builder: (context, child) {
                        return Opacity(
                          opacity: _fadeAnimation.value,
                          child: Transform.scale(
                            scale: _scaleAnimation.value,
                            child: _buildIllustration(screen.illustration),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Text Content
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Column(
                        children: [
                          Text(
                            screen.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              height: 1.2,
                              shadows: [
                                Shadow(color: Colors.black26, blurRadius: 4),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: 280,
                            child: Text(
                              screen.subtitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Progress Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    totalScreens,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: currentScreen == index ? 32 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: currentScreen == index
                            ? Colors.white
                            : Colors.white.withOpacity(0.4),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Action Button
                isLastScreen
                    ? ElevatedButton(
                        onPressed: _handleGetStarted,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: screen.gradient.first,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          elevation: 8,
                          shadowColor: Colors.white30,
                        ),
                        child: const Text(
                          'Get Started',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : FloatingActionButton(
                        onPressed: _handleNext,
                        backgroundColor: Colors.white,
                        elevation: 8,
                        child: Icon(
                          Icons.chevron_right,
                          color: screen.gradient.first,
                          size: 32,
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIllustration(String type) {
    switch (type) {
      case 'recycle-bin':
        return Stack(
          children: [
            Container(
              width: 192,
              height: 192,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white30,
                    blurRadius: 20,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: Icon(Icons.recycling, color: Colors.white, size: 128),
            ),
            Positioned(
              bottom: -16,
              right: -16,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.yellow.withOpacity(0.6),
                ),
              ),
            ),
            Positioned(
              top: -16,
              left: -16,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withOpacity(0.6),
                ),
              ),
            ),
          ],
        );

      case 'scan':
        return Stack(
          children: [
            Container(
              width: 192,
              height: 224,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                color: Colors.white.withOpacity(0.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white30,
                    blurRadius: 20,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 96,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 4,
                      ),
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _scanController,
                    builder: (context, child) {
                      return Positioned(
                        top: 20 + (180 * _scanAnimation.value),
                        left: 0,
                        right: 0,
                        child: Container(height: 2, color: Colors.white60),
                      );
                    },
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: -8,
              left: 32,
              child: Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.yellow.withOpacity(0.5),
                ),
              ),
            ),
          ],
        );

      case 'bins':
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < 3; i++)
              AnimatedBuilder(
                animation: _scaleController,
                builder: (context, child) {
                  return Container(
                    margin: EdgeInsets.only(left: i > 0 ? 16 : 0),
                    width: 96,
                    height: 128,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: [Colors.blue, Colors.yellow, Colors.green][i],
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 8),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(Icons.recycling, color: Colors.white, size: 32),
                        const SizedBox(height: 16),
                      ],
                    ),
                  );
                },
              ),
          ],
        );

      case 'stats':
        return Stack(
          children: [
            Container(
              width: 208,
              height: 208,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                color: Colors.white.withOpacity(0.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white30,
                    blurRadius: 20,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  for (int i = 0; i < 5; i++)
                    Positioned(
                      left: 16 + i * 32,
                      bottom: 24,
                      child: AnimatedBuilder(
                        animation: _scaleController,
                        builder: (context, child) {
                          final heights = [60, 85, 40, 95, 70];
                          return Container(
                            width: 24,
                            height: heights[i].toDouble(),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: Colors.white.withOpacity(0.8),
                            ),
                          );
                        },
                      ),
                    ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Icon(
                      Icons.trending_up,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: -16,
              left: 24,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.yellow.withOpacity(0.4),
                ),
              ),
            ),
          ],
        );

      case 'globe':
        return Stack(
          children: [
            Container(
              width: 192,
              height: 192,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white30,
                    blurRadius: 20,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Icon(Icons.public, color: Colors.white, size: 128),
                  );
                },
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                width: 256,
                height: 256,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.yellow.withOpacity(0.3),
                ),
              ),
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }
}

class OnboardingScreen {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final String illustration;

  const OnboardingScreen({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.illustration,
  });
}
