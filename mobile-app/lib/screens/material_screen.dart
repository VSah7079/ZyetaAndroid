import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/api_service.dart';
import '../utils/validators.dart';
import '../utils/app_theme.dart';
import '../utils/responsive.dart';

class MaterialScreen extends StatefulWidget {
  final bool showAppBar;
  const MaterialScreen({super.key, this.showAppBar = true});

  @override
  State<MaterialScreen> createState() => _MaterialScreenState();
}

class _MaterialScreenState extends State<MaterialScreen> {
  List<dynamic> _materials = [];
  bool _isLoading = true;
  String _filter = 'ALL';
  String _search = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchMaterials();
  }

  void _fetchMaterials() async {
    setState(() => _isLoading = true);
    final movementType = _filter == 'ALL' ? null : _filter;
    final list = await ApiService.getMaterials(
      movementType: movementType,
      search: _search.isNotEmpty ? _search : null,
    );
    if (mounted) {
      setState(() {
        _materials = list;
        _isLoading = false;
      });
    }
  }

  void _showMaterialDCPass(Map<String, dynamic> m) {
    final dcNumber = m['dc_number'] ?? 'DC-2026-4401';
    final isReturnable = m['is_returnable'] == 1 || m['is_returnable'] == true;

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
                              background: AppTheme.warningBg,
                              borderColor: AppTheme.warningBorder,
                              radius: 8,
                            ),
                            child: const Icon(Icons.inventory_2_rounded, color: AppTheme.warning, size: 18),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'MATERIAL GATE PASS (DC)',
                              style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 11.5, letterSpacing: 0.5),
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
                        background: isReturnable ? AppTheme.warningBg : AppTheme.primarySubtle,
                        borderColor: isReturnable ? AppTheme.warningBorder : AppTheme.primaryLight,
                        radius: 6,
                      ),
                      child: Text(
                        isReturnable ? 'RETURNABLE' : 'NON-RETURNABLE',
                        style: TextStyle(
                          color: isReturnable ? AppTheme.warning : AppTheme.primary,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: 56,
                  height: 56,
                  decoration: AppTheme.badgeDecoration(
                    background: AppTheme.warningBg,
                    borderColor: AppTheme.warningBorder,
                    radius: 28,
                  ),
                  child: const Icon(Icons.inventory_rounded, color: AppTheme.warning, size: 28),
                ),
                const SizedBox(height: 10),
                Text(
                  m['material_name'] ?? 'Material',
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Qty: ${m['quantity']} ${m['unit']} • ${m['vendor_name'] ?? 'Supplier'}',
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
                        data: dcNumber,
                        version: QrVersions.auto,
                        size: 120.0,
                        backgroundColor: Colors.transparent,
                        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppTheme.textPrimary),
                        dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        dcNumber,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Scan at Material Inward / Outward Gate',
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

  void _openReturnModal(Map<String, dynamic> m) {
    final qtyCtrl = TextEditingController(text: '${m['quantity']}');
    final remarksCtrl = TextEditingController(text: 'Material returned through security gate');
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
                          background: AppTheme.warningBg,
                          borderColor: AppTheme.warningBorder,
                          radius: 8,
                        ),
                        child: const Icon(Icons.assignment_return_rounded, color: AppTheme.warning, size: 20),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Update Returnable DC Status',
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Material: ${m['material_name']} (${m['dc_number']})',
                style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Returned Quantity *',
                  labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  filled: true,
                  fillColor: AppTheme.bgSurface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: remarksCtrl,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Remarks / Condition of items',
                  labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  filled: true,
                  fillColor: AppTheme.bgSurface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.warning,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          final returnQty = int.tryParse(qtyCtrl.text.trim()) ?? 0;
                          if (returnQty <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a valid returned quantity'), backgroundColor: AppTheme.warning),
                            );
                            return;
                          }
                          setModalState(() => isSaving = true);
                          final ok = await ApiService.updateMaterialReturn(
                            m['id'],
                            returnQuantity: returnQty,
                            remarks: remarksCtrl.text.trim(),
                          );
                          setModalState(() => isSaving = false);
                          if (ok && mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('✓ Return status updated successfully!'), backgroundColor: AppTheme.success),
                            );
                            _fetchMaterials();
                          }
                        },
                  child: isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('CONFIRM RETURN RECORD', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  void _openNewDCModal() {
    final materialCtrl = TextEditingController();
    final categoryCtrl = TextEditingController(text: 'Raw Material');
    final quantityCtrl = TextEditingController();
    final unitCtrl = TextEditingController(text: 'Nos');
    final vendorCtrl = TextEditingController();
    final vehicleCtrl = TextEditingController();
    final driverNameCtrl = TextEditingController();
    final driverPhoneCtrl = TextEditingController();
    final invoiceCtrl = TextEditingController();
    final remarksCtrl = TextEditingController();
    String movementType = 'INWARD';
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
                            background: AppTheme.warningBg,
                            borderColor: AppTheme.warningBorder,
                            radius: 8,
                          ),
                          child: const Icon(Icons.add_shopping_cart_rounded, color: AppTheme.warning, size: 20),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Create Material Delivery Challan',
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
                      value: movementType,
                      isExpanded: true,
                      dropdownColor: Colors.white,
                      style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                      items: const [
                        DropdownMenuItem(value: 'INWARD', child: Text('📥 Inward (Standard Supply)')),
                        DropdownMenuItem(value: 'OUTWARD', child: Text('📤 Outward (Dispatched to Site)')),
                        DropdownMenuItem(value: 'RETURNABLE_IN', child: Text('🔄 Returnable In (Tools / Rentals In)')),
                        DropdownMenuItem(value: 'RETURNABLE_OUT', child: Text('🔁 Returnable Out (Temporary Loan)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => movementType = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _buildTextField(materialCtrl, 'Material Name (e.g., Cement, Steel, Paint) *', Icons.shopping_bag_rounded),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildTextField(quantityCtrl, 'Quantity *', Icons.numbers_rounded, keyboardType: TextInputType.number),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: _buildTextField(unitCtrl, 'Unit (Bags/Kg/MT/Nos)', Icons.straighten_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildTextField(vendorCtrl, 'Supplier / Vendor / Contractor', Icons.business_rounded),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(vehicleCtrl, 'Vehicle No *', Icons.local_shipping_rounded),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(driverNameCtrl, 'Driver Name', Icons.person_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildTextField(driverPhoneCtrl, 'Driver Mobile No', Icons.phone_rounded, keyboardType: TextInputType.phone),
                const SizedBox(height: 10),
                _buildTextField(invoiceCtrl, 'Challan / Invoice Number', Icons.receipt_rounded),
                const SizedBox(height: 10),
                _buildTextField(remarksCtrl, 'Remarks / Purpose', Icons.notes_rounded),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.warning,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            final matErr = FormValidators.validateName(materialCtrl.text, fieldName: 'Material name');
                            if (matErr != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(matErr), backgroundColor: AppTheme.warning));
                              return;
                            }

                            final qtyErr = FormValidators.validatePositiveNumber(quantityCtrl.text, fieldName: 'Quantity');
                            if (qtyErr != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(qtyErr), backgroundColor: AppTheme.warning));
                              return;
                            }

                            final vehErr = FormValidators.validateVehicleNumber(vehicleCtrl.text);
                            if (vehErr != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(vehErr), backgroundColor: AppTheme.warning));
                              return;
                            }

                            final driverPhoneErr = FormValidators.validatePhone(driverPhoneCtrl.text, isRequired: false, fieldName: 'Driver phone');
                            if (driverPhoneErr != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(driverPhoneErr), backgroundColor: AppTheme.warning));
                              return;
                            }

                            setModalState(() => isSaving = true);
                            final payload = {
                              'material_name': materialCtrl.text.trim(),
                              'category': categoryCtrl.text.trim().isEmpty ? 'General Material' : categoryCtrl.text.trim(),
                              'quantity': quantityCtrl.text.trim(),
                              'unit': unitCtrl.text.trim().isEmpty ? 'Nos' : unitCtrl.text.trim(),
                              'movement_type': movementType,
                              'vendor_name': vendorCtrl.text.trim().isEmpty ? 'Direct Supplier' : vendorCtrl.text.trim(),
                              'vehicle_number': vehicleCtrl.text.trim().toUpperCase(),
                              'driver_name': driverNameCtrl.text.trim(),
                              'driver_mobile': driverPhoneCtrl.text.trim(),
                              'invoice_number': invoiceCtrl.text.trim(),
                              'remarks': remarksCtrl.text.trim(),
                            };
                            final success = await ApiService.createMaterialEntry(payload);
                            setModalState(() => isSaving = false);
                            if (success && mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('✓ Material Gate Pass logged successfully!'), backgroundColor: AppTheme.success),
                              );
                              _fetchMaterials();
                            } else if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Failed to create Material DC'), backgroundColor: AppTheme.danger),
                              );
                            }
                          },
                    child: isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('CREATE GATE PASS & APPROVE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
              title: const Text('Material Gate Pass (DC)', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              actions: [
                IconButton(
                  tooltip: 'Refresh',
                  icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary),
                  onPressed: _fetchMaterials,
                ),
                const LogoutIconButton(),
              ],
            )
          : null,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.warning,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Material DC', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        onPressed: _openNewDCModal,
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
                      hintText: 'Search DC number, material, vehicle...',
                      hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary, size: 18),
                      suffixIcon: _search.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, color: AppTheme.textSecondary, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _search = '');
                                _fetchMaterials();
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
                      _fetchMaterials();
                    },
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('ALL', 'All Passes'),
                        const SizedBox(width: 8),
                        _buildFilterChip('INWARD', '📥 Inward'),
                        const SizedBox(width: 8),
                        _buildFilterChip('OUTWARD', '📤 Outward'),
                        const SizedBox(width: 8),
                        _buildFilterChip('RETURNABLE_IN', '🔄 Returnable In'),
                        const SizedBox(width: 8),
                        _buildFilterChip('RETURNABLE_OUT', '🔁 Returnable Out'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.warning))
                  : _materials.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: AppTheme.bgSurface, shape: BoxShape.circle),
                                child: const Icon(Icons.inventory_2_outlined, size: 40, color: AppTheme.warning),
                              ),
                              const SizedBox(height: 12),
                              const Text('No material records found', style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              const Text('Create a Delivery Challan using the button below', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async => _fetchMaterials(),
                          color: AppTheme.warning,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            itemCount: _materials.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, idx) {
                              final m = _materials[idx];
                              final isReturnable = (m['movement_type'] ?? '').toString().startsWith('RETURNABLE');
                              final returnStatus = (m['return_status'] ?? '').toString();

                              Color typeColor = isReturnable ? AppTheme.warning : const Color(0xFF0284C7);
                              Color typeBg = isReturnable ? AppTheme.warningBg : AppTheme.primarySubtle;
                              Color typeBorder = isReturnable ? AppTheme.warningBorder : AppTheme.primaryLight;

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
                                            background: typeBg,
                                            borderColor: typeBorder,
                                            radius: 12,
                                          ),
                                          child: Icon(Icons.inventory_2_rounded, color: typeColor, size: 24),
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
                                                      m['material_name'] ?? '',
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: AppTheme.badgeDecoration(
                                                      background: typeBg,
                                                      borderColor: typeBorder,
                                                      radius: 6,
                                                    ),
                                                    child: Text(
                                                      m['movement_type'] ?? '',
                                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: typeColor),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                '${m['dc_number']} • Qty: ${m['quantity']} ${m['unit']}',
                                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
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
                                        Expanded(
                                          child: Text(
                                            'Vendor: ${m['vendor_name'] ?? 'Direct'}',
                                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (m['vehicle_number'] != null && m['vehicle_number'].toString().isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: AppTheme.badgeDecoration(
                                              background: AppTheme.bgSurface,
                                              borderColor: AppTheme.border,
                                              radius: 4,
                                            ),
                                            child: Text(
                                              '🚛 ${m['vehicle_number']}',
                                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                      ],
                                    ),
                                    if (m['driver_name'] != null && m['driver_name'].toString().isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Driver: ${m['driver_name']} (${m['driver_mobile'] ?? 'N/A'})',
                                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                                      ),
                                    ],
                                    if (isReturnable) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Return Status: $returnStatus (${m['return_quantity'] ?? 0}/${m['quantity']})',
                                              style: TextStyle(
                                                color: returnStatus == 'Fully Returned' ? AppTheme.success : AppTheme.warning,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          if (returnStatus != 'Fully Returned')
                                            TextButton(
                                              style: TextButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                backgroundColor: AppTheme.warningBg,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                              ),
                                              onPressed: () => _openReturnModal(m),
                                              child: const Text('Update Return', style: TextStyle(color: AppTheme.warning, fontSize: 11, fontWeight: FontWeight.bold)),
                                            ),
                                        ],
                                      ),
                                    ],
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 36,
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.qr_code_2_rounded, size: 16, color: Colors.white),
                                        label: const Text('View DC Pass QR', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.primary,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        onPressed: () => _showMaterialDCPass(m),
                                      ),
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
        _fetchMaterials();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.warning : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? AppTheme.warning : AppTheme.border),
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
