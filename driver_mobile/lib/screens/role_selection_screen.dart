import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/design_system.dart';
import '../providers/auth_provider.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with SingleTickerProviderStateMixin {
  String _selectedRole = 'Driver';
  late AnimationController _controller;

  final List<_RoleOption> _roles = [
    _RoleOption(
      key: 'Driver',
      title: 'Driver',
      subtitle: 'Commercial or private vehicle driver',
      icon: Icons.drive_eta_rounded,
      color: ErinaColors.primary,
      features: ['RSA Roadside Assistance', 'Vehicle Management', 'KYC Verification'],
    ),
    _RoleOption(
      key: 'Driver',
      title: 'Vehicle Owner',
      subtitle: 'Own a vehicle, manage coverage',
      icon: Icons.car_rental_rounded,
      color: const Color(0xFF10B981),
      features: ['RC Registration', 'Insurance Tracking', 'Roadside Coverage'],
    ),
    _RoleOption(
      key: 'Fleet Owner',
      title: 'Fleet Manager',
      subtitle: 'Manage a fleet of commercial vehicles',
      icon: Icons.local_shipping_rounded,
      color: const Color(0xFFF59E0B),
      features: ['Fleet Dashboard', 'Driver Management', 'Bulk Coverage Plans'],
    ),
    _RoleOption(
      key: 'Partner',
      title: 'Partner / Dealer',
      subtitle: 'Automotive partner or service dealer',
      icon: Icons.handshake_rounded,
      color: const Color(0xFF8B5CF6),
      features: ['Commission Earnings', 'Customer Referrals', 'Service Portal'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _proceed() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    auth.setSelectedRole(_selectedRole);
    auth.completeRoleSelection();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: kAuthGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo mark
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: ErinaColors.primaryDim,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: ErinaColors.primary.withOpacity(0.3)),
                      ),
                      child: const Icon(Icons.shield_rounded,
                          color: ErinaColors.primary, size: 22),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Who are\nyou?',
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: ErinaColors.textPrimary,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select your account type to get\nthe right experience.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: ErinaColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Role cards
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _roles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final role = _roles[i];
                    final isSelected = _selectedRole == role.key &&
                        _roles[_roles.indexWhere((r) => r.key == _selectedRole)].title ==
                            role.title;
                    // Simpler: track by title
                    final isSelectedByTitle = _selectedRole == role.key &&
                        (_roles.indexWhere((r) => r.title == _roles
                                .firstWhere((x) => x.key == _selectedRole)
                                .title) == i);

                    return _buildRoleCard(role, i == _roles.indexWhere((r) =>
                        r.key == _selectedRole &&
                        r.title == _roles.firstWhere((x) => x.key == _selectedRole).title), i);
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: ErinaPrimaryButton(
                  label: 'Continue as ${_roles.firstWhere((r) => r.key == _selectedRole, orElse: () => _roles[0]).title}',
                  onPressed: _proceed,
                  icon: Icons.arrow_forward_rounded,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _selectedTitle = 'Driver';

  Widget _buildRoleCard(_RoleOption role, bool isSelected, int index) {
    final sel = _selectedTitle == role.title;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedRole = role.key;
        _selectedTitle = role.title;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: sel ? role.color.withOpacity(0.08) : ErinaColors.bg1,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: sel ? role.color : ErinaColors.border,
            width: sel ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: role.color.withOpacity(sel ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(role.icon,
                  color: sel ? role.color : ErinaColors.textSecondary, size: 24),
            ),
            const SizedBox(width: 14),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role.title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: sel ? role.color : ErinaColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    role.subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: ErinaColors.textSecondary,
                    ),
                  ),
                  if (sel) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: role.features.map((f) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: role.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          f,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: role.color,
                          ),
                        ),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),

            // Selector
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: sel ? role.color : Colors.transparent,
                border: Border.all(
                  color: sel ? role.color : ErinaColors.borderBright,
                  width: 2,
                ),
              ),
              child: sel
                  ? const Icon(Icons.check, color: Colors.white, size: 13)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleOption {
  final String key;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<String> features;

  const _RoleOption({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.features,
  });
}
