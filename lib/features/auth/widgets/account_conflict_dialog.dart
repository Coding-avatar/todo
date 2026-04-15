import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/providers.dart';
import '../../../data/repositories/auth_repository.dart';

/// Dialog shown when an account-exists-with-different-credential conflict occurs.
///
/// Informs the user that an account already exists with a different sign-in
/// method, and guides them through re-authentication + account linking.
class AccountConflictDialog extends ConsumerStatefulWidget {
  final AccountConflictException conflict;

  const AccountConflictDialog({super.key, required this.conflict});

  /// Show this dialog from anywhere when an [AccountConflictException] is caught.
  static Future<void> show(BuildContext context, AccountConflictException conflict) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AccountConflictDialog(conflict: conflict),
    );
  }

  @override
  ConsumerState<AccountConflictDialog> createState() => _AccountConflictDialogState();
}

class _AccountConflictDialogState extends ConsumerState<AccountConflictDialog> {
  bool _isLinking = false;
  String? _errorMessage;

  Future<void> _handleLink() async {
    final credential = widget.conflict.pendingCredential;
    if (credential == null) {
      setState(() => _errorMessage = 'No credential to link. Please try signing in again.');
      return;
    }

    setState(() {
      _isLinking = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authNotifierProvider.notifier).linkPendingCredential(credential);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Accounts linked successfully!')),
        );
      }
    } on AuthException catch (e) {
      setState(() {
        _isLinking = false;
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _isLinking = false;
        _errorMessage = 'Failed to link accounts. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final email = widget.conflict.email ?? 'your email';

    return AlertDialog(
      icon: Icon(Icons.link_off, color: theme.colorScheme.error, size: 40),
      title: const Text('Account Already Exists'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'An account associated with $email already exists using a different sign-in method.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'Sign in with your existing method first, then link this new method to your account.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLinking ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if (FirebaseAuth.instance.currentUser != null)
          FilledButton(
            onPressed: _isLinking ? null : _handleLink,
            child: _isLinking
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Link Account'),
          ),
      ],
    );
  }
}
