import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ─── Erina Design System ────────────────────────────────────────────────────
/// A centralized design token system for Apple/Google-quality UI consistency.

class ErinaColors {
  // Background layers
  static const bg0 = Color(0xFF020617);       // Deepest background
  static const bg1 = Color(0xFF0B1329);       // Card/surface
  static const bg2 = Color(0xFF111827);       // Elevated surface
  static const bg3 = Color(0xFF1E2D4A);       // Highlighted surface

  // Brand
  static const primary = Color(0xFF3B82F6);   // Blue — primary actions
  static const primaryLight = Color(0xFF60A5FA);
  static const primaryDim = Color(0x1A3B82F6);

  static const accent = Color(0xFF10B981);    // Green — success / verified
  static const accentDim = Color(0x1A10B981);

  // Status
  static const warning = Color(0xFFF59E0B);
  static const warningDim = Color(0x1AF59E0B);
  static const error = Color(0xFFEF4444);
  static const errorDim = Color(0x1AEF4444);
  static const info = Color(0xFF8B5CF6);

  // Neutrals
  static const white = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFFF1F5F9);
  static const textSecondary = Color(0xFF94A3B8);
  static const textMuted = Color(0xFF4B5563);
  static const border = Color(0x14FFFFFF);    // 8% white
  static const borderBright = Color(0x29FFFFFF); // 16% white

  // Language palette
  static const langs = [
    Color(0xFF3B82F6), // English
    Color(0xFFEF4444), // Hindi
    Color(0xFF10B981), // Tamil
    Color(0xFFF59E0B), // Telugu
    Color(0xFF8B5CF6), // Kannada
    Color(0xFFEC4899), // Marathi
  ];
}

class ErinaTheme {
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      surface: ErinaColors.bg1,
      primary: ErinaColors.primary,
      secondary: ErinaColors.accent,
      error: ErinaColors.error,
    ),
    scaffoldBackgroundColor: ErinaColors.bg0,
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    cardTheme: const CardThemeData(
      color: ErinaColors.bg1,
      elevation: 0,
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ErinaColors.bg1,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: ErinaColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: ErinaColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: ErinaColors.primary, width: 1.5),
      ),
      hintStyle: const TextStyle(color: ErinaColors.textMuted, fontSize: 15),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ErinaColors.primary,
        foregroundColor: ErinaColors.white,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
        textStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          letterSpacing: 0.3,
        ),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: ErinaColors.bg1,
      indicatorColor: ErinaColors.primaryDim,
      labelTextStyle: WidgetStateProperty.all(
        GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: ErinaColors.bg1,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.inter(
        color: ErinaColors.textPrimary,
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: const IconThemeData(color: ErinaColors.textPrimary),
    ),
  );
}

/// ─── Reusable Design Components ─────────────────────────────────────────────

class ErinaCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? color;
  final double? borderRadius;
  final Border? border;
  final List<BoxShadow>? shadow;
  final VoidCallback? onTap;

  const ErinaCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.borderRadius,
    this.border,
    this.shadow,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color ?? ErinaColors.bg1,
          borderRadius: BorderRadius.circular(borderRadius ?? 20),
          border: border ?? Border.all(color: ErinaColors.border),
          boxShadow: shadow,
        ),
        child: child,
      ),
    );
  }
}

class ErinaPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? color;

  const ErinaPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? ErinaColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          disabledBackgroundColor: (color ?? ErinaColors.primary).withOpacity(0.5),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class ErinaStatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const ErinaStatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class ErinaTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final Widget? suffix;
  final int? maxLength;
  final int maxLines;
  final String? initialValue;
  final void Function(String)? onChanged;
  final bool readOnly;
  final VoidCallback? onTap;

  const ErinaTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.prefixIcon,
    this.suffix,
    this.maxLength,
    this.maxLines = 1,
    this.initialValue,
    this.onChanged,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: ErinaColors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          maxLength: maxLength,
          maxLines: maxLines,
          initialValue: initialValue,
          onChanged: onChanged,
          readOnly: readOnly,
          onTap: onTap,
          style: GoogleFonts.inter(
            color: ErinaColors.textPrimary,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon,
            suffix: suffix,
            counterText: '',
          ),
        ),
      ],
    );
  }
}

/// Gradient used on auth / onboarding screens
const kAuthGradient = LinearGradient(
  colors: [Color(0xFF020617), Color(0xFF0D1B3E)],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);
