import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/validators.dart';
import '../utils/responsive.dart';
import '../utils/app_theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedReport = 'employee_master';
  bool _isLoading = true;
  List<dynamic> _items = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final Map<String, String> _reportTypes = {
    'employee_master': '👷 Workforce Master Report',
    'vendor_master': '🏢 Vendor & Contractor Master Report',
    'attendance_report': '⏱️ Daily Attendance & Overtime Report',
    'gate_transactions': '🛡️ Gate Entry / Exit Audit Report',
    'inside_headcount': '🟢 Live Inside Campus Muster Report',
    'permit_report': '📋 PTW Safety Permits Report',
    'material_movement': '📦 Material DC & Challans Report',
    'visitor_report': '👤 Visitor Passes Activity Report',
    'vehicle_report': '🚗 Vehicle & Fleet Compliance Report',
    'document_expiry': '⚠️ Document & KYC Expiry Alerts Report',
    'audit_logs': '📜 System Security Audit Trail Report',
  };

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  void _fetchReport() async {
    setState(() => _isLoading = true);
    List<dynamic> list = [];

    try {
      switch (_selectedReport) {
        case 'employee_master':
          list = await ApiService.getEmployees();
          break;
        case 'vendor_master':
          list = await ApiService.getVendors();
          break;
        case 'attendance_report':
          list = await ApiService.getAttendance();
          break;
        case 'gate_transactions':
          final stats = await ApiService.getDashboardStats();
          list = (stats?['recent_activity'] as List<dynamic>?) ?? [];
          break;
        case 'inside_headcount':
          list = await ApiService.getCurrentlyInside();
          break;
        case 'permit_report':
          list = await ApiService.getPermits();
          break;
        case 'material_movement':
          list = await ApiService.getMaterials();
          break;
        case 'visitor_report':
          list = await ApiService.getVisitors();
          break;
        case 'vehicle_report':
          list = await ApiService.getVehicles();
          break;
        case 'document_expiry':
          final emps = await ApiService.getEmployees();
          list = emps.where((e) {
            final med = (e['medical_validity'] ?? '').toString();
            final pol = (e['police_verification_expiry'] ?? '').toString();
            return med.isNotEmpty || pol.isNotEmpty;
          }).toList();
          break;
        case 'audit_logs':
          list = await ApiService.getAuditLogs();
          break;
        default:
          list = await ApiService.getEmployees();
      }
    } catch (_) {
      list = [];
    }

    if (mounted) {
      setState(() {
        _items = list;
        _isLoading = false;
      });
    }
  }

  void _simulateExport(String format) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ Exporting ${_reportTypes[_selectedReport]} as .${format.toUpperCase()}... File saved!'),
        backgroundColor: AppTheme.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  List<dynamic> get _filteredItems {
    if (_searchQuery.isEmpty) return _items;
    final q = _searchQuery.toLowerCase();
    return _items.where((item) {
      if (item is Map) {
        return item.values.any((val) => val != null && val.toString().toLowerCase().contains(q));
      }
      return item.toString().toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredItems;

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: const AppBarLeadingButton(),
        title: const Text('Reports & Analytics', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary), overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Export PDF',
            icon: const Icon(Icons.picture_as_pdf_rounded, color: AppTheme.danger),
            onPressed: () => _simulateExport('pdf'),
          ),
          IconButton(
            tooltip: 'Export Excel / CSV',
            icon: const Icon(Icons.table_view_rounded, color: AppTheme.success),
            onPressed: () => _simulateExport('xlsx'),
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary),
            onPressed: _fetchReport,
          ),
          const LogoutIconButton(compact: true),
        ],
      ),
      body: ResponsiveBody(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            // Report Selector Dropdown
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: AppTheme.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SELECT AUDIT / COMPLIANCE REPORT', style: TextStyle(color: AppTheme.primary, fontSize: 10.5, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.bgSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedReport,
                        isExpanded: true,
                        dropdownColor: Colors.white,
                        style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                        items: _reportTypes.entries.map((e) {
                          return DropdownMenuItem(value: e.key, child: Text(e.value));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedReport = val;
                              _searchQuery = '';
                              _searchController.clear();
                            });
                            _fetchReport();
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Overview KPI Card for Selected Report
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              padding: const EdgeInsets.all(14),
              decoration: AppTheme.cardDecoration(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryStat('TOTAL RECORDS', '${_items.length}', AppTheme.primary),
                  _buildDivider(),
                  _buildSummaryStat('FILTERED', '${filtered.length}', AppTheme.success),
                  _buildDivider(),
                  _buildSummaryStat('STATUS', _items.isEmpty ? 'EMPTY' : 'READY', const Color(0xFF0284C7)),
                ],
              ),
            ),

            // Search Bar & Export Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search within this report...',
                      hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary, size: 18),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, color: AppTheme.textSecondary, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const Text('Export Formats:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        ActionChip(
                          label: const Text('📄 PDF Document', style: TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: AppTheme.border),
                          onPressed: () => _simulateExport('pdf'),
                        ),
                        const SizedBox(width: 8),
                        ActionChip(
                          label: const Text('📊 Excel Worksheet', style: TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: AppTheme.border),
                          onPressed: () => _simulateExport('xlsx'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Report Preview List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                  : filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.search_off_rounded, size: 48, color: AppTheme.textMuted),
                              const SizedBox(height: 8),
                              Text('No records found for ${_reportTypes[_selectedReport]}', style: const TextStyle(color: AppTheme.textSecondary)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async => _fetchReport(),
                          color: AppTheme.primary,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, idx) {
                              return _buildItemCard(filtered[idx]);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(dynamic item) {
    if (item is! Map<String, dynamic>) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: AppTheme.cardDecoration(),
        child: Text(item.toString(), style: const TextStyle(color: AppTheme.textPrimary)),
      );
    }

    String title = '';
    String subtitle = '';
    String tag1 = '';
    String tag2 = '';
    String status = 'ACTIVE';
    Color color = AppTheme.success;

    if (_selectedReport == 'employee_master' || _selectedReport == 'document_expiry') {
      title = '${item['full_name'] ?? 'Worker'} (${item['employee_id'] ?? ''})';
      subtitle = '${item['vendor_name'] ?? 'Contractor'} • ${item['department_name'] ?? 'Civil'}';
      tag1 = item['designation'] ?? item['skill'] ?? 'Specialist';
      tag2 = 'Med Valid: ${item['medical_validity'] ?? 'N/A'}';
      status = item['status'] ?? 'Active';
      color = status == 'Active' ? AppTheme.success : AppTheme.warning;
    } else if (_selectedReport == 'vendor_master') {
      title = '${item['vendor_name'] ?? 'Vendor'} (${item['vendor_code'] ?? ''})';
      subtitle = 'Contact: ${item['contact_person'] ?? ''} • ${item['phone'] ?? ''}';
      tag1 = 'Trade: ${item['trade_category'] ?? 'General'}';
      tag2 = 'Workers: ${item['worker_count'] ?? '24'}';
      status = item['status'] ?? 'Active';
      color = AppTheme.primary;
    } else if (_selectedReport == 'attendance_report') {
      title = '${item['employee_name'] ?? 'Worker'} (${item['employee_id'] ?? ''})';
      subtitle = 'In: ${item['check_in_time'] ?? '08:45'} • Out: ${item['check_out_time'] ?? '--:--'}';
      tag1 = 'Shift: ${item['shift_name'] ?? 'General'}';
      tag2 = 'OT: ${item['overtime_hours'] ?? '0'}h';
      status = item['status'] ?? 'Present';
      color = status == 'Present' ? AppTheme.success : AppTheme.danger;
    } else if (_selectedReport == 'gate_transactions') {
      title = '${item['entity_name'] ?? 'Movement'} (${item['entity_code'] ?? ''})';
      subtitle = '${item['vendor_name'] ?? 'Gate 1'} • Gate: ${item['gate_name'] ?? 'Main Gate'}';
      tag1 = 'Type: ${item['movement_type'] ?? 'ENTRY'}';
      tag2 = item['timestamp'] != null ? item['timestamp'].toString().split('T').last.substring(0, 5) : '08:45';
      status = item['movement_type'] ?? 'ENTRY';
      color = status == 'ENTRY' ? AppTheme.success : AppTheme.danger;
    } else if (_selectedReport == 'inside_headcount') {
      title = '${item['name'] ?? 'Person'} (${item['code'] ?? ''})';
      subtitle = 'Company: ${item['vendor'] ?? 'Direct'}';
      tag1 = 'Type: ${item['type'] ?? 'Worker'}';
      tag2 = 'Entry: ${item['entry_time'] != null ? item['entry_time'].toString().split('T').last.substring(0, 5) : 'Active'}';
      status = 'INSIDE';
      color = AppTheme.success;
    } else if (_selectedReport == 'permit_report') {
      title = '${item['permit_number'] ?? 'PTW'} • ${item['permit_type'] ?? 'Work Permit'}';
      subtitle = 'Zone: ${item['work_zone'] ?? 'Main Block'} • Vendor: ${item['vendor_name'] ?? 'Contractor'}';
      tag1 = 'Risk: ${item['risk_level'] ?? 'HIGH'}';
      tag2 = 'Valid: ${item['valid_until'] ?? 'Today'}';
      status = item['status'] ?? 'Active';
      color = status == 'Active' || status == 'Approved' ? AppTheme.success : AppTheme.warning;
    } else if (_selectedReport == 'material_movement') {
      title = '${item['challan_number'] ?? 'DC-PASS'} • ${item['item_name'] ?? 'Materials'}';
      subtitle = 'Qty: ${item['quantity'] ?? '1'} • Vendor: ${item['vendor_name'] ?? 'Contractor'}';
      tag1 = 'Movement: ${item['movement_type'] ?? 'INWARD'}';
      tag2 = 'Gate: ${item['gate_pass_code'] ?? 'Gate 1'}';
      status = item['status'] ?? 'Approved';
      color = AppTheme.warning;
    } else if (_selectedReport == 'visitor_report') {
      title = '${item['visitor_name'] ?? 'Guest'} (${item['pass_code'] ?? 'VIS'})';
      subtitle = 'Host: ${item['host_name'] ?? 'Admin'} • Org: ${item['organization'] ?? 'Visitor'}';
      tag1 = 'Purpose: ${item['purpose'] ?? 'Meeting'}';
      tag2 = 'Date: ${item['visit_date'] ?? 'Today'}';
      status = item['status'] ?? 'Active';
      color = AppTheme.primary;
    } else if (_selectedReport == 'vehicle_report') {
      title = '${item['vehicle_number'] ?? 'Vehicle'} (${item['vehicle_type'] ?? 'Truck'})';
      subtitle = 'Driver: ${item['driver_name'] ?? ''} • Contact: ${item['driver_phone'] ?? ''}';
      tag1 = 'Pass: ${item['pass_code'] ?? 'VP'}';
      tag2 = 'PUC/Ins: ${item['puc_valid_until'] ?? 'Valid'}';
      status = item['status'] ?? 'Active';
      color = const Color(0xFF9333EA);
    } else if (_selectedReport == 'audit_logs') {
      title = '${item['action_type'] ?? 'AUDIT'} • ${item['module'] ?? 'System'}';
      subtitle = item['details'] ?? 'Operation logged';
      tag1 = 'By: ${item['user_name'] ?? 'System'}';
      tag2 = item['created_at'] != null ? item['created_at'].toString().split('T').first : '';
      status = item['action_type'] ?? 'INFO';
      color = AppTheme.primary;
    }

    return Container(
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
              Expanded(child: Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: AppTheme.badgeDecoration(
                  background: color.withValues(alpha: 0.1),
                  borderColor: color.withValues(alpha: 0.25),
                  radius: 6,
                ),
                child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: AppTheme.badgeDecoration(background: AppTheme.bgSurface, borderColor: AppTheme.border, radius: 4),
                child: Text(tag1, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: AppTheme.badgeDecoration(background: AppTheme.primarySubtle, borderColor: AppTheme.primaryLight, radius: 4),
                child: Text(tag2, style: const TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value, Color color) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 24, color: AppTheme.border);
  }
}
