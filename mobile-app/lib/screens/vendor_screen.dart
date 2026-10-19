import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/api_service.dart';
import '../utils/validators.dart';
import '../utils/app_theme.dart';

class VendorScreen extends StatefulWidget {
  const VendorScreen({super.key});

  @override
  State<VendorScreen> createState() => _VendorScreenState();
}

class _VendorScreenState extends State<VendorScreen> {
  List<dynamic> _vendors = [];
  int? _selectedVendorId;
  Map<String, dynamic>? _selectedVendorDetails;
  bool _isLoading = true;
  bool _isDetailsLoading = false;
  int _currentTab = 0;

  // --- CONTRACTOR GLOBAL FILTERS ---
  String _contractorSearch = '';
  String _contractorTradeFilter = 'ALL';

  // --- TAB 0: WORKERS & 3-TIER APPROVALS FILTERS ---
  String _workerSearch = '';
  String _workerStatusFilter = 'ALL'; // 'ALL', 'INSIDE', 'OUTSIDE', 'PENDING', 'CLEARED'
  String _workerTradeFilter = 'ALL'; // 'ALL', 'Scaffolding', 'Welding', 'Electrical', 'Masonry', 'Plumbing', 'Technician', 'Helper'
  String _workerApprovalStageFilter = 'ALL'; // 'ALL', 'admin', 'safety', 'super_admin', 'completed'
  String _workerSortBy = 'NAME_ASC'; // 'NAME_ASC', 'NAME_DESC', 'ID_ASC', 'ATT_DESC'
  final TextEditingController _workerSearchController = TextEditingController();

  // --- TAB 1: PTW PERMITS FILTERS ---
  String _permitSearch = '';
  String _permitStatusFilter = 'ALL'; // 'ALL', 'PENDING', 'APPROVED', 'EXPIRED'
  String _permitTypeFilter = 'ALL'; // 'ALL', 'Hot Work', 'Height', 'Confined', 'Electrical'
  final TextEditingController _permitSearchController = TextEditingController();

  // --- TAB 2: ATTENDANCE MUSTER & ANALYTICS FILTERS ---
  String _attendancePeriod = 'today'; // 'today', 'week', 'month', 'year', 'custom'
  DateTimeRange? _attendanceCustomRange;
  String _attendanceShiftFilter = 'ALL'; // 'ALL', 'Morning', 'General', 'Night'
  String _attendanceStatusFilter = 'ALL'; // 'ALL', 'Present', 'Completed'
  Map<String, dynamic>? _attendanceAnalytics;
  bool _isAttendanceLoading = false;

  // --- TAB 3: DC MOVEMENTS FILTERS ---
  String _dcSearch = '';
  String _dcTypeFilter = 'ALL'; // 'ALL', 'INWARD', 'OUTWARD', 'RETURNABLE'
  final TextEditingController _dcSearchController = TextEditingController();

  // --- TAB 4: SAFETY & FLEET FILTERS ---
  String _safetySeverityFilter = 'ALL'; // 'ALL', 'RED', 'YELLOW', 'GREEN'
  String _vehicleFilter = 'ALL'; // 'ALL', 'INSIDE', 'AUTHORIZED'

  @override
  void initState() {
    super.initState();
    _fetchVendors();
  }

  @override
  void dispose() {
    _workerSearchController.dispose();
    _permitSearchController.dispose();
    _dcSearchController.dispose();
    super.dispose();
  }

  void _fetchVendors([int? targetId]) async {
    setState(() => _isLoading = true);
    final list = await ApiService.getVendors();
    if (mounted) {
      setState(() {
        _vendors = list;
        _isLoading = false;
        if (_vendors.isNotEmpty) {
          final idToSelect = targetId ?? _selectedVendorId ?? _vendors.first['id'] as int;
          _selectedVendorId = idToSelect;
        }
      });
      if (_selectedVendorId != null) {
        _fetchVendorDetails(_selectedVendorId!);
      }
    }
  }

  void _fetchVendorDetails(int id) async {
    setState(() => _isDetailsLoading = true);
    final details = await ApiService.getVendorById(id);
    if (mounted) {
      setState(() {
        _selectedVendorDetails = details;
        _isDetailsLoading = false;
      });
      _loadAttendanceAnalytics(_attendancePeriod);
    }
  }

  void _loadAttendanceAnalytics(String period) async {
    if (_selectedVendorId == null) return;
    setState(() {
      _attendancePeriod = period;
      _isAttendanceLoading = true;
    });
    final data = await ApiService.getVendorAttendanceAnalytics(
      period: period == 'custom' || period == 'today' ? 'week' : period,
      vendorId: _selectedVendorId.toString(),
    );
    if (mounted) {
      setState(() {
        _attendanceAnalytics = data;
        _isAttendanceLoading = false;
      });
    }
  }

  void _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _attendanceCustomRange ?? DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF06B6D4),
              onPrimary: Colors.black,
              surface: Color(0xFF1E293B),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _attendanceCustomRange = picked;
        _attendancePeriod = 'custom';
      });
      _loadAttendanceAnalytics('custom');
    }
  }

  // --- 3-TIER APPROVAL FLOW ACTION ---
  void _approveWorkerStage(int empId, String stage) async {
    HapticFeedback.mediumImpact();
    final ok = await ApiService.approveEmployeeStage(
      empId: empId,
      stage: stage,
      action: 'Approved',
      remarks: 'Verified & cleared by ${ApiService.currentUser?.fullName ?? "Authorized Officer"}',
    );
    if (ok && mounted) {
      String stageName = stage == 'super_admin' ? 'Super Admin (ID Issued)' : (stage == 'safety' ? 'Safety Clearance' : 'Admin KYC');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.verified, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text('Worker passed [$stageName] stage successfully!')),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (_selectedVendorId != null) _fetchVendorDetails(_selectedVendorId!);
    }
  }

  void _rejectWorker(int empId) async {
    HapticFeedback.heavyImpact();
    final ok = await ApiService.updateEmployee(empId, {'status': 'Deactivated'});
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Worker clearance request rejected / deactivated'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (_selectedVendorId != null) _fetchVendorDetails(_selectedVendorId!);
    }
  }

  void _approvePermit(int permitId) async {
    HapticFeedback.mediumImpact();
    final ok = await ApiService.approvePermit(permitId);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Work Permit (PTW) Approved & Live!'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (_selectedVendorId != null) _fetchVendorDetails(_selectedVendorId!);
    }
  }

  void _rejectPermit(int permitId) async {
    HapticFeedback.heavyImpact();
    final ok = await ApiService.rejectPermit(permitId, reason: 'Site HSE safety criteria not satisfied');
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Work Permit (PTW) Rejected'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (_selectedVendorId != null) _fetchVendorDetails(_selectedVendorId!);
    }
  }

  // --- ATTENDANCE CSV EXPORT DOWNLOAD ---
  void _downloadAttendanceReport() async {
    HapticFeedback.lightImpact();
    final vendorId = _selectedVendorId?.toString();
    final csvContent = await ApiService.exportAttendanceCSVData(
      period: _attendancePeriod == 'today' ? 'week' : _attendancePeriod,
      vendorId: vendorId,
    );

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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF06B6D4).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.file_download_done, color: Color(0xFF06B6D4), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Attendance Report Ready', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(
                          '${_selectedVendorDetails?['company_name'] ?? 'Contractor'} • ${_attendancePeriod.toUpperCase()}',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.table_chart, color: Color(0xFF10B981), size: 16),
                      SizedBox(width: 6),
                      Text('CSV Data Preview (First 5 Rows)', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    csvContent.split('\n').take(6).join('\n'),
                    style: const TextStyle(color: Colors.white60, fontSize: 10, fontFamily: 'monospace'),
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF06B6D4)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: csvContent));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✓ CSV text copied to clipboard!'), backgroundColor: Color(0xFF06B6D4)),
                      );
                    },
                    icon: const Icon(Icons.copy, color: Color(0xFF06B6D4), size: 18),
                    label: const Text('COPY CSV', style: TextStyle(color: Color(0xFF06B6D4), fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✓ Downloaded Attendance_${_attendancePeriod.toUpperCase()}_Report.csv successfully!'),
                          backgroundColor: const Color(0xFF10B981),
                        ),
                      );
                    },
                    icon: const Icon(Icons.download, color: Colors.white, size: 18),
                    label: const Text('DOWNLOAD CSV', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- CONTRACTOR SWITCHER BOTTOM SHEET ---
  void _openContractorSwitcherModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final filteredVendors = _vendors.where((v) {
            final name = (v['company_name'] ?? '').toString().toLowerCase();
            final code = (v['vendor_id'] ?? v['vendor_code'] ?? '').toString().toLowerCase();
            final trade = (v['trade_scope'] ?? '').toString().toLowerCase();
            final matchesSearch = _contractorSearch.isEmpty || name.contains(_contractorSearch.toLowerCase()) || code.contains(_contractorSearch.toLowerCase());
            final matchesTrade = _contractorTradeFilter == 'ALL' || trade.contains(_contractorTradeFilter.toLowerCase());
            return matchesSearch && matchesTrade;
          }).toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.business, color: Color(0xFF06B6D4), size: 22),
                        SizedBox(width: 8),
                        Text('Select Contractor Roster', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 12),
                // Search field
                TextField(
                  onChanged: (val) => setSheetState(() => _contractorSearch = val),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search contractor by name or code...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF06B6D4), size: 20),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                // Trade Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['ALL', 'Civil', 'Electrical', 'Plumbing', 'HVAC', 'Finishing', 'Safety'].map((trade) {
                      final isSel = _contractorTradeFilter == trade;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          selected: isSel,
                          showCheckmark: false,
                          label: Text(trade, style: TextStyle(color: isSel ? Colors.black : Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                          backgroundColor: const Color(0xFF1E293B),
                          selectedColor: const Color(0xFF06B6D4),
                          onSelected: (val) => setSheetState(() => _contractorTradeFilter = trade),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: filteredVendors.isEmpty
                      ? const Center(child: Text('No contractors match filter', style: TextStyle(color: Colors.white54)))
                      : ListView.builder(
                          itemCount: filteredVendors.length,
                          itemBuilder: (ctx, i) {
                            final v = filteredVendors[i];
                            final isCurrent = v['id'] == _selectedVendorId;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: isCurrent ? const Color(0xFF06B6D4).withValues(alpha: 0.15) : const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: isCurrent ? const Color(0xFF06B6D4) : Colors.white10),
                              ),
                              child: ListTile(
                                onTap: () {
                                  Navigator.pop(ctx);
                                  setState(() => _selectedVendorId = v['id'] as int);
                                  _fetchVendorDetails(v['id'] as int);
                                },
                                leading: CircleAvatar(
                                  backgroundColor: isCurrent ? const Color(0xFF06B6D4) : Colors.white10,
                                  child: Text(
                                    (v['company_name'] ?? 'C')[0].toUpperCase(),
                                    style: TextStyle(color: isCurrent ? Colors.black : Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(v['company_name'] ?? 'Contractor', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                subtitle: Text(
                                  '${v['vendor_id'] ?? v['vendor_code'] ?? 'VND'} • ${v['trade_scope'] ?? 'General'}',
                                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                                ),
                                trailing: isCurrent
                                    ? const Icon(Icons.check_circle, color: Color(0xFF06B6D4), size: 22)
                                    : const Icon(Icons.chevron_right, color: Colors.white38),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- WORKER ADVANCED FILTER MODAL ---
  void _openWorkerFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
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
                        Icon(Icons.tune, color: Color(0xFF6366F1), size: 22),
                        SizedBox(width: 8),
                        Text('Workforce Filters & Sort', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _workerStatusFilter = 'ALL';
                          _workerTradeFilter = 'ALL';
                          _workerApprovalStageFilter = 'ALL';
                          _workerSortBy = 'NAME_ASC';
                        });
                        setModalState(() {});
                        Navigator.pop(ctx);
                      },
                      child: const Text('Reset All', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Trade Filter
                const Text('TRADE / SKILL SCOPE', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: ['ALL', 'Scaffolding', 'Welding', 'Electrical', 'Masonry', 'Plumbing', 'Technician', 'Helper'].map((trade) {
                    final isSel = _workerTradeFilter == trade;
                    return ChoiceChip(
                      selected: isSel,
                      showCheckmark: false,
                      label: Text(trade, style: TextStyle(color: isSel ? Colors.black : Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                      backgroundColor: const Color(0xFF1E293B),
                      selectedColor: const Color(0xFF6366F1),
                      onSelected: (val) => setModalState(() => setState(() => _workerTradeFilter = trade)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // 3-Tier Approval Stage Filter
                const Text('3-TIER APPROVAL STAGE', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    {'id': 'ALL', 'label': 'All Stages'},
                    {'id': 'admin', 'label': '1. Pending Admin KYC'},
                    {'id': 'safety', 'label': '2. Pending Safety HSE'},
                    {'id': 'super_admin', 'label': '3. Pending Super Admin'},
                    {'id': 'completed', 'label': '✓ Fully Issued'},
                  ].map((stage) {
                    final isSel = _workerApprovalStageFilter == stage['id'];
                    return ChoiceChip(
                      selected: isSel,
                      showCheckmark: false,
                      label: Text(stage['label']!, style: TextStyle(color: isSel ? Colors.black : Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                      backgroundColor: const Color(0xFF1E293B),
                      selectedColor: const Color(0xFFF59E0B),
                      onSelected: (val) => setModalState(() => setState(() => _workerApprovalStageFilter = stage['id']!)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Sort By
                const Text('SORT WORKERS BY', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    {'id': 'NAME_ASC', 'label': 'Name (A to Z)'},
                    {'id': 'NAME_DESC', 'label': 'Name (Z to A)'},
                    {'id': 'ID_ASC', 'label': 'EMP ID Code'},
                    {'id': 'ATT_DESC', 'label': 'Inside Gate First'},
                  ].map((s) {
                    final isSel = _workerSortBy == s['id'];
                    return ChoiceChip(
                      selected: isSel,
                      showCheckmark: false,
                      label: Text(s['label']!, style: TextStyle(color: isSel ? Colors.black : Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                      backgroundColor: const Color(0xFF1E293B),
                      selectedColor: const Color(0xFF06B6D4),
                      onSelected: (val) => setModalState(() => setState(() => _workerSortBy = s['id']!)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 22),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('APPLY FILTERS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- MODAL: ONBOARD CONTRACTOR ---
  void _openOnboardVendorModal() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final contactPersonCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final tradeCtrl = TextEditingController(text: 'Civil & Structural');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.business_center, color: Color(0xFF06B6D4)),
                        SizedBox(width: 8),
                        Text('Onboard Contractor / Vendor', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 14),
                _buildTextField(nameCtrl, 'Company Legal Name *', Icons.business),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildTextField(codeCtrl, 'Vendor Code (e.g. VND-101)', Icons.tag)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTextField(tradeCtrl, 'Trade Scope', Icons.handyman)),
                  ],
                ),
                const SizedBox(height: 10),
                _buildTextField(contactPersonCtrl, 'Contact Person / Owner *', Icons.person),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildTextField(phoneCtrl, 'Phone Number *', Icons.phone, keyboardType: TextInputType.phone)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTextField(emailCtrl, 'Email Address', Icons.email, keyboardType: TextInputType.emailAddress)),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF06B6D4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            final nameErr = FormValidators.validateName(nameCtrl.text, fieldName: 'Company name');
                            if (nameErr != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(nameErr), backgroundColor: Colors.orange));
                              return;
                            }
                            final phoneErr = FormValidators.validatePhone(phoneCtrl.text, fieldName: 'Phone number');
                            if (phoneErr != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(phoneErr), backgroundColor: Colors.orange));
                              return;
                            }
                            setModalState(() => isSaving = true);
                            final ok = await ApiService.createVendor({
                              'company_name': nameCtrl.text.trim(),
                              'vendor_code': codeCtrl.text.trim(),
                              'trade_scope': tradeCtrl.text.trim(),
                              'contact_person': contactPersonCtrl.text.trim(),
                              'phone': phoneCtrl.text.trim(),
                              'email': emailCtrl.text.trim(),
                            });
                            setModalState(() => isSaving = false);
                            if (ok != null && mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('✓ Contractor onboarded successfully!'), backgroundColor: Color(0xFF10B981)),
                              );
                              _fetchVendors();
                            }
                          },
                    child: isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('ONBOARD CONTRACTOR', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- MODAL: ENROLL WORKER WITH COMPREHENSIVE COMPLIANCE & 3-TIER SUBMISSION ---
  void _openAddWorkerModal() {
    if (_selectedVendorId == null) return;
    final nameCtrl = TextEditingController();
    final fatherCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final roleCtrl = TextEditingController(text: 'Scaffolder');
    final aadhaarCtrl = TextEditingController();
    final bloodCtrl = TextEditingController(text: 'O+');
    final medicalCtrl = TextEditingController(text: 'Fit - Grade A (All Clear)');
    final emergencyCtrl = TextEditingController();
    String selectedShift = 'General (08:30 - 17:30)';
    String uploadedPhotoUrl = 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80';
    String uploadedAadhaarDoc = 'aadhaar_card_front_back.pdf';
    String uploadedMedicalDoc = 'medical_fitness_apollo_cert.pdf';
    bool isSaving = false;

    final photoPresets = [
      {'title': 'Worker 1', 'url': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80'},
      {'title': 'Worker 2', 'url': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&auto=format&fit=crop&q=80'},
      {'title': 'Worker 3', 'url': 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150&auto=format&fit=crop&q=80'},
      {'title': 'Worker 4', 'url': 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=150&auto=format&fit=crop&q=80'},
      {'title': 'Worker 5', 'url': 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=150&auto=format&fit=crop&q=80'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.person_add, color: Color(0xFF6366F1), size: 22),
                        SizedBox(width: 8),
                        Text('Enroll Worker & Initiate 3-Tier ID', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Color(0xFF818CF8), size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Uploaded documents and photo will be embossed on the digital gate pass and verified across 1. Site Admin KYC ➔ 2. Safety Medical ➔ 3. Super Admin Gate Pass.',
                          style: TextStyle(color: Color(0xFFC7D2FE), fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // 1. PHOTO UPLOADER WITH PREVIEW
                Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF06B6D4), width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 32,
                            backgroundImage: NetworkImage(uploadedPhotoUrl),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Color(0xFF06B6D4), shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt, color: Colors.black, size: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Worker Profile Photo *', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          const Text('Select portrait for ID badge & Face-ID:', style: TextStyle(color: Colors.white54, fontSize: 10)),
                          const SizedBox(height: 6),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: photoPresets.map((p) {
                                final isSel = uploadedPhotoUrl == p['url'];
                                return InkWell(
                                  onTap: () => setModalState(() => uploadedPhotoUrl = p['url']!),
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 6),
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: isSel ? const Color(0xFF06B6D4) : Colors.transparent, width: 2),
                                    ),
                                    child: CircleAvatar(radius: 14, backgroundImage: NetworkImage(p['url']!)),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                _buildTextField(nameCtrl, 'Worker Full Name (As per Aadhaar) *', Icons.person),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildTextField(fatherCtrl, "Father's / Guardian Name", Icons.people_outline)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTextField(mobileCtrl, 'Mobile Number *', Icons.phone, keyboardType: TextInputType.phone)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildTextField(roleCtrl, 'Designation / Trade *', Icons.badge)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTextField(aadhaarCtrl, '12-Digit Aadhaar No. *', Icons.credit_card, keyboardType: TextInputType.number)),
                  ],
                ),

                const SizedBox(height: 12),

                // 2. AADHAAR CARD DOCUMENT UPLOAD BOX
                InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setModalState(() {
                      uploadedAadhaarDoc = 'aadhaar_verified_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}.pdf';
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✓ Aadhaar Document (Front & Back) Selected & Attached!'), backgroundColor: Color(0xFF10B981)),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.upload_file, color: Color(0xFF818CF8), size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Aadhaar Card Document Upload *', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                              Text('Attached: $uploadedAadhaarDoc • 1.4 MB', style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                          child: const Text('ATTACHED ✓', style: TextStyle(color: Color(0xFF10B981), fontSize: 9.5, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 3. MEDICAL FITNESS CERTIFICATE UPLOAD BOX
                InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setModalState(() {
                      uploadedMedicalDoc = 'medical_clearance_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}.pdf';
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✓ Medical Fitness Certificate Attached!'), backgroundColor: Color(0xFF10B981)),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.health_and_safety, color: Color(0xFF10B981), size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Medical Fitness Certificate Upload *', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                              Text('Attached: $uploadedMedicalDoc • Grade A', style: const TextStyle(color: Color(0xFF10B981), fontSize: 11)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                          child: const Text('ATTACHED ✓', style: TextStyle(color: Color(0xFF10B981), fontSize: 9.5, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(child: _buildTextField(bloodCtrl, 'Blood Group', Icons.bloodtype)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTextField(medicalCtrl, 'Medical Fitness Cert', Icons.health_and_safety)),
                  ],
                ),
                const SizedBox(height: 10),
                _buildTextField(emergencyCtrl, 'Emergency Contact (Name & Phone)', Icons.contact_phone),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: selectedShift,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Shift Allocation',
                    labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'General (08:30 - 17:30)', child: Text('General Shift (08:30 - 17:30)')),
                    DropdownMenuItem(value: 'Morning (06:00 - 14:00)', child: Text('Morning Shift (06:00 - 14:00)')),
                    DropdownMenuItem(value: 'Night (20:00 - 05:00)', child: Text('Night Shift (20:00 - 05:00)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedShift = val);
                  },
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (nameCtrl.text.trim().isEmpty || mobileCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please fill Name and Mobile Number'), backgroundColor: Colors.orange),
                              );
                              return;
                            }
                            setModalState(() => isSaving = true);
                            final ok = await ApiService.createEmployee({
                              'full_name': nameCtrl.text.trim(),
                              'father_name': fatherCtrl.text.trim(),
                              'mobile': mobileCtrl.text.trim(),
                              'designation': roleCtrl.text.trim(),
                              'skill': roleCtrl.text.trim(),
                              'aadhaar_no': aadhaarCtrl.text.trim(),
                              'aadhaar_doc': uploadedAadhaarDoc,
                              'medical_doc': uploadedMedicalDoc,
                              'photo_url': uploadedPhotoUrl,
                              'profile_photo': uploadedPhotoUrl,
                              'blood_group': bloodCtrl.text.trim(),
                              'medical_cert': medicalCtrl.text.trim(),
                              'emergency_phone': emergencyCtrl.text.trim(),
                              'shift': selectedShift,
                              'vendor_id': _selectedVendorId,
                              'vendor_name': _selectedVendorDetails?['company_name'] ?? 'Contractor',
                            });
                            setModalState(() => isSaving = false);
                            if (ok && mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✓ Worker enrolled with Photo, Aadhaar & Medical docs! Sent for 3-tier clearance.'),
                                  backgroundColor: Color(0xFF10B981),
                                ),
                              );
                              _fetchVendorDetails(_selectedVendorId!);
                            }
                          },
                    child: isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('SUBMIT FOR 3-TIER APPROVAL & ID', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- MODAL: ISSUE PERMIT (PTW) ---
  void _openIssuePermitModal() {
    final typeCtrl = TextEditingController(text: 'Hot Work (Welding/Cutting)');
    final descCtrl = TextEditingController();
    final zoneCtrl = TextEditingController(text: 'Block A - 4th Floor AHU Plant');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.local_fire_department, color: Color(0xFFF59E0B), size: 22),
                        SizedBox(width: 8),
                        Text('Issue Permit to Work (PTW)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 14),
                _buildTextField(typeCtrl, 'Permit Type (e.g. Hot Work, Height)', Icons.assignment_late),
                const SizedBox(height: 10),
                _buildTextField(zoneCtrl, 'Location Zone *', Icons.location_on),
                const SizedBox(height: 10),
                _buildTextField(descCtrl, 'Scope & Safety Measures Description *', Icons.description),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (descCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please describe the work permit scope'), backgroundColor: Colors.orange),
                              );
                              return;
                            }
                            setModalState(() => isSaving = true);
                            final ok = await ApiService.createPermit({
                              'permit_type': typeCtrl.text.trim(),
                              'location_zone': zoneCtrl.text.trim(),
                              'description': descCtrl.text.trim(),
                              'vendor_name': _selectedVendorDetails?['company_name'] ?? 'Contractor',
                            });
                            setModalState(() => isSaving = false);
                            if (ok && mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('✓ PTW Permit submitted for Safety & Admin sign-off!'), backgroundColor: Color(0xFF10B981)),
                              );
                              if (_selectedVendorId != null) _fetchVendorDetails(_selectedVendorId!);
                            }
                          },
                    child: isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('SUBMIT PTW FOR REVIEW', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- MODAL: CREATE MATERIAL DC PASS ---
  void _openCreateMaterialModal() {
    final matCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '10');
    final vehCtrl = TextEditingController(text: 'KA 04 E 9921');
    final driverCtrl = TextEditingController();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.inventory_2, color: Color(0xFF10B981), size: 22),
                        SizedBox(width: 8),
                        Text('Material Delivery Pass (DC)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 14),
                _buildTextField(matCtrl, 'Material Description *', Icons.category),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildTextField(qtyCtrl, 'Quantity (Sets/Units)', Icons.numbers, keyboardType: TextInputType.number)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTextField(vehCtrl, 'Vehicle Number', Icons.local_shipping)),
                  ],
                ),
                const SizedBox(height: 10),
                _buildTextField(driverCtrl, 'Driver Name', Icons.person),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (matCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter material description'), backgroundColor: Colors.orange),
                              );
                              return;
                            }
                            setModalState(() => isSaving = true);
                            final ok = await ApiService.createMaterialEntry({
                              'material_name': matCtrl.text.trim(),
                              'quantity': int.tryParse(qtyCtrl.text.trim()) ?? 1,
                              'vehicle_number': vehCtrl.text.trim(),
                              'driver_name': driverCtrl.text.trim(),
                              'vendor_name': _selectedVendorDetails?['company_name'] ?? 'Contractor',
                            });
                            setModalState(() => isSaving = false);
                            if (ok && mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('✓ Material DC created for Gate verification!'), backgroundColor: Color(0xFF10B981)),
                              );
                              if (_selectedVendorId != null) _fetchVendorDetails(_selectedVendorId!);
                            }
                          },
                    child: isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('GENERATE DC PASS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- MODAL: LOG SAFETY PUNCH ---
  void _openSafetyPunchModal() {
    String colorType = 'YELLOW';
    final workerCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    final zoneCtrl = TextEditingController(text: 'Main Construction Bay');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.shield_outlined, color: Color(0xFFEF4444), size: 22),
                        SizedBox(width: 8),
                        Text('Log Safety Punch / Observation', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: colorType,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Severity Level',
                    labelStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'RED', child: Text('🔴 RED (Critical Stop-Work)', style: TextStyle(color: Colors.redAccent))),
                    DropdownMenuItem(value: 'YELLOW', child: Text('🟡 YELLOW (PPE Warning)', style: TextStyle(color: Colors.amber))),
                    DropdownMenuItem(value: 'GREEN', child: Text('🟢 GREEN (Proactive Safety)', style: TextStyle(color: Colors.greenAccent))),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => colorType = val);
                  },
                ),
                const SizedBox(height: 10),
                _buildTextField(workerCtrl, 'Worker Involved (Name / ID)', Icons.person),
                const SizedBox(height: 10),
                _buildTextField(zoneCtrl, 'Location Zone', Icons.place),
                const SizedBox(height: 10),
                _buildTextField(reasonCtrl, 'Observation / Reason *', Icons.warning_amber),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (reasonCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please describe the safety observation'), backgroundColor: Colors.orange),
                              );
                              return;
                            }
                            setModalState(() => isSaving = true);
                            final ok = await ApiService.createSafetyPunch({
                              'color_type': colorType,
                              'worker_name': workerCtrl.text.trim().isNotEmpty ? workerCtrl.text.trim() : 'Contractor Worker',
                              'zone': zoneCtrl.text.trim(),
                              'reason': reasonCtrl.text.trim(),
                              'vendor_name': _selectedVendorDetails?['company_name'] ?? 'Contractor',
                            });
                            setModalState(() => isSaving = false);
                            if (ok && mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Safety observation recorded!'), backgroundColor: Color(0xFF10B981)),
                              );
                              if (_selectedVendorId != null) _fetchVendorDetails(_selectedVendorId!);
                            }
                          },
                    child: isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('LOG SAFETY OBSERVATION', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- SMART HOLOGRAM DIGITAL ID BADGE MODAL ---
  void _openHologramBadge(Map<String, dynamic> emp) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF090D16)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF06B6D4).withValues(alpha: 0.3),
                blurRadius: 30,
                spreadRadius: 2,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Hologram Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF06B6D4).withValues(alpha: 0.15),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(23)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.nfc, color: Color(0xFF06B6D4), size: 20),
                        const SizedBox(width: 8),
                        Text('ZYETA SMART PASS • NFC/QR', style: TextStyle(color: Colors.cyan.shade200, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFF10B981)),
                      ),
                      child: const Text('GATE PASS VERIFIED', style: TextStyle(color: Color(0xFF10B981), fontSize: 9.5, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Avatar & Details with Photo Support
                    Row(
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF06B6D4), width: 2),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFF06B6D4).withValues(alpha: 0.3), blurRadius: 12)
                            ],
                          ),
                          child: ClipOval(
                            child: (emp['photo_url'] != null || emp['profile_photo'] != null)
                                ? Image.network(
                                    emp['photo_url'] ?? emp['profile_photo'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: const Color(0xFF6366F1),
                                      child: Center(
                                        child: Text((emp['full_name'] ?? 'W')[0].toUpperCase(), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: const Color(0xFF6366F1),
                                    child: Center(
                                      child: Text((emp['full_name'] ?? 'W')[0].toUpperCase(), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(emp['full_name'] ?? 'Worker', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                              const SizedBox(height: 2),
                              Text('ID: ${emp['employee_id'] ?? "EMP-100"}', style: const TextStyle(fontSize: 12, color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
                              Text('${emp['designation'] ?? 'Technician'} • ${emp['skill'] ?? 'General'}', style: const TextStyle(fontSize: 11, color: Colors.white60)),
                              Text('Vendor: ${emp['vendor_name'] ?? _selectedVendorDetails?['company_name'] ?? "Contractor"}', style: const TextStyle(fontSize: 10, color: Colors.white38), overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // QR Code Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: 'ZYETA-EMP-${emp['employee_id'] ?? emp['id']}-${emp['full_name']}',
                        version: QrVersions.auto,
                        size: 135.0,
                        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF0F172A)),
                        dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: Color(0xFF0F172A)),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Attached Verified Documents Row
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.attachment, color: Color(0xFF06B6D4), size: 14),
                              SizedBox(width: 4),
                              Text('Verified Onboarding Attachments (Active on ID):', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(6)),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.credit_card, color: Color(0xFF6366F1), size: 12),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          emp['aadhaar_doc'] ?? 'aadhaar_verified.pdf',
                                          style: const TextStyle(color: Colors.white70, fontSize: 9),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 10),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(6)),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.health_and_safety, color: Color(0xFF10B981), size: 12),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          emp['medical_doc'] ?? 'medical_cert.pdf',
                                          style: const TextStyle(color: Colors.white70, fontSize: 9),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 10),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Compliance Badges Row
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildHoloBadge(Icons.bloodtype, 'Blood', emp['blood_group'] ?? 'O+', Colors.redAccent),
                          _buildHoloBadge(Icons.health_and_safety, 'Medical', 'Grade A', Colors.greenAccent),
                          _buildHoloBadge(Icons.shield, 'Safety', 'Inducted', Colors.amberAccent),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF06B6D4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('CLOSE PASS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHoloBadge(IconData icon, String label, String val, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9)),
        Text(val, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon, {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.white54, size: 20),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }

  // ==========================================
  // MAIN BUILD METHOD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    final stats = _selectedVendorDetails?['stats'] ?? {};
    final todayManpower = stats['today_manpower'] ?? 0;
    final yesterdayManpower = stats['yesterday_manpower'] ?? 0;
    final totalWorkers = stats['total_employees'] ?? 0;
    final pendingApprovals = stats['pending_employee_approvals'] ?? 0;
    final activePermits = stats['active_permits'] ?? 0;
    final pendingPermits = stats['pending_permits'] ?? 0;

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Contractor Command Hub', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.success),
                ),
                const SizedBox(width: 5),
                const Text('GATE SYNCHRONIZED • REALTIME', style: TextStyle(fontSize: 9.5, color: AppTheme.success, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh All',
            icon: const Icon(Icons.refresh, color: AppTheme.primary),
            onPressed: () => _fetchVendors(_selectedVendorId),
          ),
          const LogoutIconButton(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_business, color: Colors.white),
        label: const Text('Add Contractor', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        onPressed: _openOnboardVendorModal,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF06B6D4)))
          : _vendors.isEmpty
              ? const Center(child: Text('No registered contractors in system', style: TextStyle(color: Colors.white54)))
              : Column(
                  children: [
                    // CONTRACTOR HERO BANNER & QUICK SELECTOR
                    _buildContractorHeader(),

                    Expanded(
                      child: _isDetailsLoading
                          ? const Center(child: CircularProgressIndicator(color: Color(0xFF06B6D4)))
                          : ListView(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              children: [
                                // ACTION SHORTCUT GLOW PILLS
                                _buildActionShortcutsRow(),

                                const SizedBox(height: 12),

                                // TELEMETRY METRIC CARDS
                                _buildMetricTelemetryGrid(
                                  today: todayManpower,
                                  yesterday: yesterdayManpower,
                                  totalWorkers: totalWorkers,
                                  pendingApprovals: pendingApprovals,
                                  activePermits: activePermits,
                                  pendingPermits: pendingPermits,
                                ),

                                const SizedBox(height: 14),

                                // SEGMENTED GLOW TABS
                                _buildSegmentTabs(pendingApprovals: pendingApprovals, pendingPermits: pendingPermits),

                                const SizedBox(height: 12),

                                // ACTIVE TAB CONTENT
                                _buildCurrentTabView(),
                              ],
                            ),
                    ),
                  ],
                ),
    );
  }

  // --- CONTRACTOR HEADER & SELECTOR ---
  Widget _buildContractorHeader() {
    final vName = _selectedVendorDetails?['company_name'] ?? 'Select Contractor';
    final vCode = _selectedVendorDetails?['vendor_id'] ?? _selectedVendorDetails?['vendor_code'] ?? 'VND-100';
    final trade = _selectedVendorDetails?['trade_scope'] ?? 'General Contracting';
    final contact = _selectedVendorDetails?['owner_name'] ?? _selectedVendorDetails?['contact_person'] ?? 'Rep';
    final phone = _selectedVendorDetails?['phone'] ?? '+91';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border(bottom: BorderSide(color: const Color(0xFF06B6D4).withValues(alpha: 0.2))),
      ),
      child: Row(
        children: [
          // Contractor Logo Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF06B6D4), width: 1.5),
              gradient: const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF6366F1)]),
            ),
            child: Center(
              child: Text(
                vName.isNotEmpty ? vName[0].toUpperCase() : 'C',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        vName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                      ),
                      child: const Text('ACTIVE', style: TextStyle(color: Color(0xFF10B981), fontSize: 9.5, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$vCode • $trade • $contact ($phone)',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Switch Contractor Button
          InkWell(
            onTap: _openContractorSwitcherModal,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.swap_horiz, color: Color(0xFF06B6D4), size: 16),
                  SizedBox(width: 4),
                  Text('SWITCH', style: TextStyle(color: Color(0xFF06B6D4), fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- ACTION SHORTCUTS ROW ---
  Widget _buildActionShortcutsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildActionGlowPill('+ Enroll Worker', Icons.person_add, const Color(0xFF6366F1), _openAddWorkerModal),
          const SizedBox(width: 8),
          _buildActionGlowPill('+ Work Permit', Icons.local_fire_department, const Color(0xFFF59E0B), _openIssuePermitModal),
          const SizedBox(width: 8),
          _buildActionGlowPill('+ Material DC', Icons.inventory_2, const Color(0xFF10B981), _openCreateMaterialModal),
          const SizedBox(width: 8),
          _buildActionGlowPill('+ Log Safety', Icons.shield_outlined, const Color(0xFFEF4444), _openSafetyPunchModal),
          const SizedBox(width: 8),
          _buildActionGlowPill('📥 Export CSV', Icons.download, const Color(0xFF06B6D4), _downloadAttendanceReport),
        ],
      ),
    );
  }

  Widget _buildActionGlowPill(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // --- TELEMETRY METRIC GRID ---
  Widget _buildMetricTelemetryGrid({
    required int today,
    required int yesterday,
    required int totalWorkers,
    required int pendingApprovals,
    required int activePermits,
    required int pendingPermits,
  }) {
    final tile1 = _buildMetricTile(
      'TODAY ON-SITE',
      '$today',
      'Manpower present',
      const Color(0xFF06B6D4),
      Icons.access_time_filled,
      trend: '+12% shift',
    );
    final tile2 = _buildMetricTile(
      'TOTAL WORKFORCE',
      '$totalWorkers',
      'Registered crew',
      const Color(0xFF818CF8),
      Icons.groups,
    );
    final tile3 = _buildMetricTile(
      '3-TIER APPROVALS',
      '$pendingApprovals',
      pendingApprovals > 0 ? 'Action required' : 'All cleared',
      pendingApprovals > 0 ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
      Icons.verified_user,
    );
    final tile4 = _buildMetricTile(
      'ACTIVE PTWs',
      '$activePermits',
      pendingPermits > 0 ? '$pendingPermits pending' : 'Valid',
      const Color(0xFFF97316),
      Icons.assignment,
    );

    final isMobile = MediaQuery.of(context).size.width < 600;
    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: tile1),
              const SizedBox(width: 8),
              Expanded(child: tile2),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: tile3),
              const SizedBox(width: 8),
              Expanded(child: tile4),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: tile1),
        const SizedBox(width: 8),
        Expanded(child: tile2),
        const SizedBox(width: 8),
        Expanded(child: tile3),
        const SizedBox(width: 8),
        Expanded(child: tile4),
      ],
    );
  }

  Widget _buildMetricTile(String title, String value, String sub, Color color, IconData icon, {String? trend}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: color, fontSize: 9.5, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, color: color, size: 14),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(color: Colors.white38, fontSize: 9), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  // --- SEGMENT TABS SWITCHER ---
  Widget _buildSegmentTabs({required int pendingApprovals, required int pendingPermits}) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildSegmentTabItem(0, 'Workers & IDs', Icons.people, pendingApprovals),
          _buildSegmentTabItem(1, 'Permits (PTW)', Icons.local_fire_department, pendingPermits),
          _buildSegmentTabItem(2, 'Muster Roll & Analytics', Icons.bar_chart, 0),
          _buildSegmentTabItem(3, 'DC Movements', Icons.inventory_2, 0),
          _buildSegmentTabItem(4, 'Safety & Fleet', Icons.shield, 0),
        ],
      ),
    );
  }

  Widget _buildSegmentTabItem(int index, String title, IconData icon, int badgeCount) {
    final isSelected = _currentTab == index;
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _currentTab = index);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF06B6D4).withValues(alpha: 0.2) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? const Color(0xFF06B6D4) : Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF06B6D4) : Colors.white54, size: 16),
            const SizedBox(width: 6),
            Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            if (badgeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: const Color(0xFFF59E0B), borderRadius: BorderRadius.circular(10)),
                child: Text('$badgeCount', style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 0: WORKERS & 3-TIER APPROVALS
  // ==========================================
  Widget _buildWorkersTab() {
    final pendingList = _selectedVendorDetails?['pending_employees'] as List<dynamic>? ?? [];
    final empList = _selectedVendorDetails?['employees'] as List<dynamic>? ?? [];
    final allWorkers = [...pendingList, ...empList];

    // Filter workers based on search, status, trade, and approval stage
    final filtered = allWorkers.where((emp) {
      final name = (emp['full_name'] ?? '').toString().toLowerCase();
      final code = (emp['employee_id'] ?? '').toString().toLowerCase();
      final trade = (emp['designation'] ?? emp['skill'] ?? '').toString().toLowerCase();
      final aadhaar = (emp['aadhaar_no'] ?? '').toString().toLowerCase();

      // Search match
      final matchesSearch = _workerSearch.isEmpty ||
          name.contains(_workerSearch.toLowerCase()) ||
          code.contains(_workerSearch.toLowerCase()) ||
          trade.contains(_workerSearch.toLowerCase()) ||
          aadhaar.contains(_workerSearch.toLowerCase());

      // Status match
      bool matchesStatus = true;
      if (_workerStatusFilter == 'INSIDE') matchesStatus = emp['currently_inside'] == 1;
      if (_workerStatusFilter == 'OUTSIDE') matchesStatus = emp['currently_inside'] != 1;
      if (_workerStatusFilter == 'PENDING') matchesStatus = emp['status'].toString().contains('Pending');
      if (_workerStatusFilter == 'CLEARED') matchesStatus = emp['status'] == 'Active' || emp['status'] == 'Approved';

      // Trade match
      bool matchesTrade = _workerTradeFilter == 'ALL' || trade.contains(_workerTradeFilter.toLowerCase());

      // Stage match
      bool matchesStage = true;
      if (_workerApprovalStageFilter != 'ALL') {
        final approvals = emp['approvals'] as Map<String, dynamic>? ?? {};
        if (_workerApprovalStageFilter == 'admin') matchesStage = approvals['admin'] != 'Approved';
        if (_workerApprovalStageFilter == 'safety') matchesStage = approvals['admin'] == 'Approved' && approvals['safety'] != 'Approved';
        if (_workerApprovalStageFilter == 'super_admin') matchesStage = approvals['safety'] == 'Approved' && approvals['super_admin'] != 'Approved';
        if (_workerApprovalStageFilter == 'completed') matchesStage = approvals['super_admin'] == 'Approved';
      }

      return matchesSearch && matchesStatus && matchesTrade && matchesStage;
    }).toList();

    // Sort workers
    if (_workerSortBy == 'NAME_ASC') {
      filtered.sort((a, b) => (a['full_name'] ?? '').toString().compareTo((b['full_name'] ?? '').toString()));
    } else if (_workerSortBy == 'NAME_DESC') {
      filtered.sort((a, b) => (b['full_name'] ?? '').toString().compareTo((a['full_name'] ?? '').toString()));
    } else if (_workerSortBy == 'ATT_DESC') {
      filtered.sort((a, b) => (b['currently_inside'] ?? 0).compareTo(a['currently_inside'] ?? 0));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // WORKER FILTER BAR & SEARCH
        Row(
          children: [
            Expanded(
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white10),
                ),
                child: TextField(
                  controller: _workerSearchController,
                  onChanged: (val) => setState(() => _workerSearch = val),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search worker name, ID, Aadhaar...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF6366F1), size: 18),
                    suffixIcon: _workerSearch.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white54, size: 16),
                            onPressed: () {
                              _workerSearchController.clear();
                              setState(() => _workerSearch = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Filter Modal Button with Active Count Badge
            InkWell(
              onTap: _openWorkerFilterModal,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: (_workerTradeFilter != 'ALL' || _workerApprovalStageFilter != 'ALL')
                      ? const Color(0xFF6366F1).withValues(alpha: 0.25)
                      : const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.tune, color: Color(0xFF6366F1), size: 18),
                    if (_workerTradeFilter != 'ALL' || _workerApprovalStageFilter != 'ALL') ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Color(0xFF6366F1), shape: BoxShape.circle),
                        child: const Text('!', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // STATUS FILTER CHIPS
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('All Workers (${allWorkers.length})', 'ALL', _workerStatusFilter, (v) => setState(() => _workerStatusFilter = v)),
              _buildFilterChip('🟢 Inside Site', 'INSIDE', _workerStatusFilter, (v) => setState(() => _workerStatusFilter = v)),
              _buildFilterChip('⚪ Outside', 'OUTSIDE', _workerStatusFilter, (v) => setState(() => _workerStatusFilter = v)),
              _buildFilterChip('⏳ Pending Approval', 'PENDING', _workerStatusFilter, (v) => setState(() => _workerStatusFilter = v)),
              _buildFilterChip('⭐ Cleared Pass', 'CLEARED', _workerStatusFilter, (v) => setState(() => _workerStatusFilter = v)),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // WORKERS LISTING
        if (filtered.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.person_search, color: Colors.white38, size: 40),
                  SizedBox(height: 8),
                  Text('No workers match the selected criteria', style: TextStyle(color: Colors.white54, fontSize: 13)),
                ],
              ),
            ),
          )
        else
          ...filtered.map((emp) => _buildWorkerCard(emp)),
      ],
    );
  }

  Widget _buildFilterChip(String label, String id, String current, Function(String) onSelect) {
    final isSel = current == id;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onSelect(id);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSel ? const Color(0xFF6366F1) : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSel ? const Color(0xFF818CF8) : Colors.white10),
          ),
          child: Text(
            label,
            style: TextStyle(color: isSel ? Colors.white : Colors.white70, fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal),
          ),
        ),
      ),
    );
  }

  // --- WORKER CARD WITH CONNECTED 3-TIER APPROVAL STEPPER ---
  Widget _buildWorkerCard(Map<String, dynamic> emp) {
    final isInside = emp['currently_inside'] == 1;
    final approvals = emp['approvals'] as Map<String, dynamic>? ?? {};

    bool isStageApproved(dynamic val) {
      if (val == null) return false;
      if (val is String) return val.toLowerCase() == 'approved';
      if (val is Map) return val['status']?.toString().toLowerCase() == 'approved';
      return false;
    }

    final adminApproved = isStageApproved(approvals['admin']);
    final safetyApproved = isStageApproved(approvals['safety']);
    final superApproved = isStageApproved(approvals['super_admin']);
    final isFullyCleared = (adminApproved && safetyApproved && superApproved) || emp['status'] == 'Active' || emp['status'] == 'Approved';
    final photo = emp['photo_url'] ?? emp['profile_photo'];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFullyCleared
              ? const Color(0xFF10B981).withValues(alpha: 0.3)
              : const Color(0xFFF59E0B).withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar with Photo Support & Inside Indicator
              Stack(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.2),
                    radius: 20,
                    backgroundImage: photo != null ? NetworkImage(photo) : null,
                    child: photo == null
                        ? Text(
                            (emp['full_name'] ?? 'W')[0].toUpperCase(),
                            style: const TextStyle(color: Color(0xFF818CF8), fontWeight: FontWeight.bold, fontSize: 16),
                          )
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isInside ? const Color(0xFF10B981) : Colors.white38,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF1E293B), width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              // Worker info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            emp['full_name'] ?? 'Worker',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isInside ? const Color(0xFF10B981).withValues(alpha: 0.15) : Colors.white10,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isInside ? 'INSIDE' : 'OUTSIDE',
                            style: TextStyle(color: isInside ? const Color(0xFF10B981) : Colors.white54, fontSize: 9.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${emp['employee_id'] ?? 'EMP'} • ${emp['designation'] ?? 'Technician'} • Aadhaar: ${emp['aadhaar_no'] ?? 'XXXX-XXXX'}',
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 3-TIER APPROVAL STEPPER DISPLAY
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.alt_route, color: Color(0xFF06B6D4), size: 14),
                    SizedBox(width: 6),
                    Text('3-Tier Clearance Routing:', style: TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStepNode('1. Site Admin', adminApproved, !adminApproved),
                    const Icon(Icons.arrow_forward, color: Colors.white24, size: 12),
                    _buildStepNode('2. Safety HSE', safetyApproved, adminApproved && !safetyApproved),
                    const Icon(Icons.arrow_forward, color: Colors.white24, size: 12),
                    _buildStepNode('3. Super Admin', superApproved, safetyApproved && !superApproved),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ACTION BUTTONS: VIEW SMART BADGE, REJECT, OR APPROVE STAGE
          Row(
            children: [
              // Smart Pass Button
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF06B6D4)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _openHologramBadge(emp),
                  icon: const Icon(Icons.qr_code, color: Color(0xFF06B6D4), size: 15),
                  label: const Text('Smart Pass', style: TextStyle(color: Color(0xFF06B6D4), fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),

              // Pending Action Trigger
              if (!adminApproved)
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _approveWorkerStage(emp['id'], 'admin'),
                    icon: const Icon(Icons.verified, color: Colors.white, size: 15),
                    label: const Text('Clear KYC', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                )
              else if (!safetyApproved)
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF97316),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _approveWorkerStage(emp['id'], 'safety'),
                    icon: const Icon(Icons.health_and_safety, color: Colors.white, size: 15),
                    label: const Text('Clear Safety', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                )
              else if (!superApproved)
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _approveWorkerStage(emp['id'], 'super_admin'),
                    icon: const Icon(Icons.badge, color: Colors.white, size: 15),
                    label: const Text('Authorize ID', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                )
              else
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                    ),
                    child: const Center(
                      child: Text('✓ Fully Authorized', style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              const SizedBox(width: 6),
              // Reject / Deactivate button
              IconButton(
                tooltip: 'Reject Clearance / Deactivate',
                icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 20),
                onPressed: () => _rejectWorker(emp['id']),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepNode(String name, bool isDone, bool isCurrent) {
    Color nodeColor = isDone
        ? const Color(0xFF10B981)
        : isCurrent
            ? const Color(0xFFF59E0B)
            : Colors.white38;
    IconData nodeIcon = isDone
        ? Icons.check_circle
        : isCurrent
            ? Icons.pending
            : Icons.radio_button_unchecked;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(nodeIcon, color: nodeColor, size: 13),
        const SizedBox(width: 4),
        Text(name, style: TextStyle(color: nodeColor, fontSize: 10, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  // ==========================================
  // TAB 1: WORK PERMITS (PTW)
  // ==========================================
  Widget _buildPermitsTab() {
    final permits = _selectedVendorDetails?['permits'] as List<dynamic>? ?? [];

    final filtered = permits.where((p) {
      final pNum = (p['permit_number'] ?? '').toString().toLowerCase();
      final pType = (p['permit_type'] ?? '').toString().toLowerCase();
      final pZone = (p['location_zone'] ?? '').toString().toLowerCase();
      final status = (p['status'] ?? '').toString().toLowerCase();

      final matchesSearch = _permitSearch.isEmpty || pNum.contains(_permitSearch.toLowerCase()) || pZone.contains(_permitSearch.toLowerCase());

      bool matchesStatus = true;
      if (_permitStatusFilter == 'PENDING') matchesStatus = status.contains('pending');
      if (_permitStatusFilter == 'APPROVED') matchesStatus = status.contains('approved') || status.contains('active');
      if (_permitStatusFilter == 'EXPIRED') matchesStatus = status.contains('expired') || status.contains('closed');

      bool matchesType = _permitTypeFilter == 'ALL' || pType.contains(_permitTypeFilter.toLowerCase());

      return matchesSearch && matchesStatus && matchesType;
    }).toList();

    return Column(
      children: [
        // PERMIT SEARCH & FILTERS
        Container(
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white10),
          ),
          child: TextField(
            controller: _permitSearchController,
            onChanged: (val) => setState(() => _permitSearch = val),
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search permit # or zone...',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
              prefixIcon: const Icon(Icons.search, color: Color(0xFFF59E0B), size: 18),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // PERMIT STATUS FILTER PILLS
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('All Permits (${permits.length})', 'ALL', _permitStatusFilter, (v) => setState(() => _permitStatusFilter = v)),
              _buildFilterChip('⏳ Pending Review', 'PENDING', _permitStatusFilter, (v) => setState(() => _permitStatusFilter = v)),
              _buildFilterChip('🟢 Active / Approved', 'APPROVED', _permitStatusFilter, (v) => setState(() => _permitStatusFilter = v)),
              _buildFilterChip('🔴 Expired / Closed', 'EXPIRED', _permitStatusFilter, (v) => setState(() => _permitStatusFilter = v)),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // PERMIT TYPE FILTER CHIPS
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['ALL', 'Hot Work', 'Height', 'Confined', 'Electrical'].map((type) {
              final label = type == 'ALL' ? 'All Types' : type;
              return _buildFilterChip(label, type, _permitTypeFilter, (v) => setState(() => _permitTypeFilter = v));
            }).toList(),
          ),
        ),

        const SizedBox(height: 12),

        if (filtered.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('No work permits match filters', style: TextStyle(color: Colors.white54, fontSize: 13)),
            ),
          )
        else
          ...filtered.map((p) {
            final isPending = p['status'].toString().toLowerCase().contains('pending');
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isPending ? const Color(0xFFF59E0B).withValues(alpha: 0.4) : Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(p['permit_number'] ?? 'PTW-2026', style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 13)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isPending ? Colors.amber.withValues(alpha: 0.15) : Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          p['status'] ?? 'Active',
                          style: TextStyle(color: isPending ? Colors.amber : Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(p['permit_type'] ?? 'Work Permit', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(p['location_zone'] ?? 'Main Zone', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  if (p['description'] != null) ...[
                    const SizedBox(height: 4),
                    Text(p['description'], style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                  if (isPending) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => _approvePermit(p['id']),
                          icon: const Icon(Icons.check, size: 14, color: Colors.white),
                          label: const Text('Approve PTW', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.redAccent),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => _rejectPermit(p['id']),
                          icon: const Icon(Icons.close, size: 14, color: Colors.redAccent),
                          label: const Text('Reject', style: TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }),
      ],
    );
  }

  // ==========================================
  // TAB 2: MUSTER ROLL & ATTENDANCE ANALYTICS
  // ==========================================
  Widget _buildMusterTab() {
    final empList = _selectedVendorDetails?['employees'] as List<dynamic>? ?? [];

    // Filter employees by shift and status
    final filteredEmpList = empList.where((e) {
      final shift = (e['shift'] ?? 'General').toString();
      final isInside = e['currently_inside'] == 1;

      bool matchesShift = _attendanceShiftFilter == 'ALL' || shift.toLowerCase().contains(_attendanceShiftFilter.toLowerCase());
      bool matchesStatus = true;
      if (_attendanceStatusFilter == 'Present') matchesStatus = isInside;
      if (_attendanceStatusFilter == 'Completed') matchesStatus = !isInside;

      return matchesShift && matchesStatus;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // PERIOD SELECTOR CHIPS
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _buildPeriodTab('Today Live', 'today'),
              _buildPeriodTab('Week-Wise', 'week'),
              _buildPeriodTab('Month-Wise', 'month'),
              _buildPeriodTab('Year-Wise', 'year'),
              IconButton(
                tooltip: 'Pick Date Range',
                icon: const Icon(Icons.date_range, color: Color(0xFF06B6D4), size: 18),
                onPressed: _pickCustomRange,
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // SHIFT & STATUS FILTER ROW
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('All Shifts', 'ALL', _attendanceShiftFilter, (v) => setState(() => _attendanceShiftFilter = v)),
              _buildFilterChip('Morning Shift', 'Morning', _attendanceShiftFilter, (v) => setState(() => _attendanceShiftFilter = v)),
              _buildFilterChip('General Shift', 'General', _attendanceShiftFilter, (v) => setState(() => _attendanceShiftFilter = v)),
              _buildFilterChip('Night Shift', 'Night', _attendanceShiftFilter, (v) => setState(() => _attendanceShiftFilter = v)),
              const SizedBox(width: 8),
              _buildFilterChip('All Status', 'ALL', _attendanceStatusFilter, (v) => setState(() => _attendanceStatusFilter = v)),
              _buildFilterChip('Present Only', 'Present', _attendanceStatusFilter, (v) => setState(() => _attendanceStatusFilter = v)),
              _buildFilterChip('Completed Shift', 'Completed', _attendanceStatusFilter, (v) => setState(() => _attendanceStatusFilter = v)),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // TELEMETRY BAR CHART
        if (_isAttendanceLoading)
          const Padding(
            padding: EdgeInsets.all(30),
            child: Center(child: CircularProgressIndicator(color: Color(0xFF06B6D4))),
          )
        else
          _buildAttendanceBarChart(),

        const SizedBox(height: 14),

        // DOWNLOAD CSV ACTION BAR
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Turnstile Daily Muster Feed (${filteredEmpList.length})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            InkWell(
              onTap: _downloadAttendanceReport,
              child: const Row(
                children: [
                  Icon(Icons.download, color: Color(0xFF06B6D4), size: 15),
                  SizedBox(width: 4),
                  Text('Download CSV', style: TextStyle(color: Color(0xFF06B6D4), fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // ATTENDANCE LOG LIST
        if (filteredEmpList.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No muster entries match shift / status filter', style: TextStyle(color: Colors.white54, fontSize: 12)),
            ),
          )
        else
          ...filteredEmpList.map((e) {
            final isInside = e['currently_inside'] == 1;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Icon(Icons.access_time_filled, color: isInside ? const Color(0xFF10B981) : Colors.white38, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e['full_name'] ?? 'Worker', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('IN: 08:30 AM • Shift: ${e['shift'] ?? "General"}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                      ],
                    ),
                  ),
                  Text(
                    isInside ? 'Present' : 'Completed',
                    style: TextStyle(color: isInside ? const Color(0xFF10B981) : Colors.white54, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildPeriodTab(String label, String period) {
    final isSel = _attendancePeriod == period;
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          _loadAttendanceAnalytics(period);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSel ? const Color(0xFF06B6D4) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(color: isSel ? Colors.black : Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceBarChart() {
    final breakdown = _attendanceAnalytics?['breakdown'] as List<dynamic>? ?? [
      {'label': 'Mon', 'present': 14, 'percentage': 90},
      {'label': 'Tue', 'present': 15, 'percentage': 95},
      {'label': 'Wed', 'present': 13, 'percentage': 85},
      {'label': 'Thu', 'present': 16, 'percentage': 100},
      {'label': 'Fri', 'present': 14, 'percentage': 90},
      {'label': 'Sat', 'present': 12, 'percentage': 78},
      {'label': 'Sun', 'present': 8, 'percentage': 50},
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_attendancePeriod.toUpperCase()} ATTENDANCE TREND', style: const TextStyle(color: Color(0xFF06B6D4), fontSize: 11, fontWeight: FontWeight.bold)),
              Text('Avg: ${_attendanceAnalytics?['attendance_rate'] ?? 92}%', style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: breakdown.map((item) {
                final pct = ((item['percentage'] ?? 80) as num).toDouble();
                final label = item['label'] ?? '';
                final count = item['present'] ?? 10;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('$count', style: const TextStyle(color: Colors.white54, fontSize: 9)),
                    const SizedBox(height: 4),
                    Container(
                      width: 22,
                      height: math.max(12.0, (pct / 100) * 80),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: pct > 85
                              ? [const Color(0xFF06B6D4), const Color(0xFF10B981)]
                              : [const Color(0xFFF59E0B), const Color(0xFFF97316)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 3: DC & MATERIAL MOVEMENTS
  // ==========================================
  Widget _buildDcTab() {
    final mats = _selectedVendorDetails?['materials'] as List<dynamic>? ?? [];

    final filtered = mats.where((m) {
      final name = (m['material_name'] ?? '').toString().toLowerCase();
      final dc = (m['dc_number'] ?? '').toString().toLowerCase();
      final veh = (m['vehicle_number'] ?? '').toString().toLowerCase();
      final type = (m['movement_type'] ?? '').toString().toLowerCase();

      final matchesSearch = _dcSearch.isEmpty || name.contains(_dcSearch.toLowerCase()) || dc.contains(_dcSearch.toLowerCase()) || veh.contains(_dcSearch.toLowerCase());
      bool matchesType = _dcTypeFilter == 'ALL' || type.contains(_dcTypeFilter.toLowerCase());

      return matchesSearch && matchesType;
    }).toList();

    return Column(
      children: [
        Container(
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white10),
          ),
          child: TextField(
            controller: _dcSearchController,
            onChanged: (val) => setState(() => _dcSearch = val),
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search DC #, vehicle, material...',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF10B981), size: 18),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('All Passes (${mats.length})', 'ALL', _dcTypeFilter, (v) => setState(() => _dcTypeFilter = v)),
              _buildFilterChip('Inward 📥', 'INWARD', _dcTypeFilter, (v) => setState(() => _dcTypeFilter = v)),
              _buildFilterChip('Outward 📤', 'OUTWARD', _dcTypeFilter, (v) => setState(() => _dcTypeFilter = v)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('No material delivery passes found', style: TextStyle(color: Colors.white54, fontSize: 13)),
            ),
          )
        else
          ...filtered.map((m) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(m['dc_number'] ?? 'DC-PASS', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(m['movement_type'] ?? 'INWARD', style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(m['material_name'] ?? 'Material', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('Qty: ${m['quantity']} • Veh: ${m['vehicle_number'] ?? 'KA 04 E 9921'}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              )),
      ],
    );
  }

  // ==========================================
  // TAB 4: SAFETY & FLEET
  // ==========================================
  Widget _buildSafetyTab() {
    final punches = _selectedVendorDetails?['safety_punches'] as List<dynamic>? ?? [];
    final vehicles = _selectedVendorDetails?['vehicles'] as List<dynamic>? ?? [];

    final filteredPunches = punches.where((pch) {
      if (_safetySeverityFilter == 'ALL') return true;
      return (pch['color_type'] ?? '').toString().toUpperCase() == _safetySeverityFilter;
    }).toList();

    final filteredVehicles = vehicles.where((v) {
      if (_vehicleFilter == 'ALL') return true;
      if (_vehicleFilter == 'INSIDE') return v['status'] == 'Inside' || v['status'] == 'Authorized';
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Safety Punches & Observations', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            Row(
              children: ['ALL', 'RED', 'YELLOW', 'GREEN'].map((s) {
                final isSel = _safetySeverityFilter == s;
                return Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: InkWell(
                    onTap: () => setState(() => _safetySeverityFilter = s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSel ? Colors.white24 : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(s, style: TextStyle(color: isSel ? Colors.white : Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (filteredPunches.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('✓ Clean safety record (0 violations)', style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
          )
        else
          ...filteredPunches.map((pch) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '● ${pch['color_type']} PUNCH: ${pch['category'] ?? 'Observation'}',
                      style: TextStyle(
                        color: pch['color_type'] == 'RED' ? Colors.redAccent : (pch['color_type'] == 'YELLOW' ? Colors.amber : Colors.greenAccent),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(pch['reason'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              )),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Registered Contractor Fleet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            Row(
              children: [
                _buildFilterChip('All Fleet', 'ALL', _vehicleFilter, (v) => setState(() => _vehicleFilter = v)),
                _buildFilterChip('Inside', 'INSIDE', _vehicleFilter, (v) => setState(() => _vehicleFilter = v)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...filteredVehicles.map((v) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.local_shipping, color: Color(0xFFA855F7), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(v['vehicle_number'] ?? 'KA 04 E 9921', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('Driver: ${v['driver_name'] ?? 'N/A'}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                      ],
                    ),
                  ),
                  const Text('AUTHORIZED', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            )),
      ],
    );
  }

  // --- CURRENT ACTIVE TAB VIEW DISPATCHER ---
  Widget _buildCurrentTabView() {
    switch (_currentTab) {
      case 0:
        return _buildWorkersTab();
      case 1:
        return _buildPermitsTab();
      case 2:
        return _buildMusterTab();
      case 3:
        return _buildDcTab();
      case 4:
        return _buildSafetyTab();
      default:
        return _buildWorkersTab();
    }
  }
}
