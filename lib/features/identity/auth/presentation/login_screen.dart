import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quest/core/theme/app_colors_extension.dart';
import 'package:quest/features/identity/auth/data/auth_provider.dart';
import 'package:quest/shared/widgets/quest_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isLoading = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final colors = context.colors;

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      await ref.read(authProvider.notifier).signInWithEmail(email, password);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Welcome back!'),
          backgroundColor: colors.emerald,
        ),
      );
      final redirectParam = GoRouterState.of(
        context,
      ).uri.queryParameters['redirect'];
      if (redirectParam != null && redirectParam.isNotEmpty) {
        router.go(redirectParam);
      } else {
        router.go('/home');
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: colors.crimson),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Authentication failed: ${e.toString()}'),
          backgroundColor: colors.crimson,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    HapticFeedback.lightImpact();
    final messenger = ScaffoldMessenger.of(context);
    final colors = context.colors;

    try {
      if (kIsWeb) {
        // Web uses a full-page OAuth redirect, so intent cannot be evaluated
        // after the handshake. Known limitation (see audit report).
        await Supabase.instance.client.auth
            .signInWithOAuth(OAuthProvider.google);
      } else {
        final outcome = await ref
            .read(authProvider.notifier)
            .continueWithGoogle(GoogleIntent.signIn);
        if (!mounted) return;
        // On success the router redirect decides home vs onboarding.
        switch (outcome) {
          case GoogleAuthOutcome.noAccount:
            messenger.showSnackBar(
              SnackBar(
                content: const Text(
                  'No Quest account exists for this Google account. '
                  'Use Sign Up to create one.',
                ),
                backgroundColor: colors.crimson,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Sign Up',
                  textColor: Colors.white,
                  onPressed: () => GoRouter.of(context).push('/signup'),
                ),
              ),
            );
          case GoogleAuthOutcome.signedIn:
          case GoogleAuthOutcome.createdAccount:
          case GoogleAuthOutcome.cancelled:
          case GoogleAuthOutcome.accountExists:
            break;
        }
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      final msg = e.message.contains('not enabled')
          ? 'Google Sign-In is not enabled yet in your Supabase Dashboard.'
          : e.message;
      messenger.showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: colors.crimson,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Google Sign-In: ${e.toString()}'),
          backgroundColor: colors.crimson,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _handleGuestSignIn() async {
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final colors = context.colors;
    
    try {
      await ref.read(authProvider.notifier).signInAnonymously();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Signed in as Guest!'),
          backgroundColor: colors.emerald,
        ),
      );
      router.go('/home');
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Guest Sign-In failed: ${e.toString()}'),
          backgroundColor: colors.crimson,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    final resetEmailCtrl = TextEditingController(text: email);
    final messenger = ScaffoldMessenger.of(context);
    final colors = context.colors;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text(
          'Reset Password',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your account email to receive a password reset link:',
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: resetEmailCtrl,
              style: TextStyle(color: colors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: colors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: colors.questBlue),
            onPressed: () async {
              final resetEmail = resetEmailCtrl.text.trim();
              if (resetEmail.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await Supabase.instance.client.auth.resetPasswordForEmail(
                  resetEmail,
                );
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Password reset email sent to $resetEmail'),
                    backgroundColor: colors.emerald,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Could not send reset email: $e'),
                    backgroundColor: colors.crimson,
                  ),
                );
              }
            },
            child: const Text(
              'Send Reset Link',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: Stack(
        children: [
          // Ambient Glows
          Positioned(
            top: MediaQuery.of(context).size.height * 0.05,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                color: context.colors.questBlue.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.15,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                color: context.colors.auroraPurple.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
            ),
          ),

          SafeArea(
            child: Stack(
              children: [
                // Guest Button Top Right
                Positioned(
                  top: 0,
                  right: 16,
                  child: TextButton(
                    onPressed: _isLoading ? null : _handleGuestSignIn,
                    child: Text(
                      'Continue as Guest',
                      style: TextStyle(
                        color: context.colors.questBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header Logo & Branding
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: context.colors.questBlue,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: context.colors.questBlue.withValues(
                                          alpha: 0.4,
                                        ),
                                        blurRadius: 18,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.auto_awesome,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'Quest',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: context.colors.textPrimary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Sign in to access your guild & quests',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: context.colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 48),

                          // Card Container
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: context.colors.card,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: context.colors.border),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Google OAuth Button at the top
                                QuestButton(
                                  label: 'Continue with Google',
                                  isFullWidth: true,
                                  variant: QuestButtonVariant.secondary,
                                  icon: Icons.g_mobiledata_rounded,
                                  onPressed: _handleGoogleSignIn,
                                ),
                                
                                const SizedBox(height: 24),
                                
                                // Divider
                                Row(
                                  children: [
                                    Expanded(
                                      child: Divider(color: context.colors.border),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 14),
                                      child: Text(
                                        'or',
                                        style: TextStyle(
                                          color: context.colors.textMuted,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(color: context.colors.border),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 20),

                                // Email Address or Username
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: TextStyle(
                                    color: context.colors.textPrimary,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Email or Username',
                                    labelStyle: TextStyle(
                                      color: context.colors.textMuted,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.email_outlined,
                                      color: context.colors.questBlue,
                                    ),
                                    filled: true,
                                    fillColor: context.colors.surface,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: context.colors.border,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: context.colors.border,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: context.colors.questBlue,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter your email or username';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Password
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  style: TextStyle(
                                    color: context.colors.textPrimary,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    labelStyle: TextStyle(
                                      color: context.colors.textMuted,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.lock_outline,
                                      color: context.colors.questBlue,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: context.colors.textMuted,
                                      ),
                                      onPressed: () => setState(
                                        () => _obscurePassword = !_obscurePassword,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: context.colors.surface,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: context.colors.border,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: context.colors.border,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: context.colors.questBlue,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a password';
                                    }
                                    return null;
                                  },
                                ),

                                // Forgot Password
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _handleForgotPassword,
                                    child: Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        color: context.colors.questBlue,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 8),

                                // Submit Button
                                QuestButton(
                                  label: _isLoading ? 'Please wait...' : 'Sign In',
                                  isFullWidth: true,
                                  onPressed: _isLoading ? null : _submit,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Bottom switch text
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                GoRouter.of(context).push('/signup');
                              },
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    color: context.colors.textSecondary,
                                    fontSize: 14,
                                  ),
                                  children: [
                                    const TextSpan(
                                      text: "Don't have an account? ",
                                    ),
                                    TextSpan(
                                      text: 'Sign Up',
                                      style: TextStyle(
                                        color: context.colors.questBlue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

