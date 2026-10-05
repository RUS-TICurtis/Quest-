import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quest/core/theme/app_colors_extension.dart';
import 'package:quest/features/identity/auth/data/auth_provider.dart';
import 'package:quest/shared/widgets/quest_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final colors = context.colors;

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final res = await ref
          .read(authProvider.notifier)
          .signUpWithEmail(email, password, name);
      if (!mounted) return;

      if (res.session == null) {
        // Supabase has email confirmation enabled
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: colors.surface,
            title: Text(
              'Verify Your Email',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Your account was created! We sent a confirmation link to $email.\n\nPlease verify your email address, then Sign In.',
              style: TextStyle(color: colors.textSecondary, height: 1.4),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.questBlue,
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  router.go('/login');
                },
                child: const Text(
                  'Go to Sign In',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
        return;
      }

      messenger.showSnackBar(
        SnackBar(
          content: const Text('Account created! Welcome to Quest.'),
          backgroundColor: colors.emerald,
        ),
      );
      final redirectParam = GoRouterState.of(
        context,
      ).uri.queryParameters['redirect'];
      if (redirectParam != null && redirectParam.isNotEmpty) {
        router.go(redirectParam);
      } else {
        router.go('/onboarding');
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
            .continueWithGoogle(GoogleIntent.signUp);
        if (!mounted) return;
        // On success the router redirect sends new accounts to onboarding.
        switch (outcome) {
          case GoogleAuthOutcome.accountExists:
            messenger.showSnackBar(
              SnackBar(
                content: const Text(
                  'A Quest account already exists for this Google account. '
                  'Please sign in instead.',
                ),
                backgroundColor: colors.crimson,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Sign In',
                  textColor: Colors.white,
                  onPressed: () => GoRouter.of(context).go('/login'),
                ),
              ),
            );
          case GoogleAuthOutcome.signedIn:
          case GoogleAuthOutcome.createdAccount:
          case GoogleAuthOutcome.cancelled:
          case GoogleAuthOutcome.noAccount:
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
                                  'Forge your real-world identity',
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

                                // Full Name
                                TextFormField(
                                  controller: _nameController,
                                  style: TextStyle(
                                    color: context.colors.textPrimary,
                                  ),
                                  textCapitalization: TextCapitalization.words,
                                  decoration: InputDecoration(
                                    labelText: 'Full Name',
                                    labelStyle: TextStyle(
                                      color: context.colors.textMuted,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.person_outline,
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
                                      return 'Please enter your name';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Email Address
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: TextStyle(
                                    color: context.colors.textPrimary,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Email Address',
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
                                      return 'Please enter your email';
                                    }
                                    if (!RegExp(
                                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                    ).hasMatch(value.trim())) {
                                      return 'Please enter a valid email';
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
                                    if (value.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Confirm Password
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: _obscureConfirmPassword,
                                  style: TextStyle(
                                    color: context.colors.textPrimary,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Confirm Password',
                                    labelStyle: TextStyle(
                                      color: context.colors.textMuted,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.lock_outline,
                                      color: context.colors.questBlue,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirmPassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: context.colors.textMuted,
                                      ),
                                      onPressed: () => setState(
                                        () => _obscureConfirmPassword =
                                            !_obscureConfirmPassword,
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
                                    if (value != _passwordController.text) {
                                      return 'Passwords do not match';
                                    }
                                    return null;
                                  },
                                ),
                                
                                const SizedBox(height: 24),

                                // Submit Button
                                QuestButton(
                                  label: _isLoading ? 'Please wait...' : 'Create Account',
                                  icon: Icons.rocket_launch,
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
                                GoRouter.of(context).push('/login');
                              },
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    color: context.colors.textSecondary,
                                    fontSize: 14,
                                  ),
                                  children: [
                                    const TextSpan(
                                      text: 'Already have an account? ',
                                    ),
                                    TextSpan(
                                      text: 'Sign In',
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
