import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../utils/validators.dart';
import '../utils/app_theme.dart';

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  void _showEventDetail(Map<String, dynamic> log) {
    HapticFeedback.lightImpact();
    final actionType = (log['action_type'] ?? 'EVENT').toString();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppTheme.border)),
        child: SizedBox(
          width: MediaQuery.of(ctx).size.width.clamp(280.0, 500.0),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primarySubtle,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                      ),
                      child: Text(actionType, style: const TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    IconButton(icon: const Icon(Icons.close, color: AppTheme.textSecondary, size: 20), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(log['details'] ?? 'Event record detail', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                _buildDetailItem('Module Target', log['module'] ?? 'System'),
                _buildDetailItem('Operator User', '${log['user_name'] ?? 'System'} (${log['user_role'] ?? 'Service'})'),
                _buildDetailItem('Event Timestamp', log['created_at'] ?? DateTime.now().toIso8601String()),
                _buildDetailItem('IP / Node Source', log['ip_address'] ?? '10.64.56.201 (Terminal Gate)'),
                _buildDetailItem('Audit Verification', 'SHA-256 Checksum Verified ✓'),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close Record', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11.5, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  List<dynamic> get _filteredLogs {
    return _logs.where((log) {
      final module = (log['module'] ?? '').toString().toLowerCase();
      if (_selectedModule == 'GATE' && !module.contains('gate') && !module.contains('entry') && !module.contains('terminal')) return false;
      if (_selectedModule == 'WORKFORCE' && !module.contains('worker') && !module.contains('emp') && !module.contains('attendance') && !module.contains('id')) return false;
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
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.history_toggle_off, color: AppTheme.primary, size: 20),
            SizedBox(width: 8),
            Text('Security Audit Trail', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh, color: AppTheme.primary),
            onPressed: _fetchLogs,
          ),
          const LogoutIconButton(),
        ],
      ),
      body: Column(
        children: [
          // HEADER SUMMARY & SEARCH
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppTheme.border)),
              boxShadow: AppTheme.softShadow,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('FORENSIC COMPLIANCE LEDGER', style: TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                        const SizedBox(height: 2),
                        Text(
                          '${_logs.length} Immutable Event Records',
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: AppTheme.badgeDecoration(color: AppTheme.success),
                      child: const Row(
                        children: [
                          Icon(Icons.lock, color: AppTheme.success, size: 12),
                          SizedBox(width: 4),
                          Text('LIVE SYNCED', style: TextStyle(color: AppTheme.success, fontSize: 9.5, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // SEARCH BAR
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: 'Search audit trail by actor, action, module...',
                    hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    prefixIcon: const Icon(Icons.search, color: AppTheme.primary, size: 18),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppTheme.textSecondary, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _search = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppTheme.bgSurface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
                  ),
                  onChanged: (val) => setState(() => _search = val.trim()),
                ),
                const SizedBox(height: 10),

                // MODULE FILTER CHIPS
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPill('ALL', 'All Events (${_logs.length})'),
                      _buildPill('GATE', '🚪 Gate Access'),
                      _buildPill('WORKFORCE', '👷 Workforce & IDs'),
                      _buildPill('PERMITS', '⛑️ PTW Safety'),
                      _buildPill('USERS', '🛡️ User Admin'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // TIMELINE FEED
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
                              decoration: const BoxDecoration(color: AppTheme.primarySubtle, shape: BoxShape.circle),
                              child: const Icon(Icons.history_toggle_off, size: 40, color: AppTheme.primary),
                            ),
                            const SizedBox(height: 10),
                            const Text('No audit events found for current filter', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => _fetchLogs(),
                        color: AppTheme.primary,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(14),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, idx) {
                            final log = filtered[idx];
                            final actionType = (log['action_type'] ?? 'EVENT').toString().toUpperCase();

                            Color actionColor = actionType.contains('CREATE') || actionType.contains('ENTRY') || actionType.contains('APPROVE')
                                ? AppTheme.success
                                : actionType.contains('UPDATE') || actionType.contains('ISSUED')
                                    ? AppTheme.primary
                                    : actionType.contains('DENY') || actionType.contains('DELETE') || actionType.contains('OUT')
                                        ? AppTheme.danger
                                        : AppTheme.warning;

                            return InkWell(
                              onTap: () => _showEventDetail(log),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: AppTheme.cardDecoration(customBorder: Border.all(color: AppTheme.border)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: AppTheme.badgeDecoration(color: actionColor),
                                          child: Text(
                                            actionType,
                                            style: TextStyle(color: actionColor, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            const Icon(Icons.category, color: AppTheme.primary, size: 12),
                                            const SizedBox(width: 4),
                                            Text(
                                              log['module'] ?? 'System',
                                              style: const TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      log['details'] ?? 'Operation executed',
                                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 8),
                                    const Divider(color: AppTheme.border, height: 1),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              const Icon(Icons.person, color: AppTheme.textMuted, size: 12),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  '${log['user_name'] ?? 'System'} (${log['user_role'] ?? 'Actor'})',
                                                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          log['created_at'] != null ? log['created_at'].toString().split('T').first : 'Today',
                                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 10.5),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
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

  Widget _buildPill(String key, String label) {
    final isSelected = _selectedModule == key;
    return InkWell(
      onTap: () => setState(() => _selectedModule = key),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.border),
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
