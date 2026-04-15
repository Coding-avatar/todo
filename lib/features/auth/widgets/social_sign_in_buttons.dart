import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/providers.dart';
import '../../../core/router/route_names.dart';
import '../../../data/repositories/auth_repository.dart';
import 'account_conflict_dialog.dart';

/// Reusable social sign-in buttons used on both Login and Signup screens.
class SocialSignInButtons extends ConsumerStatefulWidget {
  const SocialSignInButtons({super.key});

  @override
  ConsumerState<SocialSignInButtons> createState() => _SocialSignInButtonsState();
}

class _SocialSignInButtonsState extends ConsumerState<SocialSignInButtons> {
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    try {
      await ref.read(authNotifierProvider.notifier).signInWithGoogle();
      // Navigation handled by router redirect
    } on AccountConflictException catch (e) {
      if (mounted) {
        AccountConflictDialog.show(context, e);
      }
    } on AuthException catch (e) {
      if (mounted) {
        _showErrorSnackbar(e.message);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('An unexpected error occurred.');
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() => _isAppleLoading = true);
    try {
      await ref.read(authNotifierProvider.notifier).signInWithApple();
      // Navigation handled by router redirect
    } on AccountConflictException catch (e) {
      if (mounted) {
        AccountConflictDialog.show(context, e);
      }
    } on AuthException catch (e) {
      if (mounted) {
        _showErrorSnackbar(e.message);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('An unexpected error occurred.');
      }
    } finally {
      if (mounted) setState(() => _isAppleLoading = false);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isApplePlatform = Platform.isIOS || Platform.isMacOS;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Divider ──
        Row(
          children: [
            Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Or continue with',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
          ],
        ),
        const SizedBox(height: 24),

        // ── Phone (Primary) ──
        OutlinedButton.icon(
          onPressed: () => context.pushNamed(RouteNames.phoneAuth),
          icon: const Icon(Icons.phone),
          label: const Text('Sign in with Phone Number'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: BorderSide(color: theme.colorScheme.outline),
          ),
        ),
        const SizedBox(height: 12),

        // ── Google ──
        OutlinedButton.icon(
          onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
          icon: _isGoogleLoading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.g_mobiledata, size: 24),
          label: const Text('Sign in with Google'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: BorderSide(color: theme.colorScheme.outline),
          ),
        ),

        // ── Apple (only on Apple devices) ──
        if (isApplePlatform) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _isAppleLoading ? null : _handleAppleSignIn,
            icon: _isAppleLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.apple, size: 24),
            label: const Text('Sign in with Apple'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: theme.colorScheme.outline),
              backgroundColor: theme.brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
              foregroundColor: theme.brightness == Brightness.dark
                  ? Colors.black
                  : Colors.white,
            ),
          ),
        ],
      ],
    );
  }
}
