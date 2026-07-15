import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/design_system.dart';
import '../providers/auth_provider.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = "+91${_phoneController.text.trim()}";
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.sendOtp(phone);
    if (success && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const OtpScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: ErinaColors.bg0,
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
                    // Brand Logo
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: ErinaColors.primaryDim,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: ErinaColors.primary.withOpacity(0.25),
                                width: 1.5),
                          ),
                          child: const Icon(
                            Icons.shield_rounded,
                            color: ErinaColors.primary,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          'ERINA',
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '.driver',
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w300,
                            color: ErinaColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Roadside Assistance Dispatch Portal',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: ErinaColors.textSecondary,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Login Card
                    ErinaCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mobile Verification',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enter your phone number to receive a 6-digit verification code.',
                            style: GoogleFonts.inter(
                              color: ErinaColors.textSecondary,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Input Field
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                              color: ErinaColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              counterText: "",
                              prefixIcon: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 14),
                                margin: const EdgeInsets.only(right: 12),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    right: BorderSide(
                                        color: ErinaColors.border),
                                  ),
                                ),
                                child: Text(
                                  '+91',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              hintText: '98765 43210',
                              hintStyle: GoogleFonts.inter(
                                color: ErinaColors.textMuted,
                                letterSpacing: 1.5,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                  return 'Please enter phone number';
                              }
                              if (value.length < 10) {
                                  return 'Please enter a valid 10-digit number';
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
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: ErinaColors.error, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      authProvider.errorMessage!,
                                      style: GoogleFonts.inter(
                                          color: ErinaColors.error, fontSize: 11),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close,
                                        color: ErinaColors.error, size: 14),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => authProvider.clearError(),
                                  ),
                                ],
                              ),
                            )
                          ],

                          const SizedBox(height: 28),

                          // Submit Button
                          ErinaPrimaryButton(
                            label: 'CONTINUE',
                            onPressed: authProvider.isLoading ? null : _submit,
                            isLoading: authProvider.isLoading,
                            icon: Icons.arrow_forward_rounded,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                    Text(
                      "By logging in, you agree to Erina's Terms & Conditions",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: ErinaColors.textSecondary,
                        fontSize: 10,
                      ),
                    )
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
