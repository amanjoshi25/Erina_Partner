import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/design_system.dart';
import '../providers/auth_provider.dart';
import '../services/consent_service.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen>
    with SingleTickerProviderStateMixin {
  bool _termsAccepted = false;
  bool _privacyAccepted = false;
  bool _marketingConsent = false;
  bool _isLoading = false;
  int _activeTab = 0; // 0=Terms, 1=Privacy

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() => _activeTab = _tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _canProceed => _termsAccepted && _privacyAccepted;

  Future<void> _acceptAndContinue() async {
    if (!_canProceed) return;
    setState(() => _isLoading = true);

    final consentService = ConsentService();
    final success = await consentService.acceptConsent(
      termsAccepted: _termsAccepted,
      privacyAccepted: _privacyAccepted,
      marketingConsent: _marketingConsent,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.refreshProfileAndKyc();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ErinaColors.bg0,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: ErinaColors.primaryDim,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.gavel_rounded,
                            color: ErinaColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Legal',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: ErinaColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Terms &\nPrivacy Policy',
                    style: GoogleFonts.inter(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: ErinaColors.textPrimary,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please read and accept to continue using Erina.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: ErinaColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tab bar
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: ErinaColors.bg1,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ErinaColors.border),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: ErinaColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelStyle: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle:
                          GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                      labelColor: Colors.white,
                      unselectedLabelColor: ErinaColors.textSecondary,
                      tabs: const [
                        Tab(text: 'Terms of Service'),
                        Tab(text: 'Privacy Policy'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _LegalContent(sections: _termsContent),
                  _LegalContent(sections: _privacyContent),
                ],
              ),
            ),

            // Consent controls
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: ErinaColors.bg1,
                border: Border(top: BorderSide(color: ErinaColors.border)),
              ),
              child: Column(
                children: [
                  _ConsentToggle(
                    label: 'I agree to the Terms of Service',
                    subtitle: 'Required to use Erina platform',
                    value: _termsAccepted,
                    onChanged: (v) => setState(() => _termsAccepted = v),
                    color: ErinaColors.primary,
                  ),
                  const SizedBox(height: 12),
                  _ConsentToggle(
                    label: 'I agree to the Privacy Policy',
                    subtitle: 'Required — governs data handling',
                    value: _privacyAccepted,
                    onChanged: (v) => setState(() => _privacyAccepted = v),
                    color: ErinaColors.primary,
                  ),
                  const SizedBox(height: 12),
                  _ConsentToggle(
                    label: 'Receive offers & updates',
                    subtitle: 'Optional — unsubscribe anytime',
                    value: _marketingConsent,
                    onChanged: (v) => setState(() => _marketingConsent = v),
                    color: ErinaColors.accent,
                    optional: true,
                  ),
                  const SizedBox(height: 16),
                  ErinaPrimaryButton(
                    label: 'Accept & Continue',
                    onPressed: _canProceed ? _acceptAndContinue : null,
                    isLoading: _isLoading,
                    icon: Icons.shield_rounded,
                    color: _canProceed ? ErinaColors.primary : ErinaColors.textMuted,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const List<_Section> _termsContent = [
    _Section(
      title: '1. Acceptance of Terms',
      body:
          'By creating an account and using the Erina platform, you agree to be bound by these Terms of Service. If you do not agree, please do not use our services.',
    ),
    _Section(
      title: '2. Service Description',
      body:
          'Erina provides roadside assistance coordination services including breakdown assistance, towing, battery jump-start, and related automotive emergency services through a network of certified technicians.',
    ),
    _Section(
      title: '3. User Accounts',
      body:
          'You must provide accurate, current, and complete information during registration. You are responsible for maintaining the confidentiality of your account credentials and for all activities under your account.',
    ),
    _Section(
      title: '4. KYC Verification',
      body:
          'To access all platform features, you must complete identity verification (KYC) including submission of government-issued identification documents. False information will result in account termination.',
    ),
    _Section(
      title: '5. Service Fees',
      body:
          'Subscription fees are billed in advance. Roadside assistance requests beyond plan limits may incur additional charges. All fees are non-refundable unless otherwise stated.',
    ),
    _Section(
      title: '6. Limitation of Liability',
      body:
          'Erina connects users with independent service providers. We are not liable for the actions of third-party technicians beyond ensuring platform compliance with our standards.',
    ),
    _Section(
      title: '7. Modifications',
      body:
          'Erina reserves the right to modify these terms at any time. Continued use after changes constitutes acceptance of the new terms.',
    ),
  ];

  static const List<_Section> _privacyContent = [
    _Section(
      title: '1. Data We Collect',
      body:
          'We collect: Mobile number, name, date of birth, driving licence details, PAN/Aadhaar, vehicle registration data, GPS location during active RSA requests, and device information.',
    ),
    _Section(
      title: '2. How We Use Your Data',
      body:
          'Your data is used to: verify identity, coordinate roadside assistance, process payments, send service notifications, and improve our platform. We do not sell personal data to third parties.',
    ),
    _Section(
      title: '3. KYC Document Storage',
      body:
          'KYC documents are encrypted and stored on Firebase Storage with access restricted to verified Erina administrators. Documents are retained for the duration required by Indian regulatory law.',
    ),
    _Section(
      title: '4. Location Data',
      body:
          'Location is only accessed during active RSA requests to dispatch the nearest technician. We do not track your location in the background.',
    ),
    _Section(
      title: '5. Data Sharing',
      body:
          'We share minimal necessary data with: certified technicians (to fulfill your service request), Razorpay (payment processing), and government verification APIs (KYC compliance).',
    ),
    _Section(
      title: '6. Your Rights',
      body:
          'You may request data deletion via the app settings. KYC documents required for legal compliance may be retained even after account deletion per IRDAI/RBI guidelines.',
    ),
    _Section(
      title: '7. Security',
      body:
          'We use industry-standard encryption (TLS 1.3, AES-256) and JWT authentication. Our systems undergo regular security audits.',
    ),
  ];
}

class _Section {
  final String title;
  final String body;
  const _Section({required this.title, required this.body});
}

class _LegalContent extends StatelessWidget {
  final List<_Section> sections;
  const _LegalContent({required this.sections});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: sections.length,
      separatorBuilder: (_, __) =>
          const Divider(color: ErinaColors.border, height: 24),
      itemBuilder: (_, i) {
        final s = sections[i];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: ErinaColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              s.body,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: ErinaColors.textSecondary,
                height: 1.6,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ConsentToggle extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color color;
  final bool optional;

  const _ConsentToggle({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.color,
    this.optional = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: value ? color.withOpacity(0.07) : ErinaColors.bg0,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value ? color.withOpacity(0.3) : ErinaColors.border,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: value ? color : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: value ? color : ErinaColors.borderBright,
                  width: 1.5,
                ),
              ),
              child: value
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: ErinaColors.textPrimary,
                          ),
                        ),
                      ),
                      if (optional)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: ErinaColors.textMuted.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Optional',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              color: ErinaColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: ErinaColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
