import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../state/app_state.dart';
import '../services/auth_service.dart';
import 'auth/signup_screen.dart';
import 'dashboard_screen.dart';
import '../widgets/onboarding_dialog.dart';
import 'main_screen.dart';
import 'admin_screen.dart';
import 'staff_screen.dart';
import '../constants/app_constants.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _navigated = false;
  bool _authListenerRegistered = false;
  AppState? _appState;

  late final AnimationController _fadeInController;
  late final Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();

    _fadeInController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _fadeInAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeInController, curve: Curves.easeOutCubic),
    );
    _fadeInController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_authListenerRegistered) {
      _appState = context.read<AppState>();
      _appState!.addListener(_onAuthStateChanged);
      _authListenerRegistered = true;
    }

    _checkAuthStateAndNavigate();
  }

  Widget _getScreenForCurrentUser() {
    if (AuthService.isAdmin) return const AdminScreen();
    if (AuthService.isStaff) return const StaffScreen();
    return const MainScreen();
  }

  void _onAuthStateChanged() {
    if (!mounted) return;
    final appState = _appState ?? context.read<AppState>();
    if (appState.user != null && !_navigated) {
      _navigated = true;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => _getScreenForCurrentUser()),
      );
    }
  }

  void _checkAuthStateAndNavigate() {
    final appState = context.read<AppState>();

    if (appState.user != null && !_navigated) {
      _navigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => _getScreenForCurrentUser()),
          );
        }
      });
      return;
    }

    if (appState.user == null && !appState.onboardingCompleted && !_navigated) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final completed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => const OnboardingDialog(),
        );
        if (completed == true && mounted) {
          await appState.completeOnboarding();
        }
      });
    }
  }

  @override
  void dispose() {
    if (_authListenerRegistered && _appState != null) {
      _appState!.removeListener(_onAuthStateChanged);
    }
    _scrollController.dispose();
    _fadeInController.dispose();
    super.dispose();
  }

  static const _accent = AppConstants.brand2Color;
  static const _textPrimary = AppConstants.textColor;
  static const _textMuted = AppConstants.mutedColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.bgColor,
      body: Stack(
        children: [
          // Dashboard-aligned deep blue gradient + subtle radial glow
          DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppConstants.bgColor,
                  AppConstants.panelColor,
                  AppConstants.cardColor,
                  AppConstants.bgColor,
                ],
                stops: [0.0, 0.35, 0.7, 1.0],
              ),
            ),
          ),
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _accent.withOpacity(0.12),
                    _accent.withOpacity(0.04),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 120,
            right: -100,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppConstants.brandColor.withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeInAnimation,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _accent.withOpacity(0.4),
                                blurRadius: 14,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 15,
                            backgroundColor: _accent,
                            child: const Icon(
                              Icons.recycling,
                              size: 18,
                              color: Color(0xFF02131F),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'SEG',
                                style: GoogleFonts.orbitron(
                                  color: _textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              TextSpan(
                                text: 'bin',
                                style: GoogleFonts.orbitron(
                                  color: _accent,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          color: _accent.withOpacity(0.12),
                          border: Border.all(color: _accent.withOpacity(0.4)),
                          boxShadow: [
                            BoxShadow(
                              color: _accent.withOpacity(0.08),
                              blurRadius: 14,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Text(
                          ' LIVE AT CTU DANAO',
                          style: TextStyle(
                            color: _accent,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Center(child: _HeadingText()),
                    const SizedBox(height: 18),
                    const Center(
                      child: Text(
                        'The future of sustainability at CTU\nDanao starts here. Real-time\nsegregation, automated tracking.',
                        style: TextStyle(
                          color: _textMuted,
                          fontSize: 16,
                          height: 1.6,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const _PreviewCard(),
                    const SizedBox(height: 32),
                    _GlowButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed(SignUpScreen.route);
                      },
                      child: const Text('Get Started'),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(
                            context,
                          ).pushNamed(DashboardScreen.route);
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: _textPrimary.withOpacity(0.2),
                          ),
                          foregroundColor: _textPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          textStyle: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          backgroundColor: AppConstants.cardColor.withOpacity(
                            0.35,
                          ),
                        ),
                        child: const Text('View Dashboard'),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const _StatsRow(),
                    const SizedBox(height: 40),
                    const Text(
                      'Eco-Tech Innovation',
                      style: TextStyle(
                        color: _textPrimary,
                        fontFamily: 'Poppins',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Advancing waste management through\nartificial intelligence and IoT connectivity.',
                      style: TextStyle(
                        color: _textMuted,
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 22),
                    const _FeatureCard(
                      icon: Icons.sensors_outlined,
                      title: 'Real-time Tracking',
                      subtitle: 'Monitor bin levels instantly across campus.',
                    ),
                    const SizedBox(height: 14),
                    const _FeatureCard(
                      icon: Icons.autorenew_rounded,
                      title: 'Auto-Segregation',
                      subtitle: 'AI identifies and sorts waste automatically.',
                    ),
                    const SizedBox(height: 40),
                    const _CtaCard(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeadingText extends StatelessWidget {
  const _HeadingText();

  static const _accent = AppConstants.brand2Color;
  static const _textPrimary = AppConstants.textColor;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'AI-Powered\n',
            style: TextStyle(
              color: _textPrimary,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w800,
              fontSize: 34,
              height: 1.1,
            ),
          ),
          TextSpan(
            text: 'Smart Waste\n',
            style: TextStyle(
              color: _accent,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w800,
              fontSize: 34,
              height: 1.1,
            ),
          ),
          TextSpan(
            text: 'Monitoring',
            style: TextStyle(
              color: _textPrimary,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w800,
              fontSize: 34,
              height: 1.1,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _GlowButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;

  const _GlowButton({required this.onPressed, required this.child});

  static const _accent = AppConstants.brand2Color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _accent.withOpacity(0.45),
            blurRadius: 20,
            spreadRadius: -2,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: _accent.withOpacity(0.25),
            blurRadius: 32,
            spreadRadius: -8,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: child,
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard();

  static const _accent = AppConstants.brand2Color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 275,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8E5DC), Color(0xFFD4CFC4)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Soft gradient lighting from top left
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 120,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(26),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white.withOpacity(0.15), Colors.transparent],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 150,
              height: 190,
              margin: const EdgeInsets.only(bottom: 34),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFC3BDAF), Color(0xFFACA690)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 36,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFA39A86),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                  ),
                  const Positioned(
                    top: 16,
                    right: 20,
                    child: CircleAvatar(
                      radius: 6,
                      backgroundColor: Color(0xFF121212),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.35),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'BIN STATUS',
                              style: TextStyle(
                                color: const Color(0xFF5A6B76),
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                letterSpacing: 0.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '82% Recyclables',
                              style: TextStyle(
                                color: _accent,
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.tune, color: _accent, size: 20),
                    ],
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

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _StatItem(value: '99%', label: 'ACCURACY'),
        _StatDivider(),
        _StatItem(value: '45%', label: 'EFFICIENCY'),
        _StatDivider(),
        _StatItem(value: '12t', label: 'REDUCED'),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  static const _textMuted = AppConstants.mutedColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 42,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: _textMuted.withOpacity(0.25),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  static const _textPrimary = AppConstants.textColor;
  static const _textMuted = AppConstants.mutedColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: _textPrimary,
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: _textMuted,
              fontFamily: 'Poppins',
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  static const _accent = AppConstants.brand2Color;
  static const _textPrimary = AppConstants.textColor;
  static const _textMuted = AppConstants.mutedColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _accent.withOpacity(0.2)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xE2081E32), Color(0xCC051A28)],
        ),
        boxShadow: [
          BoxShadow(
            color: _accent.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF0A2A3F),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _accent.withOpacity(0.15),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Icon(icon, color: _accent, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _textMuted,
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CtaCard extends StatelessWidget {
  const _CtaCard();

  static const _accent = AppConstants.brand2Color;
  static const _textPrimary = AppConstants.textColor;
  static const _textMuted = AppConstants.mutedColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _accent.withOpacity(0.25)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xE20C2A3C), Color(0xCC081E2C)],
        ),
        boxShadow: [
          BoxShadow(
            color: _accent.withOpacity(0.15),
            blurRadius: 36,
            spreadRadius: -12,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Ready to transform CTU\nDanao?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textPrimary,
              fontFamily: 'Poppins',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Join the smart recycling revolution\ntoday and contribute to a cleaner\ncampus.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textMuted,
              fontFamily: 'Poppins',
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: _accent.withOpacity(0.4),
                  blurRadius: 16,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed(SignUpScreen.route);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                minimumSize: const Size(130, 48),
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('Join Now'),
            ),
          ),
        ],
      ),
    );
  }
}
