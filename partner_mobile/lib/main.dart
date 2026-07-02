import 'package:flutter/material.dart';

void main() {
  runApp(const ErinaPartnerApp());
}

class ErinaPartnerApp extends StatelessWidget {
  const ErinaPartnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Erina Partner',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF14B8A6),
          brightness: Brightness.dark,
          surface: const Color(0xFF042521),
          primary: const Color(0xFF14B8A6),
          secondary: const Color(0xFF10B981),
          error: const Color(0xFFEF4444),
        ),
        scaffoldBackgroundColor: const Color(0xFF011512),
        cardTheme: const CardTheme(
          color: Color(0xFF042521),
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
      ),
      home: const PartnerDashboardScreen(),
    );
  }
}

class PartnerDashboardScreen extends StatefulWidget {
  const PartnerDashboardScreen({super.key});

  @override
  State<PartnerDashboardScreen> createState() => _PartnerDashboardScreenState();
}

class _PartnerDashboardScreenState extends State<PartnerDashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF042521),
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF14B8A6).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF14B8A6).withOpacity(0.3), width: 1),
              ),
              child: const Icon(Icons.people_outline, color: Color(0xFF14B8A6), size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'ERINA',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                fontSize: 18,
              ),
            ),
            const Text(
              '.partner',
              style: TextStyle(
                fontWeight: FontWeight.w300,
                color: Color(0xFF14B8A6),
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: const Color(0xFF042521),
        indicatorColor: const Color(0xFF14B8A6).withOpacity(0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: Color(0xFF14B8A6)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_add_alt_outlined),
            selectedIcon: Icon(Icons.person_add_alt, color: Color(0xFF14B8A6)),
            label: 'Onboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet, color: Color(0xFF14B8A6)),
            label: 'Commissions',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFF14B8A6)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_selectedIndex == 0) {
      return const PartnerHomeTab();
    }
    return Center(
      child: Text(
        'Tab ${_selectedIndex + 1} Content Under Construction',
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }
}

class PartnerHomeTab extends StatelessWidget {
  const PartnerHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Earnings overview card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF042521), Color(0xFF075E54)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.teal.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Balance',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '₹18,450',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Divider(color: Colors.teal.withOpacity(0.2)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('DRIVER REFERRALS', style: TextStyle(color: Colors.grey, fontSize: 10)),
                      SizedBox(height: 4),
                      Text(
                        '48 Drivers',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF14B8A6),
                      foregroundColor: const Color(0xFF011512),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Withdraw', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Quick Onboarding Action
        ElevatedButton(
          onPressed: () => _showOnboardingDialog(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF14B8A6),
            foregroundColor: const Color(0xFF011512),
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 4,
            shadowColor: const Color(0xFF14B8A6).withOpacity(0.4),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_add_alt_1_rounded, size: 24),
              SizedBox(width: 12),
              Text(
                'ONBOARD NEW DRIVER',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Statistics
        const Text(
          'Commission Metrics',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.4,
          children: [
            _buildStatCard(
              icon: Icons.monetization_on_outlined,
              title: 'Earnings Today',
              value: '₹1,200',
              color: Colors.amber,
            ),
            _buildStatCard(
              icon: Icons.verified_user_outlined,
              title: 'Successful sales',
              value: '18 Active',
              color: Colors.green,
            ),
            _buildStatCard(
              icon: Icons.hourglass_empty,
              title: 'Pending Payout',
              value: '₹3,400',
              color: Colors.orange,
            ),
            _buildStatCard(
              icon: Icons.trending_up,
              title: 'Referral Rank',
              value: 'Gold Elite',
              color: Colors.indigo,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF042521),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.teal.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          )
        ],
      ),
    );
  }

  void _showOnboardingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF042521),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Onboard Driver'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter driver mobile number to send subscription setup link:'),
              const SizedBox(height: 16),
              TextField(
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  prefixText: '+91 ',
                  hintText: 'Enter Mobile Number',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF14B8A6)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF14B8A6),
                foregroundColor: const Color(0xFF011512),
              ),
              child: const Text('Send Link'),
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Onboarding link sent to driver successfully!'),
                    backgroundColor: Color(0xFF14B8A6),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
