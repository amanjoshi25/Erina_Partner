import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/design_system.dart';
import '../providers/auth_provider.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  // Personal Details
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _emergencyRelationController = TextEditingController();

  String? _selectedSex;
  DateTime? _selectedDate;

  // Address
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _countryController = TextEditingController(text: 'India');

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _emergencyRelationController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 7300)), // ~20 years ago
      firstDate: DateTime(1940),
      lastDate: DateTime.now().subtract(const Duration(days: 6570)), // Must be at least 18
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: ErinaColors.primary,
              onPrimary: Colors.white,
              surface: ErinaColors.bg1,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select your gender'),
          backgroundColor: ErinaColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final addressMap = {
      "address_line1": _addressLine1Controller.text.trim(),
      "address_line2": _addressLine2Controller.text.trim().isEmpty
          ? null
          : _addressLine2Controller.text.trim(),
      "city": _cityController.text.trim(),
      "state": _stateController.text.trim(),
      "postal_code": _postalCodeController.text.trim(),
      "country": _countryController.text.trim(),
    };

    final success = await authProvider.setupProfile(
      fullName: _fullNameController.text.trim(),
      dob: _dobController.text.trim(),
      sex: _selectedSex!,
      emergencyContactNo: "+91${_emergencyPhoneController.text.trim()}",
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      emergencyContactName: _emergencyNameController.text.trim().isEmpty
          ? null
          : _emergencyNameController.text.trim(),
      emergencyContactRelation: _emergencyRelationController.text.trim().isEmpty
          ? null
          : _emergencyRelationController.text.trim(),
      address: addressMap,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile saved successfully! Proceeding to KYC.'),
          backgroundColor: ErinaColors.accent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: ErinaColors.bg0,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Complete Profile',
                style: GoogleFonts.inter(
                    fontSize: 17, fontWeight: FontWeight.w700)),
            Text('Step 2 of 3: Account setup',
                style: GoogleFonts.inter(
                    fontSize: 11, color: ErinaColors.textSecondary)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: ErinaColors.error),
            onPressed: () => authProvider.logout(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Section 1: Personal Details
                _buildHeader('Personal Details', Icons.person_outline_rounded),
                const SizedBox(height: 12),
                ErinaCard(
                  child: Column(
                    children: [
                      ErinaTextField(
                        label: 'Full Name (as in DL/Aadhaar)',
                        hint: 'John Doe',
                        controller: _fullNameController,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      ErinaTextField(
                        label: 'Email Address',
                        hint: 'john.doe@example.com',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty) return null;
                          final emailReg =
                              RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (!emailReg.hasMatch(v)) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ErinaTextField(
                              label: 'Date of Birth',
                              hint: 'YYYY-MM-DD',
                              controller: _dobController,
                              readOnly: true,
                              onTap: () => _selectDate(context),
                              suffix: const Icon(
                                Icons.calendar_today_rounded,
                                color: ErinaColors.primary,
                                size: 16,
                              ),
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Gender',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: ErinaColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  value: _selectedSex,
                                  dropdownColor: ErinaColors.bg1,
                                  style: GoogleFonts.inter(
                                    color: ErinaColors.textPrimary,
                                    fontSize: 15,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Select',
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                  ),
                                  items: ['Male', 'Female', 'Other']
                                      .map((val) => DropdownMenuItem(
                                            value: val,
                                            child: Text(val),
                                          ))
                                      .toList(),
                                  onChanged: (val) =>
                                      setState(() => _selectedSex = val),
                                  validator: (v) =>
                                      v == null ? 'Required' : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Section 2: Emergency Contact
                _buildHeader('Emergency Contact', Icons.emergency_rounded),
                const SizedBox(height: 12),
                ErinaCard(
                  child: Column(
                    children: [
                      ErinaTextField(
                        label: 'Contact Person Name',
                        hint: 'Jane Doe',
                        controller: _emergencyNameController,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ErinaTextField(
                              label: 'Relationship',
                              hint: 'Spouse/Parent',
                              controller: _emergencyRelationController,
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ErinaTextField(
                              label: 'Phone Number',
                              hint: '98765 43210',
                              controller: _emergencyPhoneController,
                              keyboardType: TextInputType.phone,
                              maxLength: 10,
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(
                                    left: 12.0, right: 8.0, top: 15.0),
                                child: Text('+91',
                                    style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: ErinaColors.textPrimary)),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Required';
                                if (v.length < 10) return 'Invalid number';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Section 3: Address
                _buildHeader('Permanent Address', Icons.home_rounded),
                const SizedBox(height: 12),
                ErinaCard(
                  child: Column(
                    children: [
                      ErinaTextField(
                        label: 'Address Line 1',
                        hint: 'Flat/House No, Building Name',
                        controller: _addressLine1Controller,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      ErinaTextField(
                        label: 'Address Line 2 (Optional)',
                        hint: 'Street, Locality',
                        controller: _addressLine2Controller,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ErinaTextField(
                              label: 'City',
                              hint: 'Bengaluru',
                              controller: _cityController,
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ErinaTextField(
                              label: 'State',
                              hint: 'Karnataka',
                              controller: _stateController,
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ErinaTextField(
                              label: 'Postal Code',
                              hint: '560001',
                              controller: _postalCodeController,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ErinaTextField(
                              label: 'Country',
                              controller: _countryController,
                              readOnly: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Submit Button
                ErinaPrimaryButton(
                  label: 'Save & Continue to KYC',
                  onPressed: _submit,
                  isLoading: authProvider.isLoading,
                  icon: Icons.check_circle_outline_rounded,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: ErinaColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: ErinaColors.primary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
