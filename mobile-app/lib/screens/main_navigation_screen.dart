import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'security_dashboard_screen.dart';
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
    final role = ApiService.currentUser?.role ?? 'Super Admin';
    final isSuperAdmin = role == 'Super Admin';
    final isAdmin = role == 'Admin';
    final isVendor = role == 'Vendor';
    final isSecurity = role == 'Security';

    // Build Role-Specific Screens & Bottom Navigation
    List<Widget> screens;
    List<BottomNavigationBarItem> navItems;

    if (isVendor) {
      screens = const [
        VendorPortalScreen(),
        EmployeeScreen(),
        PermitScreen(),
        MaterialScreen(),
      ];
      navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined), activeIcon: Icon(Icons.storefront), label: 'My Portal'),
        BottomNavigationBarItem(icon: Icon(Icons.badge_outlined), activeIcon: Icon(Icons.badge), label: 'My Workers'),
        BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), activeIcon: Icon(Icons.assignment), label: 'My Permits'),
        BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), activeIcon: Icon(Icons.inventory_2), label: 'Material DC'),
      ];
    } else if (isSecurity) {
      screens = const [
        SecurityDashboardScreen(),
        QRScannerScreen(),
        GatePassesHubScreen(),
        InsideHeadcountScreen(),
      ];
      navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.shield_outlined), activeIcon: Icon(Icons.shield), label: 'Terminal'),
        BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner_outlined), activeIcon: Icon(Icons.qr_code_scanner), label: 'Scanner'),
        BottomNavigationBarItem(icon: Icon(Icons.door_sliding_outlined), activeIcon: Icon(Icons.door_sliding), label: 'Passes Hub'),
        BottomNavigationBarItem(icon: Icon(Icons.groups_outlined), activeIcon: Icon(Icons.groups), label: 'Headcount'),
      ];
    } else {
      // Super Admin & Site Admin
      screens = const [
        SecurityDashboardScreen(),
        EmployeeScreen(),
        PermitScreen(),
        GatePassesHubScreen(),
        AttendanceScreen(),
      ];
      navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.shield_outlined), activeIcon: Icon(Icons.shield), label: 'Terminal'),
        BottomNavigationBarItem(icon: Icon(Icons.badge_outlined), activeIcon: Icon(Icons.badge), label: 'Workers'),
        BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), activeIcon: Icon(Icons.assignment), label: 'Permits'),
        BottomNavigationBarItem(icon: Icon(Icons.door_sliding_outlined), activeIcon: Icon(Icons.door_sliding), label: 'Passes'),
        BottomNavigationBarItem(icon: Icon(Icons.how_to_reg_outlined), activeIcon: Icon(Icons.how_to_reg), label: 'Muster'),
      ];
    }

    // Safety check for index
    if (_currentIndex >= screens.length) {
      _currentIndex = 0;
    }

    Color roleColor = isSuperAdmin
        ? const Color(0xFFF59E0B)
        : isAdmin
            ? const Color(0xFF6366F1)
            : isVendor
                ? const Color(0xFF06B6D4)
                : const Color(0xFF10B981);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      drawer: Drawer(
        backgroundColor: const Color(0xFF0F172A),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Role-Aware Drawer Header
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [roleColor.withValues(alpha: 0.8), const Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              currentAccountPicture: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white24,
                ),
                child: Icon(
                  isSuperAdmin
                      ? Icons.admin_panel_settings
                      : isAdmin
                          ? Icons.business
                          : isVendor
                              ? Icons.storefront
                              : Icons.security,
                  color: Colors.white,
                  size: 38,
                ),
              ),
              accountName: Text(
                ApiService.currentUser?.fullName ?? 'Zyeta User',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              accountEmail: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'ROLE: ${role.toUpperCase()}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            // --- VENDOR-SPECIFIC MENU ---
            if (isVendor) ...[
              _buildDrawerTile(Icons.storefront, '🏗️ My Company Portal', () {
                Navigator.pop(context);
                setState(() => _currentIndex = 0);
              }, isSelected: _currentIndex == 0),
              _buildDrawerTile(Icons.badge, '👷 My Deployed Workers', () {
                Navigator.pop(context);
                setState(() => _currentIndex = 1);
              }, isSelected: _currentIndex == 1),
              _buildDrawerTile(Icons.assignment, '📋 My Work Permits (PTW)', () {
                Navigator.pop(context);
                setState(() => _currentIndex = 2);
              }, isSelected: _currentIndex == 2),
              _buildDrawerTile(Icons.inventory_2, '📦 My Material Delivery Passes', () {
                Navigator.pop(context);
                setState(() => _currentIndex = 3);
              }, isSelected: _currentIndex == 3),
            ],

            // --- SECURITY-SPECIFIC MENU ---
            if (isSecurity) ...[
              _buildDrawerTile(Icons.dashboard, '🛡️ Gate Security Terminal', () {
                Navigator.pop(context);
                setState(() => _currentIndex = 0);
              }, isSelected: _currentIndex == 0),
              _buildDrawerTile(Icons.qr_code_scanner, '📷 Camera QR Scanner', () {
                Navigator.pop(context);
                setState(() => _currentIndex = 1);
              }, isSelected: _currentIndex == 1),
              _buildDrawerTile(Icons.door_sliding, '🚪 Gate Passes (Visitors / DC / Vehicle)', () {
                Navigator.pop(context);
                setState(() => _currentIndex = 2);
              }, isSelected: _currentIndex == 2),
              _buildDrawerTile(Icons.groups, '🟢 Live Inside Headcount', () {
                Navigator.pop(context);
                setState(() => _currentIndex = 3);
              }, isSelected: _currentIndex == 3),
            ],

            // --- ADMIN & SUPER ADMIN MENU ---
            if (isAdmin || isSuperAdmin) ...[
              _buildDrawerTile(Icons.dashboard, '🛡️ Site Terminal & KPIs', () {
                Navigator.pop(context);
                setState(() => _currentIndex = 0);
              }, isSelected: _currentIndex == 0),
              _buildDrawerTile(Icons.badge, '👷 Workers & ID Passes', () {
                Navigator.pop(context);
                setState(() => _currentIndex = 1);
              }, isSelected: _currentIndex == 1),
              _buildDrawerTile(Icons.assignment, '📋 Work Permits (PTW)', () {
                Navigator.pop(context);
                setState(() => _currentIndex = 2);
              }, isSelected: _currentIndex == 2),
              _buildDrawerTile(Icons.door_sliding, '🚪 Gate Passes Hub', () {
                Navigator.pop(context);
                setState(() => _currentIndex = 3);
              }, isSelected: _currentIndex == 3),
              _buildDrawerTile(Icons.how_to_reg, '📊 Attendance & Muster Roll', () {
                Navigator.pop(context);
                setState(() => _currentIndex = 4);
              }, isSelected: _currentIndex == 4),

              const Divider(color: Colors.white12),

              // Super Admin Exclusive
              if (isSuperAdmin) ...[
                _buildDrawerTile(Icons.admin_panel_settings, '👑 Super Admin Suite (Users)', () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SuperAdminScreen()));
                }),
                _buildDrawerTile(Icons.storefront, '🏗️ Contractor / Vendor Portal', () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorPortalScreen()));
                }),
              ],

              _buildDrawerTile(Icons.analytics, '📊 Reports & Analytics', () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
              }),

              _buildDrawerTile(Icons.business, 'Contractors & Vendors Directory', () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorScreen()));
              }),

              _buildDrawerTile(Icons.groups, 'Live Inside Headcount', () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const InsideHeadcountScreen()));
              }),

              _buildDrawerTile(Icons.qr_code_scanner, 'Camera QR Scanner', () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const QRScannerScreen()));
              }),

              _buildDrawerTile(Icons.history_edu, 'System Audit Trail', () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AuditLogsScreen()));
              }),
            ],

            const Divider(color: Colors.white12),

            // Logout / Switch Role
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
