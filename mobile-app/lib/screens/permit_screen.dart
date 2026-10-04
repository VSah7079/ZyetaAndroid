import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/api_service.dart';
import '../utils/validators.dart';

class PermitScreen extends StatefulWidget {
  final bool showAppBar;
  const PermitScreen({super.key, this.showAppBar = true});

  @override
  State<PermitScreen> createState() => _PermitScreenState();
}

class _PermitScreenState extends State<PermitScreen> {
  List<dynamic> _permits = [];
  bool _isLoading = true;
  String _filter = 'ALL';
  String _search = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPermits();
  }

  void _fetchPermits() async {
    setState(() => _isLoading = true);
    final status = _filter == 'ALL' ? null : _filter;
    final list = await ApiService.getPermits(
      status: status,
      search: _search.isNotEmpty ? _search : null,
    );
    if (mounted) {
      setState(() {
        _permits = list;
        _isLoading = false;
      });
    }
  }

  void _approve(int id, String permitNumber) async {
    final ok = await ApiService.approvePermit(id);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Permit $permitNumber Approved & Activated!'), backgroundColor: Colors.green),
      );
      _fetchPermits();
    }
  }

  void _reject(int id, String permitNumber) async {
    final reasonCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('Reject Permit $permitNumber', style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: reasonCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Reason for rejection (e.g. Inadequate PPE, Fire risk)...',
            hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
            filled: true,
            fillColor: Color(0xFF0F172A),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF43F5E)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm Rejection', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final ok = await ApiService.rejectPermit(id, reason: reasonCtrl.text.trim());
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Permit $permitNumber Rejected'), backgroundColor: Colors.orange),
        );
        _fetchPermits();
      }
    }
  }

  void _showPermitDetails(Map<String, dynamic> permit) {
    final isPending = permit['status'].toString().contains('Pending');
    final isApproved = permit['status'] == 'Approved' || permit['status'] == 'Active';
    final checklist = (permit['safety_checklist'] as List<dynamic>?) ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.85,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.assignment, color: Color(0xFF6366F1), size: 24),
                    const SizedBox(width: 8),
                    Text(
                      permit['permit_number'] ?? 'PTW Details',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 12),

            Expanded(
              child: ListView(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(permit['permit_type'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isApproved ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                permit['status'] ?? '',
                                style: TextStyle(color: isApproved ? Colors.greenAccent : Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(permit['description'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 10),
                        _buildPermitField('📍 Work Location', permit['location_zone'] ?? 'N/A'),
                        _buildPermitField('🏢 Contractor', permit['vendor_name'] ?? 'Direct'),
                        _buildPermitField('👤 Supervisor / Lead', '${permit['applicant_name']} (${permit['applicant_contact']})'),
                        _buildPermitField('⏱️ Validity Time Window', 'Today 09:00 - 18:00 (Standard Shift)'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'MANDATORY SAFETY HAZARD CONTROLS (HSE)',
                    style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 8),
                  if (checklist.isEmpty)
                    const Text('Standard PPE & Safety Protocol mandatory on site', style: TextStyle(color: Colors.white70, fontSize: 12))
                  else
                    ...checklist.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 16),
                              const SizedBox(width: 8),
                              Expanded(child: Text(item.toString(), style: const TextStyle(color: Colors.white70, fontSize: 12))),
                            ],
                          ),
                        )),
                  const SizedBox(height: 16),

                  // Approver / HSE Stamp
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        const Icon(Icons.verified, color: Color(0xFF06B6D4), size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('HSE SAFETY OFFICER ENDORSEMENT', style: TextStyle(color: Color(0xFF06B6D4), fontSize: 10, fontWeight: FontWeight.bold)),
                              Text(
                                permit['safety_officer_endorsed'] == true ? 'Certified & Approved by Er. Rajesh Varma' : 'Pending HSE On-Site Inspection',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8)],
                    ),
                    child: Column(
                      children: [
                        QrImageView(
                          data: permit['permit_number'] ?? 'PTW-2026-001',
                          version: QrVersions.auto,
                          size: 110.0,
                          backgroundColor: Colors.white,
                          eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                          dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${permit['permit_number']} • VALIDATED PTW PASS',
                          style: const TextStyle(color: Colors.black87, fontSize: 10.5, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (isPending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _reject(permit['id'], permit['permit_number'] ?? '');
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('REJECT', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _approve(permit['id'], permit['permit_number'] ?? '');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('APPROVE PTW', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPermitField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11))),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  // --- SECTION 12 PERMIT APPLICATION MODAL ---
  void _openNewPermitModal() {
    final descCtrl = TextEditingController();
    final locationCtrl = TextEditingController(text: 'Block A - Floor 4 AHU Plant');
    final applicantCtrl = TextEditingController(text: ApiService.currentUser?.fullName ?? 'Supervisor');
    final phoneCtrl = TextEditingController(text: ApiService.currentUser?.phone ?? '+91 9900112233');

    String permitType = 'Hot Work (Welding/Cutting)';
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
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
                    const Row(
                      children: [
                        Icon(Icons.assignment_add, color: Color(0xFF6366F1)),
                        SizedBox(width: 8),
                        Text('Apply for Work Permit (Section 12)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 14),

                const Text('PERMIT CATEGORY (PRD 12.0)', style: TextStyle(color: Color(0xFF6366F1), fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(10)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: permitType,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1E293B),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      items: const [
                        DropdownMenuItem(value: 'Hot Work (Welding/Cutting)', child: Text('🔥 Hot Work Permit (Welding/Cutting)')),
                        DropdownMenuItem(value: 'Height Work (> 1.8m)', child: Text('🪜 Height Work Permit (> 1.8m)')),
                        DropdownMenuItem(value: 'Electrical Isolation (LOTO)', child: Text('⚡ Electrical Isolation (LOTO)')),
                        DropdownMenuItem(value: 'Confined Space Entry', child: Text('🕳️ Confined Space Entry Permit')),
                        DropdownMenuItem(value: 'Excavation & Trenching', child: Text('⛏️ Excavation & Trenching Permit')),
                        DropdownMenuItem(value: 'Material Movement Permit', child: Text('📦 Material Movement Permit')),
                        DropdownMenuItem(value: 'Vehicle Entry Permit', child: Text('🚗 Vehicle Site Access Permit')),
                        DropdownMenuItem(value: 'General Contractor Work', child: Text('🛠️ General Work Permit')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => permitType = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _buildTextField(locationCtrl, 'Work Location / Specific Zone *', Icons.location_on),
                const SizedBox(height: 10),
                _buildTextField(descCtrl, 'Work Description & Scope of Work *', Icons.description),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildTextField(applicantCtrl, 'Supervisor Name', Icons.person)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildTextField(phoneCtrl, 'Supervisor Mobile', Icons.phone, keyboardType: TextInputType.phone)),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            final locErr = FormValidators.validateRequired(locationCtrl.text, fieldName: 'Work location');
                            if (locErr != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(locErr), backgroundColor: Colors.orange));
                              return;
                            }

                            final descErr = FormValidators.validateRequired(descCtrl.text, fieldName: 'Work description', minLength: 5);
                            if (descErr != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(descErr), backgroundColor: Colors.orange));
                              return;
                            }

                            setModalState(() => isSaving = true);
                            final ok = await ApiService.createPermit({
                              'permit_type': permitType,
                              'description': descCtrl.text.trim(),
                              'location_zone': locationCtrl.text.trim(),
                              'applicant_name': applicantCtrl.text.trim().isEmpty ? 'Supervisor' : applicantCtrl.text.trim(),
                              'applicant_contact': phoneCtrl.text.trim(),
                            });
                            setModalState(() => isSaving = false);
                            if (ok && mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Permit Request Submitted for HSE & Admin Review!'), backgroundColor: Colors.green),
                              );
                              _fetchPermits();
                            }
                          },
                    child: isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('SUBMIT PERMIT REQUEST', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon, {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
        prefixIcon: Icon(icon, color: Colors.white54, size: 18),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: const Color(0xFF0F172A),
              elevation: 0,
              title: const Text('Permits to Work (PTW)', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white70),
                  onPressed: _fetchPermits,
                ),
              ],
            )
          : null,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Apply for PTW', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        onPressed: _openNewPermitModal,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF0F172A),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search permit number, contractor, zone, type...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white54),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _search = '');
                              _fetchPermits();
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
                    _fetchPermits();
                  },
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('ALL', 'All Permits (5)'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Pending', 'Pending Review (2)'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Approved', 'Approved (2)'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Active', 'Active (1)'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                : _permits.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.assignment_outlined, size: 50, color: Colors.white24),
                            const SizedBox(height: 10),
                            const Text('No permits found', style: TextStyle(color: Colors.white54)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => _fetchPermits(),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(14),
                          itemCount: _permits.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, idx) {
                            final p = _permits[idx];
                            final isApproved = p['status'] == 'Approved' || p['status'] == 'Active';
                            final isPending = p['status'].toString().contains('Pending');

                            return InkWell(
                              onTap: () => _showPermitDetails(p),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isPending
                                        ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
                                        : isApproved
                                            ? Colors.green.withValues(alpha: 0.3)
                                            : Colors.white10,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0F172A),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.4)),
                                          ),
                                          child: Text(
                                            p['permit_number'] ?? '',
                                            style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold, fontSize: 11),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isApproved ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            p['status'] ?? '',
                                            style: TextStyle(
                                              color: isApproved ? Colors.greenAccent : Colors.orangeAccent,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      p['permit_type'] ?? '',
                                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      p['description'] ?? '',
                                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '📍 ${p['location_zone']} • ${p['vendor_name']}',
                                            style: const TextStyle(color: Colors.white54, fontSize: 11),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 12),
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

  Widget _buildFilterChip(String key, String label) {
    final selected = _filter == key;
    return InkWell(
      onTap: () {
        setState(() => _filter = key);
        _fetchPermits();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF6366F1) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: selected ? Colors.white : Colors.white70,
          ),
        ),
      ),
    );
  }
}
