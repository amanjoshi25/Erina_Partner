import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../services/driver_service.dart';

class KycStatusScreen extends StatefulWidget {
  const KycStatusScreen({super.key});

  @override
  State<KycStatusScreen> createState() => _KycStatusScreenState();
}

class _KycStatusScreenState extends State<KycStatusScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAndUploadImage(String type) async {
    try {
      final XFile? image = await showModalBottomSheet<XFile?>(
        context: context,
        backgroundColor: const Color(0xFF0B1329),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (BuildContext context) {
          return SafeArea(
            child: Wrap(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.blueAccent),
                  title: const Text('Pick from Gallery'),
                  onTap: () async {
                    final XFile? file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                    if (mounted) Navigator.pop(context, file);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera, color: Colors.blueAccent),
                  title: const Text('Capture with Camera'),
                  onTap: () async {
                    final XFile? file = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
                    if (mounted) Navigator.pop(context, file);
                  },
                ),
              ],
            ),
          );
        },
      );

      if (image != null && mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final success = await authProvider.uploadDocument(type, image.path);
        
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_cleanDocName(type)} uploaded and processed by OCR!'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture image: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  String _cleanDocName(String type) {
    if (type == "driving_licence") return "Driving Licence";
    if (type == "pan_card") return "PAN Card";
    if (type == "selfie") return "Selfie Photo";
    return type;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final docs = authProvider.kycDocuments;
    final String generalKycStatus = authProvider.kycStatus ?? "pending";

    final Map<String, dynamic> docMap = {
      for (var d in docs) d["document_id"].toString(): d
    };

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1329),
        title: const Text('KYC Verification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => authProvider.logout(),
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFF020617),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    _buildKycHeaderCard(generalKycStatus),
                    const SizedBox(height: 24),

                    const Text(
                      'Required Verification Documents',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 12),

                    _buildDocumentSlot(
                      type: "driving_licence",
                      label: "Driving Licence (DL)",
                      subtitle: "Upload front side clearly showing number & validity",
                      icon: Icons.badge_outlined,
                      docData: docMap["driving_licence"],
                      onUpload: () => _pickAndUploadImage("driving_licence"),
                    ),
                    const SizedBox(height: 16),

                    _buildDocumentSlot(
                      type: "pan_card",
                      label: "PAN Card",
                      subtitle: "Upload front side showing card number & date of birth",
                      icon: Icons.credit_card_outlined,
                      docData: docMap["pan_card"],
                      onUpload: () => _pickAndUploadImage("pan_card"),
                    ),
                    const SizedBox(height: 16),

                    _buildDocumentSlot(
                      type: "selfie",
                      label: "Selfie Portrait",
                      subtitle: "Capture a clear selfie photo for biometric liveness match",
                      icon: Icons.face_retouching_natural_outlined,
                      docData: docMap["selfie"],
                      onUpload: () => _pickAndUploadImage("selfie"),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),

              if (docs.isNotEmpty) _buildAdminSandboxPanel(docs, authProvider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKycHeaderCard(String status) {
    Color cardColor = const Color(0xFF1E293B);
    Color textColor = Colors.white;
    IconData icon = Icons.info_outline;
    String title = "Status Pending";
    String description = "Please upload all three required documents below to submit your profile for review.";

    if (status == "in_progress") {
      cardColor = Colors.orange.withOpacity(0.08);
      textColor = Colors.orangeAccent;
      icon = Icons.hourglass_top;
      title = "Onboarding In Progress";
      description = "Finish uploading the remaining documents to complete your verification sequence.";
    } else if (status == "pending_review") {
      cardColor = Colors.blue.withOpacity(0.08);
      textColor = Colors.blueAccent;
      icon = Icons.rate_review_outlined;
      title = "Pending Manual Review";
      description = "All files uploaded! A platform administrator will manually verify your documents shortly.";
    } else if (status == "rejected") {
      cardColor = Colors.red.withOpacity(0.08);
      textColor = Colors.redAccent;
      icon = Icons.cancel_outlined;
      title = "Verification Rejected";
      description = "Some documents failed validation checks. Please review feedback details and re-upload.";
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1329),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: textColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    const SizedBox(height: 2),
                    const Text('KYC VERIFICATION SYSTEM', style: TextStyle(color: Colors.grey, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.06)),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentSlot({
    required String type,
    required String label,
    required String subtitle,
    required IconData icon,
    required Map<String, dynamic>? docData,
    required VoidCallback onUpload,
  }) {
    final bool isUploaded = docData != null;
    final String status = docData != null ? docData["verification_status"] : "pending";
    final String? rejectionReason = docData != null ? docData["rejection_reason"] : null;
    final String? docNumber = docData != null ? docData["document_no"] : null;
    final Map<String, dynamic>? ocrData = docData != null ? docData["ocr_response"] : null;

    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.radio_button_unchecked;
    String statusLabel = "Not Uploaded";

    if (isUploaded) {
      if (status == "approved") {
        statusColor = const Color(0xFF10B981);
        statusIcon = Icons.check_circle;
        statusLabel = "Approved";
      } else if (status == "rejected") {
        statusColor = Colors.redAccent;
        statusIcon = Icons.cancel;
        statusLabel = "Rejected";
      } else {
        statusColor = Colors.blueAccent;
        statusIcon = Icons.hourglass_empty;
        statusLabel = "Uploaded";
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B1329),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: status == "rejected" 
              ? Colors.redAccent.withOpacity(0.3) 
              : Colors.white.withOpacity(0.05)
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF3B82F6), size: 22),
          ),
          title: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 12),
                const SizedBox(width: 4),
                Text(
                  statusLabel,
                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          trailing: isUploaded && status == "approved"
              ? const Icon(Icons.check, color: Color(0xFF10B981))
              : ElevatedButton(
                  onPressed: onUpload,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isUploaded ? Colors.white.withOpacity(0.08) : const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    isUploaded ? 'RE-UPLOAD' : 'UPLOAD',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
          children: [
            if (isUploaded)
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF020617),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.image, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'File: ${docData["firebase_url"].toString().split('/').last}',
                              style: const TextStyle(color: Colors.grey, fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (status == "rejected" && rejectionReason != null) ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.withOpacity(0.2)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.warning, color: Colors.redAccent, size: 14),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Rejection Reason: $rejectionReason',
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      if (ocrData != null) ...[
                        const Row(
                          children: [
                            Icon(Icons.auto_awesome, size: 14, color: Colors.amber),
                            SizedBox(width: 6),
                            Text(
                              'OCR EXTRACTION RESULTS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (docNumber != null) ...[
                          _buildDetailRow("Document No.", docNumber),
                          const SizedBox(height: 6),
                        ],
                        if (ocrData["name"] != null) ...[
                          _buildDetailRow("Name on Card", ocrData["name"]),
                          const SizedBox(height: 6),
                        ],
                        if (ocrData["date_of_birth"] != null) ...[
                          _buildDetailRow("DOB", ocrData["date_of_birth"]),
                          const SizedBox(height: 6),
                        ],
                        if (ocrData["valid_till"] != null) ...[
                          _buildDetailRow("Valid Till", ocrData["valid_till"]),
                          const SizedBox(height: 6),
                        ],
                        _buildDetailRow(
                          "Extraction Confidence", 
                          "${((ocrData["ocr_confidence"] ?? 0.95) * 100).toStringAsFixed(0)}%"
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            if (!isUploaded)
              const Padding(
                padding: EdgeInsets.only(left: 20, right: 20, bottom: 20),
                child: Text(
                  'No file has been uploaded for this section yet.',
                  style: TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String key, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(key, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
      ],
    );
  }

  Widget _buildAdminSandboxPanel(List<dynamic> docs, AuthProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1329),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.construction, color: Colors.blueAccent, size: 16),
              SizedBox(width: 8),
              Text(
                'ADMIN KYC SIMULATOR (DEV SANDBOX)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: Colors.blueAccent,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final String docId = doc["id"].toString();
              final String typeName = _cleanDocName(doc["document_id"]);
              final String status = doc["verification_status"];

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '$typeName ($status)',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: status == "approved" 
                              ? null 
                              : () => _simulateVerification(docId, "approved", provider),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.green.withOpacity(0.12),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                          ),
                          child: const Text('APPROVE', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: status == "rejected" 
                              ? null 
                              : () => _simulateVerification(docId, "rejected", provider),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.red.withOpacity(0.12),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                          ),
                          child: const Text('REJECT', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _simulateVerification(String docId, String status, AuthProvider provider) async {
    final res = await DriverService().adminVerifyDocument(
      documentId: docId,
      status: status,
      rejectionReason: status == "rejected" ? "Image was blur and number was not readable" : null,
    );

    if (res["success"] && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Simulated KYC status update: $status!'),
          backgroundColor: status == "approved" ? const Color(0xFF10B981) : Colors.redAccent,
        ),
      );
      await provider.refreshProfileAndKyc();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Simulation error: ${res["message"]}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
