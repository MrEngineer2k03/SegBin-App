import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';
import 'new_home_screen.dart';
import '../services/auth_service.dart';
import '../services/bin_service.dart';
import '../services/storage_service.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _departmentController = TextEditingController();
  final _courseController = TextEditingController();
  final _idNumberController = TextEditingController();
  final List<TextEditingController> _simNumberControllers = [];
  bool _isLoading = false;
  String? _message;
  String? _profileBase64; // data URL string
  final _imagePicker = ImagePicker();
  DateTime? _simulateCollectAt;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final currentUser = AuthService.currentUser;
    if (currentUser != null) {
      _usernameController.text = currentUser.username;
      _nameController.text = currentUser.name ?? '';
      _departmentController.text = currentUser.department ?? '';
      _courseController.text = currentUser.course ?? '';
      _idNumberController.text = currentUser.idNumber ?? '';

      // Load profile picture from current user data or local storage
      if (currentUser.profilePicture != null) {
        setState(() {
          _profileBase64 = currentUser.profilePicture;
        });
      } else {
        _loadProfilePicture(currentUser.username);
      }

      _initializeSimNumberControllers(currentUser.simNumbers);
    }
  }

  void _initializeSimNumberControllers(List<String> simNumbers) {
    // Dispose existing controllers
    for (var controller in _simNumberControllers) {
      controller.dispose();
    }
    _simNumberControllers.clear();

    // Create controllers for existing SIM numbers
    for (var simNumber in simNumbers) {
      _simNumberControllers.add(TextEditingController(text: simNumber));
    }

    // Add empty controllers for new SIM numbers (up to 5 total)
    while (_simNumberControllers.length < 5) {
      _simNumberControllers.add(TextEditingController());
    }
  }

  Future<void> _loadProfilePicture(String username) async {
    final img = await StorageService.loadProfilePicture(username);
    setState(() {
      _profileBase64 = img;
    });
  }

  ImageProvider? _getImageProvider() {
    if (_profileBase64 == null) return null;
    final dataUrl = _profileBase64!;
    if (dataUrl.startsWith('data:')) {
      final commaIndex = dataUrl.indexOf(',');
      if (commaIndex != -1) {
        final base64String = dataUrl.substring(commaIndex + 1);
        try {
          final bytes = base64Decode(base64String);
          return MemoryImage(bytes);
        } catch (e) {
          print('Error decoding base64: $e');
          return null;
        }
      }
    }
    return NetworkImage(dataUrl);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _departmentController.dispose();
    _courseController.dispose();
    _idNumberController.dispose();
    for (var controller in _simNumberControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService.currentUser;
    final isStaff = AuthService.isStaff;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E293B),
              Color(0xFF0F172A),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    if (Navigator.of(context).canPop())
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    if (Navigator.of(context).canPop())
                      const SizedBox(width: 16),
                    Text(
                      'Account',
                      style: GoogleFonts.orbitron(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Profile Card with Avatar
                        _buildGlassCard(
                          child: Column(
                            children: [
                              // Avatar with glow
                              _buildProfileAvatar(currentUser),
                              const SizedBox(height: 20),
                              // Avatar buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildPillButton(
                                    label: 'Change Picture',
                                    icon: Icons.camera_alt_outlined,
                                    onTap: _pickImage,
                                  ),
                                  if (_profileBase64 != null) ...[
                                    const SizedBox(width: 12),
                                    _buildPillButton(
                                      label: 'Remove',
                                      icon: Icons.delete_outline,
                                      onTap: _removePicture,
                                      isDestructive: true,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // User Information Card
                        _buildGlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionHeader('Personal Information', Icons.person_outline),
                              const SizedBox(height: 20),
                              if (!isStaff) ...[
                                _buildInfoField(
                                  label: 'Full Name',
                                  value: _nameController.text,
                                  icon: Icons.badge_outlined,
                                ),
                                const SizedBox(height: 16),
                                _buildInfoField(
                                  label: 'Department',
                                  value: _departmentController.text,
                                  icon: Icons.business_outlined,
                                ),
                                const SizedBox(height: 16),
                                _buildInfoField(
                                  label: 'Course',
                                  value: _courseController.text,
                                  icon: Icons.school_outlined,
                                ),
                                const SizedBox(height: 16),
                                _buildInfoField(
                                  label: 'ID Number',
                                  value: _idNumberController.text,
                                  icon: Icons.numbers_outlined,
                                ),
                                const SizedBox(height: 16),
                              ],
                              _buildInfoField(
                                label: 'Email / Username',
                                value: _usernameController.text,
                                icon: Icons.email_outlined,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Security Card
                        _buildSecurityCard(),
                        // Staff sections
                        if (isStaff) ...[
                          const SizedBox(height: 20),
                          _buildStaffManagementCard(),
                          const SizedBox(height: 20),
                          _buildSimNumbersCard(),
                        ],
                        const SizedBox(height: 24),
                        // Save Button
                        _buildSaveButton(),
                        // Message
                        if (_message != null) ...[
                          const SizedBox(height: 16),
                          _buildMessageBanner(),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withOpacity(0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(dynamic currentUser) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppConstants.brand2Color.withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: 5,
          ),
          BoxShadow(
            color: AppConstants.brandColor.withOpacity(0.2),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.3),
              Colors.white.withOpacity(0.1),
            ],
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF1E293B),
          ),
          child: CircleAvatar(
            radius: 56,
            backgroundColor: AppConstants.brand2Color.withOpacity(0.3),
            backgroundImage: _getImageProvider(),
            child: _profileBase64 == null
                ? Text(
                    _initials(currentUser?.username ?? 'U'),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildPillButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive 
        ? AppConstants.dangerColor 
        : AppConstants.brand2Color;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withOpacity(0.5),
              width: 1,
            ),
            color: color.withOpacity(0.1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppConstants.brand2Color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: AppConstants.brand2Color,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppConstants.brand2Color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 20,
              color: AppConstants.brand2Color.withOpacity(0.8),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.5),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isNotEmpty ? value : '—',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard() {
    final isStaff = AuthService.isStaff;
    
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Security', Icons.shield_outlined),
          const SizedBox(height: 20),
          // Change Password clickable card
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showPasswordDialog(),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAB308).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.lock_outline,
                        size: 20,
                        color: const Color(0xFFEAB308).withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Change Password',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Update your account password',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEAB308).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.lock_outline,
                size: 20,
                color: const Color(0xFFEAB308).withOpacity(0.9),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Change Password',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter new password',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                filled: true,
                fillColor: const Color(0xFF0F172A).withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Password must be at least 6 characters',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.4),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _passwordController.clear();
              Navigator.of(context).pop();
            },
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _changePassword();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.brandColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF22C55E),
            Color(0xFF16A34A),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22C55E).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _saveProfile,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.white, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBanner() {
    final isSuccess = _message!.contains('saved') || _message!.contains('success');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isSuccess ? AppConstants.brandColor : AppConstants.dangerColor)
            .withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isSuccess ? AppConstants.brandColor : AppConstants.dangerColor)
              .withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.error_outline,
            color: isSuccess ? AppConstants.brandColor : AppConstants.dangerColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _message!,
              style: TextStyle(
                color: isSuccess ? AppConstants.brandColor : AppConstants.dangerColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffManagementCard() {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Staff Management', Icons.admin_panel_settings_outlined),
          const SizedBox(height: 20),
          // Simulate Garbage Collection
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Simulate Collection Time',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickCollectDateTime,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: Text(
                            _simulateCollectAt == null
                                ? 'Select date & time'
                                : _simulateCollectAt!.toLocal().toString().substring(0, 16),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildSmallActionButton(
                      icon: Icons.play_arrow,
                      onTap: _simulateCollectAt != null ? _applySimulateCollect : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Action buttons grid
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildStaffActionButton(
                label: 'Clear Bins',
                icon: Icons.delete_sweep,
                onTap: _clearAllBins,
              ),
              _buildStaffActionButton(
                label: 'Charge All',
                icon: Icons.battery_charging_full,
                onTap: _chargeAllBatteries,
              ),
              _buildStaffActionButton(
                label: 'Reset',
                icon: Icons.restart_alt,
                onTap: _resetSystem,
                isDestructive: true,
              ),
              _buildStaffActionButton(
                label: 'Report',
                icon: Icons.article,
                onTap: _generateReport,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallActionButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppConstants.brandColor.withOpacity(onTap != null ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppConstants.brandColor.withOpacity(onTap != null ? 1 : 0.4),
          ),
        ),
      ),
    );
  }

  Widget _buildStaffActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? AppConstants.dangerColor : AppConstants.brandColor;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimNumbersCard() {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('SIM Numbers', Icons.sim_card_outlined),
          const SizedBox(height: 8),
          Text(
            'Manage up to 5 SIM numbers for this account',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 20),
          ...List.generate(5, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                      child: TextFormField(
                        controller: _simNumberControllers[index],
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'SIM Number ${index + 1}',
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.phone_android,
                            size: 18,
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _removeSimNumber(index),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppConstants.dangerColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: AppConstants.dangerColor.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: _buildStaffActionButton(
              label: 'Save SIM Numbers',
              icon: Icons.save,
              onTap: _saveSimNumbers,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffButton(String label, IconData icon, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppConstants.brandColor,
        foregroundColor: AppConstants.bgColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final currentUser = AuthService.currentUser!;
      final newPassword = _passwordController.text.trim().isEmpty
          ? null
          : _passwordController.text.trim();

      // Only update password if provided, keep other fields unchanged
      final success = await AuthService.updateProfile(
        currentUser.username, // Keep same username
        newPassword,
        name: currentUser.name, // Keep existing name
        department: currentUser.department, // Keep existing department
        course: currentUser.course, // Keep existing course
      );

      setState(() {
        _message = success ? 'Profile saved!' : 'Failed to save profile.';
      });

      if (success && newPassword != null) {
        _passwordController.clear();
      }
    } catch (e) {
      setState(() {
        _message = 'An error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery, maxWidth: 1024);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final base64 = 'data:${picked.mimeType ?? 'image/png'};base64,${base64Encode(bytes)}';

    // Save to both Firestore and local storage
    final success = await AuthService.updateProfilePicture(base64);

    if (success) {
      setState(() {
        _profileBase64 = base64;
      });
      _showNotification('Profile picture updated!', isError: false);
    } else {
      _showNotification('Failed to update profile picture', isError: true);
    }
  }

  Future<void> _removePicture() async {
    // Remove from both Firestore and local storage
    await AuthService.removeProfilePicture();

    setState(() {
      _profileBase64 = null;
    });
    _showNotification('Profile picture removed', isError: false);
  }

  String _initials(String username) {
    final parts = username.split(RegExp(r'[\s_-]+'));
    if (parts.length >= 2) {
      return (parts.first[0] + parts.last[0]).toUpperCase();
    }
    return username.substring(0, username.length >= 2 ? 2 : 1).toUpperCase();
  }

  Future<void> _pickCollectDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    if (time == null) return;
    setState(() {
      _simulateCollectAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _applySimulateCollect() async {
    if (_simulateCollectAt == null) return;
    await BinService.simulateCollect(_simulateCollectAt!);
    _showNotification('Applied simulated collection time.', isError: false);
  }

  Future<void> _clearAllBins() async {
    await BinService.clearAllBins();
    _showNotification('All bins cleared successfully!', isError: false);
  }

  Future<void> _chargeAllBatteries() async {
    await BinService.chargeAllBatteries();
    _showNotification('All batteries charged to 100%!', isError: false);
  }

  Future<void> _resetSystem() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset System'),
        content: const Text(
          'Are you sure you want to reset the entire system? This will clear all bins and randomize battery levels.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await BinService.resetSystem();
      _showNotification('System reset successfully!', isError: false);
    }
  }

  void _generateReport() {
    final report = BinService.generateReport();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('System Report'),
        content: SingleChildScrollView(
          child: Text(
            report,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showNotification(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error : Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? AppConstants.dangerColor : AppConstants.brandColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _removeSimNumber(int index) {
    if (index < _simNumberControllers.length) {
      _simNumberControllers[index].clear();
      // Refresh the UI to show the cleared field
      setState(() {});
    }
  }

  Future<void> _saveSimNumbers() async {
    // Collect non-empty SIM numbers
    final simNumbers = <String>[];
    for (var controller in _simNumberControllers) {
      final simNumber = controller.text.trim();
      if (simNumber.isNotEmpty) {
        simNumbers.add(simNumber);
      }
    }

    // Validate we don't exceed 5 SIM numbers
    if (simNumbers.length > 5) {
      _showNotification('Maximum 5 SIM numbers allowed', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = AuthService.currentUser!;
      final success = await AuthService.updateProfile(
        currentUser.username,
        null, // No password change
        name: currentUser.name,
        department: currentUser.department,
        course: currentUser.course,
        simNumbers: simNumbers,
      );

      if (success) {
        // Update current user data
        final updatedUser = currentUser.copyWith(simNumbers: simNumbers);
        // Note: You might need to add a method in AuthService to update currentUser
        _showNotification('SIM numbers saved successfully!', isError: false);
        // Reinitialize controllers with the new data
        _initializeSimNumberControllers(simNumbers);
      } else {
        _showNotification('Failed to save SIM numbers', isError: true);
      }
    } catch (e) {
      _showNotification('An error occurred while saving SIM numbers', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _changePassword() async {
    // Validate password field
    final newPassword = _passwordController.text.trim();
    if (newPassword.isEmpty) {
      _showNotification('Please enter a new password', isError: true);
      return;
    }

    if (newPassword.length < 6) {
      _showNotification('Password must be at least 6 characters', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = AuthService.currentUser!;
      final success = await AuthService.updateProfile(
        currentUser.username,
        newPassword,
        name: currentUser.name,
        department: currentUser.department,
        course: currentUser.course,
        simNumbers: currentUser.simNumbers,
      );

      if (success) {
        _passwordController.clear();
        _showNotification('Password updated successfully!', isError: false);
      } else {
        _showNotification('Failed to update password', isError: true);
      }
    } catch (e) {
      _showNotification('An error occurred while updating password', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
