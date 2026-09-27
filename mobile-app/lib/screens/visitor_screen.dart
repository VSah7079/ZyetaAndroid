import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/validators.dart';

class VisitorScreen extends StatefulWidget {
  const VisitorScreen({super.key});

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

  void _checkout(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Checkout Visitor', style: TextStyle(color: Colors.white)),
        content: Text('Mark exit for $name?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF43F5E)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm Exit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final ok = await ApiService.checkoutVisitor(id);
      if (ok) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$name checked out successfully'), backgroundColor: Colors.green),
          );
        }
        _fetchVisitors();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Checkout failed'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _openNewVisitorModal() {
    final nameCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final companyCtrl = TextEditingController();
    final hostCtrl = TextEditingController();
    final purposeCtrl = TextEditingController(text: 'Official Meeting');
    final vehicleCtrl = TextEditingController();
    final idProofCtrl = TextEditingController();
    bool instantEntry = true;
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
                        Icon(Icons.person_add, color: Color(0xFF10B981)),
                        SizedBox(width: 8),
                        Text(
                          'Issue Visitor Pass',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(ctx),
                    )
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(nameCtrl, 'Visitor Full Name *', Icons.person),
                const SizedBox(height: 10),
                _buildTextField(mobileCtrl, 'Mobile Number *', Icons.phone, keyboardType: TextInputType.phone),
                const SizedBox(height: 10),
                _buildTextField(companyCtrl, 'Company / Organization', Icons.business),
                const SizedBox(height: 10),
                _buildTextField(hostCtrl, 'Person To Meet (Host Name) *', Icons.badge),
                const SizedBox(height: 10),
                _buildTextField(purposeCtrl, 'Purpose of Visit', Icons.work),
                const SizedBox(height: 10),
                _buildTextField(vehicleCtrl, 'Vehicle Number (Optional)', Icons.directions_car),
                const SizedBox(height: 10),
                _buildTextField(idProofCtrl, 'ID Proof Number (Aadhaar/DL)', Icons.credit_card),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Switch(
                        value: instantEntry,
                        activeThumbColor: const Color(0xFF10B981),
                        onChanged: (val) => setModalState(() => instantEntry = val),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Mark Entry Immediately (Instant Gate Check-in)',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
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
                      backgroundColor: const Color(0xFF10B981),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            final nameErr = FormValidators.validateName(nameCtrl.text, fieldName: 'Visitor name');
                            if (nameErr != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(nameErr), backgroundColor: Colors.orange));
                              return;
                            }

                            final mobileErr = FormValidators.validatePhone(mobileCtrl.text, fieldName: 'Visitor mobile');
                            if (mobileErr != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mobileErr), backgroundColor: Colors.orange));
                              return;
                            }

                            final hostErr = FormValidators.validateName(hostCtrl.text, fieldName: 'Person to meet (Host)');
                            if (hostErr != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(hostErr), backgroundColor: Colors.orange));
                              return;
                            }

                            final vehErr = FormValidators.validateVehicleNumber(vehicleCtrl.text, isRequired: false);
                            if (vehErr != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(vehErr), backgroundColor: Colors.orange));
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
                                const SnackBar(content: Text('Visitor Pass Issued Successfully!'), backgroundColor: Colors.green),
                              );
                              _fetchVisitors();
                            } else if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Failed to issue pass'), backgroundColor: Colors.red),
                              );
                            }
                          },
                    child: isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
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
        title: const Text('Visitor Pass Management', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _fetchVisitors,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF10B981),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Visitor Pass', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        onPressed: _openNewVisitorModal,
      ),
      body: Column(
        children: [
          // Filter Chips & Search Bar
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF0F172A),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search visitor name, pass code, host...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white54),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _search = '');
                              _fetchVisitors();
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
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
                : _visitors.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 50, color: Colors.white24),
                            const SizedBox(height: 10),
                            const Text('No visitors found', style: TextStyle(color: Colors.white54)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => _fetchVisitors(),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(14),
                          itemCount: _visitors.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, idx) {
                            final v = _visitors[idx];
                            final isInside = (v['status'] ?? '').toString().toLowerCase() == 'inside';
                            final isExited = (v['status'] ?? '').toString().toLowerCase() == 'exited';

                            Color statusColor = isInside
                                ? const Color(0xFF10B981)
                                : isExited
                                    ? Colors.white38
                                    : const Color(0xFF06B6D4);

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
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
                                          color: statusColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(Icons.person, color: statusColor, size: 24),
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
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: statusColor.withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(color: statusColor.withValues(alpha: 0.4)),
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
                                          const Icon(Icons.meeting_room, color: Colors.white38, size: 15),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Host: ${v['person_to_meet'] ?? 'N/A'}',
                                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                      if (v['mobile'] != null)
                                        Row(
                                          children: [
                                            const Icon(Icons.phone, color: Colors.white38, size: 15),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${v['mobile']}',
                                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                  if (v['purpose'] != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Purpose: ${v['purpose']}',
                                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                                    ),
                                  ],
                                  if (isInside) ...[
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 36,
                                      child: OutlinedButton.icon(
                                        icon: const Icon(Icons.logout, size: 16, color: Color(0xFFF43F5E)),
                                        label: const Text('MARK EXIT / CHECK OUT', style: TextStyle(color: Color(0xFFF43F5E), fontSize: 12, fontWeight: FontWeight.bold)),
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(color: const Color(0xFFF43F5E).withValues(alpha: 0.5)),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        onPressed: () => _checkout(v['id'], v['visitor_name'] ?? 'Visitor'),
                                      ),
                                    ),
                                  ]
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
        _fetchVisitors();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF10B981) : const Color(0xFF1E293B),
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
