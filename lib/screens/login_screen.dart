// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onDone;
  const LoginScreen({super.key, required this.onDone});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeIn  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _signIn() async {
    setState(() => _loading = true);
    final ok = await AuthService().signIn();
    if (mounted) setState(() => _loading = false);
    if (ok) widget.onDone();
  }

  Future<void> _skip() async {
    await AuthService().skipAuth();
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: SlideTransition(
            position: _slideUp,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Logo arabesque
                  Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.gold.withOpacity(0.3), width: 1.5),
                    ),
                    child: const Center(
                      child: Text('🎂', style: TextStyle(fontSize: 42)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text('Pâtisserie',
                    style: TextStyle(
                      fontFamily: 'PlayfairDisplay',
                      color: AppColors.gold,
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    )),
                  Text('Orientale',
                    style: TextStyle(
                      fontFamily: 'PlayfairDisplay',
                      color: AppColors.textSecondary,
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 4,
                    )),

                  const SizedBox(height: 12),
                  Container(
                    width: 40, height: 2,
                    color: AppColors.gold.withOpacity(0.5),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Gestion de stock & commandes\npour vos gâteaux traditionnels',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15, height: 1.6,
                    )),

                  const Spacer(flex: 2),

                  // Google Sign-In
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Sauvegarde Gmail',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16, fontWeight: FontWeight.w700,
                          )),
                        const SizedBox(height: 6),
                        const Text(
                          'Connectez votre compte Gmail pour\nsauvegarder vos données sur Google Drive',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
                        const SizedBox(height: 20),

                        // Google button
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _signIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF1F1F1F),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            ),
                            child: _loading
                              ? const SizedBox(
                                  width: 22, height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppColors.gold))
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _GoogleIcon(),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Continuer avec Google',
                                      style: TextStyle(
                                        fontSize: 15, fontWeight: FontWeight.w700)),
                                  ],
                                ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Séparateur
                        Row(
                          children: [
                            const Expanded(child: Divider(color: AppColors.border)),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('ou',
                                style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 12))),
                            const Expanded(child: Divider(color: AppColors.border)),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Skip
                        SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: _skip,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                              side: const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('Continuer sans compte',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    'Vos données sont stockées localement sur votre appareil.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 22, height: 22,
      child: Text('G',
        style: TextStyle(
          color: Color(0xFF4285F4),
          fontSize: 18, fontWeight: FontWeight.w900)),
    );
  }
}
