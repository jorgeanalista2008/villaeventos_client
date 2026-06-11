import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/auth_state.dart';
import '../core/providers/cart_state.dart';
import 'login_page.dart';
import 'menu_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    _startAnimationAndInit();
  }

  Future<void> _startAnimationAndInit() async {
    // Fetch providers before any async gap to avoid BuildContext issues
    final auth = Provider.of<AuthState>(context, listen: false);

    // 1. Wait a tiny bit then trigger the fade-in animation
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    setState(() {
      _opacity = 1.0;
    });

    // 2. Start checking session in the background
    final startTime = DateTime.now();
    await auth.checkSession();
    final endTime = DateTime.now();
    
    final elapsedMs = endTime.difference(startTime).inMilliseconds;
    const minimumDurationMs = 2500;

    if (elapsedMs < minimumDurationMs) {
      await Future.delayed(Duration(milliseconds: minimumDurationMs - elapsedMs));
    }

    if (!mounted) return;

    // Sync client saved delivery coordinates with the CartState provider if authenticated
    if (auth.isAuthenticated && auth.profile != null) {
      Provider.of<CartState>(context, listen: false).setClientDetails(auth.profile!);
    }

    // 3. Smooth transition to target page
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return auth.isAuthenticated ? const MenuPage() : const LoginPage();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 1500),
                opacity: _opacity,
                curve: Curves.easeInOut,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo Container
                    Container(
                      width: 140,
                      height: 140,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.darkCard,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: AppTheme.primaryGold, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryGold.withValues(alpha: 0.15),
                            blurRadius: 20,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.restaurant,
                            color: AppTheme.primaryGold,
                            size: 70,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Brand Text
                    const Text(
                      "Villa Eventos",
                      style: TextStyle(
                        fontFamily: 'Cinzel',
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "DELIVERY & DOMICILIOS",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGold,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Subtly positioned progress loader at the bottom
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 1000),
                  opacity: _opacity,
                  child: const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGold),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
