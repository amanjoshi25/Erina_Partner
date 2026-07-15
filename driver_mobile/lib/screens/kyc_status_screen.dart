import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../core/design_system.dart';
import '../providers/auth_provider.dart';

/// Premium Document Wallet screen — lists all KYC & vehicle documents
/// with status badges, expiry dates, and upload/re-upload flows.
class DocumentWalletScreen extends StatefulWidget {
  const DocumentWalletScreen({super.key});

  @override
  State<DocumentWalletScreen> createState() => _DocumentWalletScreenState();
}

class _DocumentWalletScreenState extends State<DocumentWalletScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final docs = auth.kycDocuments;
    final kycStatus = auth.kycStatus ?? 'pending';

    return Scaffold(
      backgroundColor: ErinaColors.bg0,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Document Wallet',
                style: GoogleFonts.inter(
                    fontSize: 17, fontWeight: FontWeight.w700)),
            Text('Secure encrypted storage',
                style: GoogleFonts.inter(
                    fontSize: 11, color: ErinaColors.textSecondary)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () async {
              setState(() => _isLoading = true);
              await auth.refreshProfileAndKyc();
              setState(() => _isLoading = false);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Overall KYC status banner
          _KycStatusBanner(status: kycStatus, docs: docs),

          // Tab bar
          Container(
            color: ErinaColors.bg1,
            child: TabBar(
              controller: _tabController,
              labelStyle: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelStyle:
                  GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
              labelColor: ErinaColors.primary,
              unselectedLabelColor: ErinaColors.textSecondary,
              indicatorColor: ErinaColors.primary,
              indicatorWeight: 2.5,
              tabs: const [
                Tab(text: 'Identity Documents'),
                Tab(text: 'Vehicle Documents'),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _DocumentSection(
                  docs: docs,
                  docTypes: _identityDocs,
                  onUpload: (type) => _pickAndUpload(type),
                ),
                _DocumentSection(
                  docs: docs,
                  docTypes: _vehicleDocs,
                  onUpload: (type) => _pickAndUpload(type),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const List<_DocType> _identityDocs = [
    _DocType('driving_licence', 'Driving Licence', Icons.credit_card_rounded,
        ErinaColors.primary, true),
    _DocType('pan_card', 'PAN Card', Icons.badge_rounded,
        Color(0xFFF59E0B), true),
    _DocType('aadhaar_front', 'Aadhaar Front', Icons.portrait_rounded,
        Color(0xFF10B981), true),
    _DocType('aadhaar_back', 'Aadhaar Back', Icons.flip_rounded,
        Color(0xFF10B981), false),
    _DocType('selfie', 'Live Selfie', Icons.face_rounded,
        Color(0xFF8B5CF6), true),
  ];

  static const List<_DocType> _vehicleDocs = [
    _DocType('rc_book', 'RC Book', Icons.directions_car_rounded,
        ErinaColors.primary, false),
    _DocType('insurance', 'Insurance Certificate', Icons.verified_user_rounded,
        Color(0xFF10B981), false),
    _DocType('puc', 'PUC Certificate', Icons.eco_rounded,
        Color(0xFFF59E0B), false),
    _DocType('fitness_cert', 'Fitness Certificate', Icons.health_and_safety_rounded,
        Color(0xFF8B5CF6), false),
    _DocType('permit', 'Permit / Authorization', Icons.article_rounded,
        Color(0xFFEC4899), false),
  ];

  Future<void> _pickAndUpload(String docType) async {
    final source = await _showSourceDialog();
    if (source == null || !mounted) return;

    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (file == null || !mounted) return;

    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.uploadDocument(docType, file.path);
    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Document uploaded successfully'
              : auth.errorMessage ?? 'Upload failed'),
          backgroundColor: success ? ErinaColors.accent : ErinaColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<ImageSource?> _showSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: ErinaColors.bg1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: ErinaColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text('Upload Document',
                  style: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Choose image source',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: ErinaColors.textSecondary)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _SourceTile(
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      color: ErinaColors.primary,
                      onTap: () => Navigator.pop(context, ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SourceTile(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      color: const Color(0xFF8B5CF6),
                      onTap: () => Navigator.pop(context, ImageSource.gallery),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KycStatusBanner extends StatelessWidget {
  final String status;
  final List docs;

  const _KycStatusBanner({required this.status, required this.docs});

  @override
  Widget build(BuildContext context) {
    final configs = {
      'pending': (ErinaColors.textSecondary, Icons.pending_outlined,
          'Upload identity documents to start verification'),
      'in_progress': (ErinaColors.warning, Icons.upload_rounded,
          'Keep uploading — some documents still needed'),
      'pending_review': (ErinaColors.primary, Icons.hourglass_top_rounded,
          'Documents submitted — under admin review (24h)'),
      'verified': (ErinaColors.accent, Icons.verified_rounded,
          'Identity fully verified ✓'),
      'rejected': (ErinaColors.error, Icons.error_rounded,
          'Verification rejected — please re-upload marked documents'),
    };

    final config = configs[status] ?? configs['pending']!;
    final color = config.$1;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(config.$2, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.replaceAll('_', ' ').toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  config.$3,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: ErinaColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentSection extends StatelessWidget {
  final List docs;
  final List<_DocType> docTypes;
  final void Function(String) onUpload;

  const _DocumentSection({
    required this.docs,
    required this.docTypes,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: docTypes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final type = docTypes[i];
        final doc = docs.cast<Map<String, dynamic>?>().firstWhere(
          (d) => d?['document_type'] == type.key,
          orElse: () => null,
        );
        return _DocCard(
          docType: type,
          doc: doc,
          onUpload: () => onUpload(type.key),
        );
      },
    );
  }
}

class _DocCard extends StatelessWidget {
  final _DocType docType;
  final Map<String, dynamic>? doc;
  final VoidCallback onUpload;

  const _DocCard({
    required this.docType,
    required this.doc,
    required this.onUpload,
  });

  String? get _status => doc?['verification_status'];
  bool get _isUploaded => doc != null;
  bool get _isExpired => doc?['is_expired'] == true;

  Color get _statusColor {
    if (!_isUploaded) return ErinaColors.textMuted;
    if (_isExpired) return ErinaColors.error;
    return switch (_status) {
      'approved' => ErinaColors.accent,
      'rejected' => ErinaColors.error,
      'pending' => ErinaColors.warning,
      _ => ErinaColors.primary,
    };
  }

  String get _statusLabel {
    if (!_isUploaded) return 'NOT UPLOADED';
    if (_isExpired) return 'EXPIRED';
    return switch (_status) {
      'approved' => 'VERIFIED',
      'rejected' => 'REJECTED',
      'pending' => 'UNDER REVIEW',
      _ => 'PENDING',
    };
  }

  IconData get _statusIcon {
    if (!_isUploaded) return Icons.cloud_upload_outlined;
    if (_isExpired) return Icons.event_busy_rounded;
    return switch (_status) {
      'approved' => Icons.verified_rounded,
      'rejected' => Icons.error_rounded,
      'pending' => Icons.hourglass_top_rounded,
      _ => Icons.pending_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ErinaColors.bg1,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _isUploaded ? _statusColor.withOpacity(0.2) : ErinaColors.border,
        ),
      ),
      child: Column(
        children: [
          // Main row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: docType.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(docType.icon, color: docType.color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            docType.label,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: ErinaColors.textPrimary,
                            ),
                          ),
                          if (docType.required) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: ErinaColors.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Required',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  color: ErinaColors.error,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (doc?['document_no'] != null)
                        Text(
                          doc!['document_no'],
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: ErinaColors.textSecondary,
                          ),
                        ),
                      if (doc?['expiry_date'] != null)
                        Text(
                          'Expires: ${doc!['expiry_date']}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: _isExpired
                                ? ErinaColors.error
                                : ErinaColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                // Status badge
                ErinaStatusBadge(
                  label: _statusLabel,
                  color: _statusColor,
                  icon: _statusIcon,
                ),
              ],
            ),
          ),

          // Rejection reason
          if (_status == 'rejected' && doc?['rejection_reason'] != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ErinaColors.errorDim,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: ErinaColors.error.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: ErinaColors.error, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      doc!['rejection_reason'],
                      style: GoogleFonts.inter(
                          fontSize: 11, color: ErinaColors.error, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),

          // Upload button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton.icon(
                onPressed: onUpload,
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      _isUploaded ? ErinaColors.textSecondary : docType.color,
                  side: BorderSide(
                    color: _isUploaded
                        ? ErinaColors.border
                        : docType.color.withOpacity(0.4),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: Icon(
                  _isUploaded ? Icons.refresh_rounded : Icons.upload_rounded,
                  size: 16,
                ),
                label: Text(
                  _isUploaded
                      ? (_status == 'rejected' ? 'Re-upload' : 'Replace')
                      : 'Upload',
                  style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SourceTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocType {
  final String key;
  final String label;
  final IconData icon;
  final Color color;
  final bool required;

  const _DocType(this.key, this.label, this.icon, this.color, this.required);
}
