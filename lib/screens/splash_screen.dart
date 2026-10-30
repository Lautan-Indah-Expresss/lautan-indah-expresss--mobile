import 'package:flutter/material.dart';
import '../core/session_manager.dart';
import '../widgets/typography_logo.dart';
import 'driver_home_screen.dart';
import 'driver_login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _controller.forward();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    // Artificial minimum duration to allow driver to see brand logotype
    final results = await Future.wait([
      SessionManager.isLoggedIn(),
      Future.delayed(const Duration(milliseconds: 1400)),
    ]);

    if (!mounted) return;

    final isLoggedIn = results[0] as bool;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => isLoggedIn
            ? const DriverHomeScreen()
            : const DriverLoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                ),
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),
                // Pure Typography Logo for Mobile Splash
                const TypographyLogo(
                  variant: LogoVariant.driver,
                  themeMode: LogoThemeMode.dark,
                  style: LogoStyle.velocity,
                  size: LogoSize.extraLarge,
                  customSubtitle: 'APLIKASI TUGAS PENGEMUDI B2B',
                ),
                const SizedBox(height: 12),
                const Text(
                  'PT LAUTAN INDAH EXPRESS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3.5,
                    color: Color(0xFF64748B),
                  ),
                ),
                const Spacer(flex: 2),
                // Minimal smooth loading indicator
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Memuat data sesi armada...',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const Spacer(flex: 1),
                const Text(
                  'v1.3.10 • B2B Fleet System',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF475569),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
