import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/driver_provider.dart';

class VehiclesTab extends StatefulWidget {
  const VehiclesTab({super.key});

  @override
  State<VehiclesTab> createState() => _VehiclesTabState();
}

class _VehiclesTabState extends State<VehiclesTab> {
  final _formKey = GlobalKey<FormState>();
  final _regNumController = TextEditingController();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _colorController = TextEditingController();
  
  bool _isAddingVehicle = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _regNumController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  void _submitNewVehicle() async {
    if (!_formKey.currentState!.validate()) return;
    
    final driverProvider = Provider.of<DriverProvider>(context, listen: false);
    final success = await driverProvider.createVehicle(
      registrationNumber: _regNumController.text.trim().toUpperCase(),
      make: _makeController.text.trim(),
      model: _modelController.text.trim(),
      year: int.parse(_yearController.text.trim()),
      color: _colorController.text.trim(),
    );

    if (success && mounted) {
      setState(() {
        _isAddingVehicle = false;
        _regNumController.clear();
        _makeController.clear();
        _modelController.clear();
        _yearController.clear();
        _colorController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vehicle registered successfully!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  Future<void> _uploadVehicleDoc(String vehicleId, String docType) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (image != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Uploading $docType...'),
            backgroundColor: const Color(0xFF3B82F6),
          ),
        );
        
        // Mock success locally (since full doc tracking is mock verified)
        await Future.delayed(const Duration(seconds: 2));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$docType uploaded successfully (Verified by Mock OCR)!'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DriverProvider>(context);
    final activeVehicle = provider.activeVehicle;

    if (_isAddingVehicle) {
      return _buildAddVehicleForm();
    }

    if (activeVehicle == null) {
      return _buildNoVehiclePlaceholder();
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildVehicleCard(activeVehicle),
        const SizedBox(height: 24),
        const Text(
          'Vehicle Transport Documents',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
        ),
        const SizedBox(height: 12),
        _buildDocRow(activeVehicle["id"], "Registration Certificate (RC)", "rc_card", Icons.assignment_outlined, true),
        const SizedBox(height: 12),
        _buildDocRow(activeVehicle["id"], "Vehicle Insurance", "insurance", Icons.security_outlined, true),
        const SizedBox(height: 12),
        _buildDocRow(activeVehicle["id"], "Pollution Under Control (PUC)", "puc", Icons.opacity_outlined, false),
        const SizedBox(height: 12),
        _buildDocRow(activeVehicle["id"], "Fitness Certificate", "fitness_certificate", Icons.offline_bolt_outlined, false),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _isAddingVehicle = true;
            });
          },
          icon: const Icon(Icons.add, size: 16),
          label: const Text('REGISTER ANOTHER VEHICLE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF3B82F6),
            side: const BorderSide(color: Color(0xFF3B82F6)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }

  Widget _buildNoVehiclePlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1329),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.04)),
              ),
              child: const Icon(Icons.directions_car_filled_outlined, size: 48, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Vehicle Registered',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your primary vehicle details below to map your profile and upload transport documents.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isAddingVehicle = true;
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('ADD NEW VEHICLE', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> vehicle) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${vehicle["make"]} ${vehicle["model"]}'.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Year: ${vehicle["year"]}  |  Color: ${vehicle["color"]}',
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('ACTIVE', style: TextStyle(color: Color(0xFF3B82F6), fontSize: 10, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 24),
          Text(
            vehicle["registration_number"],
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              fontFamily: 'Courier',
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text('PLATFORM DRIVER ASSIGNED VEHICLE', style: TextStyle(color: Colors.grey, fontSize: 9)),
        ],
      ),
    );
  }

  Widget _buildDocRow(String vehicleId, String name, String docType, IconData icon, bool verified) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1329),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF3B82F6), size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      verified ? Icons.check_circle : Icons.hourglass_top,
                      color: verified ? const Color(0xFF10B981) : Colors.orangeAccent,
                      size: 11,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      verified ? "Verified" : "Pending Review",
                      style: TextStyle(
                        color: verified ? const Color(0xFF10B981) : Colors.orangeAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _uploadVehicleDoc(vehicleId, docType),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.08),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('UPLOAD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildAddVehicleForm() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1329),
        title: const Text('Add Vehicle Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _isAddingVehicle = false;
            });
          },
        ),
      ),
      body: Container(
        color: const Color(0xFF020617),
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildFormFields(),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submitNewVehicle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('REGISTER VEHICLE', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1329),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          _buildTextField(
            label: 'Registration Number (e.g. KA-51-MJ-2810)',
            controller: _regNumController,
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Manufacturer/Make (e.g. Tata, Maruti Suzuki)',
            controller: _makeController,
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Model (e.g. Nexon, Dzire)',
            controller: _modelController,
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  label: 'Year',
                  controller: _yearController,
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  label: 'Color',
                  controller: _colorController,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF020617),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.0),
        ),
      ),
    );
  }
}
