import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/api_service.dart';
import '../utils/validators.dart';

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
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF06B6D4).withValues(alpha: 0.25),
                blurRadius: 25,
                spreadRadius: 2,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.inventory_2, color: Color(0xFF06B6D4), size: 20),
                      SizedBox(width: 6),
                      Text(
                        'MATERIAL DC PASS',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: isReturnable ? Colors.orange.withValues(alpha: 0.2) : Colors.cyan.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      isReturnable ? 'RETURNABLE' : 'NON-RETURN',
                      style: TextStyle(
                        color: isReturnable ? Colors.orangeAccent : Colors.cyanAccent,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                m['material_name'] ?? 'Material Shipment',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Qty: ${m['quantity']} ${m['unit']} • ${m['vendor_name'] ?? 'Vendor'}',
                style: const TextStyle(color: Color(0xFF06B6D4), fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8)],
                ),
                child: Column(
                  children: [
                    QrImageView(
                      data: dcNumber,
                      version: QrVersions.auto,
                      size: 115.0,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                      dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dcNumber,
                      style: const TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Vehicle: ${m['vehicle_number'] ?? 'N/A'} • Driver: ${m['driver_name'] ?? 'N/A'}',
                style: const TextStyle(color: Colors.white54, fontSize: 10),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Close Challan', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openReturnModal(Map<String, dynamic> item) {
    final qtyCtrl = TextEditingController();
    final returnDcCtrl = TextEditingController();
    final remarksCtrl = TextEditingController();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Update Return for ${item['dc_number']}',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(ctx),
                  )
                ],
              ),
              Text(
                'Item: ${item['material_name']} | Total: ${item['quantity']} ${item['unit']} (Returned: ${item['return_quantity'] ?? 0})',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 16),
              _buildTextField(qtyCtrl, 'Return Quantity Now *', Icons.numbers, keyboardType: TextInputType.number),
              const SizedBox(height: 10),
              _buildTextField(returnDcCtrl, 'Return DC Number (Optional)', Icons.receipt),
              const SizedBox(height: 10),
              _buildTextField(remarksCtrl, 'Remarks / Condition', Icons.notes),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          final qty = int.tryParse(qtyCtrl.text.trim());
                          if (qty == null || qty <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a valid return quantity'), backgroundColor: Colors.orange),
                            );
                            return;
                          }
                          setModalState(() => isSaving = true);
                          final ok = await ApiService.updateMaterialReturn(
                            item['id'],
                            returnQuantity: qty,
                            returnDcNumber: returnDcCtrl.text.trim().isEmpty ? null : returnDcCtrl.text.trim(),
                            remarks: remarksCtrl.text.trim().isEmpty ? null : remarksCtrl.text.trim(),
                          );
                          setModalState(() => isSaving = false);
                          if (ok && mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Material return updated!'), backgroundColor: Colors.green),
                            );
                            _fetchMaterials();
                          } else if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Failed to update return'), backgroundColor: Colors.red),
                            );
                          }
                        },
                  child: isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('CONFIRM RETURN', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _openNewDCModal() {
    final materialCtrl = TextEditingController();
    final categoryCtrl = TextEditingController(text: 'General Material');
    final quantityCtrl = TextEditingController();
    final unitCtrl = TextEditingController(text: 'Bags');
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
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.inventory_2, color: Color(0xFFF59E0B)),
                        SizedBox(width: 8),
                        Text(
                          'New Material Gate Pass (DC)',
                          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(ctx),
                    )
                  ],
                ),
                const SizedBox(height: 14),

                // Movement Type Selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: movementType,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1E293B),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      items: const [
                        DropdownMenuItem(value: 'INWARD', child: Text('📥 INWARD (Non-Returnable)')),
                        DropdownMenuItem(value: 'OUTWARD', child: Text('📤 OUTWARD (Non-Returnable)')),
                        DropdownMenuItem(value: 'RETURNABLE_IN', child: Text('🔄 RETURNABLE INWARD')),
                        DropdownMenuItem(value: 'RETURNABLE_OUT', child: Text('🔁 RETURNABLE OUTWARD')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => movementType = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _buildTextField(materialCtrl, 'Material Name (e.g., Cement, Steel, Paint) *', Icons.shopping_bag),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildTextField(quantityCtrl, 'Quantity *', Icons.numbers, keyboardType: TextInputType.number),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: _buildTextField(unitCtrl, 'Unit (Bags/Kg/MT/Nos)', Icons.straighten),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildTextField(vendorCtrl, 'Supplier / Vendor / Contractor', Icons.business),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(vehicleCtrl, 'Vehicle No *', Icons.local_shipping),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(driverNameCtrl, 'Driver Name', Icons.person),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildTextField(driverPhoneCtrl, 'Driver Mobile No', Icons.phone, keyboardType: TextInputType.phone),
                const SizedBox(height: 10),
                _buildTextField(invoiceCtrl, 'Challan / Invoice Number', Icons.receipt),
                const SizedBox(height: 10),
                _buildTextField(remarksCtrl, 'Remarks / Purpose', Icons.notes),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            final matErr = FormValidators.validateName(materialCtrl.text, fieldName: 'Material name');
                            if (matErr != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(matErr), backgroundColor: Colors.orange));
                              return;
                            }

                            final qtyErr = FormValidators.validatePositiveNumber(quantityCtrl.text, fieldName: 'Quantity');
                            if (qtyErr != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(qtyErr), backgroundColor: Colors.orange));
                              return;
                            }

                            final vehErr = FormValidators.validateVehicleNumber(vehicleCtrl.text);
                            if (vehErr != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(vehErr), backgroundColor: Colors.orange));
                              return;
                            }

                            final driverPhoneErr = FormValidators.validatePhone(driverPhoneCtrl.text, isRequired: false, fieldName: 'Driver phone');
                            if (driverPhoneErr != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(driverPhoneErr), backgroundColor: Colors.orange));
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
                                const SnackBar(content: Text('Material Gate Pass logged successfully!'), backgroundColor: Colors.green),
                              );
                              _fetchMaterials();
                            } else if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Failed to create Material DC'), backgroundColor: Colors.red),
                              );
                            }
                          },
                    child: isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
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
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: const Color(0xFF0F172A),
              elevation: 0,
              title: const Text('Material Gate Pass (DC)', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white70),
                  onPressed: _fetchMaterials,
                ),
              ],
            )
          : null,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFF59E0B),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Material DC', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        onPressed: _openNewDCModal,
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
                    hintText: 'Search DC number, material, vehicle...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white54),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _search = '');
                              _fetchMaterials();
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
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)))
                : _materials.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 50, color: Colors.white24),
                            const SizedBox(height: 10),
                            const Text('No material records found', style: TextStyle(color: Colors.white54)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => _fetchMaterials(),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(14),
                          itemCount: _materials.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, idx) {
                            final m = _materials[idx];
                            final isReturnable = (m['movement_type'] ?? '').toString().startsWith('RETURNABLE');
                            final returnStatus = (m['return_status'] ?? '').toString();

                            Color typeColor = isReturnable ? const Color(0xFFF59E0B) : const Color(0xFF06B6D4);

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: typeColor.withValues(alpha: 0.3)),
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
                                        decoration: BoxDecoration(
                                          color: typeColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(Icons.inventory_2, color: typeColor, size: 24),
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
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: typeColor.withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(color: typeColor.withValues(alpha: 0.4)),
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
                                              style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  const Divider(color: Colors.white10, height: 1),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Vendor: ${m['vendor_name'] ?? 'Direct'}',
                                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                                      ),
                                      if (m['vehicle_number'] != null && m['vehicle_number'].toString().isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.black26,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: Colors.white12),
                                          ),
                                          child: Text(
                                            '🚛 ${m['vehicle_number']}',
                                            style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (m['driver_name'] != null && m['driver_name'].toString().isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Driver: ${m['driver_name']} (${m['driver_mobile'] ?? 'N/A'})',
                                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                                    ),
                                  ],
                                  if (isReturnable) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Return Status: $returnStatus (${m['return_quantity'] ?? 0}/${m['quantity']})',
                                          style: TextStyle(
                                            color: returnStatus == 'Fully Returned' ? Colors.greenAccent : const Color(0xFFF59E0B),
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (returnStatus != 'Fully Returned')
                                          TextButton(
                                            style: TextButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                            ),
                                            onPressed: () => _openReturnModal(m),
                                            child: const Text('Update Return', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.bold)),
                                          ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 36,
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.qr_code_2, size: 16, color: Colors.black87),
                                      label: const Text('View DC Pass QR', style: TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF06B6D4),
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
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final selected = _filter == key;
    return InkWell(
      onTap: () {
        setState(() => _filter = key);
        _fetchMaterials();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF59E0B) : const Color(0xFF1E293B),
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
