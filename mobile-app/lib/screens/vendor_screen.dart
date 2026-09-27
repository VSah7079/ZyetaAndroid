import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/validators.dart';

class VendorScreen extends StatefulWidget {
  const VendorScreen({super.key});

  @override
  State<VendorScreen> createState() => _VendorScreenState();
}

class _VendorScreenState extends State<VendorScreen> {
  List<dynamic> _vendors = [];
  bool _isLoading = true;
  String _search = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchVendors();
  }

  void _fetchVendors() async {
    setState(() => _isLoading = true);
    final list = await ApiService.getVendors(
      search: _search.isNotEmpty ? _search : null,
    );
    if (mounted) {
      setState(() {
        _vendors = list;
        _isLoading = false;
      });
    }
  }

  void _openOnboardVendorModal() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final contactPersonCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final tradeCtrl = TextEditingController(text: 'Civil & Structural');
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
                        Icon(Icons.business_center, color: Color(0xFF06B6D4)),
                        SizedBox(width: 8),
                        Text(
                          'Onboard Contractor / Vendor',
                          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 14),
                _buildTextField(nameCtrl, 'Company Name *', Icons.business),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildTextField(codeCtrl, 'Vendor Code (e.g., VND-101)', Icons.tag)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTextField(tradeCtrl, 'Trade / Scope', Icons.handyman)),
                  ],
                ),
                const SizedBox(height: 10),
                _buildTextField(contactPersonCtrl, 'Contact Person *', Icons.person),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildTextField(phoneCtrl, 'Phone *', Icons.phone, keyboardType: TextInputType.phone)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTextField(emailCtrl, 'Email Address', Icons.email, keyboardType: TextInputType.emailAddress)),
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

                            final contactErr = FormValidators.validateName(contactPersonCtrl.text, fieldName: 'Contact person');
                            if (contactErr != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(contactErr), backgroundColor: Colors.orange));
                              return;
                            }

                            final phoneErr = FormValidators.validatePhone(phoneCtrl.text, fieldName: 'Phone number');
                            if (phoneErr != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(phoneErr), backgroundColor: Colors.orange));
                              return;
                            }

                            final emailErr = FormValidators.validateEmail(emailCtrl.text, isRequired: false);
                            if (emailErr != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(emailErr), backgroundColor: Colors.orange));
                              return;
                            }

                            setModalState(() => isSaving = true);
                            final ok = await ApiService.createVendor({
                              'company_name': nameCtrl.text.trim(),
                              'vendor_code': codeCtrl.text.trim(),
                              'trade_scope': tradeCtrl.text.trim(),
                              'contact_person': contactPersonCtrl.text.trim(),
                              'phone': phoneCtrl.text.trim(),
                              'email': emailCtrl.text.trim(),
                            });
                            setModalState(() => isSaving = false);
                            if (ok && mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Contractor onboarded successfully!'), backgroundColor: Colors.green),
                              );
                              _fetchVendors();
                            } else if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Failed to onboard contractor'), backgroundColor: Colors.red),
                              );
                            }
                          },
                    child: isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('ONBOARD CONTRACTOR', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
        title: const Text('Contractor & Vendor Portal', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _fetchVendors,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF06B6D4),
        icon: const Icon(Icons.add_business, color: Colors.white),
        label: const Text('New Contractor', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        onPressed: _openOnboardVendorModal,
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
                hintText: 'Search contractor name, trade, contact...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _search = '');
                          _fetchVendors();
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
                _fetchVendors();
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF06B6D4)))
                : _vendors.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.business_outlined, size: 50, color: Colors.white24),
                            const SizedBox(height: 10),
                            const Text('No contractors found', style: TextStyle(color: Colors.white54)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => _fetchVendors(),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(14),
                          itemCount: _vendors.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, idx) {
                            final v = _vendors[idx];

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.3)),
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
                                          color: const Color(0xFF06B6D4).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.business, color: Color(0xFF06B6D4), size: 24),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              v['company_name'] ?? 'Contractor',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${v['vendor_code'] ?? 'VND'} • ${v['trade_scope'] ?? 'General'}',
                                              style: const TextStyle(color: Color(0xFF06B6D4), fontSize: 12, fontWeight: FontWeight.w600),
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
                                        'Contact: ${v['contact_person'] ?? 'N/A'}',
                                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                                      ),
                                      if (v['phone'] != null)
                                        Text(
                                          '${v['phone']}',
                                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  // Stats badges
                                  Row(
                                    children: [
                                      _buildStatPill('👷 Workers', '${v['employee_count'] ?? 0}', Colors.blueAccent),
                                      const SizedBox(width: 8),
                                      _buildStatPill('● Inside', '${v['inside_count'] ?? 0}', Colors.greenAccent),
                                      const SizedBox(width: 8),
                                      _buildStatPill('📋 Permits', '${v['active_permits'] ?? 0}', const Color(0xFFF59E0B)),
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

  Widget _buildStatPill(String label, String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
