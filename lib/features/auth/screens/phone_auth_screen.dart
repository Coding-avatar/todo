import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/providers.dart';
import '../../../data/repositories/auth_repository.dart';

/// Two-step phone auth screen: enter phone → enter OTP.
class PhoneAuthScreen extends ConsumerStatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  ConsumerState<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends ConsumerState<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _phoneFocusNode = FocusNode();
  final _otpFocusNode = FocusNode();

  bool _isSendingOtp = false;
  bool _isVerifying = false;
  String? _errorMessage;

  // OTP state
  String? _verificationId;
  int? _resendToken;
  bool _otpSent = false;
  int _countdown = 0;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _phoneFocusNode.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  String get _fullPhoneNumber => '+91${_phoneController.text.trim()}';

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      setState(() => _errorMessage = 'Please enter a valid 10-digit phone number.');
      return;
    }

    setState(() {
      _isSendingOtp = true;
      _errorMessage = null;
    });

    await ref.read(authNotifierProvider.notifier).sendPhoneOtp(
          phoneNumber: _fullPhoneNumber,
          forceResendingToken: _resendToken,
          onCodeSent: (verificationId, resendToken) {
            if (mounted) {
              setState(() {
                _verificationId = verificationId;
                _resendToken = resendToken;
                _otpSent = true;
                _isSendingOtp = false;
                _countdown = 60;
              });
              _startCountdown();
              _otpFocusNode.requestFocus();
            }
          },
          onAutoVerified: (credential) async {
            // Android auto-verification: sign in immediately
            if (mounted) {
              setState(() {
                _isVerifying = true;
                _isSendingOtp = false;
              });
            }
            try {
              await ref.read(authNotifierProvider.notifier).signInWithPhoneCredential(credential);
              // Navigation handled by router redirect
            } on AccountConflictException catch (e) {
              if (mounted) {
                setState(() {
                  _isVerifying = false;
                  _errorMessage = e.message;
                });
              }
            } catch (e) {
              if (mounted) {
                setState(() {
                  _isVerifying = false;
                  _errorMessage = e.toString();
                });
              }
            }
          },
          onError: (message) {
            if (mounted) {
              setState(() {
                _isSendingOtp = false;
                _errorMessage = message;
              });
            }
          },
        );
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _errorMessage = 'Please enter the 6-digit OTP.');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authNotifierProvider.notifier).verifyPhoneOtp(
            verificationId: _verificationId!,
            otp: otp,
          );
      // Navigation handled by router redirect
    } on AccountConflictException catch (e) {
      setState(() {
        _isVerifying = false;
        _errorMessage = e.message;
      });
    } on AuthException catch (e) {
      setState(() {
        _isVerifying = false;
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _isVerifying = false;
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    }
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _countdown--);
      return _countdown > 0;
    });
  }

  void _goBackToPhone() {
    setState(() {
      _otpSent = false;
      _otpController.clear();
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_otpSent) {
              _goBackToPhone();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(_otpSent ? 'Verify OTP' : 'Phone Sign-In'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),

              // Icon
              Icon(
                _otpSent ? Icons.sms_outlined : Icons.phone_android,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                _otpSent ? 'Enter Verification Code' : 'Enter Phone Number',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                _otpSent
                    ? 'We sent a 6-digit code to $_fullPhoneNumber'
                    : 'We\'ll send you a verification code via SMS',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Error message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: theme.colorScheme.onErrorContainer),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // ── Phone Input Step ──
              if (!_otpSent) ...[
                TextFormField(
                  controller: _phoneController,
                  focusNode: _phoneFocusNode,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '9876543210',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    prefixText: '+91 ',
                    prefixStyle: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    counterText: '',
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isSendingOtp ? null : _sendOtp,
                  child: _isSendingOtp
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send OTP'),
                ),
              ],

              // ── OTP Input Step ──
              if (_otpSent) ...[
                TextFormField(
                  controller: _otpController,
                  focusNode: _otpFocusNode,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    letterSpacing: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Verification Code',
                    hintText: '------',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isVerifying ? null : _verifyOtp,
                  child: _isVerifying
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Verify & Sign In'),
                ),
                const SizedBox(height: 16),

                // Resend / countdown
                Center(
                  child: _countdown > 0
                      ? Text(
                          'Resend OTP in ${_countdown}s',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        )
                      : TextButton(
                          onPressed: _isSendingOtp ? null : _sendOtp,
                          child: const Text('Resend OTP'),
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
