import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/validators.dart';

class VehicleScreen extends StatefulWidget {
  const VehicleScreen({super.key});

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

  void _openNewVehicleModal() {
    final numberCtrl = TextEditingController();
    final driverCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final ownerCtrl = TextEditingController();
    final rcCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    String vehicleType = 'Commercial Truck';
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
                        Icon(Icons.local_shipping, color: Color(0xFFA855F7)),
                        SizedBox(width: 8),
                        Text(
                          'Register Vehicle',
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

                // Vehicle Type Selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: vehicleType,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1E293B),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      items: const [
                        DropdownMenuItem(value: 'Commercial Truck', child: Text('🚛 Commercial Truck')),
                        DropdownMenuItem(value: 'Pickup / Tempo', child: Text('🚚 Pickup / Tempo')),
                        DropdownMenuItem(value: 'Transit Mixer / Tanker', child: Text('🚜 Transit Mixer / Tanker')),
                        DropdownMenuItem(value: 'Passenger Bus / Van', child: Text('🚐 Passenger Bus / Van')),
                        DropdownMenuItem(value: 'Car / 4-Wheeler', child: Text('🚗 Car / 4-Wheeler')),
                        DropdownMenuItem(value: 'Two Wheeler', child: Text('🏍️ Two Wheeler')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => vehicleType = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _buildTextField(numberCtrl, 'Vehicle Number (e.g., KA 01 AB 1234) *', Icons.directions_car),
                const SizedBox(height: 10),
                _buildTextField(ownerCtrl, 'Contractor / Transporter / Owner', Icons.business),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(driverCtrl, 'Driver Name *', Icons.person),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(mobileCtrl, 'Driver Mobile *', Icons.phone, keyboardType: TextInputType.phone),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildTextField(rcCtrl, 'RC / Fitness Certificate No', Icons.badge),
                const SizedBox(height: 10),
                _buildTextField(notesCtrl, 'Gate Entry Notes / Cargo details', Icons.notes),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA855F7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            final vehErr = FormValidators.validateVehicleNumber(numberCtrl.text);
                            if (vehErr != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(vehErr), backgroundColor: Colors.orange));
                              return;
                            }

                            final driverErr = FormValidators.validateName(driverCtrl.text, fieldName: 'Driver name');
                            if (driverErr != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(driverErr), backgroundColor: Colors.orange));
                              return;
                            }

                            final mobileErr = FormValidators.validatePhone(mobileCtrl.text, fieldName: 'Driver mobile');
                            if (mobileErr != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mobileErr), backgroundColor: Colors.orange));
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
                                const SnackBar(content: Text('Vehicle registered & verified!'), backgroundColor: Colors.green),
                              );
                              _fetchVehicles();
                            } else if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Failed to register vehicle'), backgroundColor: Colors.red),
                              );
                            }
                          },
                    child: isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Text('Vehicle Check & Compliance', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _fetchVehicles,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFA855F7),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Register Vehicle', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        onPressed: _openNewVehicleModal,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF0F172A),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search vehicle number, driver, contractor...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _search = '');
                          _fetchVehicles();
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
                _fetchVehicles();
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFA855F7)))
                : _vehicles.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.local_shipping_outlined, size: 50, color: Colors.white24),
                            const SizedBox(height: 10),
                            const Text('No vehicles found', style: TextStyle(color: Colors.white54)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => _fetchVehicles(),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(14),
                          itemCount: _vehicles.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, idx) {
                            final veh = _vehicles[idx];
                            final isNonCompliant = (veh['compliance_status'] ?? '').toString() == 'Non-Compliant';

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isNonCompliant ? Colors.redAccent.withValues(alpha: 0.5) : const Color(0xFFA855F7).withValues(alpha: 0.3),
                                ),
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
                                          color: const Color(0xFFA855F7).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.local_shipping, color: Color(0xFFA855F7), size: 24),
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
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white, letterSpacing: 0.5),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: isNonCompliant ? Colors.red.withValues(alpha: 0.2) : Colors.green.withValues(alpha: 0.2),
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(
                                                      color: isNonCompliant ? Colors.redAccent.withValues(alpha: 0.5) : Colors.greenAccent.withValues(alpha: 0.5),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    isNonCompliant ? '⚠️ Non-Compliant' : '✅ Compliant',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: isNonCompliant ? Colors.redAccent : Colors.greenAccent,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              '${veh['vehicle_type']} • ${veh['owner_vendor'] ?? 'Direct'}',
                                              style: const TextStyle(color: Colors.white54, fontSize: 12),
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
                                      Row(
                                        children: [
                                          const Icon(Icons.person, color: Colors.white38, size: 15),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Driver: ${veh['driver_name'] ?? 'N/A'}',
                                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                      if (veh['driver_mobile'] != null && veh['driver_mobile'].toString().isNotEmpty)
                                        Row(
                                          children: [
                                            const Icon(Icons.phone, color: Colors.white38, size: 15),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${veh['driver_mobile']}',
                                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // PUC / Insurance tags
                                  Row(
                                    children: [
                                      _buildDocStatusTag(
                                        'PUC: ${veh['puc_validity'] ?? 'Valid'}',
                                        veh['is_puc_expired'] == true,
                                      ),
                                      const SizedBox(width: 8),
                                      _buildDocStatusTag(
                                        'Insurance: ${veh['insurance_validity'] ?? 'Valid'}',
                                        veh['is_insurance_expired'] == true,
                                      ),
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
    );
  }

  Widget _buildDocStatusTag(String text, bool isExpired) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isExpired ? Colors.red.withValues(alpha: 0.15) : Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isExpired ? Colors.redAccent.withValues(alpha: 0.3) : Colors.greenAccent.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isExpired ? Colors.redAccent : Colors.greenAccent,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
