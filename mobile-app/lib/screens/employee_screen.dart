import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/api_service.dart';
import '../utils/validators.dart';

class EmployeeScreen extends StatefulWidget {
  final bool showAppBar;
  const EmployeeScreen({super.key, this.showAppBar = true});

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

  // --- DIGITAL ID CARD MODAL ---
  void _showDigitalIDCard(Map<String, dynamic> emp) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 330,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                blurRadius: 30,
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
                        'ZYETA WORKFORCE PASS',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: emp['currently_inside'] == 1 ? Colors.green.withValues(alpha: 0.25) : Colors.white10,
                      borderRadius: BorderRadius.circular(5),
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
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF6366F1), width: 2.5),
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
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    _buildIDRow('Pass ID', emp['employee_id'] ?? ''),
                    _buildIDRow('Contractor', emp['vendor_name'] ?? 'Direct'),
                    _buildIDRow('Department', emp['department_name'] ?? 'General'),
                    _buildIDRow('Blood Group', emp['blood_group'] ?? 'O+'),
                    _buildIDRow('Mobile', emp['mobile'] ?? ''),
                    _buildIDRow('Police Verification', emp['police_verification_expiry'] ?? 'Verified'),
                    _buildIDRow('Emergency', '${emp['emergency_name'] ?? 'N/A'} (${emp['emergency_phone'] ?? ''})'),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // High-Res QR Code View
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
                      data: emp['employee_id'] ?? 'EMP-101',
                      version: QrVersions.auto,
                      size: 110.0,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                      dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      emp['employee_id'] ?? '',
                      style: const TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Official Turnstile & Gate QR Pass • Valid for All Entry Points',
                style: TextStyle(color: Colors.white38, fontSize: 9.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showEmployeeFullProfile(emp);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF6366F1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('View Full Dossier', style: TextStyle(color: Color(0xFF6366F1), fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Close Pass', style: TextStyle(color: Colors.white70, fontSize: 11)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- APPENDIX B: SUGGESTED EMPLOYEE PROFILE SECTIONS ---
  void _showEmployeeFullProfile(Map<String, dynamic> emp) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => DefaultTabController(
        length: 5,
        child: Container(
          height: MediaQuery.of(ctx).size.height * 0.88,
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            children: [
              // Header with Photo
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF6366F1), width: 2),
                        image: DecorationImage(
                          image: NetworkImage(emp['profile_photo'] ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(emp['full_name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                          Text('${emp['employee_id']} • ${emp['designation']}', style: const TextStyle(color: Color(0xFF06B6D4), fontSize: 12)),
                          Text('Contractor: ${emp['vendor_name']}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                        ],
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Profile Tabs (Appendix B)
              const TabBar(
                isScrollable: true,
                indicatorColor: Color(0xFF6366F1),
                indicatorWeight: 3,
                labelColor: Color(0xFF6366F1),
                unselectedLabelColor: Colors.white54,
                labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                tabs: [
                  Tab(text: 'Personal Info'),
                  Tab(text: 'Employment'),
                  Tab(text: 'Documents & KYC'),
                  Tab(text: 'Attendance Log'),
                  Tab(text: 'Gate History'),
                ],
              ),
              const Divider(color: Colors.white12, height: 1),

              // Tab Views
              Expanded(
                child: TabBarView(
                  children: [
                    // Tab 1: Personal Info
                    _buildProfileSection([
                      _buildInfoTile('Full Name', emp['full_name'] ?? 'N/A'),
                      _buildInfoTile("Father's Name", emp['father_name'] ?? 'Dinesh Patel'),
                      _buildInfoTile('Date of Birth', emp['dob'] ?? '1990-05-14'),
                      _buildInfoTile('Gender', emp['gender'] ?? 'Male'),
                      _buildInfoTile('Mobile Number', emp['mobile'] ?? 'N/A'),
                      _buildInfoTile('Alternate Mobile', emp['alternate_mobile'] ?? '+91 9876543211'),
                      _buildInfoTile('Email', emp['email'] ?? 'N/A'),
                      _buildInfoTile('Residential Address', emp['address'] ?? 'Munnekolala, Whitefield'),
                      _buildInfoTile('City, State, Pincode', '${emp['city'] ?? 'Bangalore'}, ${emp['state'] ?? 'Karnataka'} - ${emp['pincode'] ?? '560037'}'),
                      _buildInfoTile('Emergency Contact', '${emp['emergency_name'] ?? 'Sunita Patel'} (${emp['emergency_relation'] ?? 'Spouse'}) - ${emp['emergency_phone'] ?? '+91 9876543212'}'),
                    ]),

                    // Tab 2: Employment
                    _buildProfileSection([
                      _buildInfoTile('Employee ID', emp['employee_id'] ?? 'N/A'),
                      _buildInfoTile('Contractor / Vendor', emp['vendor_name'] ?? 'ABC Infra Projects Pvt Ltd'),
                      _buildInfoTile('Department', emp['department_name'] ?? 'Civil & Construction'),
                      _buildInfoTile('Designation', emp['designation'] ?? 'Senior Scaffolding Lead'),
                      _buildInfoTile('Trade / Skill Level', emp['skill'] ?? 'Expert Height Scaffolder'),
                      _buildInfoTile('Employee Type', emp['employee_type'] ?? 'Contractor Workforce'),
                      _buildInfoTile('Assigned Shift', emp['shift_name'] ?? 'General Shift (09:00 - 18:00)'),
                      _buildInfoTile('Joining Date', emp['joining_date'] ?? '2024-02-10'),
                      _buildInfoTile('Campus Gate Access', 'Main Gate 1, Material Gate 2, Turnstile 3'),
                      _buildInfoTile('Current Status', emp['status'] ?? 'Active'),
                    ]),

                    // Tab 3: Documents & KYC (Section 16 PRD)
                    _buildProfileSection([
                      _buildComplianceBadgeTile('Aadhaar / ID Card', emp['aadhaar_no'] ?? '4532 8912 7701', 'VERIFIED', Colors.green),
                      _buildComplianceBadgeTile('PAN Card', emp['pan_no'] ?? 'ABCDE9876K', 'VERIFIED', Colors.green),
                      _buildComplianceBadgeTile('Police Verification Doc', emp['police_verification_doc'] ?? 'police_clearance_101.pdf', 'EXP: ${emp['police_verification_expiry'] ?? '2027-02-01'}', Colors.green),
                      _buildComplianceBadgeTile('Medical Fitness Certificate', emp['medical_cert'] ?? 'Fit for Height Work', 'EXP: ${emp['medical_validity'] ?? '2027-01-15'}', Colors.green),
                      _buildComplianceBadgeTile('Height Work Safety Certification', 'Scaffolding Rigging Certified', 'VALID', Colors.green),
                    ]),

                    // Tab 4: Attendance History
                    _buildProfileSection([
                      _buildHistoryRow('2026-09-29', 'In: 08:45 AM', 'Out: Still Inside', 'Present (On Time)', Colors.green),
                      _buildHistoryRow('2026-09-28', 'In: 08:50 AM', 'Out: 06:10 PM', 'Present (9.3 hrs)', Colors.green),
                      _buildHistoryRow('2026-09-27', 'In: 09:15 AM', 'Out: 06:05 PM', 'Late (15 min)', Colors.orange),
                      _buildHistoryRow('2026-09-26', 'In: 08:40 AM', 'Out: 07:00 PM', 'Overtime (1.0 hr)', Colors.blue),
                      _buildHistoryRow('2026-09-25', 'In: 08:45 AM', 'Out: 06:00 PM', 'Present (9.2 hrs)', Colors.green),
                    ]),

                    // Tab 5: Gate History
                    _buildProfileSection([
                      _buildGateMovementRow('Main Gate 1', 'ENTRY', '2026-09-29 08:45 AM', 'QR Turnstile Verified', true),
                      _buildGateMovementRow('Main Gate 1', 'EXIT', '2026-09-28 06:10 PM', 'QR Turnstile Verified', false),
                      _buildGateMovementRow('Main Gate 1', 'ENTRY', '2026-09-28 08:50 AM', 'QR Turnstile Verified', true),
                      _buildGateMovementRow('Main Gate 1', 'EXIT', '2026-09-27 06:05 PM', 'QR Turnstile Verified', false),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection(List<Widget> children) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: children,
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          const Divider(color: Colors.white10, height: 1),
        ],
      ),
    );
  }

  Widget _buildComplianceBadgeTile(String title, String subtitle, String badge, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(badge, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryRow(String date, String inTime, String outTime, String status, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(date, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              Text('$inTime • $outTime', style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ],
          ),
          Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildGateMovementRow(String gate, String movement, String time, String method, bool isEntry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(isEntry ? Icons.arrow_downward : Icons.arrow_upward, color: isEntry ? Colors.greenAccent : Colors.redAccent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$movement - $gate', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                Text('$time • $method', style: const TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
        ],
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

  // --- SECTION 8.1 COMPREHENSIVE ONBOARDING MODAL ---
  void _openOnboardWorkerModal() {
    final nameCtrl = TextEditingController();
    final fatherCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final altMobileCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final desigCtrl = TextEditingController(text: 'Senior Scaffolder');
    final tradeCtrl = TextEditingController(text: 'Scaffolding & Rigging');
    final aadhaarCtrl = TextEditingController();
    final panCtrl = TextEditingController();
    final bloodCtrl = TextEditingController(text: 'B+');
    final emgNameCtrl = TextEditingController();
    final emgPhoneCtrl = TextEditingController();
    final medicalCtrl = TextEditingController(text: 'Fit for Height Work');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
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
                        Text('Onboard Worker (Section 8.1)', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 14),

                const Text('1. IDENTITY & CONTACT INFO', style: TextStyle(color: Color(0xFF6366F1), fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildTextField(nameCtrl, 'Full Name *', Icons.person),
                const SizedBox(height: 8),
                _buildTextField(fatherCtrl, "Father's / Guardian Name", Icons.family_restroom),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildTextField(mobileCtrl, 'Mobile *', Icons.phone, keyboardType: TextInputType.phone)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildTextField(altMobileCtrl, 'Alt Mobile', Icons.phone_android, keyboardType: TextInputType.phone)),
                  ],
                ),
                const SizedBox(height: 8),
                _buildTextField(emailCtrl, 'Email Address', Icons.email, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 8),
                _buildTextField(addressCtrl, 'Residential Address & City', Icons.home),

                const SizedBox(height: 14),
                const Text('2. EMPLOYMENT & ROLE DETAILS', style: TextStyle(color: Color(0xFF6366F1), fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildTextField(desigCtrl, 'Designation / Role', Icons.badge)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildTextField(tradeCtrl, 'Skill / Trade', Icons.handyman)),
                  ],
                ),

                const SizedBox(height: 14),
                const Text('3. DOCUMENTS & MEDICAL COMPLIANCE', style: TextStyle(color: Color(0xFF6366F1), fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildTextField(aadhaarCtrl, 'Aadhaar (12 Digits) *', Icons.credit_card, keyboardType: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildTextField(panCtrl, 'PAN Number', Icons.assignment_ind)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildTextField(bloodCtrl, 'Blood Group', Icons.water_drop)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildTextField(medicalCtrl, 'Medical Fitness Cert', Icons.health_and_safety)),
                  ],
                ),

                const SizedBox(height: 14),
                const Text('4. EMERGENCY CONTACT', style: TextStyle(color: Color(0xFF6366F1), fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildTextField(emgNameCtrl, 'Emergency Contact Name', Icons.contact_emergency)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildTextField(emgPhoneCtrl, 'Emergency Phone', Icons.phone_forwarded, keyboardType: TextInputType.phone)),
                  ],
                ),

                const SizedBox(height: 20),
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

                            setModalState(() => isSaving = true);
                            final payload = {
                              'full_name': nameCtrl.text.trim(),
                              'father_name': fatherCtrl.text.trim(),
                              'mobile': mobileCtrl.text.trim(),
                              'alternate_mobile': altMobileCtrl.text.trim(),
                              'email': emailCtrl.text.trim(),
                              'address': addressCtrl.text.trim(),
                              'designation': desigCtrl.text.trim(),
                              'skill': tradeCtrl.text.trim(),
                              'aadhaar_no': aadhaarCtrl.text.trim(),
                              'pan_no': panCtrl.text.trim(),
                              'blood_group': bloodCtrl.text.trim(),
                              'medical_cert': medicalCtrl.text.trim(),
                              'emergency_name': emgNameCtrl.text.trim(),
                              'emergency_phone': emgPhoneCtrl.text.trim(),
                            };
                            final ok = await ApiService.createEmployee(payload);
                            setModalState(() => isSaving = false);
                            if (ok && mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Worker Registered & Digital Gate Pass Generated!'), backgroundColor: Colors.green),
                              );
                              _fetchEmployees();
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
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
        prefixIcon: Icon(icon, color: Colors.white54, size: 18),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              title: const Text('Workforce & ID Passes', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white70),
                  onPressed: _fetchEmployees,
                ),
              ],
            )
          : null,
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
                    hintText: 'Search worker name, ID, trade, mobile, contractor...',
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
                      _buildFilterChip('ALL', 'All Workers (84)'),
                      const SizedBox(width: 8),
                      _buildFilterChip('INSIDE', '● Inside Site (42)'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Active', 'Active (79)'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Pending', 'Pending Approval (5)'),
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
                            const Icon(Icons.badge_outlined, size: 50, color: Colors.white24),
                            const SizedBox(height: 10),
                            const Text('No workers found matching filter', style: TextStyle(color: Colors.white54)),
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
                                    const Icon(Icons.qr_code_2, color: Colors.white38, size: 24),
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
