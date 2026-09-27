import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'permit_screen.dart';
import 'employee_screen.dart';
import 'material_screen.dart';

class VendorPortalScreen extends StatefulWidget {
  const VendorPortalScreen({super.key});

  @override
  State<VendorPortalScreen> createState() => _VendorPortalScreenState();
}

class _VendorPortalScreenState extends State<VendorPortalScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _myEmployees = [];
  List<dynamic> _myPermits = [];
  List<dynamic> _myMaterials = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadVendorData();
  }

  void _loadVendorData() async {
    setState(() => _isLoading = true);
    final vendorId = ApiService.currentUser?.vendorId?.toString();
    final emps = await ApiService.getEmployees(vendorId: vendorId);
    final permits = await ApiService.getPermits();
    final materials = await ApiService.getMaterials();

    if (mounted) {
      setState(() {
        _myEmployees = emps;
        _myPermits = permits;
        _myMaterials = materials;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiService.currentUser;
    final insideCount = _myEmployees.where((e) => e['currently_inside'] == 1).length;
    final activePermitsCount = _myPermits.where((p) => p['status'] == 'Active' || p['status'] == 'Approved').length;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vendor & Contractor Portal',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              user?.fullName ?? 'Contractor Representative',
              style: const TextStyle(fontSize: 11, color: Color(0xFF06B6D4)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadVendorData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF06B6D4),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: [
            Tab(icon: const Icon(Icons.badge, size: 18), text: 'Workers (${_myEmployees.length})'),
            Tab(icon: const Icon(Icons.assignment, size: 18), text: 'Permits (${_myPermits.length})'),
            Tab(icon: const Icon(Icons.inventory_2, size: 18), text: 'Materials (${_myMaterials.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF06B6D4)))
          : Column(
              children: [
                // Contractor Quick Stats Banner
                Container(
                  padding: const EdgeInsets.all(14),
                  color: const Color(0xFF1E293B),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem('TOTAL WORKFORCE', '${_myEmployees.length}', Colors.blueAccent),
                      _buildDivider(),
                      _buildSummaryItem('INSIDE SITE', '$insideCount', Colors.greenAccent),
                      _buildDivider(),
                      _buildSummaryItem('ACTIVE PERMITS', '$activePermitsCount', const Color(0xFFF59E0B)),
                    ],
                  ),
                ),

                // Tab Views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: const [
                      EmployeeScreen(),
                      PermitScreen(),
                      MaterialScreen(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.white54, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 24, color: Colors.white12);
  }
}
