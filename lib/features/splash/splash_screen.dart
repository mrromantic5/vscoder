import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../shared/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (mounted) Navigator.pushReplacementNamed(context, '/projects');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Logo — tries assets/logo.png, falls back to gradient icon ──
            _SplashLogo()
                .animate()
                .scale(begin: const Offset(0.55, 0.55), duration: 650.ms, curve: Curves.easeOutBack)
                .fadeIn(duration: 500.ms),

            const SizedBox(height: 28),

            // App name
            const Text(
              'VScoder',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
              ),
            )
                .animate(delay: 320.ms)
                .fadeIn(duration: 500.ms)
                .slideY(begin: 0.25, duration: 500.ms, curve: Curves.easeOut),

            const SizedBox(height: 8),

            const Text(
              'Professional Mobile Code Editor',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ).animate(delay: 520.ms).fadeIn(duration: 400.ms),

            const SizedBox(height: 64),

            // Animated loading dots
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return Container(
                  width: 6, height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                )
                    .animate(
                      delay: Duration(milliseconds: 720 + i * 140),
                      onPlay: (c) => c.repeat(reverse: true),
                    )
                    .scaleXY(begin: 0.4, end: 1.0, duration: 500.ms, curve: Curves.easeInOut)
                    .fadeIn(begin: 0.2);
              }),
            ).animate(delay: 600.ms).fadeIn(duration: 300.ms),
          ],
        ),
      ),
    );
  }
}

/// Tries to load `assets/logo.png`. Falls back to the branded
/// gradient icon so the splash never shows a broken image.
class _SplashLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96, height: 96,
      child: Image.asset(
        'assets/logo.png',
        width: 96, height: 96,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Container(
          width: 96, height: 96,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF58A6FF), Color(0xFF1F6FEB)],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withOpacity(0.45),
                blurRadius: 36,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(Icons.code_rounded, color: Colors.white, size: 50),
        ),
      ),
    );
  }
}
