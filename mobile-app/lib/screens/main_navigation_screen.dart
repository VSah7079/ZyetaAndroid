import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/validators.dart';
import '../utils/app_theme.dart';
import 'security_dashboard_screen.dart';
import 'safety_officer_screen.dart';
import 'employee_screen.dart';
import 'permit_screen.dart';
import 'gate_passes_hub_screen.dart';
import 'attendance_screen.dart';
import 'vendor_screen.dart';
import 'site_admin_screen.dart';
import 'inside_headcount_screen.dart';
import 'audit_logs_screen.dart';
import 'qr_scanner_screen.dart';
import 'super_admin_screen.dart';
import 'vendor_portal_screen.dart';
import 'reports_screen.dart';
import 'material_screen.dart';
import 'emergency_muster_screen.dart';
import 'toolbox_talk_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    NavUtils.openDrawerCallback = () => _scaffoldKey.currentState?.openDrawer();
  }

  @override
  void dispose() {
    NavUtils.openDrawerCallback = null;
    super.dispose();
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
      if (role == 'Admin' || (user?.can('vendors') == true && role != 'Vendor' && role != 'Security' && role != 'Safety Officer')) {
        screens.add(const SiteAdminScreen());
        navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.business_outlined), activeIcon: Icon(Icons.business), label: 'Site Admin'));
      } else if (user?.can('safety') == true && role == 'Safety Officer') {
        screens.add(const SafetyOfficerScreen());
        navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.health_and_safety_outlined), activeIcon: Icon(Icons.health_and_safety), label: 'HSE Command'));
      } else if (user?.can('gate') == true) {
        screens.add(const SecurityDashboardScreen());
        navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.shield_outlined), activeIcon: Icon(Icons.shield), label: 'Terminal'));
      } else if (role == 'Vendor') {
        screens.add(const VendorPortalScreen());
        navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined), activeIcon: Icon(Icons.storefront), label: 'My Portal'));
      }

      if (user?.can('employees') == true && screens.length < 5) {
        screens.add(const EmployeeScreen());
        navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.badge_outlined), activeIcon: Icon(Icons.badge), label: 'Workers'));
      }

      if (user?.can('permits') == true && screens.length < 5) {
        screens.add(const PermitScreen());
        navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), activeIcon: Icon(Icons.assignment), label: 'Permits'));
      }

      if (user?.can('materials') == true && role == 'Vendor') {
        screens.add(const MaterialScreen());
        navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), activeIcon: Icon(Icons.inventory_2), label: 'Material DC'));
      } else if ((user?.can('visitors') == true || user?.can('materials') == true || user?.can('vehicles') == true) && screens.length < 5) {
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

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.bgPrimary,
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Drawer Header with Clean Modern Gradient
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E40AF), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              currentAccountPicture: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.2),
                  border: Border.all(color: Colors.white30, width: 2),
                ),
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
                  size: 36,
                ),
              ),
              accountName: Text(
                user?.fullName ?? 'Zyeta User',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
              ),
              accountEmail: Row(
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'ROLE: ${role.toUpperCase()} ${isSuperAdmin ? '(MASTER ROOT)' : ''}',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- SUPER ADMIN MASTER MODULE ---
            if (isSuperAdmin || user?.can('superadmin') == true)
              _buildDrawerTile(Icons.admin_panel_settings_outlined, '👑 Super Admin Control Suite', () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SuperAdminScreen()));
              }),

            // --- PERMITTED MODULES ---
            if (isSuperAdmin || user?.can('gate') == true)
              _buildDrawerTile(Icons.dashboard_outlined, '🛡️ Gate Security Terminal', () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SecurityDashboardScreen()));
              }),

            if (isSuperAdmin || user?.can('gate') == true)
              _buildDrawerTile(Icons.qr_code_scanner, '📷 Camera QR Scanner', () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const QRScannerScreen()));
              }),

            if (isSuperAdmin || user?.can('safety') == true)
              _buildDrawerTile(Icons.health_and_safety_outlined, '⛑️ HSE Safety Command Hub', () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SafetyOfficerScreen()));
              }),

            if (isSuperAdmin || user?.can('employees') == true)
              _buildDrawerTile(Icons.badge_outlined, '👷 Workforce & ID Passes', () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeeScreen()));
              }),

            if (isSuperAdmin || user?.can('permits') == true)
              _buildDrawerTile(Icons.assignment_outlined, '📋 Work Permits (PTW)', () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PermitScreen()));
              }),

            if (isSuperAdmin || user?.can('visitors') == true || user?.can('materials') == true || user?.can('vehicles') == true)
              _buildDrawerTile(Icons.door_sliding_outlined, '🚪 Gate Passes Hub', () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const GatePassesHubScreen()));
              }),

            if (isSuperAdmin || role == 'Admin' || user?.can('vendors') == true)
              _buildDrawerTile(Icons.business_center_outlined, '🏛️ Site Admin Contractor Command', () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SiteAdminScreen()));
              }),

            if (isSuperAdmin || user?.can('vendors') == true)
              _buildDrawerTile(Icons.business_outlined, '🏗️ Contractors & Vendors Roster', () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorScreen()));
              }),

            if (role == 'Vendor')
              _buildDrawerTile(Icons.storefront_outlined, '🏢 Vendor Self-Service Portal', () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorPortalScreen()));
              }),

            if (isSuperAdmin || user?.can('attendance') == true)
              _buildDrawerTile(Icons.how_to_reg_outlined, '📊 Attendance & Muster Roll', () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceScreen()));
              }),

            if (isSuperAdmin || user?.can('headcount') == true)
              _buildDrawerTile(Icons.groups_outlined, '🟢 Live Inside Headcount', () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const InsideHeadcountScreen()));
              }),

            if (isSuperAdmin || user?.can('reports') == true)
              _buildDrawerTile(Icons.analytics_outlined, '📈 Reports & Analytics', () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
              }),

            if (isSuperAdmin || user?.can('audit') == true)
              _buildDrawerTile(Icons.history_edu_outlined, '📜 System Audit Trail', () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AuditLogsScreen()));
              }),

            _buildDrawerTile(Icons.record_voice_over_outlined, '🗣️ Daily Toolbox Talks (TBT)', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ToolboxTalkScreen()));
            }),

            _buildDrawerTile(Icons.emergency_outlined, '🚨 Emergency Muster & Evacuation', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyMusterScreen()));
            }),

            const Divider(color: AppTheme.border, height: 24),

            // Logout / Switch User Account
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppTheme.danger),
              title: const Text('Switch Role / Logout', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold, fontSize: 13.5)),
              onTap: () {
                Navigator.pop(context);
                AuthUtils.showLogoutDialog(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: AppTheme.border, width: 1)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (idx) => setState(() => _currentIndex = idx),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: AppTheme.textMuted,
          selectedFontSize: 11,
          unselectedFontSize: 10,
          elevation: 0,
          items: navItems,
        ),
      ),
    );
  }

  Widget _buildDrawerTile(IconData icon, String title, VoidCallback onTap, {bool isSelected = false}) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppTheme.primary : AppTheme.textSecondary, size: 21),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 13,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      selected: isSelected,
      selectedTileColor: AppTheme.primarySubtle,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      dense: true,
      onTap: onTap,
    );
  }
}
