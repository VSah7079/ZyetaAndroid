import 'package:flutter/material.dart';
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
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
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

  void _openManualAttendanceModal() {
    final empCodeCtrl = TextEditingController();
    final remarksCtrl = TextEditingController(text: 'Manual security override');
    String status = 'Present';
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                  const Text('Mark Manual Attendance', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: empCodeCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Employee ID (e.g., EMP-101) *',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.badge, color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
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
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    items: const [
                      DropdownMenuItem(value: 'Present', child: Text('✅ Present')),
                      DropdownMenuItem(value: 'Late', child: Text('⏱️ Late')),
                      DropdownMenuItem(value: 'Half Day', child: Text('🌓 Half Day')),
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
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Remarks / Reason',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.notes, color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                              const SnackBar(content: Text('Attendance recorded!'), backgroundColor: Colors.green),
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
                      : const Text('SUBMIT ATTENDANCE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Text('Attendance & Muster Roll', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF10B981),
        icon: const Icon(Icons.check, color: Colors.white),
        label: const Text('Manual Attendance', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        onPressed: _openManualAttendanceModal,
      ),
      body: Column(
        children: [
          // KPI Metric Header
          Container(
            padding: const EdgeInsets.all(14),
            color: const Color(0xFF0F172A),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildKpiCard('PRESENT', '${_summary?['present'] ?? 0}', const Color(0xFF10B981)),
                    const SizedBox(width: 8),
                    _buildKpiCard('LATE', '${_summary?['late'] ?? 0}', const Color(0xFFF59E0B)),
                    const SizedBox(width: 8),
                    _buildKpiCard('TOTAL', '${_summary?['total_active_workforce'] ?? 0}', const Color(0xFF6366F1)),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search muster roll by name, code...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white54),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _search = '');
                              _loadData();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                  onSubmitted: (val) {
                    setState(() => _search = val.trim());
                    _loadData();
                  },
                ),
              ],
            ),
          ),

          // Attendance List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
                : _attendanceList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 50, color: Colors.white24),
                            const SizedBox(height: 10),
                            const Text('No attendance records found', style: TextStyle(color: Colors.white54)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => _loadData(),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(14),
                          itemCount: _attendanceList.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, idx) {
                            final a = _attendanceList[idx];
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
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: badgeColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      isPresent ? Icons.check_circle : Icons.schedule,
                                      color: badgeColor,
                                      size: 24,
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
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: badgeColor.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(6),
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
                                          '${a['employee_code']} • ${a['vendor_name'] ?? 'Direct'}',
                                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              'In: ${a['in_time'] != null ? a['in_time'].toString().split('T').last.substring(0, 5) : '--:--'}',
                                              style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'Out: ${a['out_time'] != null ? a['out_time'].toString().split('T').last.substring(0, 5) : '--:--'}',
                                              style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                            ),
                                            const Spacer(),
                                            Text(
                                              a['date'] ?? '',
                                              style: const TextStyle(color: Colors.white38, fontSize: 11),
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

  Widget _buildKpiCard(String label, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(count, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
