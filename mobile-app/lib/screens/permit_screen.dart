import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/validators.dart';

class PermitScreen extends StatefulWidget {
  const PermitScreen({super.key});

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
        SnackBar(content: Text('Permit $permitNumber Approved!'), backgroundColor: Colors.green),
      );
      _fetchPermits();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to approve permit'), backgroundColor: Colors.red),
      );
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
            hintText: 'Reason for rejection...',
            hintStyle: TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Color(0xFF0F172A),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF43F5E)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
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

  void _openNewPermitModal() {
    final descCtrl = TextEditingController();
    final locationCtrl = TextEditingController(text: 'Floor 2 - Server Room');
    final applicantCtrl = TextEditingController(text: ApiService.currentUser?.fullName ?? 'Engineer');
    final phoneCtrl = TextEditingController(text: ApiService.currentUser?.phone ?? '+91 9900112233');

    String permitType = 'Hot Work (Welding/Cutting)';
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
                        Text('Apply for Work Permit (PTW)', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 14),
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
                        DropdownMenuItem(value: 'Hot Work (Welding/Cutting)', child: Text('🔥 Hot Work (Welding/Cutting)')),
                        DropdownMenuItem(value: 'Height Work (> 1.8m)', child: Text('🪜 Height Work (> 1.8m)')),
                        DropdownMenuItem(value: 'Confined Space Entry', child: Text('🕳️ Confined Space Entry')),
                        DropdownMenuItem(value: 'Electrical Isolation (LOTO)', child: Text('⚡ Electrical Isolation (LOTO)')),
                        DropdownMenuItem(value: 'Excavation & Trenching', child: Text('⛏️ Excavation & Trenching')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => permitType = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _buildTextField(locationCtrl, 'Work Location / Zone *', Icons.location_on),
                const SizedBox(height: 10),
                _buildTextField(descCtrl, 'Work Description & Scope *', Icons.description),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildTextField(applicantCtrl, 'Supervisor Name', Icons.person)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTextField(phoneCtrl, 'Supervisor Phone', Icons.phone, keyboardType: TextInputType.phone)),
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
                            final locErr = FormValidators.validateName(locationCtrl.text, fieldName: 'Work location / zone');
                            if (locErr != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(locErr), backgroundColor: Colors.orange));
                              return;
                            }

                            final descErr = FormValidators.validateRequired(descCtrl.text, fieldName: 'Work description', minLength: 5);
                            if (descErr != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(descErr), backgroundColor: Colors.orange));
                              return;
                            }

                            final phoneErr = FormValidators.validatePhone(phoneCtrl.text, isRequired: false, fieldName: 'Supervisor phone');
                            if (phoneErr != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(phoneErr), backgroundColor: Colors.orange));
                              return;
                            }

                            setModalState(() => isSaving = true);
                            final now = DateTime.now();
                            final tomorrow = now.add(const Duration(days: 1));
                            final ok = await ApiService.createPermit({
                              'permit_type': permitType,
                              'description': descCtrl.text.trim(),
                              'location_zone': locationCtrl.text.trim(),
                              'applicant_name': applicantCtrl.text.trim().isEmpty ? 'Supervisor' : applicantCtrl.text.trim(),
                              'applicant_contact': phoneCtrl.text.trim(),
                              'start_time': now.toIso8601String(),
                              'end_time': tomorrow.toIso8601String(),
                            });
                            setModalState(() => isSaving = false);
                            if (ok && mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Permit submitted for approval!'), backgroundColor: Colors.green),
                              );
                              _fetchPermits();
                            } else if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Failed to submit permit'), backgroundColor: Colors.red),
                              );
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
        title: const Text('Permits to Work (PTW)', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _fetchPermits,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New PTW Permit', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
                    hintText: 'Search permit number, contractor, type...',
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
                      _buildFilterChip('ALL', 'All Permits'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Pending', '⏳ Pending'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Approved', '✅ Approved'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Active', '⚡ Active'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Rejected', '❌ Rejected'),
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
                            Icon(Icons.assignment_outlined, size: 50, color: Colors.white24),
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
                            final status = (p['status'] ?? 'Pending').toString();
                            final isPending = status == 'Pending';
                            final isApproved = status == 'Approved' || status == 'Active';

                            Color statusColor = isPending
                                ? const Color(0xFFF59E0B)
                                : isApproved
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFF43F5E);

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
                                        child: Icon(Icons.security, color: statusColor, size: 24),
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
                                                    p['permit_type'] ?? 'Work Permit',
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
                                                    status,
                                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              '${p['permit_number']} • ${p['vendor_name'] ?? 'Direct'}',
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
                                  Text(
                                    'Location: ${p['work_location'] ?? 'Site Zone'}',
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Valid: ${p['valid_from']?.toString().split('T').first ?? ''} to ${p['valid_to']?.toString().split('T').first ?? ''}',
                                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                                  ),
                                  if (isPending && (ApiService.currentUser?.role == 'Super Admin' || ApiService.currentUser?.role == 'Admin')) ...[
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF10B981),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                            ),
                                            onPressed: () => _approve(p['id'], p['permit_number']),
                                            child: const Text('APPROVE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(color: Color(0xFFF43F5E)),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                            ),
                                            onPressed: () => _reject(p['id'], p['permit_number']),
                                            child: const Text('REJECT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFF43F5E))),
                                          ),
                                        ),
                                      ],
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
