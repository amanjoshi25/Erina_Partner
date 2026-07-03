import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final profile = authProvider.driverProfile;

    if (profile == null) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)));
    }

    final address = profile["address"];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildProfileHeaderCard(profile),
        const SizedBox(height: 20),
        _buildDetailSection('Personal Details', Icons.person_outline, [
          _buildDetailRow('Date of Birth', profile["dob"] ?? 'N/A'),
          _buildDetailRow('Gender', profile["sex"] ?? 'N/A'),
          _buildDetailRow('Emergency Contact', profile["emergency_contact_no"] ?? 'N/A'),
        ]),
        const SizedBox(height: 20),
        _buildDetailSection('Permanent Address', Icons.home_outlined, [
          _buildDetailRow('Address Line 1', address != null ? address["address_line1"] : 'N/A'),
          _buildDetailRow('Address Line 2', address != null ? (address["address_line2"] ?? 'N/A') : 'N/A'),
          _buildDetailRow('City', address != null ? address["city"] : 'N/A'),
          _buildDetailRow('State', address != null ? address["state"] : 'N/A'),
          _buildDetailRow('PIN Code', address != null ? address["postal_code"] : 'N/A'),
          _buildDetailRow('Country', address != null ? (address["country"] ?? 'India') : 'India'),
        ]),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildProfileHeaderCard(Map<String, dynamic> profile) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1329),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: const Color(0xFF3B82F6).withOpacity(0.12),
            child: const Icon(Icons.person, color: Color(0xFF3B82F6), size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile["full_name"] ?? 'Driver Profile',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  'Code: ${profile["driver_code"] ?? "N/A"}',
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF3B82F6), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1329),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            children: children,
          ),
        )
      ],
    );
  }

  Widget _buildDetailRow(String key, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(key, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
