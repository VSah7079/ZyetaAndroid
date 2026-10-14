import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../utils/validators.dart';
import 'employee_screen.dart';
import 'permit_screen.dart';
import 'gate_passes_hub_screen.dart';
import 'attendance_screen.dart';
import 'safety_officer_screen.dart';

class SiteAdminScreen extends StatefulWidget {
  const SiteAdminScreen({super.key});

  @override
  State<SiteAdminScreen> createState() => _SiteAdminScreenState();
}

class _SiteAdminScreenState extends State<SiteAdminScreen> {
  List<dynamic> _vendors = [];
  int? _selectedVendorId;
  Map<String, dynamic>? _selectedVendorDetails;
  bool _isLoading = true;
  bool _isDetailsLoading = false;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _fetchVendors();
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
    }
  }

  // 1-Click Approve Worker (Admin Clearance)
  void _approveWorker(int empId) async {
    final ok = await ApiService.approveEmployeeStage(empId: empId, stage: 'admin', action: 'Approved');
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✓ Worker passed Admin KYC Clearance! Forwarded to Safety Officer.'), backgroundColor: Colors.green),
      );
      if (_selectedVendorId != null) _fetchVendorDetails(_selectedVendorId!);
      _fetchVendors(_selectedVendorId);
    }
  }

  // 1-Click Reject Worker
  void _rejectWorker(int empId) async {
    final ok = await ApiService.updateEmployee(empId, {'status': 'Deactivated'});
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Worker profile rejected/deactivated'), backgroundColor: Colors.orange),
      );
      if (_selectedVendorId != null) _fetchVendorDetails(_selectedVendorId!);
      _fetchVendors(_selectedVendorId);
    }
  }

  // 1-Click Approve Permit
  void _approvePermit(int permitId) async {
    final ok = await ApiService.approvePermit(permitId);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✓ Permit to Work (PTW) approved!'), backgroundColor: Colors.green),
      );
      if (_selectedVendorId != null) _fetchVendorDetails(_selectedVendorId!);
      _fetchVendors(_selectedVendorId);
    }
  }

  // 1-Click Reject Permit
  void _rejectPermit(int permitId) async {
    final ok = await ApiService.rejectPermit(permitId, reason: 'Safety checklist incomplete');
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permit (PTW) rejected'), backgroundColor: Colors.red),
      );
      if (_selectedVendorId != null) _fetchVendorDetails(_selectedVendorId!);
      _fetchVendors(_selectedVendorId);
    }
  }

  // --- MODAL: ONBOARD CONTRACTOR WITH USERNAME & PASSWORD GENERATION ---
  void _openOnboardVendorModal() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final contactPersonCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final tradeCtrl = TextEditingController(text: 'Civil & Structural');
    final usernameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    bool isSaving = false;

    // Auto generate defaults
    final autoPass = 'Zyeta@${1000 + _vendors.length + 1}';
    passwordCtrl.text = autoPass;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
                        Text('Onboard Contractor & Generate Login', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 14),
                _buildTextField(nameCtrl, 'Company Legal Name *', Icons.business, onChanged: (val) {
                  if (usernameCtrl.text.isEmpty || usernameCtrl.text.startsWith('vendor_')) {
                    final clean = val.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
                    setModalState(() {
                      usernameCtrl.text = 'vendor_${clean.length > 10 ? clean.substring(0, 10) : clean}';
                    });
                  }
                }),
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
                const SizedBox(height: 14),
                const Text('PORTAL USER LOGIN CREDENTIALS', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildTextField(usernameCtrl, 'Generated Username', Icons.account_circle)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTextField(passwordCtrl, 'Generated Password', Icons.lock)),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF06B6D4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                            final result = await ApiService.createVendor({
                              'company_name': nameCtrl.text.trim(),
                              'vendor_code': codeCtrl.text.trim(),
                              'trade_scope': tradeCtrl.text.trim(),
                              'contact_person': contactPersonCtrl.text.trim(),
                              'phone': phoneCtrl.text.trim(),
                              'email': emailCtrl.text.trim(),
                              'username': usernameCtrl.text.trim(),
                              'password': passwordCtrl.text.trim(),
                            });
                            setModalState(() => isSaving = false);

                            if (result != null && mounted) {
                              Navigator.pop(ctx);
                              _showCredentialsDialog(
                                nameCtrl.text.trim(),
                                usernameCtrl.text.trim().isNotEmpty ? usernameCtrl.text.trim() : result['credentials']?['username'] ?? 'vendor_user',
                                passwordCtrl.text.trim().isNotEmpty ? passwordCtrl.text.trim() : result['credentials']?['password'] ?? 'Zyeta@123',
                              );
                              _fetchVendors();
                            }
                          },
                    child: isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('ONBOARD CONTRACTOR & CREATE LOGIN', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- CREDENTIALS POPUP DIALOG ---
  void _showCredentialsDialog(String companyName, String username, String password) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Text('Contractor Login Created!', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vendor Account for "$companyName" is active. Share these credentials for Vendor Self-Service Portal access:', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.3))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Username:', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      Text(username, style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Password:', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      Text(password, style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: 'Username: $username\nPassword: $password'));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Credentials copied to clipboard!'), backgroundColor: Colors.green));
            },
            icon: const Icon(Icons.copy, size: 16, color: Color(0xFF38BDF8)),
            label: const Text('Copy', style: TextStyle(color: Color(0xFF38BDF8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF06B6D4)),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- MODAL: ENROLL WORKER ---
  void _openAddWorkerModal() {
    if (_selectedVendorId == null) return;
    final nameCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final roleCtrl = TextEditingController(text: 'Technician');
    final aadhaarCtrl = TextEditingController();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
                        Icon(Icons.person_add, color: Color(0xFF6366F1)),
                        SizedBox(width: 8),
                        Text('Enroll Worker for Contractor', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 14),
                _buildTextField(nameCtrl, 'Worker Full Name *', Icons.person),
                const SizedBox(height: 10),
                _buildTextField(mobileCtrl, 'Mobile Number *', Icons.phone, keyboardType: TextInputType.phone),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildTextField(roleCtrl, 'Designation / Role', Icons.badge)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTextField(aadhaarCtrl, 'Aadhaar / ID No.', Icons.credit_card)),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (nameCtrl.text.trim().isEmpty || mobileCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill Name and Mobile'), backgroundColor: Colors.orange));
                              return;
                            }
                            setModalState(() => isSaving = true);
                            final ok = await ApiService.createEmployee({
                              'full_name': nameCtrl.text.trim(),
                              'mobile': mobileCtrl.text.trim(),
                              'designation': roleCtrl.text.trim(),
                              'aadhaar_no': aadhaarCtrl.text.trim(),
                              'vendor_id': _selectedVendorId,
                              'vendor_name': _selectedVendorDetails?['company_name'] ?? 'Contractor',
                            });
                            setModalState(() => isSaving = false);
                            if (ok && mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Worker enrolled & pass issued!'), backgroundColor: Colors.green));
                              _fetchVendorDetails(_selectedVendorId!);
                            }
                          },
                    child: isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('ENROLL WORKER & ISSUE BADGE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- MODAL: ISSUE PTW ---
  void _openIssuePermitModal() {
    final typeCtrl = TextEditingController(text: 'Hot Work (Welding/Cutting)');
    final descCtrl = TextEditingController();
    final zoneCtrl = TextEditingController(text: 'Block A - 4th Floor AHU Plant');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
                        Icon(Icons.local_fire_department, color: Color(0xFFF59E0B)),
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
                _buildTextField(descCtrl, 'Work Scope & Safety Measures *', Icons.description),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (descCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please describe the work permit scope'), backgroundColor: Colors.orange));
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
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permit (PTW) submitted for review!'), backgroundColor: Colors.green));
                              if (_selectedVendorId != null) _fetchVendorDetails(_selectedVendorId!);
                            }
                          },
                    child: isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('ISSUE WORK PERMIT (PTW)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- MODAL: CREATE MATERIAL DC ENTRY ---
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
                        Icon(Icons.inventory_2, color: Color(0xFF10B981)),
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
                    Expanded(child: _buildTextField(qtyCtrl, 'Quantity', Icons.numbers, keyboardType: TextInputType.number)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTextField(vehCtrl, 'Vehicle Number', Icons.local_shipping)),
                  ],
                ),
                const SizedBox(height: 10),
                _buildTextField(driverCtrl, 'Driver Name', Icons.person),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (matCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter material description'), backgroundColor: Colors.orange));
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
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Material DC created successfully!'), backgroundColor: Colors.green));
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

  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon, {TextInputType? keyboardType, ValueChanged<String>? onChanged}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      onChanged: onChanged,
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

  @override
  Widget build(BuildContext context) {
    final stats = _selectedVendorDetails?['stats'] ?? {};
    final todayManpower = stats['today_manpower'] ?? 0;
    final yesterdayManpower = stats['yesterday_manpower'] ?? 0;
    final totalWorkers = stats['total_employees'] ?? 0;
    final pendingApprovals = stats['pending_employee_approvals'] ?? 0;
    final activePermits = stats['active_permits'] ?? 0;
    final pendingPermits = stats['pending_permits'] ?? 0;
    final totalDc = stats['total_dc_entries'] ?? 0;

    final manpowerDelta = (todayManpower as int) - (yesterdayManpower as int);
    final isDeltaUp = manpowerDelta >= 0;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Text('Site Admin: Contractor Hub', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () => _fetchVendors(_selectedVendorId),
          ),
          const LogoutIconButton(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF06B6D4),
        icon: const Icon(Icons.add_business, color: Colors.white),
        label: const Text('New Contractor', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        onPressed: _openOnboardVendorModal,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF06B6D4)))
          : _vendors.isEmpty
              ? const Center(child: Text('No registered contractors', style: TextStyle(color: Colors.white54)))
              : Column(
                  children: [
                    // TOP CONTRACTOR DROPDOWN SELECTOR
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      color: const Color(0xFF0F172A),
                      child: Row(
                        children: [
                          const Icon(Icons.business, color: Color(0xFF06B6D4), size: 20),
                          const SizedBox(width: 8),
                          const Text('Contractor:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.3)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: _selectedVendorId,
                                  dropdownColor: const Color(0xFF1E293B),
                                  isExpanded: true,
                                  style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 14),
                                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF38BDF8)),
                                  items: _vendors.map<DropdownMenuItem<int>>((v) {
                                    return DropdownMenuItem<int>(
                                      value: v['id'] as int,
                                      child: Text(
                                        '${v['company_name']} (${v['vendor_id'] ?? v['vendor_code'] ?? 'VND'})',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (newId) {
                                    if (newId != null) {
                                      setState(() => _selectedVendorId = newId);
                                      _fetchVendorDetails(newId);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: _isDetailsLoading
                          ? const Center(child: CircularProgressIndicator(color: Color(0xFF06B6D4)))
                          : ListView(
                              padding: const EdgeInsets.all(14),
                              children: [
                                // CONTRACTOR PROFILE HEADER CARD
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E293B),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.white10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _selectedVendorDetails?['company_name'] ?? 'Contractor',
                                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                                            ),
                                            child: const Text('ACTIVE', style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Rep: ${_selectedVendorDetails?['owner_name'] ?? _selectedVendorDetails?['contact_person'] ?? 'N/A'} • ${_selectedVendorDetails?['phone'] ?? 'N/A'}',
                                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'GSTIN: ${_selectedVendorDetails?['gst_pan'] ?? _selectedVendorDetails?['gstin'] ?? '29ABCDE1234F1Z5'}',
                                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                                      ),
                                      const SizedBox(height: 12),
                                      // ACTION SHORTCUT BUTTONS
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          _buildActionBtn('Add Worker', Icons.person_add, const Color(0xFF6366F1), _openAddWorkerModal),
                                          _buildActionBtn('Issue PTW', Icons.local_fire_department, const Color(0xFFF59E0B), _openIssuePermitModal),
                                          _buildActionBtn('Material DC', Icons.inventory_2, const Color(0xFF10B981), _openCreateMaterialModal),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 14),

                                // MANPOWER & KPI METRICS GRID
                                Row(
                                  children: [
                                    // TODAY MANPOWER
                                    Expanded(
                                      child: _buildMetricCard(
                                        'Today Manpower',
                                        '$todayManpower',
                                        isDeltaUp ? '+$manpowerDelta vs y\'day' : '$manpowerDelta vs y\'day',
                                        const Color(0xFF06B6D4),
                                        Icons.access_time_filled,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    // YESTERDAY MANPOWER
                                    Expanded(
                                      child: _buildMetricCard(
                                        'Y\'day Manpower',
                                        '$yesterdayManpower',
                                        'Previous muster',
                                        Colors.blueGrey,
                                        Icons.calendar_today,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildMetricCard(
                                        'Total Workforce',
                                        '$totalWorkers',
                                        'Registered',
                                        const Color(0xFF818CF8),
                                        Icons.people,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _buildMetricCard(
                                        'Worker Approvals',
                                        '$pendingApprovals',
                                        pendingApprovals > 0 ? 'Pending review' : 'All approved',
                                        pendingApprovals > 0 ? const Color(0xFFF59E0B) : Colors.white54,
                                        Icons.how_to_reg,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildMetricCard(
                                        'Active PTWs',
                                        '$activePermits',
                                        pendingPermits > 0 ? '$pendingPermits pending' : 'Valid permits',
                                        const Color(0xFFF97316),
                                        Icons.assignment,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _buildMetricCard(
                                        'Total DC Passes',
                                        '$totalDc',
                                        'Inward / Out',
                                        const Color(0xFF10B981),
                                        Icons.local_shipping,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 18),

                                // INTERCONNECTED MODULE SHORTCUTS
                                const Text('INTERCONNECTED SITE MODULES', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      _buildDeepLinkChip('👷 Workforce Hub', const Color(0xFF6366F1), () {
                                        Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeeScreen()));
                                      }),
                                      _buildDeepLinkChip('📋 PTW Hub', const Color(0xFFF59E0B), () {
                                        Navigator.push(context, MaterialPageRoute(builder: (_) => const PermitScreen()));
                                      }),
                                      _buildDeepLinkChip('🚪 Gate Passes', const Color(0xFF10B981), () {
                                        Navigator.push(context, MaterialPageRoute(builder: (_) => const GatePassesHubScreen()));
                                      }),
                                      _buildDeepLinkChip('📊 Attendance', const Color(0xFF06B6D4), () {
                                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceScreen()));
                                      }),
                                      _buildDeepLinkChip('⛑️ HSE Safety', const Color(0xFFEF4444), () {
                                        Navigator.push(context, MaterialPageRoute(builder: (_) => const SafetyOfficerScreen()));
                                      }),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // SEGMENTED TAB SELECTOR
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      _buildSegmentTab(0, 'Workers & Approvals', Icons.people, pendingApprovals),
                                      _buildSegmentTab(1, 'PTW Permits', Icons.local_fire_department, pendingPermits),
                                      _buildSegmentTab(2, 'Live Muster', Icons.access_time, 0),
                                      _buildSegmentTab(3, 'DC Movements', Icons.inventory_2, 0),
                                      _buildSegmentTab(4, 'Safety & Vehicles', Icons.shield, 0),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // TAB DETAILS VIEW
                                _buildCurrentTabView(),
                              ],
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildDeepLinkChip(String label, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ActionChip(
        backgroundColor: color.withValues(alpha: 0.15),
        side: BorderSide(color: color.withValues(alpha: 0.4)),
        label: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildMetricCard(String label, String val, String sub, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
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
              Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
              Icon(icon, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 4),
          Text(val, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          Text(sub, style: const TextStyle(color: Colors.white38, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildSegmentTab(int index, String title, IconData icon, int badgeCount) {
    final isSelected = _currentTab == index;
    return InkWell(
      onTap: () => setState(() => _currentTab = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF06B6D4).withValues(alpha: 0.2) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? const Color(0xFF06B6D4) : Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF06B6D4) : Colors.white54, size: 15),
            const SizedBox(width: 6),
            Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            if (badgeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(color: const Color(0xFFF59E0B), borderRadius: BorderRadius.circular(10)),
                child: Text('$badgeCount', style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTabView() {
    if (_currentTab == 0) {
      // TAB 0: WORKERS & PENDING APPROVALS
      final pendingList = _selectedVendorDetails?['pending_employees'] as List<dynamic>? ?? [];
      final empList = _selectedVendorDetails?['employees'] as List<dynamic>? ?? [];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pendingList.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pending Approvals Queue', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...pendingList.map((emp) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(emp['full_name'] ?? 'Worker', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text('${emp['employee_id'] ?? ''} • ${emp['designation'] ?? 'Technician'}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.check_circle, color: Colors.greenAccent),
                              onPressed: () => _approveWorker(emp['id']),
                              tooltip: 'Approve',
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.redAccent),
                              onPressed: () => _rejectWorker(emp['id']),
                              tooltip: 'Reject',
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ],
          ...empList.map((emp) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.2),
                      child: const Icon(Icons.person, color: Color(0xFF6366F1)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(emp['full_name'] ?? 'Worker', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('${emp['employee_id'] ?? ''} • ${emp['designation'] ?? ''}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: emp['currently_inside'] == 1 ? Colors.green.withValues(alpha: 0.15) : Colors.white10,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        emp['currently_inside'] == 1 ? 'INSIDE' : 'OUTSIDE',
                        style: TextStyle(color: emp['currently_inside'] == 1 ? Colors.greenAccent : Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      );
    } else if (_currentTab == 1) {
      // TAB 1: PERMITS TO WORK (PTW) & APPROVALS
      final permits = _selectedVendorDetails?['permits'] as List<dynamic>? ?? [];
      if (permits.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No permits found', style: TextStyle(color: Colors.white54))));

      return Column(
        children: permits.map((p) {
          final isPending = p['status'].toString().toLowerCase().contains('pending');
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(p['permit_number'] ?? 'PTW', style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(p['status'] ?? 'Active', style: TextStyle(color: isPending ? Colors.amber : Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(p['permit_type'] ?? 'Work Permit', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Text(p['location_zone'] ?? 'Main Zone', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                if (isPending) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                        onPressed: () => _approvePermit(p['id']),
                        icon: const Icon(Icons.check, size: 14, color: Colors.white),
                        label: const Text('Approve', style: TextStyle(fontSize: 11, color: Colors.white)),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                        onPressed: () => _rejectPermit(p['id']),
                        icon: const Icon(Icons.close, size: 14, color: Colors.redAccent),
                        label: const Text('Reject', style: TextStyle(fontSize: 11, color: Colors.redAccent)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      );
    } else if (_currentTab == 2) {
      // TAB 2: LIVE ATTENDANCE MUSTER
      final empList = _selectedVendorDetails?['employees'] as List<dynamic>? ?? [];
      return Column(
        children: empList.map((e) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: Color(0xFF06B6D4), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e['full_name'] ?? 'Worker', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('In: 08:45 AM • Gate 1', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                      ],
                    ),
                  ),
                  Text(e['currently_inside'] == 1 ? 'Present (Inside)' : 'Completed', style: TextStyle(color: e['currently_inside'] == 1 ? Colors.greenAccent : Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            )).toList(),
      );
    } else if (_currentTab == 3) {
      // TAB 3: DC & MATERIAL ENTRIES
      final mats = _selectedVendorDetails?['materials'] as List<dynamic>? ?? [];
      return Column(
        children: mats.map((m) => Container(
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
                  Text('Qty: ${m['quantity']} • Veh: ${m['vehicle_number'] ?? 'N/A'}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            )).toList(),
      );
    } else {
      // TAB 4: SAFETY & FLEET
      final punches = _selectedVendorDetails?['safety_punches'] as List<dynamic>? ?? [];
      final vehicles = _selectedVendorDetails?['vehicles'] as List<dynamic>? ?? [];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Safety Punches & Observations', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          if (punches.isEmpty)
            const Text('Clean safety record (0 violations)', style: TextStyle(color: Colors.greenAccent, fontSize: 12))
          else
            ...punches.map((pch) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('● ${pch['color_type']} PUNCH: ${pch['category'] ?? 'Observation'}', style: TextStyle(color: pch['color_type'] == 'RED' ? Colors.redAccent : Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(pch['reason'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                )),
          const SizedBox(height: 14),
          const Text('Registered Fleet Vehicles', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          ...vehicles.map((v) => Container(
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
  }
}
