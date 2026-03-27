import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../state/app_state.dart';
import '../services/auth_service.dart';
import 'auth/signin_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: AppConstants.bgColor,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.orbitron(
            color: AppConstants.textColor,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: AppConstants.panelColor,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SettingsSection(
            children: [
              _SettingsSwitchTile(
                icon: Icons.dark_mode_outlined,
                title: 'Dark Mode',
                value: context.watch<AppState>().themeMode == ThemeMode.dark,
                onChanged: (v) {
                  context.read<AppState>().setThemeMode(
                        v ? ThemeMode.dark : ThemeMode.light,
                      );
                },
              ),
              _SettingsSwitchTile(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                value: true,
                onChanged: (v) {
                  // TODO: persist and use preference
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: 'App Information',
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SegBin Version 2.0',
                      style: TextStyle(
                        fontSize: 14,
                        color: isLight
                            ? onSurface.withOpacity(0.85)
                            : AppConstants.mutedColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'SEGBIN',
                      style: TextStyle(
                        fontSize: 14,
                        color: isLight
                            ? onSurface.withOpacity(0.85)
                            : AppConstants.mutedColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await AuthService.logout();
                if (context.mounted) {
                  context.read<AppState>().setCameFromLogout(true);
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    SignInScreen.route,
                    (route) => false,
                  );
                }
              },
              icon: const Icon(Icons.logout, size: 20),
              label: const Text('Logout'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppConstants.dangerColor,
                side: BorderSide(color: AppConstants.dangerColor),
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const _SettingsSection({this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.panelColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppConstants.textColor.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                title!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textColor,
                ),
              ),
            ),
          ],
          ...children,
        ],
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppConstants.mutedColor,
        size: 22,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppConstants.textColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppConstants.brand2Color,
      ),
    );
  }
}
