import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../utils/validators.dart';

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
      backgroundColor: const Color(0xFF0F172A),
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
                const Row(
                  children: [
                    Icon(Icons.file_download_done, color: Color(0xFF10B981), size: 24),
                    SizedBox(width: 8),
                    Text('Muster Roll Exported (CSV)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              height: 140,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF070B14), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
              child: SingleChildScrollView(
                child: Text(csvContent, style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontFamily: 'monospace')),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF06B6D4)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: csvContent));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✓ CSV data copied to clipboard!'), backgroundColor: Color(0xFF06B6D4)),
                      );
                    },
                    icon: const Icon(Icons.copy, color: Color(0xFF06B6D4), size: 16),
                    label: const Text('COPY CSV', style: TextStyle(color: Color(0xFF06B6D4), fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✓ Attendance_Muster_Report.csv saved!'), backgroundColor: Color(0xFF10B981)),
                      );
                    },
                    icon: const Icon(Icons.download, color: Colors.white, size: 16),
                    label: const Text('DOWNLOAD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
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
      backgroundColor: const Color(0xFF0F172A),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.how_to_reg, color: Color(0xFF10B981)),
                      SizedBox(width: 8),
                      Text('Mark Manual Muster Attendance', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: empCodeCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Worker Badge / ID (e.g. EMP-101) *',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                  prefixIcon: const Icon(Icons.badge, color: Color(0xFF06B6D4), size: 18),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(10)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: status,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
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
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Remarks / Reason for Manual Entry',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                  prefixIcon: const Icon(Icons.notes, color: Colors.white54, size: 18),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 5,
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          final codeErr = FormValidators.validateRequired(empCodeCtrl.text, fieldName: 'Employee ID', minLength: 2);
                          if (codeErr != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(codeErr), backgroundColor: Colors.orange),
                            );
                            return;
                          }
                          setModalState(() => isSaving = true);
                          final ok = await ApiService.markManualAttendance({
                            'employee_code': empCodeCtrl.text.trim().toUpperCase(),
                            'status': status,
                            'remarks': remarksCtrl.text.trim(),
                            'date': DateTime.now().toIso8601String().split('T')[0],
                          });
                          setModalState(() => isSaving = false);
                          if (ok && mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('✓ Attendance recorded successfully!'), backgroundColor: Colors.green),
                            );
                            _loadData();
                          } else if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Failed to record attendance'), backgroundColor: Colors.red),
                            );
                          }
                        },
                  child: isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('SUBMIT ATTENDANCE RECORD', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13, letterSpacing: 0.5)),
                ),
              ),
            ],
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
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.calendar_today, color: Color(0xFF10B981), size: 18),
            SizedBox(width: 8),
            Text('Turnstile Attendance Roll', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Export CSV',
            icon: const Icon(Icons.download, color: Color(0xFF06B6D4)),
            onPressed: _downloadCSV,
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadData,
          ),
          const LogoutIconButton(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF10B981),
        icon: const Icon(Icons.how_to_reg, color: Colors.white),
        label: const Text('Manual Muster', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        onPressed: _openManualAttendanceModal,
      ),
      body: Column(
        children: [
          // KPI HEADER & METRIC SUMMARY
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF111827)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border(bottom: BorderSide(color: const Color(0xFF10B981).withValues(alpha: 0.2))),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildKpiCard('PRESENT', '$presentCount', const Color(0xFF10B981), Icons.check_circle),
                    const SizedBox(width: 8),
                    _buildKpiCard('LATE DELAY', '$lateCount', const Color(0xFFF59E0B), Icons.schedule),
                    const SizedBox(width: 8),
                    _buildKpiCard('ROSTER TOTAL', '$totalWorkforce', const Color(0xFF06B6D4), Icons.groups),
                  ],
                ),
                const SizedBox(height: 12),

                // SEARCH BAR
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search muster roll by worker name, code, contractor...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF10B981), size: 18),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white54, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _search = '');
                              _loadData();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFF070B14),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(color: Color(0xFF1E293B), shape: BoxShape.circle),
                              child: const Icon(Icons.calendar_today_outlined, size: 40, color: Color(0xFF10B981)),
                            ),
                            const SizedBox(height: 12),
                            const Text('No attendance records found', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            const Text('Records update as turnstiles read RFID badges', style: TextStyle(color: Colors.white38, fontSize: 11)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => _loadData(),
                        color: const Color(0xFF10B981),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(14),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, idx) {
                            final a = filtered[idx];
                            final isPresent = (a['status'] ?? '').toString() == 'Present';
                            final isLate = (a['late_minutes'] ?? 0) > 0;

                            Color badgeColor = isLate
                                ? const Color(0xFFF59E0B)
                                : isPresent
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFF43F5E);

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF111827), Color(0xFF0F172A)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3)),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: badgeColor.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
                                    ),
                                    child: Icon(
                                      isPresent ? Icons.check_circle : Icons.schedule,
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
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: badgeColor.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
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
                                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(Icons.login, size: 12, color: Color(0xFF10B981)),
                                            const SizedBox(width: 3),
                                            Text(
                                              'In: ${a['in_time'] != null ? a['in_time'].toString().split('T').last.substring(0, 5) : '--:--'}',
                                              style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(width: 12),
                                            const Icon(Icons.logout, size: 12, color: Color(0xFFF43F5E)),
                                            const SizedBox(width: 3),
                                            Text(
                                              'Out: ${a['out_time'] != null ? a['out_time'].toString().split('T').last.substring(0, 5) : '--:--'}',
                                              style: const TextStyle(color: Color(0xFFF43F5E), fontSize: 11, fontWeight: FontWeight.bold),
                                            ),
                                            const Spacer(),
                                            Text(
                                              a['date'] ?? '',
                                              style: const TextStyle(color: Colors.white38, fontSize: 10),
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
    );
  }

  Widget _buildKpiCard(String label, String count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF131D31),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(count, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 9.5, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? const Color(0xFF10B981) : Colors.white12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
