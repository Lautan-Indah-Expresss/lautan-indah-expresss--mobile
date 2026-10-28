import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'core/session_manager.dart';
import 'screens/driver_login_screen.dart';
import 'screens/driver_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final isLoggedIn = await SessionManager.isLoggedIn();
  runApp(LieDriverApp(initialLoggedIn: isLoggedIn));
}

class LieDriverApp extends StatelessWidget {
  final bool initialLoggedIn;

  const LieDriverApp({super.key, required this.initialLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LIE Driver',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: initialLoggedIn
          ? const DriverHomeScreen()
          : const DriverLoginScreen(),
    );
  }
}
