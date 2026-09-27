import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedReport = 'employee_master';
  Map<String, dynamic>? _reportData;
  bool _isLoading = true;

  final Map<String, String> _reportTypes = {
    'employee_master': '👷 Workforce Master Report',
    'gate_transactions': '🛡️ Gate Movement Audit Report',
    'attendance_report': '⏱️ Daily Attendance Report',
    'document_expiry': '⚠️ Compliance Expiry Report',
    'material_movement': '📦 Material DC Passes Report',
  };

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  void _fetchReport() async {
    setState(() => _isLoading = true);
    final res = await ApiService.getReportData(_selectedReport);
    if (mounted) {
      setState(() {
        _reportData = res;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = (_reportData?['data'] as List<dynamic>?) ?? [];
    final title = _reportData?['title'] ?? 'System Report';
    final total = _reportData?['total_records'] ?? list.length;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Text('Reports & Compliance Analytics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _fetchReport,
          ),
        ],
      ),
      body: Column(
        children: [
          // Report Selector
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF0F172A),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.4)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedReport,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  items: _reportTypes.entries.map((e) {
                    return DropdownMenuItem(value: e.key, child: Text(e.value));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedReport = val);
                      _fetchReport();
                    }
                  },
                ),
              ),
            ),
          ),

          // Total Records Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF1E293B),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('$total Records', style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ],
            ),
          ),

          // Data list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                : list.isEmpty
                    ? const Center(child: Text('No records found in this report', style: TextStyle(color: Colors.white54)))
                    : ListView.separated(
                        padding: const EdgeInsets.all(14),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, idx) {
                          final item = list[idx] as Map<String, dynamic>;
                          final keys = item.keys.toList();

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: keys.map((k) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        k.replaceAll('_', ' '),
                                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                                      ),
                                      Flexible(
                                        child: Text(
                                          '${item[k] ?? 'N/A'}',
                                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
