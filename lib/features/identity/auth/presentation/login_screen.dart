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
  final bool initialIsSignUp;

  const LoginScreen({super.key, this.initialIsSignUp = false});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late bool _isSignUp;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.initialIsSignUp;
  }

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
      if (_isSignUp) {
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
                    setState(() => _isSignUp = false);
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
      } else {
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
            child: Center(
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
                              _isSignUp
                                  ? 'Forge your real-world identity'
                                  : 'Sign in to access your guild & quests',
                              style: TextStyle(
                                fontSize: 14,
                                color: context.colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Segmented Controller (Sign In vs Sign Up)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: context.colors.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: context.colors.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  if (_isSignUp) {
                                    HapticFeedback.selectionClick();
                                    setState(() => _isSignUp = false);
                                  }
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: !_isSignUp
                                        ? context.colors.questBlue
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Sign In',
                                      style: TextStyle(
                                        color: !_isSignUp
                                            ? Colors.white
                                            : context.colors.textMuted,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  if (!_isSignUp) {
                                    HapticFeedback.selectionClick();
                                    setState(() => _isSignUp = true);
                                  }
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _isSignUp
                                        ? context.colors.questBlue
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Create Account',
                                      style: TextStyle(
                                        color: _isSignUp
                                            ? Colors.white
                                            : context.colors.textMuted,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

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
                            // Full Name (only on Sign Up)
                            if (_isSignUp) ...[
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
                                  if (_isSignUp &&
                                      (value == null || value.trim().isEmpty)) {
                                    return 'Please enter your name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                            ],

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

                            // Confirm Password (Sign Up only)
                            if (_isSignUp) ...[
                              const SizedBox(height: 16),
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
                                  if (_isSignUp &&
                                      value != _passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                            ],

                            // Forgot Password (Sign In only)
                            if (!_isSignUp) ...[
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
                            ] else
                              const SizedBox(height: 16),

                            const SizedBox(height: 8),

                            // Submit Button
                            QuestButton(
                              label: _isLoading
                                  ? 'Please wait...'
                                  : (_isSignUp ? 'Create Account' : 'Sign In'),
                              icon: _isSignUp
                                  ? Icons.rocket_launch
                                  : Icons.login,
                              isFullWidth: true,
                              onPressed: _isLoading ? null : _submit,
                            ),
                          ],
                        ),
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
                              'or continue with',
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

                      // Google OAuth Button
                      QuestButton(
                        label: 'Continue with Google',
                        isFullWidth: true,
                        variant: QuestButtonVariant.secondary,
                        icon: Icons.g_mobiledata_rounded,
                        onPressed: () async {
                          HapticFeedback.lightImpact();
                          final messenger = ScaffoldMessenger.of(context);
                          final router = GoRouter.of(context);
                          final colors = context.colors;
                          final redirectParam = GoRouterState.of(
                            context,
                          ).uri.queryParameters['redirect'];

                          try {
                            if (kIsWeb) {
                              await Supabase.instance.client.auth
                                  .signInWithOAuth(OAuthProvider.google);
                            } else {
                              // Mobile (Android / iOS): Strictly in-app native Google Sign-In
                              final res = await ref
                                  .read(authProvider.notifier)
                                  .signInWithGoogleNative();
                              if (res != null) {
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      'Signed in with Google!',
                                    ),
                                    backgroundColor: colors.emerald,
                                  ),
                                );
                                if (redirectParam != null &&
                                    redirectParam.isNotEmpty) {
                                  router.go(redirectParam);
                                } else {
                                  final createdAt = DateTime.tryParse(res.user?.createdAt ?? '');
                                  final lastSignIn = DateTime.tryParse(res.user?.lastSignInAt ?? '');
                                  bool isNewUser = false;
                                  if (createdAt != null && lastSignIn != null) {
                                    isNewUser = lastSignIn.difference(createdAt).inSeconds.abs() < 5;
                                  }
                                  
                                  if (isNewUser) {
                                    router.go('/onboarding');
                                  } else {
                                    router.go('/home');
                                  }
                                }
                              }
                              // Note: if res == null, the user simply cancelled or dismissed the Google modal sheet
                            }
                          } on AuthException catch (e) {
                            if (!mounted) return;
                            final msg = e.message.contains('not enabled')
                                ? 'Google Sign-In is not enabled yet in your Supabase Dashboard (Authentication > Providers > Google).'
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
                                content: Text(
                                  'Google Sign-In: ${e.toString()}',
                                ),
                                backgroundColor: colors.crimson,
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          }
                        },
                      ),

                      const SizedBox(height: 24),

                      // Bottom switch text
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _isSignUp = !_isSignUp);
                          },
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                color: context.colors.textSecondary,
                                fontSize: 14,
                              ),
                              children: [
                                TextSpan(
                                  text: _isSignUp
                                      ? 'Already have an account? '
                                      : "Don't have an account? ",
                                ),
                                TextSpan(
                                  text: _isSignUp ? 'Sign In' : 'Sign Up',
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
          ),
        ],
      ),
    );
  }
}
