import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../landing_screen.dart';
import 'signin_screen.dart';
import '../../constants/app_constants.dart';
import '../../services/auth_service.dart';
import '../../services/connectivity_service.dart';
import '../main_screen.dart';
import 'dart:async';

class SignUpScreen extends StatefulWidget {
  static const String route = '/signup';
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  String? _department;
  String? _course;
  bool _agree = false;
  bool _obscure = true;
  String? _message;
  bool _isError = false;
  bool _isLoading = false;
  bool _isConnected = true;
  StreamSubscription<bool>? _connectivitySubscription;

  static const _accent = AppConstants.brand2Color;
  static const _textPrimary = AppConstants.textColor;
  static const _textMuted = AppConstants.mutedColor;

  static const _stepTitles = [
    'Personal Details',
    'Academic',
    'Security',
    'Review',
  ];

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
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _idNumberController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  List<String> _getCoursesByDepartment(String? department) {
    switch (department) {
      case 'College of Education':
        return [
          'Bachelor of Elementary Education',
          'Bachelor of Secondary Education',
          'Bachelor of Technology and Livelihood Education',
        ];
      case 'College of Engineering':
        return [
          'BS in Mechanical Engineering',
          'BS in Industrial Engineering',
          'BS in Electrical Engineering',
          'BS in Civil Engineering',
          'BS in Computer Engineering',
        ];
      case 'College of Technology':
        return [
          'BS in Information Technology',
          'BS in Industrial Technology',
          'BS in Mechatronics',
        ];
      case 'College of Management Entrepreneurship':
        return [
          'BS in Hospitality Management',
          'BS in Tourism Management',
          'BS in Business Administration',
        ];
      default:
        return [];
    }
  }

  void _goNext() {
    if (_currentStep == 0) {
      if (!_validateStep1()) return;
    } else if (_currentStep == 1) {
      if (!_validateStep2()) return;
    } else if (_currentStep == 2) {
      if (!_validateStep3()) return;
    } else if (_currentStep == 3) {
      _onSubmit();
      return;
    }
    setState(() {
      _currentStep++;
      _message = null;
    });
  }

  bool _validateStep1() {
    final fn = _firstNameController.text.trim();
    final ln = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final id = _idNumberController.text.trim();
    if (fn.isEmpty) {
      setState(() {
        _message = 'Please enter your first name';
        _isError = true;
      });
      return false;
    }
    if (ln.isEmpty) {
      setState(() {
        _message = 'Please enter your last name';
        _isError = true;
      });
      return false;
    }
    if (email.isEmpty) {
      setState(() {
        _message = 'Please enter your university email';
        _isError = true;
      });
      return false;
    }
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      setState(() {
        _message = 'Please enter a valid email address';
        _isError = true;
      });
      return false;
    }
    if (id.isEmpty) {
      setState(() {
        _message = 'Please enter your Student/Staff ID';
        _isError = true;
      });
      return false;
    }
    if (id.length > 7 || !RegExp(r'^[0-9]+$').hasMatch(id)) {
      setState(() {
        _message = 'ID must be up to 7 digits';
        _isError = true;
      });
      return false;
    }
    return true;
  }

  bool _validateStep2() {
    if (_department == null || _department!.isEmpty) {
      setState(() {
        _message = 'Please select your department';
        _isError = true;
      });
      return false;
    }
    if (_course == null || _course!.isEmpty) {
      setState(() {
        _message = 'Please select your course';
        _isError = true;
      });
      return false;
    }
    return true;
  }

  bool _validateStep3() {
    final pwd = _passwordController.text;
    final confirm = _confirmController.text;
    if (pwd.length < 8) {
      setState(() {
        _message = 'Password must be at least 8 characters';
        _isError = true;
      });
      return false;
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(pwd) || !RegExp(r'[0-9]').hasMatch(pwd)) {
      setState(() {
        _message = 'Password must include letters and numbers';
        _isError = true;
      });
      return false;
    }
    if (pwd != confirm) {
      setState(() {
        _message = 'Passwords do not match';
        _isError = true;
      });
      return false;
    }
    if (!_agree) {
      setState(() {
        _message = 'Please accept the Terms and Privacy Policy';
        _isError = true;
      });
      return false;
    }
    return true;
  }

  Future<void> _onSubmit() async {
    if (!_isConnected) {
      setState(() {
        _message = 'Please connect to the internet first';
        _isError = true;
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _message = null;
    });
    final name =
        '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final ok = await AuthService.register(
      email,
      password,
      name: name,
      department: _department,
      course: _course,
      idNumber: _idNumberController.text.trim().isEmpty
          ? null
          : _idNumberController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (ok) {
      context.read<AppState>().clearCameFromLogout();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
    } else {
      setState(() {
        _message =
            'Registration failed. Check your information and try again.';
        _isError = true;
      });
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
          // Match landing: dark blue-to-teal gradient
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
                          _buildStepTitle(),
                          const SizedBox(height: 28),
                          if (_message != null) _buildMessage(),
                          if (_message != null) const SizedBox(height: 18),
                          _buildStepContent(),
                          const SizedBox(height: 32),
                          _buildPrimaryButton(),
                          const SizedBox(height: 24),
                          _buildLoginLink(),
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
      child: Column(
        children: [
          Row(
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
                  icon: const Icon(Icons.arrow_back, color: _textPrimary, size: 26),
                )
              else
                IconButton(
                  onPressed: () {
                    if (_currentStep > 0) {
                      setState(() {
                        _currentStep--;
                        _message = null;
                      });
                    } else {
                      Navigator.of(context).maybePop();
                    }
                  },
                  icon: const Icon(Icons.arrow_back, color: _textPrimary, size: 26),
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
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Step ${_currentStep + 1}: ${_stepTitles[_currentStep]}',
                style: const TextStyle(
                  color: _accent,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_currentStep + 1} of 4',
                style: const TextStyle(
                  color: _textMuted,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: _accent.withOpacity(0.08),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_currentStep + 1) / 4,
                  minHeight: 5,
                  backgroundColor: _textMuted.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(_accent),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepTitle() {
    String headline;
    String subtitle;
    switch (_currentStep) {
      case 0:
        headline = 'Create Your Profile';
        subtitle =
            'Connect your university credentials to unlock AI-powered waste insights.';
        break;
      case 1:
        headline = 'Academic Info';
        subtitle = 'Select your department and program for campus analytics.';
        break;
      case 2:
        headline = 'Secure Your Account';
        subtitle =
            'Choose a strong password to protect your data and rewards.';
        break;
      case 3:
        headline = 'You\'re All Set';
        subtitle = 'Review your details and create your account.';
        break;
      default:
        headline = 'Create Your Profile';
        subtitle = '';
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          headline,
          style: const TextStyle(
            color: _textPrimary,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w800,
            fontSize: 28,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: const TextStyle(
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

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1Personal();
      case 1:
        return _buildStep2Academic();
      case 2:
        return _buildStep3Security();
      case 3:
        return _buildStep4Review();
      default:
        return _buildStep1Personal();
    }
  }

  Widget _buildFormCard({required Widget child}) {
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
          child: child,
        ),
      ),
    );
  }

  Widget _buildStep1Personal() {
    return _buildFormCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildLabel('FIRST NAME'),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildLabel('LAST NAME'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _firstNameController,
                  style: const TextStyle(color: _textPrimary, fontFamily: 'Poppins'),
                  decoration: _inputDecoration(hint: 'John'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _lastNameController,
                  style: const TextStyle(color: _textPrimary, fontFamily: 'Poppins'),
                  decoration: _inputDecoration(hint: 'Doe'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildLabel('UNIVERSITY EMAIL'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: _textPrimary, fontFamily: 'Poppins'),
            decoration: _inputDecoration(
              hint: 'j.doe@university.edu',
              prefixIcon: Icons.alternate_email,
            ),
          ),
          const SizedBox(height: 20),
          _buildLabel('STUDENT / STAFF ID'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _idNumberController,
            keyboardType: TextInputType.number,
            maxLength: 7,
            style: const TextStyle(color: _textPrimary, fontFamily: 'Poppins'),
            decoration: _inputDecoration(
              hint: 'U-12345678',
              prefixIcon: Icons.badge_outlined,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: _accent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'We use this information to verify your campus affiliation and provide localized recycling guidelines.',
                  style: TextStyle(
                    color: _textMuted,
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Academic() {
    final validDepartments = [
      'College of Engineering',
      'College of Technology',
      'College of Education',
      'College of Management Entrepreneurship',
    ];
    if (_department != null && !validDepartments.contains(_department)) {
      _department = null;
      _course = null;
    }
    return _buildFormCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('DEPARTMENT'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _department,
            hint: Text(
              'Select department',
              style: TextStyle(color: _textMuted.withOpacity(0.8), fontSize: 14),
            ),
            items: validDepartments
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() {
              _department = v;
              _course = null;
            }),
            decoration: _inputDecoration(hint: 'Select department'),
            dropdownColor: AppConstants.panelColor,
            style: const TextStyle(color: _textPrimary, fontFamily: 'Poppins'),
          ),
          const SizedBox(height: 20),
          _buildLabel('COURSE / PROGRAM'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _course,
            hint: Text(
              _department == null
                  ? 'Select department first'
                  : 'Select course',
              style: TextStyle(color: _textMuted.withOpacity(0.8), fontSize: 14),
            ),
            items: _getCoursesByDepartment(_department)
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => _course = v),
            decoration: _inputDecoration(
              hint: _department == null
                  ? 'Select department first'
                  : 'Select course',
            ),
            dropdownColor: AppConstants.panelColor,
            style: const TextStyle(color: _textPrimary, fontFamily: 'Poppins'),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3Security() {
    return _buildFormCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('PASSWORD'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscure,
            style: const TextStyle(color: _textPrimary, fontFamily: 'Poppins'),
            decoration: _inputDecoration(
              hint: 'At least 8 characters, letters & numbers',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off : Icons.visibility,
                  color: _textMuted,
                  size: 22,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildLabel('CONFIRM PASSWORD'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _confirmController,
            obscureText: _obscure,
            style: const TextStyle(color: _textPrimary, fontFamily: 'Poppins'),
            decoration: _inputDecoration(hint: 'Re-enter password'),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _agree,
                  onChanged: (v) => setState(() => _agree = v ?? false),
                  activeColor: _accent,
                  fillColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) return _accent;
                    return _textMuted.withOpacity(0.3);
                  }),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _agree = !_agree),
                  child: Text(
                    'I agree to the Terms of Service and Privacy Policy',
                    style: TextStyle(
                      color: _textMuted,
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep4Review() {
    return _buildFormCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _reviewRow('Name',
              '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'),
          const SizedBox(height: 12),
          _reviewRow('Email', _emailController.text.trim()),
          const SizedBox(height: 12),
          _reviewRow('Student/Staff ID', _idNumberController.text.trim()),
          const SizedBox(height: 12),
          _reviewRow('Department', _department ?? '—'),
          const SizedBox(height: 12),
          _reviewRow('Course', _course ?? '—'),
        ],
      ),
    );
  }

  Widget _reviewRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              color: _textMuted,
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '—' : value,
            style: const TextStyle(
              color: _textPrimary,
              fontFamily: 'Poppins',
              fontSize: 14,
            ),
          ),
        ),
      ],
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
      hintStyle: TextStyle(color: _textMuted.withOpacity(0.7), fontSize: 14),
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

  Widget _buildPrimaryButton() {
    final isLastStep = _currentStep == 3;
    final label = isLastStep ? 'Create Account' : 'NEXT STEP';
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _accent.withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: -2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: (_isLoading || !_isConnected) ? null : _goNext,
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
            fontSize: 15,
            letterSpacing: 0.5,
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(label),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Already have an account? ',
            style: TextStyle(
              color: _textMuted,
              fontFamily: 'Poppins',
              fontSize: 14,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pushReplacementNamed(
              SignInScreen.route,
            ),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Log in',
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
