import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/api_service.dart';
import '../utils/validators.dart';
import '../utils/app_theme.dart';
import '../utils/responsive.dart';

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
        SnackBar(content: Text('Permit $permitNumber Approved & Activated!'), backgroundColor: AppTheme.success),
      );
      _fetchPermits();
    }
  }

  void _reject(int id, String permitNumber) async {
    final reasonCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reject Permit $permitNumber', style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: reasonCtrl,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
          decoration: const InputDecoration(
            hintText: 'Reason for rejection (e.g. Inadequate PPE, Fire risk)...',
            hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 12),
            filled: true,
            fillColor: AppTheme.bgSurface,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm Rejection', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final ok = await ApiService.rejectPermit(id, reason: reasonCtrl.text.trim());
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Permit $permitNumber Rejected'), backgroundColor: AppTheme.warning),
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
      backgroundColor: Colors.white,
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
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: AppTheme.badgeDecoration(
                          background: AppTheme.primarySubtle,
                          borderColor: AppTheme.primaryLight,
                          radius: 8,
                        ),
                        child: const Icon(Icons.assignment_rounded, color: AppTheme.primary, size: 22),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          permit['permit_number'] ?? 'PTW Details',
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 12),

            Expanded(
              child: ListView(
                children: [
                  Container(
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
                            Text(permit['permit_type'] ?? '', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: AppTheme.badgeDecoration(
                                background: isApproved ? AppTheme.successBg : AppTheme.warningBg,
                                borderColor: isApproved ? AppTheme.successBorder : AppTheme.warningBorder,
                                radius: 6,
                              ),
                              child: Text(
                                permit['status'] ?? '',
                                style: TextStyle(color: isApproved ? AppTheme.success : AppTheme.warning, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(permit['description'] ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
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
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 8),
                  if (checklist.isEmpty)
                    const Text('Standard PPE & Safety Protocol mandatory on site', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12))
                  else
                    ...checklist.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 16),
                              const SizedBox(width: 8),
                              Expanded(child: Text(item.toString(), style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12))),
                            ],
                          ),
                        )),
                  const SizedBox(height: 16),

                  // Approver / HSE Stamp
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: AppTheme.cardDecoration(
                      color: AppTheme.bgSurface,
                      customBorder: Border.all(color: AppTheme.border),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_rounded, color: AppTheme.primary, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('HSE SAFETY OFFICER ENDORSEMENT', style: TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                              Text(
                                permit['safety_officer_endorsed'] == true ? 'Certified & Approved by Er. Rajesh Varma' : 'Pending HSE On-Site Inspection',
                                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
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
                      color: AppTheme.bgSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      children: [
                        QrImageView(
                          data: permit['permit_number'] ?? 'PTW-2026-001',
                          version: QrVersions.auto,
                          size: 110.0,
                          backgroundColor: Colors.transparent,
                          eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppTheme.textPrimary),
                          dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${permit['permit_number']} • VALIDATED PTW PASS',
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 10.5, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (isPending) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _approve(permit['id'], permit['permit_number'] ?? '');
                      },
                      icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                      label: const Text('APPROVE PTW', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.danger,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _reject(permit['id'], permit['permit_number'] ?? '');
                      },
                      icon: const Icon(Icons.cancel_rounded, color: Colors.white, size: 18),
                      label: const Text('REJECT PTW', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
          Expanded(child: Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12))),
        ],
      ),
    );
  }

  void _openNewPermitModal() {
    final locationCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final applicantCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String permitType = 'Hot Work (Welding/Cutting)';
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: AppTheme.badgeDecoration(
                            background: AppTheme.primarySubtle,
                            borderColor: AppTheme.primaryLight,
                            radius: 8,
                          ),
                          child: const Icon(Icons.assignment_add, color: AppTheme.primary, size: 20),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Apply for Permit to Work (PTW)',
                          style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.bgSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: permitType,
                      isExpanded: true,
                      dropdownColor: Colors.white,
                      style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
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
                _buildTextField(locationCtrl, 'Work Location / Specific Zone *', Icons.location_on_rounded),
                const SizedBox(height: 10),
                _buildTextField(descCtrl, 'Work Description & Scope of Work *', Icons.description_rounded),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildTextField(applicantCtrl, 'Supervisor Name', Icons.person_rounded)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildTextField(phoneCtrl, 'Supervisor Mobile', Icons.phone_rounded, keyboardType: TextInputType.phone)),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            final locErr = FormValidators.validateRequired(locationCtrl.text, fieldName: 'Work location');
                            if (locErr != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(locErr), backgroundColor: AppTheme.warning));
                              return;
                            }

                            final descErr = FormValidators.validateRequired(descCtrl.text, fieldName: 'Work description', minLength: 5);
                            if (descErr != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(descErr), backgroundColor: AppTheme.warning));
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
                                const SnackBar(content: Text('Permit Request Submitted for HSE & Admin Review!'), backgroundColor: AppTheme.success),
                              );
                              _fetchPermits();
                            }
                          },
                    child: isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
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
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
        prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 18),
        filled: true,
        fillColor: AppTheme.bgSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      resizeToAvoidBottomInset: false,
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              leading: const AppBarLeadingButton(),
              title: const Text('Permits to Work (PTW)', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              actions: [
                IconButton(
                  tooltip: 'Refresh',
                  icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary),
                  onPressed: _fetchPermits,
                ),
                const LogoutIconButton(),
              ],
            )
          : null,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Apply for PTW', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        onPressed: _openNewPermitModal,
      ),
      body: ResponsiveBody(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: AppTheme.border)),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search permit number, contractor, zone, type...',
                      hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary, size: 18),
                      suffixIcon: _search.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, color: AppTheme.textSecondary, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _search = '');
                                _fetchPermits();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppTheme.bgSurface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
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
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                  : _permits.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: AppTheme.bgSurface, shape: BoxShape.circle),
                                child: const Icon(Icons.assignment_outlined, size: 40, color: AppTheme.primary),
                              ),
                              const SizedBox(height: 12),
                              const Text('No permits found', style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              const Text('Submit a permit application using the button below', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async => _fetchPermits(),
                          color: AppTheme.primary,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            itemCount: _permits.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, idx) {
                              final p = _permits[idx];
                              final isApproved = p['status'] == 'Approved' || p['status'] == 'Active';
                              final isPending = p['status'].toString().contains('Pending');

                              Color statusColor = isApproved ? AppTheme.success : (isPending ? AppTheme.warning : AppTheme.textSecondary);
                              Color statusBg = isApproved ? AppTheme.successBg : (isPending ? AppTheme.warningBg : AppTheme.bgSurface);
                              Color statusBorder = isApproved ? AppTheme.successBorder : (isPending ? AppTheme.warningBorder : AppTheme.border);

                              return InkWell(
                                onTap: () => _showPermitDetails(p),
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
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
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: AppTheme.badgeDecoration(
                                              background: AppTheme.primarySubtle,
                                              borderColor: AppTheme.primaryLight,
                                              radius: 6,
                                            ),
                                            child: Text(
                                              p['permit_number'] ?? '',
                                              style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 11),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: AppTheme.badgeDecoration(
                                              background: statusBg,
                                              borderColor: statusBorder,
                                              radius: 6,
                                            ),
                                            child: Text(
                                              p['status'] ?? '',
                                              style: TextStyle(
                                                color: statusColor,
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
                                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        p['description'] ?? '',
                                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '📍 ${p['location_zone']} • ${p['vendor_name']}',
                                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textSecondary, size: 12),
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
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? AppTheme.primary : AppTheme.border),
          boxShadow: selected ? AppTheme.softShadow : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            color: selected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
