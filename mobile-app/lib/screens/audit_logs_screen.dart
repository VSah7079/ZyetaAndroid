import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  List<dynamic> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  void _fetchLogs() async {
    setState(() => _isLoading = true);
    final list = await ApiService.getAuditLogs();
    if (mounted) {
      setState(() {
        _logs = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Text('System Audit Trail', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _fetchLogs,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : _logs.isEmpty
              ? const Center(child: Text('No audit logs available', style: TextStyle(color: Colors.white54)))
              : RefreshIndicator(
                  onRefresh: () async => _fetchLogs(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(14),
                    itemCount: _logs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, idx) {
                      final log = _logs[idx];
                      final actionType = (log['action_type'] ?? 'INFO').toString();

                      Color actionColor = actionType == 'CREATE'
                          ? Colors.greenAccent
                          : actionType == 'UPDATE'
                              ? const Color(0xFF06B6D4)
                              : const Color(0xFFF59E0B);

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: actionColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: actionColor.withValues(alpha: 0.4)),
                                  ),
                                  child: Text(
                                    actionType,
                                    style: TextStyle(color: actionColor, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Text(
                                  log['module'] ?? 'System',
                                  style: const TextStyle(color: Color(0xFF6366F1), fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              log['details'] ?? '',
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'By: ${log['user_name'] ?? 'System'} (${log['user_role'] ?? ''})',
                                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                                ),
                                Text(
                                  log['created_at'] != null ? log['created_at'].toString().split('T').first : '',
                                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
