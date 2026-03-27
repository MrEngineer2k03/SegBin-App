import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../services/app_settings_service.dart';
import '../../services/auth_service.dart';
import '../../state/app_state.dart';
import 'package:provider/provider.dart';

class SettingsAdmin extends StatefulWidget {
  const SettingsAdmin({super.key});

  @override
  State<SettingsAdmin> createState() => _SettingsAdminState();
}

class _SettingsAdminState extends State<SettingsAdmin> {
  bool _isLoggingOut = false;
  bool _isLoadingPointingSetting = true;
  bool _isPointingSystemEnabled =
      AppSettingsService.defaultPointingSystemEnabled;
  bool _isSavingPointingSetting = false;

  @override
  void initState() {
    super.initState();
    _loadPointingSystemSetting();
  }

  Future<void> _loadPointingSystemSetting() async {
    try {
      final isEnabled = await AppSettingsService.isPointingSystemEnabled();
      if (!mounted) return;

      setState(() {
        _isPointingSystemEnabled = isEnabled;
        _isLoadingPointingSetting = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingPointingSetting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load pointing system setting: $e')),
      );
    }
  }

  Future<void> _togglePointingSystem(bool enabled) async {
    final previousValue = _isPointingSystemEnabled;

    setState(() {
      _isPointingSystemEnabled = enabled;
      _isSavingPointingSetting = true;
    });

    try {
      await AppSettingsService.setPointingSystemEnabled(enabled);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabled
                ? 'Pointing system is now visible to users.'
                : 'Pointing system is now hidden from all users.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isPointingSystemEnabled = previousValue;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update pointing system: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingPointingSetting = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    setState(() {
      _isLoggingOut = true;
    });

    try {
      // Call logout from AuthService
      await AuthService.logout();

      // Clear user from app state
      final appState = context.read<AppState>();
      appState.clearUser();

      // Set cameFromLogout to show back button in sign-in screen
      appState.setCameFromLogout(true);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logged out successfully')),
        );

        // Navigate to sign in screen (consistent with app drawer implementation)
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/signin', // Navigate to SignInScreen
          (Route<dynamic> route) => false, // Remove all previous routes
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppConstants.bgColor,
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          const Text(
            'Admin Settings',
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Card(
            color: AppConstants.cardColor,
            child: ListTile(
              title: const Text(
                'Change Admin Password',
                style: TextStyle(color: AppConstants.textColor),
              ),
              subtitle: const Text(
                'Update the admin account password',
                style: TextStyle(color: AppConstants.mutedColor),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                color: AppConstants.mutedColor,
              ),
              onTap: () {
                // TODO: Implement password change
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password change not implemented yet'),
                  ),
                );
              },
            ),
          ),
          Card(
            color: AppConstants.cardColor,
            child: SwitchListTile(
              title: const Text(
                'Turn Off Pointing System',
                style: TextStyle(color: AppConstants.textColor),
              ),
              subtitle: Text(
                _isLoadingPointingSetting
                    ? 'Loading current setting...'
                    : _isPointingSystemEnabled
                        ? 'Points and rewards are visible to users.'
                        : 'Points and rewards are hidden from all users.',
                style: const TextStyle(color: AppConstants.mutedColor),
              ),
              value: !_isPointingSystemEnabled,
              activeColor: Colors.red,
              onChanged: _isLoadingPointingSetting || _isSavingPointingSetting
                  ? null
                  : (value) => _togglePointingSystem(!value),
              secondary: _isSavingPointingSetting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(
                      Icons.visibility_off_outlined,
                      color: AppConstants.mutedColor,
                    ),
            ),
          ),
          Card(
            color: AppConstants.cardColor,
            child: ListTile(
              title: const Text(
                'System Configuration',
                style: TextStyle(color: AppConstants.textColor),
              ),
              subtitle: const Text(
                'Configure system settings',
                style: TextStyle(color: AppConstants.mutedColor),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                color: AppConstants.mutedColor,
              ),
              onTap: () {
                // TODO: Implement system config
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('System configuration not implemented yet'),
                  ),
                );
              },
            ),
          ),
          Card(
            color: AppConstants.cardColor,
            child: ListTile(
              title: const Text(
                'Backup Data',
                style: TextStyle(color: AppConstants.textColor),
              ),
              subtitle: const Text(
                'Create a backup of all data',
                style: TextStyle(color: AppConstants.mutedColor),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                color: AppConstants.mutedColor,
              ),
              onTap: () {
                // TODO: Implement backup
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Backup not implemented yet')),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          // Logout Section
          const Text(
            'Account',
            style: TextStyle(
              color: AppConstants.mutedColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            color: Colors.red.shade50,
            child: ListTile(
              title: Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'Sign out of your admin account',
                style: TextStyle(color: Colors.red.shade400),
              ),
              trailing: _isLoggingOut
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                      ),
                    )
                  : Icon(Icons.logout, color: Colors.red.shade400),
              onTap: _isLoggingOut ? null : _handleLogout,
            ),
          ),
        ],
      ),
    );
  }
}
