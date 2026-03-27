import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../services/feedback_service.dart';
import '../services/auth_service.dart';
import '../models/feedback.dart';
import '../state/app_state.dart';
import 'new_home_screen.dart';

/// Feedback categories with display labels, icons, and colors
enum FeedbackCategory {
  support('Support', Icons.support_agent, AppConstants.brand2Color),
  bugsErrors('Bugs & Errors', Icons.bug_report, AppConstants.dangerColor),
  ideasSuggestions('Ideas and Suggestions', Icons.lightbulb_outline, AppConstants.brandColor);

  const FeedbackCategory(this.label, this.icon, this.iconColor);
  final String label;
  final IconData icon;
  final Color iconColor;
}

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  FeedbackCategory _selectedCategory = FeedbackCategory.ideasSuggestions;
  bool _submitting = false;
  bool _showSuccess = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final String message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() => _submitting = true);

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final currentUser = AuthService.currentUser ?? appState.user;
      final String? userId = currentUser?.username;
      final String? name = currentUser?.name;
      final String? idNumber = currentUser?.idNumber;
      final String? profilePicture = currentUser?.profilePicture;

      final FeedbackService feedbackService = FeedbackService();
      final bool success = await feedbackService.submitFeedback(
        message,
        userId: userId,
        name: name,
        subject: _subjectController.text.trim().isNotEmpty
            ? _subjectController.text.trim()
            : null,
        category: _selectedCategory.label,
        idNumber: idNumber,
        profilePicture: profilePicture,
      );

      if (!mounted) return;

      if (success) {
        setState(() => _showSuccess = true);
        await Future<void>.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        setState(() {
          _showSuccess = false;
          _subjectController.clear();
          _messageController.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit feedback. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color inputBg = isDark ? AppConstants.panelColor : const Color(0xFFF5F5F5);
    final Color textColor = isDark ? AppConstants.textColor : Colors.black;
    final Color mutedText = AppConstants.mutedColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          ValueListenableBuilder<int>(
            valueListenable: NewHomeScreen.unreadCount,
            builder: (context, unreadCount, _) {
              return Stack(
                children: [
                  IconButton(
                    tooltip: 'Notifications',
                    icon: const Icon(Icons.notifications_none),
                    onPressed: () => NewHomeScreen.showNotifications?.call(),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: AppConstants.brandColor,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_showSuccess)
                  _buildSuccessView(scheme, textColor, mutedText)
                else
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(scheme, textColor, mutedText),
                        const SizedBox(height: 28),
                        _buildCategoryDropdown(inputBg, textColor, mutedText),
                        const SizedBox(height: 20),
                        _buildSubjectField(inputBg, textColor, mutedText),
                        const SizedBox(height: 20),
                        _buildMessageField(inputBg, textColor, mutedText),
                        const SizedBox(height: 16),
                        _buildAttachmentOption(mutedText),
                        const SizedBox(height: 24),
                        _buildSendButton(scheme),
                      ],
                    ),
                  ),
                const SizedBox(height: 32),
                Center(
                  child: Text(
                    'POWERED BY SEGBIN',
                    style: TextStyle(
                      color: mutedText.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme scheme, Color textColor, Color mutedText) {
    const Color accentBlue = AppConstants.brand2Color;
    return Column(
      children: [
        Container(
          height: 80,
          width: 80,
          decoration: BoxDecoration(
            color: accentBlue,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: accentBlue.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 16),
        Text(
          'We Value Your Feedback',
          style: TextStyle(
            color: textColor,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Help us improve the SEGbin experience! Share your thoughts, suggestions, or report any issues.',
          style: TextStyle(
            color: mutedText,
            fontSize: 15,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown(Color inputBg, Color textColor, Color mutedText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CATEGORY',
          style: TextStyle(
            color: mutedText,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField2<FeedbackCategory>(
          value: _selectedCategory,
          decoration: InputDecoration(
            filled: true,
            fillColor: inputBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: mutedText.withOpacity(0.2)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          isExpanded: true,
          items: FeedbackCategory.values
              .map((c) => DropdownMenuItem<FeedbackCategory>(
                    value: c,
                    child: Row(
                      children: [
                        Icon(c.icon, color: c.iconColor, size: 22),
                        const SizedBox(width: 12),
                        Text(c.label, style: TextStyle(color: textColor, fontSize: 16)),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: _submitting
              ? null
              : (FeedbackCategory? value) {
                  if (value != null) setState(() => _selectedCategory = value);
                },
          iconStyleData: IconStyleData(
            icon: Icon(Icons.keyboard_arrow_down, color: mutedText, size: 24),
          ),
          dropdownStyleData: DropdownStyleData(
            maxHeight: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: inputBg,
            ),
            isOverButton: false, // Force menu to open below the button
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectField(Color inputBg, Color textColor, Color mutedText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SUBJECT',
          style: TextStyle(
            color: mutedText,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _subjectController,
          enabled: !_submitting,
          decoration: InputDecoration(
            hintText: 'Enter a brief title...',
            hintStyle: TextStyle(color: mutedText, fontSize: 16),
            filled: true,
            fillColor: inputBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: mutedText.withOpacity(0.2)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageField(Color inputBg, Color textColor, Color mutedText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MESSAGE',
          style: TextStyle(
            color: mutedText,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _messageController,
          enabled: !_submitting,
          minLines: 4,
          maxLines: 6,
          decoration: InputDecoration(
            hintText: "Tell us what's on your mind...",
            hintStyle: TextStyle(color: mutedText, fontSize: 16),
            filled: true,
            fillColor: inputBg,
            alignLabelWithHint: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: mutedText.withOpacity(0.2)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Please enter a message' : null,
        ),
      ],
    );
  }

  Widget _buildAttachmentOption(Color mutedText) {
    return InkWell(
      onTap: _submitting
          ? null
          : () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('File attachment coming soon'),
                ),
              );
            },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(Icons.attach_file, color: AppConstants.brand2Color, size: 20),
            const SizedBox(width: 8),
            Text(
              'Attach screenshot or file (Optional)',
              style: TextStyle(color: mutedText, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSendButton(ColorScheme scheme) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _submitting ? null : _submit,
        icon: _submitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.send_rounded),
        label: Text(_submitting ? 'Sending...' : 'Send Feedback'),
        style: FilledButton.styleFrom(
          backgroundColor: AppConstants.brand2Color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildSuccessView(ColorScheme scheme, Color textColor, Color mutedText) {
    return Column(
      children: [
        _buildHeader(scheme, textColor, mutedText),
        const SizedBox(height: 32),
        Icon(Icons.check_circle_rounded, size: 56, color: AppConstants.brand2Color),
        const SizedBox(height: 16),
        Text(
          'Thank You!',
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your feedback has been received. We appreciate your input!',
          textAlign: TextAlign.center,
          style: TextStyle(color: mutedText, fontSize: 15),
        ),
      ],
    );
  }
}
