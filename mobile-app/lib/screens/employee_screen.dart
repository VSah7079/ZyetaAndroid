import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/validators.dart';

class EmployeeScreen extends StatefulWidget {
  const EmployeeScreen({super.key});

  @override
  State<EmployeeScreen> createState() => _EmployeeScreenState();
}

class _EmployeeScreenState extends State<EmployeeScreen> {
  List<dynamic> _employees = [];
  bool _isLoading = true;
  String _filter = 'ALL';
  String _search = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
  }

  void _fetchEmployees() async {
    setState(() => _isLoading = true);
    String? status;
    String? inside;

    if (_filter == 'INSIDE') {
      inside = 'true';
    } else if (_filter != 'ALL') {
      status = _filter;
    }

    final list = await ApiService.getEmployees(
      status: status,
      inside: inside,
      search: _search.isNotEmpty ? _search : null,
    );
    if (mounted) {
      setState(() {
        _employees = list;
        _isLoading = false;
      });
    }
  }

  void _showDigitalIDCard(Map<String, dynamic> emp) {
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
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                blurRadius: 25,
                spreadRadius: 2,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.shield, color: Color(0xFF6366F1), size: 22),
                      SizedBox(width: 6),
                      Text(
                        'ZYETAGATE PASS',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: emp['currently_inside'] == 1 ? Colors.green.withValues(alpha: 0.2) : Colors.white10,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      emp['currently_inside'] == 1 ? '● INSIDE' : 'OUTSIDE',
                      style: TextStyle(
                        color: emp['currently_inside'] == 1 ? Colors.greenAccent : Colors.white54,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Photo & Name
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF6366F1), width: 2),
                  image: DecorationImage(
                    image: NetworkImage(
                      emp['profile_photo'] ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                emp['full_name'] ?? 'Worker',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              Text(
                '${emp['designation'] ?? 'Technician'} • ${emp['skill'] ?? 'General'}',
                style: const TextStyle(color: Color(0xFF06B6D4), fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              // Details Grid
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    _buildIDRow('Pass ID', emp['employee_id'] ?? ''),
                    _buildIDRow('Contractor', emp['vendor_name'] ?? 'Direct'),
                    _buildIDRow('Blood Group', emp['blood_group'] ?? 'O+'),
                    _buildIDRow('Mobile', emp['mobile'] ?? ''),
                    _buildIDRow('Emergency', '${emp['emergency_name'] ?? 'N/A'} (${emp['emergency_phone'] ?? ''})'),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // QR Code representation
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.qr_code_2, size: 70, color: Colors.black),
              ),
              const SizedBox(height: 6),
              const Text(
                'Scan at any gate turnstile for access',
                style: TextStyle(color: Colors.white38, fontSize: 10),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Close Pass', style: TextStyle(color: Colors.white70)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIDRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _openOnboardWorkerModal() {
    final nameCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final desigCtrl = TextEditingController(text: 'Electrician');
    final tradeCtrl = TextEditingController(text: 'Electrical');
    final aadhaarCtrl = TextEditingController();
    final bloodCtrl = TextEditingController(text: 'O+');
    final emgNameCtrl = TextEditingController();
    final emgPhoneCtrl = TextEditingController();
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
                        Icon(Icons.person_add_alt_1, color: Color(0xFF6366F1)),
                        SizedBox(width: 8),
                        Text(
                          'Onboard Worker / Employee',
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
                _buildTextField(nameCtrl, 'Full Name *', Icons.person),
                const SizedBox(height: 10),
                _buildTextField(mobileCtrl, 'Mobile Number *', Icons.phone, keyboardType: TextInputType.phone),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(desigCtrl, 'Designation / Role', Icons.badge),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(tradeCtrl, 'Trade / Skill', Icons.build),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(aadhaarCtrl, 'Aadhaar / ID No', Icons.credit_card),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(bloodCtrl, 'Blood Group', Icons.water_drop),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(emgNameCtrl, 'Emergency Contact Person', Icons.contact_phone),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(emgPhoneCtrl, 'Emergency Phone', Icons.phone_forwarded, keyboardType: TextInputType.phone),
                    ),
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
                            final nameErr = FormValidators.validateName(nameCtrl.text, fieldName: 'Worker name');
                            if (nameErr != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(nameErr), backgroundColor: Colors.orange));
                              return;
                            }

                            final mobileErr = FormValidators.validatePhone(mobileCtrl.text, fieldName: 'Worker mobile');
                            if (mobileErr != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mobileErr), backgroundColor: Colors.orange));
                              return;
                            }

                            final aadhaarErr = FormValidators.validateAadhaar(aadhaarCtrl.text);
                            if (aadhaarErr != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(aadhaarErr), backgroundColor: Colors.orange));
                              return;
                            }

                            final emgPhoneErr = FormValidators.validatePhone(emgPhoneCtrl.text, isRequired: false, fieldName: 'Emergency phone');
                            if (emgPhoneErr != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(emgPhoneErr), backgroundColor: Colors.orange));
                              return;
                            }

                            setModalState(() => isSaving = true);
                            final payload = {
                              'full_name': nameCtrl.text.trim(),
                              'mobile': mobileCtrl.text.trim(),
                              'designation': desigCtrl.text.trim(),
                              'skill': tradeCtrl.text.trim(),
                              'aadhaar_no': aadhaarCtrl.text.trim(),
                              'blood_group': bloodCtrl.text.trim(),
                              'emergency_name': emgNameCtrl.text.trim(),
                              'emergency_phone': emgPhoneCtrl.text.trim(),
                            };
                            final ok = await ApiService.createEmployee(payload);
                            setModalState(() => isSaving = false);
                            if (ok && mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Worker onboarded & Pass generated!'), backgroundColor: Colors.green),
                              );
                              _fetchEmployees();
                            } else if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Failed to onboard worker'), backgroundColor: Colors.red),
                              );
                            }
                          },
                    child: isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('GENERATE PASS & ONBOARD', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
        title: const Text('Workforce & ID Passes', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _fetchEmployees,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Onboard Worker', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        onPressed: _openOnboardWorkerModal,
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
                    hintText: 'Search worker name, ID, trade, mobile...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white54),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _search = '');
                              _fetchEmployees();
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
                    _fetchEmployees();
                  },
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('ALL', 'All Workers'),
                      const SizedBox(width: 8),
                      _buildFilterChip('INSIDE', '● Inside Site'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Active', 'Active'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Pending Approval', 'Pending'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                : _employees.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.badge_outlined, size: 50, color: Colors.white24),
                            const SizedBox(height: 10),
                            const Text('No workers found', style: TextStyle(color: Colors.white54)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => _fetchEmployees(),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(14),
                          itemCount: _employees.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, idx) {
                            final emp = _employees[idx];
                            final isInside = emp['currently_inside'] == 1;

                            return InkWell(
                              onTap: () => _showDigitalIDCard(emp),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isInside ? Colors.green.withValues(alpha: 0.4) : Colors.white10,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isInside ? Colors.greenAccent : const Color(0xFF6366F1),
                                          width: 1.5,
                                        ),
                                        image: DecorationImage(
                                          image: NetworkImage(
                                            emp['profile_photo'] ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
                                          ),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
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
                                                  emp['full_name'] ?? '',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: isInside ? Colors.green.withValues(alpha: 0.2) : Colors.black26,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  isInside ? '● INSIDE' : 'OUTSIDE',
                                                  style: TextStyle(
                                                    color: isInside ? Colors.greenAccent : Colors.white38,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${emp['employee_id']} • ${emp['designation'] ?? 'Worker'} (${emp['skill'] ?? 'General'})',
                                            style: const TextStyle(color: Color(0xFF06B6D4), fontSize: 12, fontWeight: FontWeight.w500),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Contractor: ${emp['vendor_name'] ?? 'Direct'}',
                                            style: const TextStyle(color: Colors.white54, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.qr_code, color: Colors.white38, size: 24),
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
        _fetchEmployees();
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
