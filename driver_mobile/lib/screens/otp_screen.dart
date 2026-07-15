import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/design_system.dart';
import '../providers/auth_provider.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int _resendTimerSeconds = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _resendTimerSeconds = 30;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimerSeconds > 0) {
        setState(() {
          _resendTimerSeconds--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final code = _codeController.text.trim();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.verifyOtp(code);
    if (success && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _resendCode() async {
    if (_resendTimerSeconds > 0) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.phoneNumber != null) {
      final success = await authProvider.sendOtp(authProvider.phoneNumber!);
      if (success) {
        _startTimer();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Verification code resent successfully.'),
              backgroundColor: ErinaColors.accent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: ErinaColors.bg0,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(gradient: kAuthGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.mark_email_read_outlined,
                      size: 64,
                      color: ErinaColors.primary.withOpacity(0.9),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Confirm Code',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Enter the 6-digit code sent to\n${authProvider.phoneNumber ?? "your mobile"}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          color: ErinaColors.textSecondary,
                          fontSize: 13,
                          height: 1.4),
                    ),
                    const SizedBox(height: 36),

                    // OTP debug code notification
                    if (authProvider.debugOtpCode != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: ErinaColors.primaryDim,
                          border: Border.all(
                              color: ErinaColors.primary.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline,
                                color: ErinaColors.primary, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'DEBUG SIMULATOR OTP',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 10,
                                      color: ErinaColors.primary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Use the OTP code ${authProvider.debugOtpCode} to authenticate.',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                _codeController.text =
                                    authProvider.debugOtpCode!;
                              },
                              style: TextButton.styleFrom(
                                backgroundColor:
                                    ErinaColors.primary.withOpacity(0.15),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                              ),
                              child: Text(
                                'AUTOFILL',
                                style: GoogleFonts.inter(
                                    fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Form card
                    ErinaCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _codeController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 8.0,
                              color: ErinaColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              counterText: "",
                              hintText: '••••••',
                              hintStyle: GoogleFonts.inter(
                                color: ErinaColors.textMuted,
                                letterSpacing: 8.0,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter OTP code';
                              }
                              if (value.length < 6) {
                                return 'Code must be 6 digits';
                              }
                              return null;
                            },
                          ),

                          if (authProvider.errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: ErinaColors.error.withOpacity(0.15),
                                border: Border.all(
                                    color: ErinaColors.error.withOpacity(0.25)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                authProvider.errorMessage!,
                                style: GoogleFonts.inter(
                                    color: ErinaColors.error, fontSize: 11),
                                textAlign: TextAlign.center,
                              ),
                            )
                          ],

                          const SizedBox(height: 24),

                          ErinaPrimaryButton(
                            label: 'VERIFY CODE',
                            onPressed: authProvider.isLoading ? null : _submit,
                            isLoading: authProvider.isLoading,
                            icon: Icons.check_circle_outline_rounded,
                            color: ErinaColors.accent,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Resend timer control
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Didn't receive code? ",
                          style: GoogleFonts.inter(
                              color: ErinaColors.textSecondary, fontSize: 13),
                        ),
                        GestureDetector(
                          onTap: _resendTimerSeconds == 0 ? _resendCode : null,
                          child: Text(
                            _resendTimerSeconds > 0
                                ? 'Resend in ${_resendTimerSeconds}s'
                                : 'Resend Code',
                            style: GoogleFonts.inter(
                              color: _resendTimerSeconds > 0
                                  ? ErinaColors.textSecondary
                                  : ErinaColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              decoration: _resendTimerSeconds > 0
                                  ? TextDecoration.none
                                  : TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
