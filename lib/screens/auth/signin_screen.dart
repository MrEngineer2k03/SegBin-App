import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../main_screen.dart';
import '../landing_screen.dart';
import '../admin_screen.dart';
import '../staff_screen.dart';
import 'signup_screen.dart';
import '../../constants/app_constants.dart';
import '../../services/auth_service.dart';
import '../../services/connectivity_service.dart';
import 'dart:async';

class SignInScreen extends StatefulWidget {
  static const String route = '/signin';
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _remember = false;
  String? _message;
  bool _isError = false;
  bool _isLoading = false;
  bool _isConnected = true;
  StreamSubscription<bool>? _connectivitySubscription;

  static const _accent = AppConstants.brand2Color;
  static const _textPrimary = AppConstants.textColor;
  static const _textMuted = AppConstants.mutedColor;

  @override
  void initState() {
    super.initState();
    _connectivitySubscription = ConnectivityService().connectionStatus.listen(
      (isConnected) {
        if (mounted) setState(() => _isConnected = isConnected);
      },
    );
    ConnectivityService().checkInternetConnection().then((connected) {
      if (mounted) setState(() => _isConnected = connected);
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    if (v == null || v.isEmpty) return 'Required';
    return null;
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final isConnected = await ConnectivityService().checkInternetConnection();
    if (!isConnected) {
      setState(() {
        _message = 'Please connect to the internet first';
        _isError = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
      _isError = false;
    });
    await Future<void>.delayed(const Duration(milliseconds: 150));

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final ok = await AuthService.login(email, password);
    if (!mounted) return;

    setState(() => _isLoading = false);

    if (ok) {
      await _waitForAuthState();
      if (!mounted) return;
      if (AuthService.isLoggedIn) {
        context.read<AppState>().clearCameFromLogout();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => AuthService.isAdmin
                ? const AdminScreen()
                : AuthService.isStaff
                    ? const StaffScreen()
                    : const MainScreen(),
          ),
          (route) => false,
        );
      } else {
        setState(() {
          _message = 'Sign in failed. Please try again.';
          _isError = true;
        });
      }
    } else {
      setState(() {
        _message = 'Invalid credentials';
        _isError = true;
      });
    }
  }

  Future<void> _waitForAuthState() async {
    const maxAttempts = 30;
    for (int i = 0; i < maxAttempts; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (AuthService.isLoggedIn) return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final showBackButton = appState.cameFromLogout;

    return Scaffold(
      backgroundColor: AppConstants.bgColor,
      body: Stack(
        children: [
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
            child: Column(
              children: [
                _buildHeader(showBackButton),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTitle(),
                          const SizedBox(height: 28),
                          if (_message != null) _buildMessage(),
                          if (_message != null) const SizedBox(height: 18),
                          _buildFormCard(),
                          const SizedBox(height: 32),
                          _buildSignInButton(),
                          const SizedBox(height: 24),
                          _buildSignUpLink(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool showBackButton) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 12),
      child: Row(
        children: [
          if (showBackButton)
            IconButton(
              onPressed: () {
                context.read<AppState>().clearCameFromLogout();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LandingScreen()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.arrow_back,
                  color: _textPrimary, size: 26),
            )
          else
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back,
                  color: _textPrimary, size: 26),
            ),
          Expanded(
            child: Text(
              'SEGBIN',
              textAlign: TextAlign.center,
              style: GoogleFonts.orbitron(
                color: _accent,
                fontWeight: FontWeight.w800,
                fontSize: 20,
                letterSpacing: 0.6,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Welcome Back',
          style: TextStyle(
            color: _textPrimary,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w800,
            fontSize: 28,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Sign in to access your dashboard and AI-powered waste insights.',
          style: TextStyle(
            color: _textMuted,
            fontFamily: 'Poppins',
            fontSize: 15,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: _isError
            ? const Color(0x22EF4444)
            : _accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _isError
              ? const Color(0x44EF4444)
              : _accent.withOpacity(0.35),
        ),
        boxShadow: [
          if (!_isError)
            BoxShadow(
              color: _accent.withOpacity(0.08),
              blurRadius: 14,
              spreadRadius: 0,
            ),
        ],
      ),
      child: Text(
        _message!,
        style: TextStyle(
          color: _isError ? const Color(0xFFF87171) : _accent,
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppConstants.cardColor.withOpacity(0.78),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: _accent.withOpacity(0.22)),
            boxShadow: [
              BoxShadow(
                color: _accent.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.22),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('UNIVERSITY EMAIL'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(
                    color: _textPrimary, fontFamily: 'Poppins'),
                decoration: _inputDecoration(
                  hint: 'you@university.edu',
                  prefixIcon: Icons.alternate_email,
                ),
                validator: _validateEmail,
              ),
              const SizedBox(height: 20),
              _buildLabel('PASSWORD'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscure,
                style: const TextStyle(
                    color: _textPrimary, fontFamily: 'Poppins'),
                decoration: _inputDecoration(
                  hint: 'Enter your password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: _textMuted,
                      size: 22,
                    ),
                    onPressed: () =>
                        setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _remember,
                          onChanged: (v) =>
                              setState(() => _remember = v ?? false),
                          activeColor: _accent,
                          fillColor: WidgetStateProperty.resolveWith(
                              (states) {
                            if (states.contains(WidgetState.selected)) {
                              return _accent;
                            }
                            return _textMuted.withOpacity(0.3);
                          }),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _remember = !_remember),
                        child: const Text(
                          'Remember me',
                          style: TextStyle(
                            color: _textMuted,
                            fontFamily: 'Poppins',
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(
                        color: _accent,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: _textMuted,
        fontFamily: 'Poppins',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
          color: _textMuted.withOpacity(0.7), fontSize: 14),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: _textMuted, size: 20)
          : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppConstants.panelColor.withOpacity(0.9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _textMuted.withOpacity(0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _textMuted.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _accent, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildSignInButton() {
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
        onPressed: (_isLoading || !_isConnected) ? null : _onSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _textMuted.withOpacity(0.3),
          disabledForegroundColor: _textMuted,
          padding: const EdgeInsets.symmetric(vertical: 18),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text('Sign In'),
      ),
    );
  }

  Widget _buildSignUpLink() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Don't have an account? ",
            style: TextStyle(
              color: _textMuted,
              fontFamily: 'Poppins',
              fontSize: 14,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context)
                .pushReplacementNamed(SignUpScreen.route),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Sign up',
              style: TextStyle(
                color: _accent,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
