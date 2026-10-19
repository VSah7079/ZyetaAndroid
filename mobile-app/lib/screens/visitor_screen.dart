import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/api_service.dart';
import '../utils/validators.dart';
import '../utils/app_theme.dart';
import '../utils/responsive.dart';

class VisitorScreen extends StatefulWidget {
  final bool showAppBar;
  const VisitorScreen({super.key, this.showAppBar = true});

  @override
  State<VisitorScreen> createState() => _VisitorScreenState();
}

class _VisitorScreenState extends State<VisitorScreen> {
  List<dynamic> _visitors = [];
  bool _isLoading = true;
  String _filter = 'ALL';
  String _search = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchVisitors();
  }

  void _fetchVisitors() async {
    setState(() => _isLoading = true);
    final status = _filter == 'ALL' ? null : _filter;
    final list = await ApiService.getVisitors(
      status: status,
      search: _search.isNotEmpty ? _search : null,
    );
    if (mounted) {
      setState(() {
        _visitors = list;
        _isLoading = false;
      });
    }
  }

  void _showVisitorQRPass(Map<String, dynamic> v) {
    final passCode = v['pass_code'] ?? v['pass_number'] ?? 'VIS-8801';
    final isInside = (v['status'] ?? '').toString().toLowerCase() == 'inside';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          width: MediaQuery.of(ctx).size.width.clamp(280.0, 360.0),
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.cardDecoration(
            borderRadius: BorderRadius.circular(20),
            shadow: AppTheme.mediumShadow,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: AppTheme.badgeDecoration(
                              background: AppTheme.primarySubtle,
                              borderColor: AppTheme.primaryLight,
                              radius: 8,
                            ),
                            child: const Icon(Icons.badge_rounded, color: AppTheme.primary, size: 18),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'VISITOR GATE PASS',
                              style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: AppTheme.badgeDecoration(
                        background: isInside ? AppTheme.successBg : AppTheme.primarySubtle,
                        borderColor: isInside ? AppTheme.successBorder : AppTheme.primaryLight,
                        radius: 6,
                      ),
                      child: Text(
                        isInside ? '● INSIDE' : 'APPROVED',
                        style: TextStyle(
                          color: isInside ? AppTheme.success : AppTheme.primary,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: 60,
                  height: 60,
                  decoration: AppTheme.badgeDecoration(
                    background: AppTheme.primarySubtle,
                    borderColor: AppTheme.primaryLight,
                    radius: 30,
                  ),
                  child: const Icon(Icons.person_rounded, color: AppTheme.primary, size: 32),
                ),
                const SizedBox(height: 10),
                Text(
                  v['visitor_name'] ?? 'Visitor',
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${v['company'] ?? 'Individual'} • Host: ${v['person_to_meet'] ?? v['host_name'] ?? 'Admin'}',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
                        data: passCode,
                        version: QrVersions.auto,
                        size: 120.0,
                        backgroundColor: Colors.transparent,
                        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppTheme.textPrimary),
                        dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        passCode,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Scan at Security Kiosk / Turnstile for Entry & Exit',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 10.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Close Pass', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _checkout(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Checkout Visitor', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        content: Text('Mark exit for $name?', style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm Exit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    final success = await ApiService.checkoutVisitor(id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✓ Visitor checked out successfully!'), backgroundColor: AppTheme.success),
      );
      _fetchVisitors();
    }
  }

  void _openNewVisitorModal() {
    final nameCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final companyCtrl = TextEditingController();
    final hostCtrl = TextEditingController();
    final purposeCtrl = TextEditingController();
    final vehicleCtrl = TextEditingController();
    final idProofCtrl = TextEditingController();
    bool instantEntry = true;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
                          child: const Icon(Icons.person_add_alt_1_rounded, color: AppTheme.primary, size: 20),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Issue New Visitor Pass',
                          style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 14),
                _buildTextField(nameCtrl, 'Visitor Full Name *', Icons.person_rounded),
                const SizedBox(height: 10),
                _buildTextField(mobileCtrl, 'Mobile Number *', Icons.phone_rounded, keyboardType: TextInputType.phone),
                const SizedBox(height: 10),
                _buildTextField(companyCtrl, 'Company / Organization', Icons.business_rounded),
                const SizedBox(height: 10),
                _buildTextField(hostCtrl, 'Person to Meet (Host) *', Icons.badge_rounded),
                const SizedBox(height: 10),
                _buildTextField(purposeCtrl, 'Purpose of Visit', Icons.notes_rounded),
                const SizedBox(height: 10),
                _buildTextField(vehicleCtrl, 'Vehicle Number (Optional)', Icons.directions_car_rounded),
                const SizedBox(height: 10),
                _buildTextField(idProofCtrl, 'Govt ID Proof No. (Optional)', Icons.credit_card_rounded),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => setModalState(() => instantEntry = !instantEntry),
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      Checkbox(
                        value: instantEntry,
                        activeColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        onChanged: (val) => setModalState(() => instantEntry = val ?? true),
                      ),
                      const SizedBox(width: 4),
                      const Expanded(
                        child: Text(
                          'Mark Entry Immediately (Instant Gate Check-in)',
                          style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
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
                            final nameErr = FormValidators.validateName(nameCtrl.text, fieldName: 'Visitor name');
                            if (nameErr != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(nameErr), backgroundColor: AppTheme.warning));
                              return;
                            }

                            final mobileErr = FormValidators.validatePhone(mobileCtrl.text, fieldName: 'Visitor mobile');
                            if (mobileErr != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mobileErr), backgroundColor: AppTheme.warning));
                              return;
                            }

                            final hostErr = FormValidators.validateName(hostCtrl.text, fieldName: 'Person to meet (Host)');
                            if (hostErr != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(hostErr), backgroundColor: AppTheme.warning));
                              return;
                            }

                            final vehErr = FormValidators.validateVehicleNumber(vehicleCtrl.text, isRequired: false);
                            if (vehErr != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(vehErr), backgroundColor: AppTheme.warning));
                              return;
                            }

                            setModalState(() => isSaving = true);
                            final payload = {
                              'visitor_name': nameCtrl.text.trim(),
                              'mobile': mobileCtrl.text.trim(),
                              'company': companyCtrl.text.trim().isEmpty ? 'Guest' : companyCtrl.text.trim(),
                              'person_to_meet': hostCtrl.text.trim(),
                              'purpose': purposeCtrl.text.trim().isEmpty ? 'Meeting' : purposeCtrl.text.trim(),
                              'vehicle_number': vehicleCtrl.text.trim().toUpperCase(),
                              'id_proof_number': idProofCtrl.text.trim(),
                              'instant_entry': instantEntry,
                            };
                            final success = await ApiService.registerVisitor(payload);
                            setModalState(() => isSaving = false);
                            if (success && mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('✓ Visitor Pass Issued Successfully!'), backgroundColor: AppTheme.success),
                              );
                              _fetchVisitors();
                            } else if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Failed to issue pass'), backgroundColor: AppTheme.danger),
                              );
                            }
                          },
                    child: isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('GENERATE PASS & CHECK-IN', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
              title: const Text('Visitor Pass Management', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              actions: [
                IconButton(
                  tooltip: 'Refresh',
                  icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary),
                  onPressed: _fetchVisitors,
                ),
                const LogoutIconButton(),
              ],
            )
          : null,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Visitor Pass', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        onPressed: _openNewVisitorModal,
      ),
      body: ResponsiveBody(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            // Filter Chips & Search Bar
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
                      hintText: 'Search visitor name, pass code, host...',
                      hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary, size: 18),
                      suffixIcon: _search.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, color: AppTheme.textSecondary, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _search = '');
                                _fetchVisitors();
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
                      _fetchVisitors();
                    },
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('ALL', 'All Visitors'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Inside', 'Currently Inside'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Pre-Registered', 'Pre-Registered'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Exited', 'Exited'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Visitor List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                  : _visitors.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: AppTheme.bgSurface, shape: BoxShape.circle),
                                child: const Icon(Icons.people_outline_rounded, size: 40, color: AppTheme.primary),
                              ),
                              const SizedBox(height: 12),
                              const Text('No visitors found', style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              const Text('Register a visitor pass using the button below', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async => _fetchVisitors(),
                          color: AppTheme.primary,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            itemCount: _visitors.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, idx) {
                              final v = _visitors[idx];
                              final isInside = (v['status'] ?? '').toString().toLowerCase() == 'inside';
                              final isExited = (v['status'] ?? '').toString().toLowerCase() == 'exited';

                              Color statusColor = isInside
                                  ? AppTheme.success
                                  : isExited
                                      ? AppTheme.textMuted
                                      : AppTheme.primary;

                              Color statusBg = isInside
                                  ? AppTheme.successBg
                                  : isExited
                                      ? AppTheme.bgSurface
                                      : AppTheme.primarySubtle;

                              Color statusBorder = isInside
                                  ? AppTheme.successBorder
                                  : isExited
                                      ? AppTheme.border
                                      : AppTheme.primaryLight;

                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: AppTheme.cardDecoration(
                                  customBorder: Border.all(color: AppTheme.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: AppTheme.badgeDecoration(
                                            background: statusBg,
                                            borderColor: statusBorder,
                                            radius: 12,
                                          ),
                                          child: Icon(Icons.person_rounded, color: statusColor, size: 24),
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
                                                      v['visitor_name'] ?? '',
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary),
                                                      overflow: TextOverflow.ellipsis,
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
                                                      v['status'] ?? 'Active',
                                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                '${v['pass_code']} • ${v['company'] ?? 'Individual'}',
                                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    const Divider(color: AppTheme.border, height: 1),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.meeting_room_rounded, color: AppTheme.textSecondary, size: 15),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Host: ${v['person_to_meet'] ?? 'N/A'}',
                                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                        if (v['mobile'] != null)
                                          Row(
                                            children: [
                                              const Icon(Icons.phone_rounded, color: AppTheme.textSecondary, size: 15),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${v['mobile']}',
                                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                    if (v['purpose'] != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Purpose: ${v['purpose']}',
                                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                                      ),
                                    ],
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            icon: const Icon(Icons.qr_code_rounded, size: 16, color: Colors.white),
                                            label: const Text('View QR Pass', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppTheme.primary,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                            ),
                                            onPressed: () => _showVisitorQRPass(v),
                                          ),
                                        ),
                                        if (isInside) ...[
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              icon: const Icon(Icons.logout_rounded, size: 16, color: AppTheme.danger),
                                              label: const Text('Check Out', style: TextStyle(color: AppTheme.danger, fontSize: 11, fontWeight: FontWeight.bold)),
                                              style: OutlinedButton.styleFrom(
                                                side: const BorderSide(color: AppTheme.dangerBorder),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                padding: const EdgeInsets.symmetric(vertical: 8),
                                              ),
                                              onPressed: () => _checkout(v['id'], v['visitor_name'] ?? 'Visitor'),
                                            ),
                                          ),
                                        ],
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
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final selected = _filter == key;
    return InkWell(
      onTap: () {
        setState(() => _filter = key);
        _fetchVisitors();
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
