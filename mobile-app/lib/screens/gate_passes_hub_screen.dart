import '../utils/validators.dart';
import '../utils/app_theme.dart';
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
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: const AppBarLeadingButton(),
        title: const Text('Gate Passes Hub', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        actions: const [
          LogoutIconButton(),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          indicatorWeight: 3,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.person_pin_rounded, size: 20), text: 'Visitors'),
            Tab(icon: Icon(Icons.inventory_2_rounded, size: 20), text: 'Materials'),
            Tab(icon: Icon(Icons.local_shipping_rounded, size: 20), text: 'Vehicles'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          VisitorScreen(showAppBar: false),
          MaterialScreen(showAppBar: false),
          VehicleScreen(showAppBar: false),
        ],
      ),
    );
  }
}
