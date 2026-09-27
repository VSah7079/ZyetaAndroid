import 'package:flutter/material.dart';
import 'visitor_screen.dart';
import 'material_screen.dart';
import 'vehicle_screen.dart';

class GatePassesHubScreen extends StatefulWidget {
  final int initialTab;
  const GatePassesHubScreen({super.key, this.initialTab = 0});

  @override
  State<GatePassesHubScreen> createState() => _GatePassesHubScreenState();
}

class _GatePassesHubScreenState extends State<GatePassesHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTab);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Text('Gate Passes Hub', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6366F1),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.person_pin, size: 20), text: 'Visitors'),
            Tab(icon: Icon(Icons.inventory_2, size: 20), text: 'Materials'),
            Tab(icon: Icon(Icons.local_shipping, size: 20), text: 'Vehicles'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          VisitorScreen(),
          MaterialScreen(),
          VehicleScreen(),
        ],
      ),
    );
  }
}
