import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'qr_scanner_screen.dart';
import 'visitor_screen.dart';
import 'material_screen.dart';
import 'vehicle_screen.dart';
import 'permit_screen.dart';
import 'inside_headcount_screen.dart';
import 'emergency_muster_screen.dart';
import 'attendance_screen.dart';
import 'reports_screen.dart';
import 'login_screen.dart';

class SecurityDashboardScreen extends StatefulWidget {
  const SecurityDashboardScreen({super.key});

  @override
  State<SecurityDashboardScreen> createState() => _SecurityDashboardScreenState();
}

class _SecurityDashboardScreenState extends State<SecurityDashboardScreen> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  final String _selectedGate = 'Main Gate 1 (Terminal Alpha)';

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() async {
    final stats = await ApiService.getDashboardStats();
    if (mounted) {
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  void _showEmergencyLockdownDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.redAccent, size: 28),
            SizedBox(width: 8),
            Text('EMERGENCY LOCKDOWN', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: const Text(
          'Initiate site-wide emergency gate lockdown and trigger evacuation muster protocol across all terminals?',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF43F5E)),
            onPressed: () async {
              Navigator.pop(ctx);
              await ApiService.triggerEmergencyEvacuation('Site Security Lockdown Triggered');
              if (context.mounted) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyMusterScreen()));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('⚠️ Emergency Lockdown & Muster Call Broadcasted!'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('TRIGGER LOCKDOWN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kpis = _stats?['kpis'];
    final recent = (_stats?['recent_activity'] as List<dynamic>?) ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.shield, color: Color(0xFF10B981), size: 18),
                SizedBox(width: 6),
                Text('Gate Security Terminal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
            Text(
              '${ApiService.currentUser?.fullName ?? 'Officer Active'} • $_selectedGate',
              style: const TextStyle(fontSize: 11, color: Colors.white54),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Emergency Lockdown',
            icon: const Icon(Icons.emergency, color: Colors.redAccent),
            onPressed: _showEmergencyLockdownDialog,
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadStats();
            },
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout, color: Colors.white54),
            onPressed: () {
              ApiService.authToken = null;
              ApiService.currentUser = null;
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : RefreshIndicator(
              onRefresh: () async => _loadStats(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TOP METRICS BAR (Appendix A PRD Wireframe)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMetricItem(
                            'INSIDE',
                            '${kpis?['currently_inside'] ?? 42}',
                            const Color(0xFF10B981),
                            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InsideHeadcountScreen())).then((_) => _loadStats()),
                          ),
                          _buildDivider(),
                          _buildMetricItem(
                            'TODAY ENTRY',
                            '${kpis?['today_entries'] ?? 58}',
                            const Color(0xFF06B6D4),
                            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceScreen())).then((_) => _loadStats()),
                          ),
                          _buildDivider(),
                          _buildMetricItem(
                            'TODAY EXIT',
                            '${kpis?['today_exits'] ?? 16}',
                            const Color(0xFFF43F5E),
                            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceScreen())).then((_) => _loadStats()),
                          ),
                          _buildDivider(),
                          _buildMetricItem(
                            'ALERTS',
                            '${kpis?['expiring_compliance_docs'] ?? 2}',
                            const Color(0xFFF59E0B),
                            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen())),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // PRIMARY LARGE ACTION BUTTONS (Appendix A)
                    const Text(
                      'PRIMARY GATE OPERATIONS (SPEED WORKFLOWS)',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 12),

                    // Big Scan QR Button
                    SizedBox(
                      width: double.infinity,
                      height: 65,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const QRScannerScreen()),
                          ).then((_) => _loadStats());
                        },
                        icon: const Icon(Icons.qr_code_scanner, size: 28, color: Colors.white),
                        label: const Text(
                          'SCAN QR CODE TERMINAL',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Grid of 4 Fast Actions
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
                            title: 'Manual Entry',
                            icon: Icons.search,
                            color: const Color(0xFF06B6D4),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const QRScannerScreen(isManual: true)),
                              ).then((_) => _loadStats());
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildActionCard(
                            title: 'Visitor Pass',
                            icon: Icons.person_add,
                            color: const Color(0xFF10B981),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const VisitorScreen()),
                              ).then((_) => _loadStats());
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
                            title: 'Material DC',
                            icon: Icons.inventory_2,
                            color: const Color(0xFFF59E0B),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const MaterialScreen()),
                              ).then((_) => _loadStats());
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildActionCard(
                            title: 'Vehicle Check',
                            icon: Icons.local_shipping,
                            color: const Color(0xFFA855F7),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const VehicleScreen()),
                              ).then((_) => _loadStats());
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
                            title: 'PTW Gate Check',
                            icon: Icons.assignment_turned_in,
                            color: const Color(0xFF6366F1),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const PermitScreen()),
                              ).then((_) => _loadStats());
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildActionCard(
                            title: 'Emergency Muster',
                            icon: Icons.emergency,
                            color: const Color(0xFFE11D48),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const EmergencyMusterScreen()),
                              ).then((_) => _loadStats());
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // RECENT GATE ACTIVITY (Appendix A)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'RECENT GATE MOVEMENTS',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 0.5),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const InsideHeadcountScreen()));
                          },
                          child: const Text('View All Muster >', style: TextStyle(color: Color(0xFF06B6D4), fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: recent.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final tx = recent[idx];
                        final isEntry = tx['movement_type'] == 'ENTRY';

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: isEntry ? Colors.green.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  isEntry ? Icons.arrow_downward : Icons.arrow_upward,
                                  color: isEntry ? Colors.greenAccent : Colors.redAccent,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx['entity_name'] ?? '',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                                    ),
                                    Text(
                                      '${tx['entity_code']} • ${tx['vendor_name'] ?? 'Direct'} • ${tx['gate_name'] ?? 'Gate 1'}',
                                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isEntry ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      tx['movement_type'] ?? '',
                                      style: TextStyle(
                                        color: isEntry ? Colors.greenAccent : Colors.redAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    tx['timestamp'] != null ? tx['timestamp'].toString().split('T').last.substring(0, 5) : '08:45',
                                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                                  ),
                                ],
                              )
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color color, [VoidCallback? onTap]) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 9, color: Colors.white54, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 26, color: Colors.white12);
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Flexible(
              child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12), overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}
