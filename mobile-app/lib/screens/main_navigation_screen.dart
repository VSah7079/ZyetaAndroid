import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'security_dashboard_screen.dart';
import 'safety_officer_screen.dart';
import 'employee_screen.dart';
import 'permit_screen.dart';
import 'gate_passes_hub_screen.dart';
import 'attendance_screen.dart';
import 'vendor_screen.dart';
import 'inside_headcount_screen.dart';
import 'audit_logs_screen.dart';
import 'qr_scanner_screen.dart';
import 'super_admin_screen.dart';
import 'vendor_portal_screen.dart';
import 'reports_screen.dart';
import 'material_screen.dart';
import 'emergency_muster_screen.dart';
import 'toolbox_talk_screen.dart';
import 'login_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiService.currentUser;
    final role = user?.role ?? 'Super Admin';
    final isSuperAdmin = user?.isSuperAdmin ?? true;

    // Build Dynamic Screens & Bottom Navigation items based on assigned permissions
    final List<Widget> screens = [];
    final List<BottomNavigationBarItem> navItems = [];

    // 1. Super Admin Full Access
    if (isSuperAdmin) {
      screens.addAll(const [
        SuperAdminScreen(),
        SecurityDashboardScreen(),
        EmployeeScreen(),
        PermitScreen(),
        GatePassesHubScreen(),
      ]);
      navItems.addAll(const [
        BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings_outlined), activeIcon: Icon(Icons.admin_panel_settings), label: 'Admin Hub'),
        BottomNavigationBarItem(icon: Icon(Icons.shield_outlined), activeIcon: Icon(Icons.shield), label: 'Terminal'),
        BottomNavigationBarItem(icon: Icon(Icons.badge_outlined), activeIcon: Icon(Icons.badge), label: 'Workers'),
        BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), activeIcon: Icon(Icons.assignment), label: 'Permits'),
        BottomNavigationBarItem(icon: Icon(Icons.door_sliding_outlined), activeIcon: Icon(Icons.door_sliding), label: 'Passes'),
      ]);
    } else {
      // Granular Role-Based Permissions Check
      if (user?.can('safety') == true && role == 'Safety Officer') {
        screens.add(const SafetyOfficerScreen());
        navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.health_and_safety_outlined), activeIcon: Icon(Icons.health_and_safety), label: 'HSE Command'));
      } else if (user?.can('gate') == true) {
        screens.add(const SecurityDashboardScreen());
        navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.shield_outlined), activeIcon: Icon(Icons.shield), label: 'Terminal'));
      } else if (role == 'Vendor') {
        screens.add(const VendorPortalScreen());
        navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined), activeIcon: Icon(Icons.storefront), label: 'My Portal'));
      }

      if (user?.can('employees') == true) {
        screens.add(const EmployeeScreen());
        navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.badge_outlined), activeIcon: Icon(Icons.badge), label: 'Workers'));
      }

      if (user?.can('permits') == true) {
        screens.add(const PermitScreen());
        navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), activeIcon: Icon(Icons.assignment), label: 'Permits'));
      }

      if (user?.can('materials') == true && role == 'Vendor') {
        screens.add(const MaterialScreen());
        navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), activeIcon: Icon(Icons.inventory_2), label: 'Material DC'));
      } else if (user?.can('visitors') == true || user?.can('materials') == true || user?.can('vehicles') == true) {
        screens.add(const GatePassesHubScreen());
        navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.door_sliding_outlined), activeIcon: Icon(Icons.door_sliding), label: 'Passes'));
      }

      if (user?.can('attendance') == true && screens.length < 5) {
        screens.add(const AttendanceScreen());
        navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.how_to_reg_outlined), activeIcon: Icon(Icons.how_to_reg), label: 'Attendance'));
      }

      if (user?.can('headcount') == true && screens.length < 5 && role == 'Security') {
        screens.add(const InsideHeadcountScreen());
        navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.groups_outlined), activeIcon: Icon(Icons.groups), label: 'Headcount'));
      }
    }

    // Fallback if no specific tab matched
    if (screens.isEmpty) {
      screens.add(const SecurityDashboardScreen());
      navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'));
    }

    // Safety index check
    if (_currentIndex >= screens.length) {
      _currentIndex = 0;
    }

    Color roleColor = isSuperAdmin
        ? const Color(0xFFF59E0B)
        : role == 'Admin'
            ? const Color(0xFF6366F1)
            : role == 'Safety Officer'
                ? const Color(0xFFF97316)
                : role == 'Vendor'
                    ? const Color(0xFF06B6D4)
                    : const Color(0xFF10B981);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      drawer: Drawer(
        backgroundColor: const Color(0xFF0F172A),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Drawer Header with User Role & Permissions Badge
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [roleColor.withValues(alpha: 0.85), const Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              currentAccountPicture: Container(
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white24),
                child: Icon(
                  isSuperAdmin
                      ? Icons.admin_panel_settings
                      : role == 'Admin'
                          ? Icons.business
                          : role == 'Safety Officer'
                              ? Icons.health_and_safety
                              : role == 'Vendor'
                                  ? Icons.storefront
                                  : Icons.security,
                  color: Colors.white,
                  size: 38,
                ),
              ),
              accountName: Text(
                user?.fullName ?? 'Zyeta User',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              accountEmail: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(4)),
                    child: Text(
                      'ROLE: ${role.toUpperCase()} ${isSuperAdmin ? '(MASTER ROOT)' : ''}',
                      style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            // --- SUPER ADMIN MASTER MODULE ---
            if (isSuperAdmin || user?.can('superadmin') == true)
              _buildDrawerTile(Icons.admin_panel_settings, '👑 Super Admin Control Suite', () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SuperAdminScreen()));
              }),

            // --- PERMITTED MODULES (CLEANLY FILTERED BASED ON PERMISSIONS) ---
            if (isSuperAdmin || user?.can('gate') == true)
              _buildDrawerTile(Icons.dashboard, '🛡️ Gate Security Terminal', () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SecurityDashboardScreen()));
              }),

            if (isSuperAdmin || user?.can('gate') == true)
              _buildDrawerTile(Icons.qr_code_scanner, '📷 Camera QR Scanner', () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const QRScannerScreen()));
              }),

            if (isSuperAdmin || user?.can('safety') == true)
              _buildDrawerTile(Icons.health_and_safety, '⛑️ HSE Safety Command Hub', () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SafetyOfficerScreen()));
              }),

            if (isSuperAdmin || user?.can('employees') == true)
              _buildDrawerTile(Icons.badge, '👷 Workforce & ID Passes', () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeeScreen()));
              }),

            if (isSuperAdmin || user?.can('permits') == true)
              _buildDrawerTile(Icons.assignment, '📋 Work Permits (PTW)', () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PermitScreen()));
              }),

            if (isSuperAdmin || user?.can('visitors') == true || user?.can('materials') == true || user?.can('vehicles') == true)
              _buildDrawerTile(Icons.door_sliding, '🚪 Gate Passes Hub', () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const GatePassesHubScreen()));
              }),

            if (isSuperAdmin || user?.can('vendors') == true)
              _buildDrawerTile(Icons.business, '🏗️ Contractors & Vendors', () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorScreen()));
              }),

            if (role == 'Vendor')
              _buildDrawerTile(Icons.storefront, '🏢 Vendor Self-Service Portal', () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorPortalScreen()));
              }),

            if (isSuperAdmin || user?.can('attendance') == true)
              _buildDrawerTile(Icons.how_to_reg, '📊 Attendance & Muster Roll', () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceScreen()));
              }),

            if (isSuperAdmin || user?.can('headcount') == true)
              _buildDrawerTile(Icons.groups, '🟢 Live Inside Headcount', () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const InsideHeadcountScreen()));
              }),

            if (isSuperAdmin || user?.can('reports') == true)
              _buildDrawerTile(Icons.analytics, '📈 Reports & Analytics', () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
              }),

            if (isSuperAdmin || user?.can('audit') == true)
              _buildDrawerTile(Icons.history_edu, '📜 System Audit Trail', () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AuditLogsScreen()));
              }),

            _buildDrawerTile(Icons.record_voice_over, '🗣️ Daily Toolbox Talks (TBT)', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ToolboxTalkScreen()));
            }),

            _buildDrawerTile(Icons.emergency, '🚨 Emergency Muster & Evacuation', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyMusterScreen()));
            }),

            const Divider(color: Colors.white12),

            // Logout / Switch User Account
            ListTile(
              leading: const Icon(Icons.switch_account, color: Color(0xFF6366F1)),
              title: const Text('Switch Role / Logout', style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
              onTap: () {
                ApiService.authToken = null;
                ApiService.currentUser = null;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (idx) => setState(() => _currentIndex = idx),
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF0F172A),
          selectedItemColor: roleColor,
          unselectedItemColor: Colors.white54,
          selectedFontSize: 11,
          unselectedFontSize: 10,
          items: navItems,
        ),
      ),
    );
  }

  Widget _buildDrawerTile(IconData icon, String title, VoidCallback onTap, {bool isSelected = false}) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? const Color(0xFF6366F1) : Colors.white70),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? const Color(0xFF6366F1) : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onTap: onTap,
    );
  }
}
