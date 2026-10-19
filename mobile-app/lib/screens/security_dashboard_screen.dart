import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../utils/validators.dart';
import '../utils/app_theme.dart';
import '../utils/responsive.dart';
import 'qr_scanner_screen.dart';
import 'visitor_screen.dart';
import 'material_screen.dart';
import 'vehicle_screen.dart';
import 'permit_screen.dart';
import 'inside_headcount_screen.dart';
import 'emergency_muster_screen.dart';
import 'attendance_screen.dart';
import 'reports_screen.dart';

class SecurityDashboardScreen extends StatefulWidget {
  const SecurityDashboardScreen({super.key});

  @override
  State<SecurityDashboardScreen> createState() => _SecurityDashboardScreenState();
}

class _SecurityDashboardScreenState extends State<SecurityDashboardScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String _selectedVendorId = 'ALL';
  List<dynamic> _vendors = [];
  final String _selectedGate = 'Main Gate 1 (Terminal Alpha)';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _loadStats('ALL');
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _loadStats([String? vendorId]) async {
    final targetVendor = vendorId ?? _selectedVendorId;
    final stats = await ApiService.getDashboardStats(vendorId: targetVendor);
    if (mounted) {
      setState(() {
        _stats = stats;
        _vendors = (stats?['vendors'] as List<dynamic>?) ?? [];
        _selectedVendorId = targetVendor;
        _isLoading = false;
      });
    }
  }

  void _onVendorChanged(String? newVendorId) {
    if (newVendorId == null || newVendorId == _selectedVendorId) return;
    HapticFeedback.selectionClick();
    setState(() {
      _isLoading = true;
      _selectedVendorId = newVendorId;
    });
    _loadStats(newVendorId);
  }

  void _showEmergencyLockdownDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: AppTheme.danger, size: 28),
            SizedBox(width: 8),
            Text(
              'EMERGENCY LOCKDOWN',
              style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: const Text(
          'Initiate site-wide emergency gate lockdown and trigger evacuation muster protocol across all terminals?',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ApiService.triggerEmergencyEvacuation('Site Security Lockdown Triggered');
              if (context.mounted) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyMusterScreen()));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('⚠️ Emergency Lockdown & Muster Call Broadcasted!'),
                    backgroundColor: AppTheme.danger,
                  ),
                );
              }
            },
            child: const Text('TRIGGER LOCKDOWN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- 1. MODAL: MARK ATTENDANCE ---
  void _openMarkAttendanceModal() {
    final pendingWorkers = (_stats?['pending_workers'] as List<dynamic>?) ?? [];
    String selectedStatus = 'Present';
    String notes = 'Gate Security manual mark';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: AppTheme.badgeDecoration(
                          background: AppTheme.primarySubtle,
                          borderColor: AppTheme.primaryLight,
                          radius: 10,
                        ),
                        child: const Icon(Icons.how_to_reg, color: AppTheme.primary, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mark Gate Attendance',
                            style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _selectedVendorId == 'ALL' ? 'All Active Pending Workers' : 'Pending for Selected Vendor',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (pendingWorkers.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.cardDecoration(
                    color: AppTheme.successBg,
                    customBorder: Border.all(color: AppTheme.successBorder),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.check_circle_outline, color: AppTheme.success, size: 40),
                      SizedBox(height: 8),
                      Text(
                        '100% Attendance Complete!',
                        style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'All active workers for this vendor have already marked attendance.',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else ...[
                const Text(
                  'SELECT PENDING WORKER TO MARK:',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 0.5),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: pendingWorkers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final worker = pendingWorkers[idx];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: AppTheme.cardDecoration(
                          customBorder: Border.all(color: AppTheme.border),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: AppTheme.primarySubtle,
                              backgroundImage: worker['profile_photo'] != null ? NetworkImage(worker['profile_photo']) : null,
                              child: worker['profile_photo'] == null
                                  ? Text(
                                      worker['full_name'] != null && worker['full_name'].toString().isNotEmpty
                                          ? worker['full_name'][0]
                                          : 'W',
                                      style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    worker['full_name'] ?? '',
                                    style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Text(
                                    '${worker['employee_id']} • ${worker['designation'] ?? 'Worker'}',
                                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                                  ),
                                  Text(
                                    '${worker['vendor_name'] ?? 'Contractor'}',
                                    style: const TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.success,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: () async {
                                Navigator.pop(ctx);
                                HapticFeedback.mediumImpact();
                                final todayStr = DateTime.now().toIso8601String().split('T')[0];
                                final success = await ApiService.markManualAttendance({
                                  'employee_id': worker['id'],
                                  'date': todayStr,
                                  'status': selectedStatus,
                                  'notes': notes,
                                });
                                if (success && mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('✓ Marked ${worker['full_name']} as $selectedStatus!'),
                                      backgroundColor: AppTheme.success,
                                    ),
                                  );
                                  _loadStats();
                                }
                              },
                              icon: const Icon(Icons.check, size: 14, color: Colors.white),
                              label: const Text('MARK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
    );
  }

  // --- 2. MODAL: REVERIFY ATTENDANCE ---
  void _openReverifyModal() {
    final presentWorkers = (_stats?['present_workers'] as List<dynamic>?) ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: AppTheme.badgeDecoration(
                          background: const Color(0xFFF3E8FF),
                          borderColor: const Color(0xFFE9D5FF),
                          radius: 10,
                        ),
                        child: const Icon(Icons.verified_user, color: Color(0xFF9333EA), size: 22),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Reverify Gate Attendance', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('Biometric / Physical Headcount Check', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Reverify All Action Bar
              if (presentWorkers.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: AppTheme.cardDecoration(
                    color: const Color(0xFFFAF5FF),
                    customBorder: Border.all(color: const Color(0xFFE9D5FF)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${presentWorkers.where((w) => w['is_reverified'] == true).length} of ${presentWorkers.length} Reverified',
                            style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          const Text('Gate double-check compliance', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9333EA),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          HapticFeedback.heavyImpact();
                          final ok = await ApiService.reverifyBulkAttendance(vendorId: _selectedVendorId);
                          if (ok && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✓ All present workers reverified successfully!'),
                                backgroundColor: Color(0xFF9333EA),
                              ),
                            );
                            _loadStats();
                          }
                        },
                        icon: const Icon(Icons.done_all, size: 16, color: Colors.white),
                        label: const Text('REVERIFY ALL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 14),

              if (presentWorkers.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.cardDecoration(color: AppTheme.bgSurface),
                  child: const Center(
                    child: Text('No workers marked present today to reverify.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ),
                )
              else ...[
                const Text(
                  'PRESENT WORKERS LIST:',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 0.5),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: presentWorkers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final worker = presentWorkers[idx];
                      final isReverified = worker['is_reverified'] == true;

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: AppTheme.cardDecoration(
                          customBorder: Border.all(
                            color: isReverified ? AppTheme.successBorder : AppTheme.warningBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: isReverified ? AppTheme.successBg : AppTheme.warningBg,
                              child: Icon(
                                isReverified ? Icons.check_circle : Icons.pending_outlined,
                                color: isReverified ? AppTheme.success : AppTheme.warning,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    worker['full_name'] ?? '',
                                    style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Text(
                                    '${worker['employee_id']} • ${worker['vendor_name'] ?? 'Contractor'}',
                                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                                  ),
                                  if (isReverified)
                                    const Text('✓ Reverified by Security', style: TextStyle(color: AppTheme.success, fontSize: 10, fontWeight: FontWeight.bold))
                                  else
                                    const Text('⚠️ Awaiting Physical Re-check', style: TextStyle(color: AppTheme.warning, fontSize: 10, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            if (!isReverified)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF9333EA),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  visualDensity: VisualDensity.compact,
                                ),
                                onPressed: () async {
                                  Navigator.pop(ctx);
                                  HapticFeedback.mediumImpact();
                                  final ok = await ApiService.reverifyAttendance(
                                    employeeId: worker['id'],
                                    notes: 'Gate physical verified',
                                  );
                                  if (ok && mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('✓ Reverified ${worker['full_name']}!'),
                                        backgroundColor: const Color(0xFF9333EA),
                                      ),
                                    );
                                    _loadStats();
                                  }
                                },
                                child: const Text('REVERIFY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: AppTheme.badgeDecoration(
                                  background: AppTheme.successBg,
                                  borderColor: AppTheme.successBorder,
                                  radius: 6,
                                ),
                                child: const Text('VERIFIED', style: TextStyle(color: AppTheme.success, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kpis = _stats?['kpis'];
    final recent = (_stats?['recent_activity'] as List<dynamic>?) ?? [];

    // The 7 Related Watch View Metrics
    final int todayManpower = (kpis?['today_manpower'] as num?)?.toInt() ?? 0;
    final int yesterdayManpower = (kpis?['yesterday_manpower'] as num?)?.toInt() ?? 0;
    final int todayEntries = (kpis?['today_entries'] as num?)?.toInt() ?? 0;
    final int completeAttendance = (kpis?['complete_attendance'] as num?)?.toInt() ?? 0;
    final int pendingAttendance = (kpis?['pending_attendance'] as num?)?.toInt() ?? 0;
    final int markedAttendance = (kpis?['marked_attendance'] as num?)?.toInt() ?? 0;
    final int reverifiedAttendance = (kpis?['reverified_attendance'] as num?)?.toInt() ?? 0;

    // Trend calculation vs Yesterday
    final int manpowerDiff = todayManpower - yesterdayManpower;
    final String trendText = manpowerDiff >= 0 ? '+$manpowerDiff vs Yesterday' : '$manpowerDiff vs Yesterday';
    final int attendancePercent = todayManpower > 0 ? ((completeAttendance / todayManpower) * 100).round() : 0;

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: const AppBarLeadingButton(),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shield_rounded, color: AppTheme.primary, size: 20),
                const SizedBox(width: 6),
                const Flexible(
                  child: Text(
                    'Gate Security Terminal',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              '${ApiService.currentUser?.fullName ?? 'Officer Active'} • $_selectedGate',
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Emergency Lockdown',
            icon: const Icon(Icons.emergency, color: AppTheme.danger),
            onPressed: _showEmergencyLockdownDialog,
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh, color: AppTheme.textSecondary),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadStats();
            },
          ),
          const LogoutIconButton(),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(
              color: AppTheme.primary,
              onRefresh: () async => _loadStats(),
              child: ResponsiveBody(
                padding: EdgeInsets.zero,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ==========================================
                      // 1. VENDOR DROPDOWN FILTER SECTION
                      // ==========================================
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: AppTheme.cardDecoration(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.domain_rounded, color: AppTheme.primary, size: 18),
                                const SizedBox(width: 8),
                                const Text(
                                  'VENDOR / CONTRACTOR FILTER',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary, letterSpacing: 0.5),
                                ),
                                const Spacer(),
                                if (_selectedVendorId != 'ALL')
                                  InkWell(
                                    onTap: () => _onVendorChanged('ALL'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: AppTheme.badgeDecoration(
                                        background: AppTheme.bgSurface,
                                        borderColor: AppTheme.border,
                                        radius: 6,
                                      ),
                                      child: const Text('Show All', style: TextStyle(color: AppTheme.textPrimary, fontSize: 10.5, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                dropdownColor: Colors.white,
                                value: _vendors.any((v) => v['id'].toString() == _selectedVendorId)
                                    ? _selectedVendorId
                                    : 'ALL',
                                icon: const Icon(Icons.arrow_drop_down_circle_outlined, color: AppTheme.primary, size: 20),
                                items: _vendors.map((v) {
                                  final isAll = v['id'] == 'ALL';
                                  final id = v['id'].toString();
                                  final name = v['company_name'] ?? 'Vendor';
                                  final workforce = v['workforce_count'] ?? 0;
                                  final present = v['present_count'] ?? 0;

                                  return DropdownMenuItem<String>(
                                    value: id,
                                    child: Row(
                                      children: [
                                        Icon(
                                          isAll ? Icons.all_inclusive : Icons.business,
                                          color: isAll ? AppTheme.success : AppTheme.primary,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            name,
                                            style: TextStyle(
                                              color: AppTheme.textPrimary,
                                              fontWeight: id == _selectedVendorId ? FontWeight.bold : FontWeight.normal,
                                              fontSize: 13,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: AppTheme.badgeDecoration(
                                            background: isAll ? AppTheme.successBg : AppTheme.primarySubtle,
                                            borderColor: isAll ? AppTheme.successBorder : AppTheme.primaryLight,
                                            radius: 6,
                                          ),
                                          child: Text(
                                            '$present/$workforce Present',
                                            style: TextStyle(
                                              color: isAll ? AppTheme.success : AppTheme.primary,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: _onVendorChanged,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // ==========================================
                      // 2. LIVE WATCH VIEW BANNER & TELEMETRY
                      // ==========================================
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              ScaleTransition(
                                scale: _pulseAnimation,
                                child: Container(
                                  width: 9,
                                  height: 9,
                                  decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'SECURITY WATCH VIEW (LIVE SYNC)',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, letterSpacing: 0.5),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: AppTheme.badgeDecoration(
                              background: AppTheme.successBg,
                              borderColor: AppTheme.successBorder,
                              radius: 8,
                            ),
                            child: const Text('MATCHED REAL DATA', style: TextStyle(color: AppTheme.success, fontSize: 9.5, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ==========================================
                      // 3. THE 7 INTERRELATED WATCH VIEW CARDS
                      // ==========================================

                      // Row 1: Today Manpower & Yesterday Manpower
                      Row(
                        children: [
                          Expanded(
                            child: _buildWatchCard(
                              title: 'TODAY MANPOWER',
                              value: '$todayManpower',
                              unit: 'Active Workers',
                              subBadge: trendText,
                              badgeColor: AppTheme.primary,
                              icon: Icons.groups_rounded,
                              accentColor: AppTheme.primary,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InsideHeadcountScreen())).then((_) => _loadStats()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildWatchCard(
                              title: 'YESTERDAY MANPOWER',
                              value: '$yesterdayManpower',
                              unit: 'Previous Present',
                              subBadge: 'Day Baseline',
                              badgeColor: AppTheme.textSecondary,
                              icon: Icons.history_rounded,
                              accentColor: AppTheme.textSecondary,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen())),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Row 2: Total Entry Today & Complete Attendance
                      Row(
                        children: [
                          Expanded(
                            child: _buildWatchCard(
                              title: 'TOTAL ENTRY TODAY',
                              value: '$todayEntries',
                              unit: 'Gate Turnstile In',
                              subBadge: '${kpis?['today_exits'] ?? 0} Exited',
                              badgeColor: const Color(0xFF0284C7),
                              icon: Icons.login_rounded,
                              accentColor: const Color(0xFF0284C7),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceScreen())).then((_) => _loadStats()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildWatchCard(
                              title: 'COMPLETE ATTENDANCE',
                              value: '$completeAttendance',
                              unit: 'Marked Present',
                              subBadge: '$attendancePercent% Checked In',
                              badgeColor: AppTheme.success,
                              icon: Icons.check_circle_rounded,
                              accentColor: AppTheme.success,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceScreen())).then((_) => _loadStats()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Row 3: Pending Attendance (Full Width / Prominent Card)
                      _buildWatchCard(
                        title: 'PENDING ATTENDANCE',
                        value: '$pendingAttendance',
                        unit: pendingAttendance == 0 ? 'All workers reported' : 'Workers awaiting gate entry',
                        subBadge: pendingAttendance == 0 ? '✓ COMPLETE' : 'NEED ACTION',
                        badgeColor: pendingAttendance == 0 ? AppTheme.success : AppTheme.warning,
                        icon: Icons.hourglass_top_rounded,
                        accentColor: pendingAttendance == 0 ? AppTheme.success : AppTheme.warning,
                        trailingButtonLabel: pendingAttendance > 0 ? 'MARK WORKER' : null,
                        onTrailingButton: _openMarkAttendanceModal,
                        onTap: _openMarkAttendanceModal,
                      ),
                      const SizedBox(height: 12),

                      // Row 4: Mark Attendance Action Card & Reverify Attendance Action Card
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionWatchCard(
                              title: 'MARK ATTENDANCE',
                              counter: '$markedAttendance / $todayManpower',
                              buttonLabel: 'MARK NOW',
                              icon: Icons.edit_calendar_rounded,
                              color: AppTheme.primary,
                              onTap: _openMarkAttendanceModal,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildActionWatchCard(
                              title: 'REVERIFY ATTENDANCE',
                              counter: '$reverifiedAttendance / $completeAttendance',
                              buttonLabel: 'REVERIFY',
                              icon: Icons.verified_user_rounded,
                              color: const Color(0xFF9333EA),
                              onTap: _openReverifyModal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ==========================================
                      // 4. PRIMARY GATE OPERATIONS (SPEED WORKFLOWS)
                      // ==========================================
                      const Text(
                        'PRIMARY GATE OPERATIONS (SPEED WORKFLOWS)',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 12),

                      // Big Scan QR Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const QRScannerScreen()),
                            ).then((_) => _loadStats());
                          },
                          icon: const Icon(Icons.qr_code_scanner_rounded, size: 24, color: Colors.white),
                          label: const Text(
                            'SCAN QR CODE TERMINAL',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 6 Fast Action Cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionCard(
                              title: 'Manual Entry',
                              icon: Icons.search_rounded,
                              color: const Color(0xFF0284C7),
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
                              icon: Icons.person_add_alt_1_rounded,
                              color: AppTheme.success,
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
                              icon: Icons.inventory_2_rounded,
                              color: AppTheme.warning,
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
                              icon: Icons.local_shipping_rounded,
                              color: const Color(0xFF9333EA),
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
                              icon: Icons.assignment_turned_in_rounded,
                              color: AppTheme.primary,
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
                              icon: Icons.emergency_rounded,
                              color: AppTheme.danger,
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

                      // ==========================================
                      // 5. RECENT GATE ACTIVITY (REAL-TIME MOVEMENTS)
                      // ==========================================
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'RECENT GATE MOVEMENTS',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 0.5),
                          ),
                          InkWell(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const InsideHeadcountScreen()));
                            },
                            child: const Text('View Muster >', style: TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      if (recent.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: AppTheme.cardDecoration(),
                          child: const Center(
                            child: Text('No gate movements logged yet today for this selection.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                          ),
                        )
                      else
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
                              decoration: AppTheme.cardDecoration(
                                customBorder: Border.all(color: AppTheme.border),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: AppTheme.badgeDecoration(
                                      background: isEntry ? AppTheme.successBg : AppTheme.dangerBg,
                                      borderColor: isEntry ? AppTheme.successBorder : AppTheme.dangerBorder,
                                      radius: 10,
                                    ),
                                    child: Icon(
                                      isEntry ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                      color: isEntry ? AppTheme.success : AppTheme.danger,
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
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontSize: 13),
                                        ),
                                        Text(
                                          '${tx['entity_code']} • ${tx['vendor_name'] ?? 'Direct'} • ${tx['gate_name'] ?? 'Gate 1'}',
                                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: AppTheme.badgeDecoration(
                                          background: isEntry ? AppTheme.successBg : AppTheme.dangerBg,
                                          borderColor: isEntry ? AppTheme.successBorder : AppTheme.dangerBorder,
                                          radius: 6,
                                        ),
                                        child: Text(
                                          tx['movement_type'] ?? '',
                                          style: TextStyle(
                                            color: isEntry ? AppTheme.success : AppTheme.danger,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        tx['timestamp'] != null ? tx['timestamp'].toString().split('T').last.substring(0, 5) : '08:45',
                                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
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
            ),
    );
  }

  // --- WATCH VIEW CARD WIDGET BUILDER ---
  Widget _buildWatchCard({
    required String title,
    required String value,
    required String unit,
    required String subBadge,
    required Color badgeColor,
    required IconData icon,
    required Color accentColor,
    String? trailingButtonLabel,
    VoidCallback? onTrailingButton,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: AppTheme.cardDecoration(
          customBorder: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: AppTheme.badgeDecoration(
                          background: accentColor.withValues(alpha: 0.1),
                          borderColor: accentColor.withValues(alpha: 0.25),
                          radius: 8,
                        ),
                        child: Icon(icon, color: accentColor, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 0.4),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: AppTheme.badgeDecoration(
                    background: badgeColor.withValues(alpha: 0.1),
                    borderColor: badgeColor.withValues(alpha: 0.25),
                    radius: 6,
                  ),
                  child: Text(subBadge, style: TextStyle(color: badgeColor, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: accentColor, height: 1.0)),
                      ),
                      const SizedBox(height: 4),
                      Text(unit, style: const TextStyle(fontSize: 10.5, color: AppTheme.textSecondary), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                if (trailingButtonLabel != null) ...[
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: onTrailingButton,
                    child: Text(trailingButtonLabel, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- ACTION WATCH CARD (MARK ATTENDANCE & REVERIFY ATTENDANCE) ---
  Widget _buildActionWatchCard({
    required String title,
    required String counter,
    required String buttonLabel,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: AppTheme.cardDecoration(
          customBorder: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: AppTheme.badgeDecoration(
                    background: color.withValues(alpha: 0.1),
                    borderColor: color.withValues(alpha: 0.25),
                    radius: 8,
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, letterSpacing: 0.4),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(counter, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 32,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: onTap,
                child: Text(buttonLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
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
        decoration: AppTheme.cardDecoration(
          customBorder: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: AppTheme.badgeDecoration(
                background: color.withValues(alpha: 0.1),
                borderColor: color.withValues(alpha: 0.2),
                radius: 8,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
