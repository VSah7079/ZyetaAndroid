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
  String _selectedModule = 'ALL';
  String _search = '';
  final TextEditingController _searchController = TextEditingController();

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

  List<dynamic> get _filteredLogs {
    return _logs.where((log) {
      final module = (log['module'] ?? '').toString().toLowerCase();
      if (_selectedModule == 'GATE' && !module.contains('gate') && !module.contains('entry') && !module.contains('terminal')) return false;
      if (_selectedModule == 'WORKFORCE' && !module.contains('worker') && !module.contains('emp') && !module.contains('attendance')) return false;
      if (_selectedModule == 'PERMITS' && !module.contains('permit') && !module.contains('ptw') && !module.contains('safety')) return false;
      if (_selectedModule == 'USERS' && !module.contains('user') && !module.contains('security') && !module.contains('admin')) return false;

      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        final details = (log['details'] ?? '').toString().toLowerCase();
        final user = (log['user_name'] ?? '').toString().toLowerCase();
        final action = (log['action_type'] ?? '').toString().toLowerCase();
        if (!details.contains(q) && !user.contains(q) && !action.contains(q) && !module.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredLogs;

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
      body: Column(
        children: [
          // Filter & Search bar
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF0F172A),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search audit records by user, action, module, details...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 18),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white54, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _search = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                  onChanged: (val) => setState(() => _search = val.trim()),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildModuleChip('ALL', 'All Events (${_logs.length})'),
                      const SizedBox(width: 6),
                      _buildModuleChip('GATE', 'Gate Access'),
                      const SizedBox(width: 6),
                      _buildModuleChip('WORKFORCE', 'Workforce'),
                      const SizedBox(width: 6),
                      _buildModuleChip('PERMITS', 'PTW Safety'),
                      const SizedBox(width: 6),
                      _buildModuleChip('USERS', 'User Admin'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Log List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                : filtered.isEmpty
                    ? const Center(child: Text('No audit logs matching query', style: TextStyle(color: Colors.white54)))
                    : RefreshIndicator(
                        onRefresh: () async => _fetchLogs(),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(14),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, idx) {
                            final log = filtered[idx];
                            final actionType = (log['action_type'] ?? 'INFO').toString();

                            Color actionColor = actionType.contains('CREATE') || actionType.contains('ENTRY')
                                ? Colors.greenAccent
                                : actionType.contains('UPDATE') || actionType.contains('APPROVE')
                                    ? const Color(0xFF06B6D4)
                                    : actionType.contains('DENY') || actionType.contains('DELETE')
                                        ? Colors.redAccent
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
          ),
        ],
      ),
    );
  }

  Widget _buildModuleChip(String key, String label) {
    final isSelected = _selectedModule == key;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.white70, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      selectedColor: const Color(0xFF6366F1),
      backgroundColor: const Color(0xFF1E293B),
      side: BorderSide(color: isSelected ? const Color(0xFF6366F1) : Colors.white12),
      onSelected: (_) => setState(() => _selectedModule = key),
    );
  }
}
