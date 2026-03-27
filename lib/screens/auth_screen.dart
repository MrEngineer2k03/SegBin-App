import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../widgets/auth_form.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppConstants.bgColor, AppConstants.panelColor],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Hero Section
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppConstants.brandColor, AppConstants.brand2Color],
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppConstants.bgColor,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: AppConstants.brandColor,
                                ),
                              ),
                              child: const Text(
                                '♻️ Smart Segregation',
                                style: TextStyle(
                                  color: AppConstants.brandColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Track bin capacity, earn eco-vouchers, and keep your campus clean.',
                              style: TextStyle(
                                color: AppConstants.bgColor,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Login or create an account to see real-time bin status, solar battery levels, last collection times, a simple map, and more.',
                              style: TextStyle(
                                color: AppConstants.bgColor,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildMetric(
                              Icons.chat_bubble_outline,
                              'Live capacity estimates',
                            ),
                            _buildMetric(
                              Icons.delete_outline,
                              'Last collection history',
                            ),
                            _buildMetric(
                              Icons.battery_charging_full,
                              'Solar battery monitoring',
                            ),
                            _buildMetric(
                              Icons.stars,
                              'Earn vouchers',
                            ),
                          ],
                        ),
                      ),
                      // Form Section
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: AuthForm(
                          isLogin: _isLogin,
                          onToggleMode: _toggleMode,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppConstants.bgColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppConstants.bgColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
