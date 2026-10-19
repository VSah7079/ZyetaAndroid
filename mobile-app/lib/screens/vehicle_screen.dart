import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/api_service.dart';
import '../utils/validators.dart';
import '../utils/app_theme.dart';
import '../utils/responsive.dart';

class VehicleScreen extends StatefulWidget {
  final bool showAppBar;
  const VehicleScreen({super.key, this.showAppBar = true});

  @override
  State<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> {
  List<dynamic> _vehicles = [];
  bool _isLoading = true;
  String _search = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchVehicles();
  }

  void _fetchVehicles() async {
    setState(() => _isLoading = true);
    final list = await ApiService.getVehicles(
      search: _search.isNotEmpty ? _search : null,
    );
    if (mounted) {
      setState(() {
        _vehicles = list;
        _isLoading = false;
      });
    }
  }

  void _showVehicleQRPass(Map<String, dynamic> veh) {
    final vehicleNo = veh['vehicle_number'] ?? 'KA 04 E 9921';
    final isNonCompliant = veh['is_puc_expired'] == true || veh['is_insurance_expired'] == true;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: SingleChildScrollView(
          child: Container(
            width: MediaQuery.of(ctx).size.width.clamp(280.0, 360.0),
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.cardDecoration(
              borderRadius: BorderRadius.circular(20),
              shadow: AppTheme.mediumShadow,
            ),
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
                              background: const Color(0xFFF3E8FF),
                              borderColor: const Color(0xFFE9D5FF),
                              radius: 8,
                            ),
                            child: const Icon(Icons.local_shipping_rounded, color: Color(0xFF9333EA), size: 18),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'VEHICLE GATE PASS',
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
                        background: isNonCompliant ? AppTheme.dangerBg : AppTheme.successBg,
                        borderColor: isNonCompliant ? AppTheme.dangerBorder : AppTheme.successBorder,
                        radius: 6,
                      ),
                      child: Text(
                        isNonCompliant ? 'NON-COMPLIANT' : 'COMPLIANT',
                        style: TextStyle(
                          color: isNonCompliant ? AppTheme.danger : AppTheme.success,
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
                    background: const Color(0xFFF3E8FF),
                    borderColor: const Color(0xFFE9D5FF),
                    radius: 28,
                  ),
                  child: const Icon(Icons.directions_car_rounded, color: Color(0xFF9333EA), size: 28),
                ),
                const SizedBox(height: 10),
                Text(
                  vehicleNo,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${veh['vehicle_type']} • ${veh['owner_vendor'] ?? 'Contractor'}',
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
                        data: vehicleNo,
                        version: QrVersions.auto,
                        size: 120.0,
                        backgroundColor: Colors.transparent,
                        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppTheme.textPrimary),
                        dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        vehicleNo,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Scan at Vehicle Gate Boom Barrier for Entry & Exit',
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

  void _openNewVehicleModal() {
    final numberCtrl = TextEditingController();
    final ownerCtrl = TextEditingController();
    final driverCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final rcCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String vehicleType = 'Commercial Truck';
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
                            background: const Color(0xFFF3E8FF),
                            borderColor: const Color(0xFFE9D5FF),
                            radius: 8,
                          ),
                          child: const Icon(Icons.add_road_rounded, color: Color(0xFF9333EA), size: 20),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Register New Vehicle Pass',
                          style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 14),
                _buildTextField(numberCtrl, 'Vehicle Number (e.g., KA 01 MJ 8812) *', Icons.pin_rounded),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.bgSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: vehicleType,
                      isExpanded: true,
                      dropdownColor: Colors.white,
                      style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                      items: const [
                        DropdownMenuItem(value: 'Commercial Truck', child: Text('🚛 Commercial Truck / Heavy')),
                        DropdownMenuItem(value: 'Dump Truck', child: Text('🚜 Tipper / Dumper / Construction')),
                        DropdownMenuItem(value: 'Pickup Van', child: Text('🚐 Pickup Van / Delivery')),
                        DropdownMenuItem(value: 'Staff Bus', child: Text('🚌 Staff Bus / Transit')),
                        DropdownMenuItem(value: 'Four Wheeler', child: Text('🚗 Four Wheeler / Official Car')),
                        DropdownMenuItem(value: 'Two Wheeler', child: Text('🛵 Two Wheeler / Bike')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => vehicleType = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _buildTextField(ownerCtrl, 'Contractor / Vendor / Owner', Icons.business_rounded),
                const SizedBox(height: 10),
                _buildTextField(driverCtrl, 'Driver Full Name', Icons.person_rounded),
                const SizedBox(height: 10),
                _buildTextField(mobileCtrl, 'Driver Mobile Number', Icons.phone_rounded, keyboardType: TextInputType.phone),
                const SizedBox(height: 10),
                _buildTextField(rcCtrl, 'RC / Vehicle Registration No.', Icons.badge_rounded),
                const SizedBox(height: 10),
                _buildTextField(notesCtrl, 'Gate Entry Notes / Purpose', Icons.notes_rounded),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9333EA),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            final vehErr = FormValidators.validateVehicleNumber(numberCtrl.text);
                            if (vehErr != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(vehErr), backgroundColor: AppTheme.warning));
                              return;
                            }

                            final mobileErr = FormValidators.validatePhone(mobileCtrl.text, isRequired: false, fieldName: 'Driver mobile');
                            if (mobileErr != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mobileErr), backgroundColor: AppTheme.warning));
                              return;
                            }

                            setModalState(() => isSaving = true);
                            final payload = {
                              'vehicle_number': numberCtrl.text.trim().toUpperCase(),
                              'vehicle_type': vehicleType,
                              'owner_vendor': ownerCtrl.text.trim().isEmpty ? 'Contractor' : ownerCtrl.text.trim(),
                              'driver_name': driverCtrl.text.trim(),
                              'driver_mobile': mobileCtrl.text.trim(),
                              'rc_number': rcCtrl.text.trim(),
                              'notes': notesCtrl.text.trim(),
                            };
                            final success = await ApiService.createVehicle(payload);
                            setModalState(() => isSaving = false);
                            if (success && mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('✓ Vehicle registered & verified!'), backgroundColor: AppTheme.success),
                              );
                              _fetchVehicles();
                            } else if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Failed to register vehicle'), backgroundColor: AppTheme.danger),
                              );
                            }
                          },
                    child: isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('REGISTER & VERIFY VEHICLE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              title: const Text('Vehicle Check & Compliance', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              actions: [
                IconButton(
                  tooltip: 'Refresh',
                  icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary),
                  onPressed: _fetchVehicles,
                ),
                const LogoutIconButton(),
              ],
            )
          : null,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF9333EA),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Register Vehicle', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        onPressed: _openNewVehicleModal,
      ),
      body: ResponsiveBody(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: AppTheme.border)),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search vehicle number, driver, contractor...',
                  hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary, size: 18),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: AppTheme.textSecondary, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _search = '');
                            _fetchVehicles();
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
                  _fetchVehicles();
                },
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF9333EA)))
                  : _vehicles.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: AppTheme.bgSurface, shape: BoxShape.circle),
                                child: const Icon(Icons.local_shipping_outlined, size: 40, color: Color(0xFF9333EA)),
                              ),
                              const SizedBox(height: 12),
                              const Text('No vehicles found', style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              const Text('Register a vehicle using the button below', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async => _fetchVehicles(),
                          color: const Color(0xFF9333EA),
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            itemCount: _vehicles.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, idx) {
                              final veh = _vehicles[idx];
                              final isNonCompliant = (veh['compliance_status'] ?? '').toString() == 'Non-Compliant';

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
                                            background: const Color(0xFFF3E8FF),
                                            borderColor: const Color(0xFFE9D5FF),
                                            radius: 12,
                                          ),
                                          child: const Icon(Icons.local_shipping_rounded, color: Color(0xFF9333EA), size: 24),
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
                                                      veh['vehicle_number'] ?? '',
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary, letterSpacing: 0.5),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: AppTheme.badgeDecoration(
                                                      background: isNonCompliant ? AppTheme.dangerBg : AppTheme.successBg,
                                                      borderColor: isNonCompliant ? AppTheme.dangerBorder : AppTheme.successBorder,
                                                      radius: 6,
                                                    ),
                                                    child: Text(
                                                      isNonCompliant ? '⚠️ Non-Compliant' : '✅ Compliant',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                        color: isNonCompliant ? AppTheme.danger : AppTheme.success,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                '${veh['vehicle_type']} • ${veh['owner_vendor'] ?? 'Direct'}',
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
                                        Expanded(
                                          child: Row(
                                            children: [
                                              const Icon(Icons.person_rounded, color: AppTheme.textSecondary, size: 15),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  'Driver: ${veh['driver_name'] ?? 'N/A'}',
                                                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (veh['driver_mobile'] != null && veh['driver_mobile'].toString().isNotEmpty) ...[
                                          const SizedBox(width: 8),
                                          Row(
                                            children: [
                                              const Icon(Icons.phone_rounded, color: AppTheme.textSecondary, size: 15),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${veh['driver_mobile']}',
                                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // PUC / Insurance tags
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        _buildDocStatusTag(
                                          'PUC: ${veh['puc_validity'] ?? 'Valid'}',
                                          veh['is_puc_expired'] == true,
                                        ),
                                        _buildDocStatusTag(
                                          'Insurance: ${veh['insurance_validity'] ?? 'Valid'}',
                                          veh['is_insurance_expired'] == true,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 36,
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.qr_code_2_rounded, size: 16, color: Colors.white),
                                        label: const Text('View Vehicle Gate Pass QR', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF9333EA),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        onPressed: () => _showVehicleQRPass(veh),
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

  Widget _buildDocStatusTag(String text, bool isExpired) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: AppTheme.badgeDecoration(
        background: isExpired ? AppTheme.dangerBg : AppTheme.successBg,
        borderColor: isExpired ? AppTheme.dangerBorder : AppTheme.successBorder,
        radius: 6,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isExpired ? AppTheme.danger : AppTheme.success,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
