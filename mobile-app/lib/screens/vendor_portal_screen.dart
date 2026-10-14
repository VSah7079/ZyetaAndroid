import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/api_service.dart';
import '../utils/validators.dart';

class VendorPortalScreen extends StatefulWidget {
  const VendorPortalScreen({super.key});

  @override
  State<VendorPortalScreen> createState() => _VendorPortalScreenState();
}

class _VendorPortalScreenState extends State<VendorPortalScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _myEmployees = [];
  List<dynamic> _myPermits = [];
  List<dynamic> _myMaterials = [];
  bool _isLoading = true;

  // Attendance Analytics State (Week / Month / Year)
  String _selectedAttendancePeriod = 'week'; // 'week' | 'month' | 'year'
  Map<String, dynamic>? _attendanceAnalytics;
  bool _isAttendanceLoading = false;

  // Employee Filters
  String _empFilter = 'ALL'; // 'ALL' | 'ACTIVE' | 'PENDING' | 'INSIDE'
  String _empSearch = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadVendorData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadVendorData() async {
    setState(() => _isLoading = true);
    final vendorId = ApiService.currentUser?.vendorId?.toString();
    final emps = await ApiService.getEmployees(vendorId: vendorId);
    final permits = await ApiService.getPermits();
    final materials = await ApiService.getMaterials();

    if (mounted) {
      setState(() {
        _myEmployees = emps;
        _myPermits = permits;
        _myMaterials = materials;
        _isLoading = false;
      });
      _loadAttendanceAnalytics(_selectedAttendancePeriod);
    }
  }

  void _loadAttendanceAnalytics(String period) async {
    setState(() {
      _selectedAttendancePeriod = period;
      _isAttendanceLoading = true;
    });
    final vendorId = ApiService.currentUser?.vendorId?.toString();
    final data = await ApiService.getVendorAttendanceAnalytics(period: period, vendorId: vendorId);
    if (mounted) {
      setState(() {
        _attendanceAnalytics = data;
        _isAttendanceLoading = false;
      });
    }
  }

  // ==========================================
  // ATTENDANCE REPORT DOWNLOAD (CSV)
  // ==========================================
  void _downloadAttendanceReport() async {
    final vendorId = ApiService.currentUser?.vendorId?.toString();
    final csvContent = await ApiService.exportAttendanceCSVData(
      period: _selectedAttendancePeriod,
      vendorId: vendorId,
    );

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.download_for_offline, color: Color(0xFF10B981), size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Download Attendance (${_selectedAttendancePeriod.toUpperCase()})',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Official muster CSV report generated for ${ApiService.currentUser?.fullName ?? 'Contractor'}. Includes shift records, overtime hours, and compliance status.',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 14),
            Container(
              height: 150,
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: SingleChildScrollView(
                child: Text(
                  csvContent,
                  style: const TextStyle(color: Color(0xFF38BDF8), fontFamily: 'monospace', fontSize: 11),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF38BDF8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.copy, color: Color(0xFF38BDF8), size: 18),
                    label: const Text('Copy CSV Data', style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: csvContent));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Attendance CSV copied to clipboard!'), backgroundColor: Colors.green),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.download, color: Colors.white, size: 18),
                    label: const Text('Download CSV', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✓ Attendance report (${_selectedAttendancePeriod.toUpperCase()}) downloaded to Downloads/Zyeta_Attendance.csv'),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // EMPLOYEE REGISTRATION MODAL (FULL DETAILS)
  // ==========================================
  void _openEmployeeRegistrationModal() {
    final nameCtrl = TextEditingController();
    final fatherCtrl = TextEditingController();
    final dobCtrl = TextEditingController(text: '1995-06-15');
    final mobileCtrl = TextEditingController();
    final altMobileCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final cityCtrl = TextEditingController(text: 'Bangalore');
    final stateCtrl = TextEditingController(text: 'Karnataka');
    final pincodeCtrl = TextEditingController(text: '560037');

    final emgNameCtrl = TextEditingController();
    final emgRelationCtrl = TextEditingController(text: 'Spouse');
    final emgPhoneCtrl = TextEditingController();

    final desigCtrl = TextEditingController(text: 'Senior Scaffolder');
    final skillCtrl = TextEditingController(text: 'Height Work & Rigging');
    final aadhaarCtrl = TextEditingController();
    final panCtrl = TextEditingController();
    final medicalValidityCtrl = TextEditingController(text: '2027-12-31');
    final pvcExpiryCtrl = TextEditingController(text: '2027-12-31');

    String selectedGender = 'Male';
    String selectedBloodGroup = 'O+';
    String selectedShift = 'General Shift (09:00 - 18:00)';
    String selectedSkillLevel = 'Skilled';
    String selectedPhotoUrl = 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80';
    String medicalFitnessStatus = 'Fit for Construction & Height Work (Class A)';
    bool isSaving = false;

    final photoPresets = [
      {'title': 'Worker 1', 'url': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80'},
      {'title': 'Worker 2', 'url': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&auto=format&fit=crop&q=80'},
      {'title': 'Worker 3', 'url': 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150&auto=format&fit=crop&q=80'},
      {'title': 'Worker 4', 'url': 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=150&auto=format&fit=crop&q=80'},
      {'title': 'Worker 5', 'url': 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=150&auto=format&fit=crop&q=80'},
    ];

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
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.person_add_alt_1, color: Color(0xFF06B6D4)),
                        SizedBox(width: 8),
                        Text('Employee Registration & ID Request', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Color(0xFF818CF8), size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'On submission, this worker profile goes for 3-tier clearance: 1. Site Admin → 2. Safety Officer → 3. Super Admin ID Badge Generation.',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),

                // SECTION 1: PROFILE PHOTO & BASIC IDENTITY
                _buildSectionHeader('1. PROFILE PHOTO & IDENTITY DETAILS'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundImage: NetworkImage(selectedPhotoUrl),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Select Photo / Camera Avatar *', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: photoPresets.map((p) {
                                final isSelected = selectedPhotoUrl == p['url'];
                                return InkWell(
                                  onTap: () => setModalState(() => selectedPhotoUrl = p['url']!),
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 6),
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: isSelected ? const Color(0xFF06B6D4) : Colors.transparent, width: 2),
                                    ),
                                    child: CircleAvatar(radius: 16, backgroundImage: NetworkImage(p['url']!)),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildFormTextField(nameCtrl, 'Full Name (As per Aadhaar) *', Icons.person),
                const SizedBox(height: 8),
                _buildFormTextField(fatherCtrl, "Father's / Husband's Name *", Icons.family_restroom),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildFormTextField(dobCtrl, 'Date of Birth (YYYY-MM-DD)', Icons.calendar_today)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(10)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedGender,
                            isExpanded: true,
                            dropdownColor: const Color(0xFF1E293B),
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            items: const [
                              DropdownMenuItem(value: 'Male', child: Text('Male')),
                              DropdownMenuItem(value: 'Female', child: Text('Female')),
                              DropdownMenuItem(value: 'Other', child: Text('Other')),
                            ],
                            onChanged: (val) {
                              if (val != null) setModalState(() => selectedGender = val);
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildFormTextField(mobileCtrl, 'Mobile Number *', Icons.phone, keyboardType: TextInputType.phone)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildFormTextField(altMobileCtrl, 'Alternate Mobile', Icons.phone_android, keyboardType: TextInputType.phone)),
                  ],
                ),
                const SizedBox(height: 8),
                _buildFormTextField(emailCtrl, 'Email Address', Icons.email, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 8),
                _buildFormTextField(addressCtrl, 'Residential Address *', Icons.home),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildFormTextField(cityCtrl, 'City', Icons.location_city)),
                    const SizedBox(width: 6),
                    Expanded(child: _buildFormTextField(stateCtrl, 'State', Icons.map)),
                    const SizedBox(width: 6),
                    Expanded(child: _buildFormTextField(pincodeCtrl, 'Pincode', Icons.pin_drop, keyboardType: TextInputType.number)),
                  ],
                ),

                // SECTION 2: WORK, TRADE & SHIFT
                const SizedBox(height: 14),
                _buildSectionHeader('2. TRADE, DESIGNATION & SHIFT'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildFormTextField(desigCtrl, 'Designation / Role *', Icons.badge)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildFormTextField(skillCtrl, 'Skill Scope', Icons.handyman)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(10)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedSkillLevel,
                            isExpanded: true,
                            dropdownColor: const Color(0xFF1E293B),
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            items: const [
                              DropdownMenuItem(value: 'Expert', child: Text('Expert')),
                              DropdownMenuItem(value: 'Skilled', child: Text('Skilled')),
                              DropdownMenuItem(value: 'Semi-Skilled', child: Text('Semi-Skilled')),
                              DropdownMenuItem(value: 'Helper', child: Text('Helper / Unskilled')),
                            ],
                            onChanged: (val) {
                              if (val != null) setModalState(() => selectedSkillLevel = val);
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(10)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedShift,
                            isExpanded: true,
                            dropdownColor: const Color(0xFF1E293B),
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            items: const [
                              DropdownMenuItem(value: 'General Shift (09:00 - 18:00)', child: Text('General (9-6)')),
                              DropdownMenuItem(value: 'Morning Shift A (06:00 - 14:30)', child: Text('Morning Shift A')),
                              DropdownMenuItem(value: 'Night Shift C (22:00 - 06:00)', child: Text('Night Shift C')),
                            ],
                            onChanged: (val) {
                              if (val != null) setModalState(() => selectedShift = val);
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // SECTION 3: AADHAAR, MEDICAL & POLICE VERIFICATION
                const SizedBox(height: 14),
                _buildSectionHeader('3. AADHAAR, MEDICAL FITNESS & SAFETY (FOR HSE)'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildFormTextField(aadhaarCtrl, 'Aadhaar Card No. (12 Digits) *', Icons.credit_card, keyboardType: TextInputType.number),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(10)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedBloodGroup,
                            isExpanded: true,
                            dropdownColor: const Color(0xFF1E293B),
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            items: const [
                              DropdownMenuItem(value: 'A+', child: Text('Blood A+')),
                              DropdownMenuItem(value: 'A-', child: Text('Blood A-')),
                              DropdownMenuItem(value: 'B+', child: Text('Blood B+')),
                              DropdownMenuItem(value: 'B-', child: Text('Blood B-')),
                              DropdownMenuItem(value: 'O+', child: Text('Blood O+')),
                              DropdownMenuItem(value: 'O-', child: Text('Blood O-')),
                              DropdownMenuItem(value: 'AB+', child: Text('Blood AB+')),
                              DropdownMenuItem(value: 'AB-', child: Text('Blood AB-')),
                            ],
                            onChanged: (val) {
                              if (val != null) setModalState(() => selectedBloodGroup = val);
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildFormTextField(panCtrl, 'PAN Card Number (Optional)', Icons.assignment_ind),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.health_and_safety, color: Color(0xFF10B981), size: 18),
                          SizedBox(width: 6),
                          Text('Medical Fitness Certificate (Attached) *', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(medicalFitnessStatus, style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(child: _buildFormTextField(medicalValidityCtrl, 'Medical Validity Until', Icons.event)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildFormTextField(pvcExpiryCtrl, 'Police Verification Valid', Icons.verified_user)),
                        ],
                      ),
                    ],
                  ),
                ),

                // SECTION 4: EMERGENCY CONTACT
                const SizedBox(height: 14),
                _buildSectionHeader('4. EMERGENCY CONTACT'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildFormTextField(emgNameCtrl, 'Emergency Contact Person *', Icons.contact_emergency)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildFormTextField(emgRelationCtrl, 'Relationship', Icons.people_outline)),
                  ],
                ),
                const SizedBox(height: 8),
                _buildFormTextField(emgPhoneCtrl, 'Emergency Phone Number *', Icons.phone_forwarded, keyboardType: TextInputType.phone),

                // SUBMIT BUTTON
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF06B6D4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            final nameErr = FormValidators.validateName(nameCtrl.text, fieldName: 'Full Name');
                            if (nameErr != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(nameErr), backgroundColor: Colors.orange));
                              return;
                            }
                            final phoneErr = FormValidators.validatePhone(mobileCtrl.text, fieldName: 'Mobile Number');
                            if (phoneErr != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(phoneErr), backgroundColor: Colors.orange));
                              return;
                            }
                            if (aadhaarCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter 12-digit Aadhaar Card number'), backgroundColor: Colors.orange),
                              );
                              return;
                            }

                            setModalState(() => isSaving = true);

                            final vendorId = ApiService.currentUser?.vendorId ?? 1;
                            final vendorName = ApiService.currentUser?.fullName ?? 'ABC Infra Projects Pvt Ltd';

                            final ok = await ApiService.createEmployee({
                              'full_name': nameCtrl.text.trim(),
                              'father_name': fatherCtrl.text.trim(),
                              'dob': dobCtrl.text.trim(),
                              'gender': selectedGender,
                              'mobile': mobileCtrl.text.trim(),
                              'alternate_mobile': altMobileCtrl.text.trim(),
                              'email': emailCtrl.text.trim(),
                              'address': addressCtrl.text.trim(),
                              'city': cityCtrl.text.trim(),
                              'state': stateCtrl.text.trim(),
                              'pincode': pincodeCtrl.text.trim(),
                              'designation': desigCtrl.text.trim(),
                              'skill': '${skillCtrl.text.trim()} ($selectedSkillLevel)',
                              'shift_name': selectedShift,
                              'aadhaar_no': aadhaarCtrl.text.trim(),
                              'pan_no': panCtrl.text.trim(),
                              'blood_group': selectedBloodGroup,
                              'profile_photo': selectedPhotoUrl,
                              'medical_cert': medicalFitnessStatus,
                              'medical_validity': medicalValidityCtrl.text.trim(),
                              'police_verification_expiry': pvcExpiryCtrl.text.trim(),
                              'emergency_name': emgNameCtrl.text.trim(),
                              'emergency_relation': emgRelationCtrl.text.trim(),
                              'emergency_phone': emgPhoneCtrl.text.trim(),
                              'vendor_id': vendorId,
                              'vendor_name': vendorName,
                            });

                            setModalState(() => isSaving = false);

                            if (ok && mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✓ Worker registered! ID Clearance request forwarded to Admin, Safety Officer & Super Admin.'),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 4),
                                ),
                              );
                              _loadVendorData();
                            }
                          },
                    child: isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'SUBMIT WORKER FOR 3-TIER ID CLEARANCE',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white, letterSpacing: 0.5),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(color: Color(0xFF06B6D4), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
    );
  }

  Widget _buildFormTextField(TextEditingController ctrl, String hint, IconData icon, {TextInputType? keyboardType}) {
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

  // ==========================================
  // DIGITAL ID BADGE DIALOG
  // ==========================================
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
            border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF06B6D4).withValues(alpha: 0.2),
                blurRadius: 30,
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
                      Icon(Icons.shield, color: Color(0xFF06B6D4), size: 20),
                      SizedBox(width: 6),
                      Text('CONTRACTOR PASS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1)),
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
              const SizedBox(height: 14),
              CircleAvatar(
                radius: 38,
                backgroundImage: NetworkImage(emp['profile_photo'] ?? 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150'),
              ),
              const SizedBox(height: 8),
              Text(emp['full_name'] ?? 'Worker', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
              Text('${emp['designation'] ?? 'Technician'} • ${emp['skill'] ?? 'General'}', style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12)),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white10)),
                child: Column(
                  children: [
                    _buildPassDetailRow('Pass ID', emp['employee_id'] ?? ''),
                    _buildPassDetailRow('Contractor', emp['vendor_name'] ?? 'Contractor'),
                    _buildPassDetailRow('Aadhaar No.', emp['aadhaar_no'] ?? 'N/A'),
                    _buildPassDetailRow('Blood Group', emp['blood_group'] ?? 'O+'),
                    _buildPassDetailRow('Medical Fitness', emp['medical_validity'] ?? 'Valid 2027'),
                    _buildPassDetailRow('ID Status', emp['id_card_status'] ?? 'Issued'),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                child: Column(
                  children: [
                    QrImageView(
                      data: emp['employee_id'] ?? 'EMP-101',
                      version: QrVersions.auto,
                      size: 100.0,
                    ),
                    const SizedBox(height: 2),
                    Text(emp['employee_id'] ?? '', style: const TextStyle(color: Colors.black87, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  minimumSize: const Size(double.infinity, 40),
                ),
                child: const Text('Close ID Card', style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPassDetailRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
          Text(val, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ==========================================
  // MAIN BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    final user = ApiService.currentUser;
    final totalWorkers = _myEmployees.length;
    final insideCount = _myEmployees.where((e) => e['currently_inside'] == 1).length;
    final pendingClearanceCount = _myEmployees.where((e) => e['status'] == 'Pending ID Clearance' || e['status'] == 'Pending Approval').length;
    final activePermitsCount = _myPermits.where((p) => p['status'] == 'Active' || p['status'] == 'Approved').length;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vendor & Contractor Portal',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              user?.fullName ?? 'Contractor Representative',
              style: const TextStyle(fontSize: 11, color: Color(0xFF06B6D4)),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Download Attendance CSV',
            icon: const Icon(Icons.file_download, color: Color(0xFF10B981)),
            onPressed: _downloadAttendanceReport,
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadVendorData,
          ),
          const LogoutIconButton(),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF06B6D4),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          isScrollable: true,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          tabs: [
            const Tab(icon: Icon(Icons.calendar_month, size: 18), text: 'Attendance Analytics'),
            Tab(icon: const Icon(Icons.badge, size: 18), text: 'Workers & IDs ($totalWorkers)'),
            Tab(icon: const Icon(Icons.assignment, size: 18), text: 'Permits (${_myPermits.length})'),
            Tab(icon: const Icon(Icons.inventory_2, size: 18), text: 'Materials (${_myMaterials.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF06B6D4),
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Register Worker', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        onPressed: _openEmployeeRegistrationModal,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF06B6D4)))
          : Column(
              children: [
                // Top Contractor Metrics Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  color: const Color(0xFF1E293B),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem('TOTAL WORKERS', '$totalWorkers', Colors.blueAccent),
                      _buildDivider(),
                      _buildSummaryItem('INSIDE CAMPUS', '$insideCount', Colors.greenAccent),
                      _buildDivider(),
                      _buildSummaryItem('ID APPROVALS', '$pendingClearanceCount', pendingClearanceCount > 0 ? const Color(0xFFF59E0B) : Colors.white54),
                      _buildDivider(),
                      _buildSummaryItem('ACTIVE PTWs', '$activePermitsCount', const Color(0xFF10B981)),
                    ],
                  ),
                ),

                // TAB BAR VIEWS
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAttendanceAnalyticsTab(),
                      _buildWorkersAndIDsTab(),
                      _buildPermitsTab(),
                      _buildMaterialsTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // ==========================================
  // TAB 1: ATTENDANCE ANALYTICS (WEEK / MONTH / YEAR)
  // ==========================================
  Widget _buildAttendanceAnalyticsTab() {
    final summary = _attendanceAnalytics?['summary'] ?? {};
    final breakdown = _attendanceAnalytics?['breakdown'] as List<dynamic>? ?? [];

    final totalPresents = summary['total_presents'] ?? 0;
    final totalLates = summary['total_lates'] ?? 0;
    final totalAbsents = summary['total_absents'] ?? 0;
    final totalOT = summary['total_overtime_hours'] ?? 0;
    final rate = summary['attendance_percentage'] ?? summary['avg_attendance_rate'] ?? summary['avg_monthly_compliance'] ?? 91;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TIME PERIOD SELECTOR (WEEK WISE / MONTH WISE / YEAR WISE)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                _buildPeriodTab('week', '📅 Week-Wise (7 Days)', Icons.view_week),
                _buildPeriodTab('month', '🗓️ Month-Wise', Icons.calendar_month),
                _buildPeriodTab('year', '📊 Year-Wise (2026)', Icons.calendar_today),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // DOWNLOAD CSV BANNER
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0F766E), Color(0xFF1E293B)]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFF10B981),
                  child: Icon(Icons.download, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_selectedAttendancePeriod.toUpperCase()} ATTENDANCE REPORT',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      const Text('Download full shift audit logs & workforce muster in CSV format', style: TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  onPressed: _downloadAttendanceReport,
                  child: const Text('DOWNLOAD', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 11)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // KPI STATS GRID
          Row(
            children: [
              Expanded(
                child: _buildAttendanceMetricCard('PRESENT SHIFTS', '$totalPresents', 'Marked on-site', const Color(0xFF10B981), Icons.check_circle),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildAttendanceMetricCard('ATTENDANCE RATE', '$rate%', 'Shift compliance', const Color(0xFF06B6D4), Icons.percent),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildAttendanceMetricCard('LATE CHECK-INS', '$totalLates', 'Flagged at turnstile', const Color(0xFFF59E0B), Icons.access_time),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAttendanceMetricCard('ABSENT SHIFTS', '$totalAbsents', 'Unaccounted', const Color(0xFFEF4444), Icons.cancel),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAttendanceMetricCard('OVERTIME', '${totalOT}h', 'Approved OT', const Color(0xFF818CF8), Icons.more_time),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // BREAKDOWN HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_selectedAttendancePeriod.toUpperCase()} ATTENDANCE BREAKDOWN',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
              ),
              Text('${breakdown.length} intervals tracked', style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 10),

          // BREAKDOWN LIST
          if (_isAttendanceLoading)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Color(0xFF06B6D4))))
          else if (breakdown.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No attendance records for this period', style: TextStyle(color: Colors.white54))))
          else
            ...breakdown.map((item) {
              final itemRate = item['rate'] ?? 90;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(item['label'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('$itemRate% Present', style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildIntervalStat('Present', '${item['present']}', Colors.greenAccent),
                        _buildIntervalStat('Late', '${item['late']}', Colors.amber),
                        _buildIntervalStat('Absent', '${item['absent']}', Colors.redAccent),
                        _buildIntervalStat('OT', '${item['overtime_hours']}h', const Color(0xFF818CF8)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (itemRate as num) / 100.0,
                        backgroundColor: Colors.white10,
                        valueColor: const AlwaysStoppedAnimation(Color(0xFF10B981)),
                        minHeight: 5,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildPeriodTab(String period, String label, IconData icon) {
    final isSelected = _selectedAttendancePeriod == period;
    return Expanded(
      child: InkWell(
        onTap: () => _loadAttendanceAnalytics(period),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF06B6D4) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.white54, size: 16),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white54,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceMetricCard(String label, String value, String sub, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
              Icon(icon, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900)),
          Text(sub, style: const TextStyle(color: Colors.white38, fontSize: 9.5)),
        ],
      ),
    );
  }

  Widget _buildIntervalStat(String title, String val, Color color) {
    return Expanded(
      child: Row(
        children: [
          Text('$title: ', style: const TextStyle(color: Colors.white38, fontSize: 10)),
          Text(val, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: TOTAL EMPLOYEES & ID CLEARANCE
  // ==========================================
  Widget _buildWorkersAndIDsTab() {
    var list = _myEmployees;

    if (_empFilter == 'ACTIVE') {
      list = list.where((e) => e['status'] == 'Active').toList();
    } else if (_empFilter == 'PENDING') {
      list = list.where((e) => e['status'] == 'Pending ID Clearance' || e['status'] == 'Pending Approval').toList();
    } else if (_empFilter == 'INSIDE') {
      list = list.where((e) => e['currently_inside'] == 1).toList();
    }

    if (_empSearch.isNotEmpty) {
      final q = _empSearch.toLowerCase();
      list = list.where((e) =>
        e['full_name'].toString().toLowerCase().contains(q) ||
        e['employee_id'].toString().toLowerCase().contains(q) ||
        e['designation'].toString().toLowerCase().contains(q) ||
        (e['aadhaar_no'] != null && e['aadhaar_no'].toString().contains(q))
      ).toList();
    }

    return Column(
      children: [
        // SEARCH & FILTER BAR
        Container(
          padding: const EdgeInsets.all(12),
          color: const Color(0xFF0F172A),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search workers by Name, Pass ID, Aadhaar...',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 18),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
                onChanged: (val) => setState(() => _empSearch = val.trim()),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('ALL', 'All (${_myEmployees.length})'),
                    _buildFilterChip('ACTIVE', 'Active Passes (${_myEmployees.where((e) => e['status'] == 'Active').length})'),
                    _buildFilterChip('PENDING', 'Pending ID Approval (${_myEmployees.where((e) => e['status'] == 'Pending ID Clearance' || e['status'] == 'Pending Approval').length})'),
                    _buildFilterChip('INSIDE', 'Inside Site (${_myEmployees.where((e) => e['currently_inside'] == 1).length})'),
                  ],
                ),
              ),
            ],
          ),
        ),

        // WORKERS LIST
        Expanded(
          child: list.isEmpty
              ? const Center(child: Text('No workers matching criteria', style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: list.length,
                  itemBuilder: (ctx, i) {
                    final emp = list[i];
                    final isActive = emp['status'] == 'Active';
                    final isPending = emp['status'] == 'Pending ID Clearance' || emp['status'] == 'Pending Approval';
                    final stage = emp['approval_stage'] ?? (isActive ? 'Completed' : 'Pending Admin');
                    final approvals = emp['approvals'] as Map<String, dynamic>? ?? {};

                    final adminOk = approvals['admin']?['status'] == 'Approved' || isActive;
                    final safetyOk = approvals['safety']?['status'] == 'Approved' || isActive;
                    final superOk = approvals['super_admin']?['status'] == 'Approved' || isActive;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isPending
                              ? const Color(0xFFF59E0B).withValues(alpha: 0.3)
                              : Colors.white10,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundImage: NetworkImage(emp['profile_photo'] ?? 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150'),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      emp['full_name'] ?? 'Worker',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    Text(
                                      '${emp['employee_id'] ?? ''} • ${emp['designation'] ?? 'Technician'}',
                                      style: const TextStyle(color: Color(0xFF06B6D4), fontSize: 12),
                                    ),
                                    Text(
                                      'Aadhaar: ${emp['aadhaar_no'] ?? 'N/A'} • Medical: ${emp['medical_validity'] ?? 'Valid'}',
                                      style: const TextStyle(color: Colors.white38, fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? Colors.green.withValues(alpha: 0.15)
                                      : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isActive ? 'ACTIVE' : 'ID CLEARANCE',
                                  style: TextStyle(
                                    color: isActive ? Colors.greenAccent : const Color(0xFFF59E0B),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(color: Colors.white10, height: 1),
                          const SizedBox(height: 10),

                          // 3-TIER APPROVAL WORKFLOW PROGRESS BAR
                          const Text(
                            'ID GENERATION CLEARANCE WORKFLOW',
                            style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _buildApprovalStep('1. Site Admin', adminOk, approvals['admin']?['status'] == 'Pending'),
                              _buildStepArrow(),
                              _buildApprovalStep('2. Safety (HSE)', safetyOk, approvals['safety']?['status'] == 'Pending'),
                              _buildStepArrow(),
                              _buildApprovalStep('3. Super Admin', superOk, approvals['super_admin']?['status'] == 'Pending'),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // ACTION BUTTONS
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isPending ? 'Stage: $stage' : 'Turnstile QR Pass Active',
                                style: TextStyle(
                                  color: isPending ? const Color(0xFFF59E0B) : Colors.greenAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (isActive)
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF06B6D4),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  ),
                                  icon: const Icon(Icons.qr_code, size: 14, color: Colors.white),
                                  label: const Text('View ID Pass & QR', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                                  onPressed: () => _showDigitalIDCard(emp),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6)),
                                  child: const Text('Pass Generated Post Approval', style: TextStyle(color: Colors.white54, fontSize: 10)),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String filterKey, String label) {
    final isSelected = _empFilter == filterKey;
    return InkWell(
      onTap: () => setState(() => _empFilter = filterKey),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF06B6D4) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildApprovalStep(String label, bool isApproved, bool isCurrent) {
    Color color = Colors.white38;
    IconData icon = Icons.radio_button_unchecked;

    if (isApproved) {
      color = Colors.greenAccent;
      icon = Icons.check_circle;
    } else if (isCurrent) {
      color = const Color(0xFFF59E0B);
      icon = Icons.pending;
    }

    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 9.5, fontWeight: isApproved ? FontWeight.bold : FontWeight.normal),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStepArrow() {
    return const Icon(Icons.chevron_right, color: Colors.white24, size: 16);
  }

  // ==========================================
  // TAB 3: WORK PERMITS (PTW)
  // ==========================================
  Widget _buildPermitsTab() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Contractor Work Permits (PTW)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            Text('${_myPermits.length} permits listed', style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 10),
        ..._myPermits.map((p) {
          final isPending = p['status'].toString().toLowerCase().contains('pending');
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(p['permit_number'] ?? 'PTW', style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(
                      p['status'] ?? 'Active',
                      style: TextStyle(color: isPending ? Colors.amber : Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(p['permit_type'] ?? 'Work Permit', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Text(p['location_zone'] ?? 'Main Construction Zone', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ==========================================
  // TAB 4: MATERIALS (DELIVERY CHALLANS)
  // ==========================================
  Widget _buildMaterialsTab() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Delivery Challans & Gate Passes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            Text('${_myMaterials.length} passes', style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 10),
        ..._myMaterials.map((m) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(m['dc_number'] ?? 'DC-PASS', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(m['movement_type'] ?? 'INWARD', style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(m['material_name'] ?? 'Material', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Text('Qty: ${m['quantity']} • Veh: ${m['vehicle_number'] ?? 'KA 04 E 9921'}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.white54, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 24, color: Colors.white12);
  }
}
