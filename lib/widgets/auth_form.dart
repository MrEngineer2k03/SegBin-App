import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../services/auth_service.dart';
import 'loading_overlay.dart';
import '../screens/main_screen.dart';

class AuthForm extends StatefulWidget {
  final bool isLogin;
  final VoidCallback onToggleMode;

  const AuthForm({
    super.key,
    required this.isLogin,
    required this.onToggleMode,
  });

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      bool success;
      if (widget.isLogin) {
        success = await AuthService.login(
          _usernameController.text.trim(),
          _passwordController.text.trim(),
        );
      } else {
        success = await AuthService.register(
          _usernameController.text.trim(),
          _passwordController.text.trim(),
        );
      }

      if (success) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        }
      } else {
        setState(() {
          _errorMessage = widget.isLogin
              ? 'Invalid credentials.'
              : 'Username already exists or cannot register with staff username.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      message: widget.isLogin ? 'Signing you in…' : 'Creating your account…',
      child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.isLogin ? 'Login' : 'Register',
            style: Theme.of(context).textTheme.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Username',
              hintText: 'e.g. eco_warrior or staff',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a username';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Password',
              hintText: '••••••••',
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a password';
              }
              return null;
            },
          ),
          
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.dangerColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppConstants.dangerColor.withOpacity(0.3),
                ),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  color: AppConstants.dangerColor,
                  fontSize: 14,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppConstants.bgColor,
                            ),
                          ),
                        )
                      : Text(widget.isLogin ? 'Login' : 'Register'),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _isLoading ? null : widget.onToggleMode,
                child: Text(
                  widget.isLogin ? 'Create account' : 'Back to login',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
        ],
      ),
    ),
  );
  }
}
