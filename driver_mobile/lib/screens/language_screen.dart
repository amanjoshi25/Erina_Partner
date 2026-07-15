import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/design_system.dart';

class LanguageScreen extends StatefulWidget {
  final VoidCallback onDone;
  const LanguageScreen({super.key, required this.onDone});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen>
    with SingleTickerProviderStateMixin {
  String _selectedCode = 'en';
  late AnimationController _entryController;
  late Animation<double> _fadeIn;

  final List<_Language> _languages = [
    _Language('en', 'English', 'English', '🇬🇧', ErinaColors.primary),
    _Language('hi', 'Hindi', 'हिन्दी', '🇮🇳', const Color(0xFFEF4444)),
    _Language('ta', 'Tamil', 'தமிழ்', '🌿', const Color(0xFF10B981)),
    _Language('te', 'Telugu', 'తెలుగు', '⭐', const Color(0xFFF59E0B)),
    _Language('kn', 'Kannada', 'ಕನ್ನಡ', '🏔️', const Color(0xFF8B5CF6)),
    _Language('mr', 'Marathi', 'मराठी', '🌺', const Color(0xFFEC4899)),
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _entryController, curve: Curves.easeOut);
    _entryController.forward();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('preferred_language') ?? 'en';
    if (mounted) setState(() => _selectedCode = saved);
  }

  Future<void> _selectLanguage(String code) async {
    setState(() => _selectedCode = code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preferred_language', code);
  }

  Future<void> _proceed() async {
    await _selectLanguage(_selectedCode);
    widget.onDone();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: kAuthGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),

                  // Header
                  Text(
                    'Select Language',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: ErinaColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Choose your preferred language for the app.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: ErinaColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Language grid
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.6,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                      ),
                      itemCount: _languages.length,
                      itemBuilder: (_, i) => _LanguageTile(
                        language: _languages[i],
                        isSelected: _selectedCode == _languages[i].code,
                        onTap: () => _selectLanguage(_languages[i].code),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Skip + Continue
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: widget.onDone,
                          style: TextButton.styleFrom(
                            foregroundColor: ErinaColors.textSecondary,
                          ),
                          child: Text(
                            'Skip',
                            style: GoogleFonts.inter(fontSize: 15),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ErinaPrimaryButton(
                          label: 'Continue',
                          onPressed: _proceed,
                          icon: Icons.arrow_forward_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final _Language language;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.language,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? language.color.withOpacity(0.12)
              : ErinaColors.bg1,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? language.color : ErinaColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(language.emoji, style: const TextStyle(fontSize: 22)),
                const Spacer(),
                if (isSelected)
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: language.color,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check,
                        color: Colors.white, size: 12),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  language.nativeName,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? language.color : ErinaColors.textPrimary,
                  ),
                ),
                Text(
                  language.englishName,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: ErinaColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Language {
  final String code;
  final String englishName;
  final String nativeName;
  final String emoji;
  final Color color;

  const _Language(
      this.code, this.englishName, this.nativeName, this.emoji, this.color);
}
