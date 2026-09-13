import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quest/core/theme/app_colors_extension.dart';
import 'package:quest/features/identity/auth/data/oauth_server_service.dart';
import 'package:quest/features/identity/profile/data/user_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class OAuthConsentScreen extends ConsumerStatefulWidget {
  final String authorizationId;

  const OAuthConsentScreen({
    super.key,
    required this.authorizationId,
  });

  @override
  ConsumerState<OAuthConsentScreen> createState() => _OAuthConsentScreenState();
}

class _OAuthConsentScreenState extends ConsumerState<OAuthConsentScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  OAuthAuthorizationDetails? _details;

  @override
  void initState() {
    super.initState();
    _loadAuthorization();
  }

  Future<void> _loadAuthorization() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authUser = Supabase.instance.client.auth.currentUser;
    if (authUser == null) {
      if (!mounted) return;
      final returnUri = Uri.encodeComponent(
        '/oauth/consent?authorization_id=${widget.authorizationId}',
      );
      context.go('/login?redirect=$returnUri');
      return;
    }

    try {
      final service = ref.read(oauthServerServiceProvider);
      final details = await service.getAuthorizationDetails(widget.authorizationId);

      if (!mounted) return;

      // If user has already consented, redirect immediately
      if (details.directRedirectUrl != null && details.directRedirectUrl!.isNotEmpty) {
        await _performRedirect(details.directRedirectUrl!);
        return;
      }

      setState(() {
        _details = details;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _handleDecision({required bool approve}) async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    final service = ref.read(oauthServerServiceProvider);
    final messenger = ScaffoldMessenger.of(context);
    final colors = context.colors;

    try {
      final redirectUrl = approve
          ? await service.approveAuthorization(widget.authorizationId)
          : await service.denyAuthorization(widget.authorizationId);

      if (!mounted) return;
      await _performRedirect(redirectUrl);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Action failed: $e'),
          backgroundColor: colors.crimson,
        ),
      );
    }
  }

  Future<void> _performRedirect(String redirectUrl) async {
    final uri = Uri.parse(redirectUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
        webOnlyWindowName: '_self',
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot navigate to: $redirectUrl'),
          backgroundColor: context.colors.crimson,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final userState = ref.watch(userProvider).value ?? UserState.initial();
    final authUser = Supabase.instance.client.auth.currentUser;
    final email = authUser?.email ?? 'quest_explorer@quest.app';

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: _isLoading
                  ? _buildLoadingState(colors)
                  : _errorMessage != null
                      ? _buildErrorState(colors)
                      : _buildConsentCard(context, colors, userState, email),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(dynamic colors) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(color: colors.questBlue),
        const SizedBox(height: 20),
        Text(
          'Connecting with Quest OAuth...',
          style: TextStyle(color: colors.textSecondary, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildErrorState(dynamic colors) {
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(20),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.crimson.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, color: colors.crimson, size: 40),
            ),
            const SizedBox(height: 18),
            Text(
              'Authorization Request Failed',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage ?? 'Invalid or expired authorization request.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.questBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () => context.go('/home'),
              child: const Text('Return to Quest Home', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsentCard(
    BuildContext context,
    dynamic colors,
    UserState user,
    String email,
  ) {
    final details = _details!;
    final clientHost = _extractHost(details.redirectUri);

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(24),
      elevation: 8,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.border),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top App Branding
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colors.questBlue, colors.auroraPurple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.hub_outlined, color: Colors.white, size: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'QUEST IDENTITY SERVER',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: colors.questBlue,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Authorize Application',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.emerald.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.emerald.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock, color: colors.emerald, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'OAuth 2.1',
                        style: TextStyle(
                          color: colors.emerald,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Client Identity Presentation
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: colors.surface,
                    backgroundImage: details.clientLogoUrl != null
                        ? NetworkImage(details.clientLogoUrl!)
                        : null,
                    child: details.clientLogoUrl == null
                        ? Icon(Icons.developer_board, color: colors.questBlue, size: 24)
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          details.clientName,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.link, size: 13, color: colors.textMuted),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                clientHost,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: colors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // User Info Context Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border.withOpacity(0.6)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: colors.card,
                    backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                        ? NetworkImage(user.avatarUrl!)
                        : null,
                    child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                        ? Text(
                            user.initials,
                            style: TextStyle(
                              color: colors.questBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Signed in as ${user.name}',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          email,
                          style: TextStyle(
                            color: colors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.check_circle, color: colors.emerald, size: 16),
                ],
              ),
            ),

            const SizedBox(height: 22),

            Text(
              '${details.clientName} is requesting permission to:',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            // Scopes list
            Column(
              children: details.scopes.map((scope) => _buildScopeItem(scope, colors)).toList(),
            ),

            const SizedBox(height: 20),

            // Privacy Assurance Note
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, size: 16, color: colors.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Quest will never share your password, credentials, or private message contents without explicit approval.',
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 26),

            // Actions
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.questBlue,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _isSubmitting
                        ? null
                        : () => _handleDecision(approve: true),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Authorize & Continue',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => _handleDecision(approve: false),
                    style: TextButton.styleFrom(
                      foregroundColor: colors.textMuted,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Cancel & Deny',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScopeItem(String scope, dynamic colors) {
    IconData icon;
    String title;
    String subtitle;

    switch (scope.toLowerCase()) {
      case 'profile':
        icon = Icons.account_circle_outlined;
        title = 'Basic Profile Info';
        subtitle = 'Access your display name, handle (@username), avatar, and level/XP';
        break;
      case 'email':
        icon = Icons.email_outlined;
        title = 'Email Address';
        subtitle = 'View your primary registered email';
        break;
      case 'offline_access':
        icon = Icons.sync_outlined;
        title = 'Offline Access';
        subtitle = 'Maintain access to perform actions when you are not actively present';
        break;
      case 'openid':
        icon = Icons.verified_user_outlined;
        title = 'Identity Verification';
        subtitle = 'Confirm your unique Quest explorer account ID with OpenID Connect';
        break;
      case 'phone':
        icon = Icons.phone_outlined;
        title = 'Phone Number';
        subtitle = 'Access your verified phone number';
        break;
      default:
        icon = Icons.extension_outlined;
        title = scope;
        subtitle = 'Custom permission requested by third-party application';
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colors.questBlue.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: colors.questBlue, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _extractHost(String uriString) {
    if (uriString.isEmpty) return 'Local client application';
    try {
      final uri = Uri.parse(uriString);
      return uri.host.isNotEmpty ? uri.host : uriString;
    } catch (_) {
      return uriString;
    }
  }
}
