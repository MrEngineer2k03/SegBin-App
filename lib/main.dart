import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'state/app_state.dart';
import 'screens/landing_screen.dart';
import 'screens/auth/signin_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/information.dart';
import 'utils/app_theme.dart';
import 'screens/main_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/staff_screen.dart';
import 'constants/app_constants.dart';
import 'services/auth_service.dart';
import 'services/connectivity_service.dart';
import 'firebase_options.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with platform-specific configuration
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final appState = AppState();
  await appState.initialize();

  // Initialize connectivity service
  await ConnectivityService().initialize();

  // Initialize Firebase Auth listener
  AuthService.initializeAuthListener((user) {
    appState.setCurrentUser(user);
  });

  runApp(
    ChangeNotifierProvider(
      create: (_) => appState,
      child: const EcoSortApp(),
    ),
  );
}

class EcoSortApp extends StatefulWidget {
  const EcoSortApp({super.key});

  @override
  State<EcoSortApp> createState() => _EcoSortAppState();
}

class _EcoSortAppState extends State<EcoSortApp> {
  bool _isConnected = true;
  StreamSubscription<bool>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _connectivitySubscription = ConnectivityService().connectionStatus.listen(
      (isConnected) {
        if (mounted) {
          setState(() {
            _isConnected = isConnected;
          });
        }
      },
    );
    // Check initial connectivity
    ConnectivityService().checkInternetConnection().then((connected) {
      if (mounted) {
        setState(() {
          _isConnected = connected;
        });
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return MaterialApp(
      title: 'EcoSort',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: appState.themeMode,
      debugShowCheckedModeBanner: false,
      home: const LandingScreen(),
      routes: {
        SignInScreen.route: (_) => const SignInScreen(),
        SignUpScreen.route: (_) => const SignUpScreen(),
        DashboardScreen.route: (_) => const DashboardScreen(),
        MainScreen.route: (_) => const MainScreen(),
        InformationScreen.route: (_) => const InformationScreen(),
        AdminScreen.route: (_) => const AdminScreen(),
        StaffScreen.route: (_) => const StaffScreen(),
      },
      builder: (context, child) {
        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: appState.themeMode == ThemeMode.dark
                    ? AppConstants.bgColor
                    : Colors.white,
              ),
              child: child,
            ),
            // Offline notification banner
            if (!_isConnected)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    color: Colors.orange,
                    child: Row(
                      children: [
                        const Icon(Icons.wifi_off, color: Colors.white),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            "You're in offline mode, please connect to internet",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
