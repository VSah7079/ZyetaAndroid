import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../utils/validators.dart';
import '../utils/app_theme.dart';
import '../utils/responsive.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<dynamic> _attendanceList = [];
  Map<String, dynamic>? _summary;
  bool _isLoading = true;
  String _search = '';
  String _statusFilter = 'ALL'; // 'ALL' | 'Present' | 'Late' | 'Absent'
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() async {
    setState(() => _isLoading = true);
    final summary = await ApiService.getAttendanceSummary();
    final list = await ApiService.getAttendance(
      search: _search.isNotEmpty ? _search : null,
    );
    if (mounted) {
      setState(() {
        _summary = summary;
        _attendanceList = list;
        _isLoading = false;
      });
    }
  }

  void _downloadCSV() async {
    HapticFeedback.mediumImpact();
    final csvContent = await ApiService.exportAttendanceCSVData(period: 'month');
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(22),
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
                        background: AppTheme.successBg,
                        borderColor: AppTheme.successBorder,
                        radius: 8,
                      ),
                      child: const Icon(Icons.file_download_done_rounded, color: AppTheme.success, size: 22),
                    ),
                    const SizedBox(width: 10),
                    const Text('Muster Roll Exported (CSV)', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 140,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.bgSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: SingleChildScrollView(
                child: Text(csvContent, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontFamily: 'monospace')),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.border),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: csvContent));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✓ CSV data copied to clipboard!'), backgroundColor: AppTheme.primary),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, color: AppTheme.textSecondary, size: 16),
                    label: const Text('COPY TEXT', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✓ Muster roll ready for external sync!'), backgroundColor: AppTheme.success),
                      );
                    },
                    icon: const Icon(Icons.download_rounded, color: Colors.white, size: 16),
                    label: const Text('DONE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openManualAttendanceModal() {
    final empCodeCtrl = TextEditingController();
    final remarksCtrl = TextEditingController(text: 'Manual supervisor muster override');
    String status = 'Present';
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: AppTheme.badgeDecoration(
                            background: AppTheme.primarySubtle,
                            borderColor: AppTheme.primaryLight,
                            radius: 8,
                          ),
                          child: const Icon(Icons.how_to_reg_rounded, color: AppTheme.primary, size: 22),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Mark Manual Muster Attendance',
                            style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: empCodeCtrl,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Worker Badge / ID (e.g. EMP-101) *',
                  hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  prefixIcon: const Icon(Icons.badge_rounded, color: AppTheme.textSecondary, size: 18),
                  filled: true,
                  fillColor: AppTheme.bgSurface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.bgSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: status,
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                    items: const [
                      DropdownMenuItem(value: 'Present', child: Text('✅ Present (Standard On-Time)')),
                      DropdownMenuItem(value: 'Late', child: Text('⏱️ Late (Turnstile Grace Delay)')),
                      DropdownMenuItem(value: 'Half Day', child: Text('🌓 Half Day (Shift Split)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => status = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: remarksCtrl,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Remarks / Reason for Manual Entry',
                  hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  prefixIcon: const Icon(Icons.notes_rounded, color: AppTheme.textSecondary, size: 18),
                  filled: true,
                  fillColor: AppTheme.bgSurface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          final codeErr = FormValidators.validateRequired(empCodeCtrl.text, fieldName: 'Employee ID', minLength: 2);
                          if (codeErr != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(codeErr), backgroundColor: AppTheme.warning),
                            );
                            return;
                          }
                          setModalState(() => isSaving = true);
                          final ok = await ApiService.markManualAttendance({
                            'employee_code': empCodeCtrl.text.trim().toUpperCase(),
                            'date': DateTime.now().toIso8601String().split('T')[0],
                            'status': status,
                            'notes': remarksCtrl.text.trim(),
                          });
                          if (mounted) {
                            Navigator.pop(ctx);
                            if (ok) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('✓ Attendance successfully recorded!'), backgroundColor: AppTheme.success),
                              );
                              _loadData();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Failed to record attendance'), backgroundColor: AppTheme.danger),
                              );
                            }
                          }
                        },
                  child: isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('SUBMIT ATTENDANCE RECORD', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13, letterSpacing: 0.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  List<dynamic> get _filteredAttendance {
    return _attendanceList.where((a) {
      if (_statusFilter != 'ALL') {
        final status = (a['status'] ?? '').toString();
        if (_statusFilter == 'Late' && (a['late_minutes'] ?? 0) <= 0 && status != 'Late') return false;
        if (_statusFilter == 'Present' && status != 'Present') return false;
        if (_statusFilter == 'Absent' && status != 'Absent') return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredAttendance;
    final presentCount = _summary?['present'] ?? 0;
    final lateCount = _summary?['late'] ?? 0;
    final totalWorkforce = _summary?['total_active_workforce'] ?? 0;

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: const AppBarLeadingButton(),
        title: const Row(
          children: [
            Icon(Icons.calendar_today_rounded, color: AppTheme.primary, size: 18),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Attendance Roll',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Export CSV',
            icon: const Icon(Icons.download_rounded, color: AppTheme.primary),
            onPressed: _downloadCSV,
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary),
            onPressed: _loadData,
          ),
          const LogoutIconButton(compact: true),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.how_to_reg_rounded, color: Colors.white),
        label: const Text('Manual Muster', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        onPressed: _openManualAttendanceModal,
      ),
      body: ResponsiveBody(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            // KPI HEADER & METRIC SUMMARY
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: AppTheme.cardDecoration(),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildKpiCard('PRESENT', '$presentCount', AppTheme.success, Icons.check_circle_rounded),
                      const SizedBox(width: 8),
                      _buildKpiCard('LATE DELAY', '$lateCount', AppTheme.warning, Icons.schedule_rounded),
                      const SizedBox(width: 8),
                      _buildKpiCard('ROSTER TOTAL', '$totalWorkforce', AppTheme.primary, Icons.groups_rounded),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // SEARCH BAR
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search muster roll by worker name, code, contractor...',
                      hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary, size: 18),
                      suffixIcon: _search.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, color: AppTheme.textSecondary, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _search = '');
                                _loadData();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppTheme.bgSurface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
                    ),
                    onSubmitted: (val) {
                      setState(() => _search = val.trim());
                      _loadData();
                    },
                  ),
                  const SizedBox(height: 10),

                  // QUICK FILTER PILLS
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterPill('ALL', 'All Records (${_attendanceList.length})'),
                        _buildFilterPill('Present', '✅ Present ($presentCount)'),
                        _buildFilterPill('Late', '⏱️ Late Delays ($lateCount)'),
                        _buildFilterPill('Absent', '❌ Absentees'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ATTENDANCE LIST
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                  : filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: AppTheme.bgSurface, shape: BoxShape.circle),
                                child: const Icon(Icons.calendar_today_outlined, size: 40, color: AppTheme.primary),
                              ),
                              const SizedBox(height: 12),
                              const Text('No attendance records found', style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              const Text('Records update as turnstiles read RFID badges', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async => _loadData(),
                          color: AppTheme.primary,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, idx) {
                              final a = filtered[idx];
                              final isPresent = (a['status'] ?? '').toString() == 'Present';
                              final isLate = (a['late_minutes'] ?? 0) > 0;

                              Color badgeColor = isLate
                                  ? AppTheme.warning
                                  : isPresent
                                      ? AppTheme.success
                                      : AppTheme.danger;

                              Color badgeBg = isLate
                                  ? AppTheme.warningBg
                                  : isPresent
                                      ? AppTheme.successBg
                                      : AppTheme.dangerBg;

                              Color badgeBorder = isLate
                                  ? AppTheme.warningBorder
                                  : isPresent
                                      ? AppTheme.successBorder
                                      : AppTheme.dangerBorder;

                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: AppTheme.cardDecoration(
                                  customBorder: Border.all(color: AppTheme.border),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: AppTheme.badgeDecoration(
                                        background: badgeBg,
                                        borderColor: badgeBorder,
                                        radius: 22,
                                      ),
                                      child: Icon(
                                        isPresent ? Icons.check_circle_rounded : Icons.schedule_rounded,
                                        color: badgeColor,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  a['employee_name'] ?? 'Worker',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: AppTheme.badgeDecoration(
                                                  background: badgeBg,
                                                  borderColor: badgeBorder,
                                                  radius: 6,
                                                ),
                                                child: Text(
                                                  isLate ? '⏱️ Late (${a['late_minutes']}m)' : a['status'] ?? 'Present',
                                                  style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '${a['employee_code']} • ${a['vendor_name'] ?? 'Zyeta Direct'}',
                                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              const Icon(Icons.login_rounded, size: 12, color: AppTheme.success),
                                              const SizedBox(width: 3),
                                              Text(
                                                'In: ${a['in_time'] != null ? a['in_time'].toString().split('T').last.substring(0, 5) : '--:--'}',
                                                style: const TextStyle(color: AppTheme.success, fontSize: 11, fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(width: 12),
                                              const Icon(Icons.logout_rounded, size: 12, color: AppTheme.danger),
                                              const SizedBox(width: 3),
                                              Text(
                                                'Out: ${a['out_time'] != null ? a['out_time'].toString().split('T').last.substring(0, 5) : '--:--'}',
                                                style: const TextStyle(color: AppTheme.danger, fontSize: 11, fontWeight: FontWeight.bold),
                                              ),
                                              const Spacer(),
                                              Text(
                                                a['date'] ?? '',
                                                style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(String label, String count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: AppTheme.cardDecoration(
          color: AppTheme.bgSurface,
          customBorder: Border.all(color: AppTheme.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: AppTheme.badgeDecoration(
                background: color.withValues(alpha: 0.1),
                borderColor: color.withValues(alpha: 0.2),
                radius: 6,
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(count, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9.5, fontWeight: FontWeight.bold, letterSpacing: 0.3),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill(String key, String label) {
    final isSelected = _statusFilter == key;
    return InkWell(
      onTap: () => setState(() => _statusFilter = key),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.border),
          boxShadow: isSelected ? AppTheme.softShadow : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
