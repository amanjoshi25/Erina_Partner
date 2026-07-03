import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/driver_provider.dart';

class RsaTrackingScreen extends StatefulWidget {
  const RsaTrackingScreen({super.key});

  @override
  State<RsaTrackingScreen> createState() => _RsaTrackingScreenState();
}

class _RsaTrackingScreenState extends State<RsaTrackingScreen> {
  int _selectedRating = 5;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _showFeedbackDialog(BuildContext context, String requestId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0B1329),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text(
                'Help Has Arrived!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Rate your assistance experience with the dispatch responder.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < _selectedRating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            _selectedRating = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _commentController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Share any details or comments...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
                      filled: true,
                      fillColor: const Color(0xFF020617),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.06)),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('SUBMIT FEEDBACK', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    final provider = Provider.of<DriverProvider>(context, listen: false);
                    final success = await provider.completeSOSFeedback(_selectedRating, _commentController.text.trim());
                    if (success && mounted) {
                      Navigator.pop(context); // close feedback dialog
                      Navigator.pop(context); // return to dashboard
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DriverProvider>(context);
    final request = provider.activeRsaRequest;

    if (request == null) {
      // Just in case we navigate back or it completed
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))),
      );
    }

    final String status = request["status"] ?? "Requested";
    final tech = request["technician"];
    final etaRaw = request["estimated_arrival"];
    final etaStr = etaRaw != null ? DateTime.parse(etaRaw.toString()).toLocal().toString().substring(11, 16) : "--:--";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1329),
        title: const Text('SOS Help Dispatch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        automaticallyImplyLeading: false,
      ),
      body: Container(
        color: const Color(0xFF020617),
        child: Column(
          children: [
            // Map/Tracking visualization graphic
            Expanded(
              child: Stack(
                children: [
                  _buildMockMapWidget(status),
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: _buildEtaOverlay(status, etaStr),
                  ),
                ],
              ),
            ),
            
            // Dispatch details overlay card
            _buildDispatchDetailsPanel(context, request, status, tech),
          ],
        ),
      ),
    );
  }

  Widget _buildMockMapWidget(String status) {
    // A premium abstract vector graphic representing the coordinates tracking grid
    return Container(
      color: const Color(0xFF02091c),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Pulses showing radar coordinates
                _buildRadarPulse(150, Colors.blue.withOpacity(0.04)),
                _buildRadarPulse(100, Colors.blue.withOpacity(0.08)),
                _buildRadarPulse(50, Colors.blue.withOpacity(0.12)),
                
                // Driver pin (center)
                const Icon(Icons.my_location, color: Colors.blueAccent, size: 28),
                
                // Responder pin (moving close)
                if (status == "Dispatched" || status == "In_Progress")
                  AnimatedAlign(
                    duration: const Duration(seconds: 4),
                    alignment: status == "In_Progress" ? const Alignment(0.1, -0.1) : const Alignment(-0.5, 0.4),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.engineering, color: Colors.white, size: 16),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'INCIDENT RESOLUTION GPS COORD RADAR',
              style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 0.8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadarPulse(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.blue.withOpacity(0.08)),
      ),
    );
  }

  Widget _buildEtaOverlay(String status, String eta) {
    String label = "RESPONDER ARRIVING";
    String details = "ETA: $eta";
    if (status == "In_Progress") {
      label = "TECHNICIAN ARRIVED";
      details = "Resolving incident";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1329).withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 8,
                height: 8,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981)),
              ),
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            ],
          ),
          Text(details, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF3B82F6))),
        ],
      ),
    );
  }

  Widget _buildDispatchDetailsPanel(BuildContext context, Map<String, dynamic> request, String status, Map<String, dynamic>? tech) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1329),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Step progress indicator
          _buildStepProgress(status),
          const SizedBox(height: 24),
          Divider(color: Colors.white.withOpacity(0.06)),
          const SizedBox(height: 16),

          // Tech Profile Info
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFEF4444).withOpacity(0.12),
                child: const Icon(Icons.person, color: Color(0xFFEF4444)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tech != null ? tech["name"] : "Responder Technician",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tech != null ? tech["phone"] : "Connecting phone...",
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                icon: const Icon(Icons.call, color: Colors.white, size: 20),
                onPressed: () {},
              )
            ],
          ),
          const SizedBox(height: 24),

          // Actions
          if (status == "In_Progress")
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('MARK AS RESOLVED', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => _showFeedbackDialog(context, request["id"]),
            )
          else ...[
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('CANCEL HELP REQUEST', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              onPressed: () async {
                final provider = Provider.of<DriverProvider>(context, listen: false);
                final success = await provider.cancelSOS();
                if (success && mounted) {
                  Navigator.pop(context);
                }
              },
            )
          ]
        ],
      ),
    );
  }

  Widget _buildStepProgress(String status) {
    int activeStep = 0;
    if (status == "Dispatched") activeStep = 1;
    if (status == "In_Progress") activeStep = 2;

    return Row(
      children: [
        _buildStepItem("SOS Raised", activeStep >= 0),
        _buildStepLine(activeStep >= 1),
        _buildStepItem("On The Way", activeStep >= 1),
        _buildStepLine(activeStep >= 2),
        _buildStepItem("Resolving", activeStep >= 2),
      ],
    );
  }

  Widget _buildStepItem(String title, bool completed) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            completed ? Icons.check_circle : Icons.radio_button_unchecked,
            color: completed ? const Color(0xFF10B981) : Colors.grey,
            size: 18,
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: completed ? Colors.white : Colors.grey,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStepLine(bool active) {
    return Container(
      width: 32,
      height: 2,
      color: active ? const Color(0xFF10B981) : Colors.grey.withOpacity(0.3),
    );
  }
}
