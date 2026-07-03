import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/driver_provider.dart';

class SubTab extends StatefulWidget {
  const SubTab({super.key});

  @override
  State<SubTab> createState() => _SubTabState();
}

class _SubTabState extends State<SubTab> {
  bool _isProcessingPayment = false;

  void _triggerPaymentSimulation(Map<String, dynamic> plan) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0B1329),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isDismissible: !_isProcessingPayment,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!_isProcessingPayment) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Secure Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Purchase ${plan["name"]}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        plan["description"] ?? 'Roadside Assistance Subscription Plan',
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF020617),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Plan Cost (Inc. GST)', style: TextStyle(color: Colors.grey, fontSize: 13)),
                            Text(
                              '₹${plan["price"]}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blueAccent),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.payment),
                        label: const Text('PAY WITH RAZORPAY', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () async {
                          setModalState(() {
                            _isProcessingPayment = true;
                          });
                          
                          // Run payment verification simulation
                          final driverProvider = Provider.of<DriverProvider>(context, listen: false);
                          final success = await driverProvider.purchasePlan(plan["id"]);
                          
                          if (mounted) {
                            Navigator.pop(context);
                            setModalState(() {
                              _isProcessingPayment = false;
                            });
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(success 
                                    ? 'Payment successful! Subscription active.' 
                                    : 'Payment verification failed.'),
                                backgroundColor: success ? const Color(0xFF10B981) : Colors.redAccent,
                              ),
                            );
                          }
                        },
                      ),
                    ] else ...[
                      const SizedBox(height: 32),
                      const Center(
                        child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Processing Secure Razorpay Transaction...',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Please do not press back or close the application.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                      const SizedBox(height: 32),
                    ]
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DriverProvider>(context);
    final plans = provider.plans;
    final history = provider.billingHistory;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Choose a Subscription Plan',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 12),
        if (plans.isEmpty)
          const Center(child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
          ))
        else
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: plans.length,
              itemBuilder: (context, index) {
                final plan = plans[index];
                return _buildPlanCard(plan);
              },
            ),
          ),

        const SizedBox(height: 32),

        const Text(
          'Billing History & Invoices',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 12),
        if (history.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1329),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.04)),
            ),
            child: const Center(
              child: Text(
                'No past payment records found.',
                style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              return _buildInvoiceRow(item);
            },
          ),
      ],
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final String name = plan["name"] ?? 'Plan';
    final double price = plan["price"] != null ? double.parse(plan["price"].toString()) : 0.0;
    final int days = plan["duration_days"] ?? 30;

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1329),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
              const SizedBox(height: 4),
              Text(
                plan["description"] ?? '',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, height: 1.3),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                textBaseline: TextBaseline.alphabetic,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                children: [
                  Text(
                    '₹$price',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Colors.blueAccent),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '/ $days Days',
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _triggerPaymentSimulation(plan),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(40),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('PURCHASE NOW', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildInvoiceRow(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1329),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item["plan_name"] ?? 'Subscription',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'Invoice: ${item["invoice_number"] ?? "INV-N/A"}',
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                ),
                const SizedBox(height: 2),
                Text(
                  'Txn: ${item["transaction_id"]}',
                  style: const TextStyle(color: Colors.grey, fontSize: 9),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${item["amount"]}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF10B981)),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'PAID',
                  style: TextStyle(color: Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
