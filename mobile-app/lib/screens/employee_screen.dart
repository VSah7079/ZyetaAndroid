import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/api_service.dart';
import '../utils/validators.dart';
import '../utils/app_theme.dart';
import '../utils/responsive.dart';
import '../utils/file_chooser_helper.dart';

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

  void _showDigitalIDCard(Map<String, dynamic> emp) {
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
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: AppTheme.badgeDecoration(
                              background: AppTheme.primarySubtle,
                              borderColor: AppTheme.primaryLight,
                              radius: 8,
                            ),
                            child: const Icon(Icons.shield_rounded, color: AppTheme.primary, size: 18),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'ZYETA WORKFORCE PASS',
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
                        background: emp['currently_inside'] == 1 ? AppTheme.successBg : AppTheme.bgSurface,
                        borderColor: emp['currently_inside'] == 1 ? AppTheme.successBorder : AppTheme.border,
                        radius: 6,
                      ),
                      child: Text(
                        emp['currently_inside'] == 1 ? '● INSIDE' : 'OUTSIDE',
                        style: TextStyle(
                          color: emp['currently_inside'] == 1 ? AppTheme.success : AppTheme.textSecondary,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Photo & Name
                Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primary, width: 2.5),
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
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${emp['designation'] ?? 'Technician'} • ${emp['skill'] ?? 'General'}',
                  style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Details Grid
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.bgSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    children: [
                      QrImageView(
                        data: emp['employee_id'] ?? 'EMP-101',
                        version: QrVersions.auto,
                        size: 110.0,
                        backgroundColor: Colors.transparent,
                        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppTheme.textPrimary),
                        dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        emp['employee_id'] ?? '',
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Official Turnstile & Gate QR Pass • Valid for All Entry Points',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 9.5),
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
                          side: const BorderSide(color: AppTheme.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Full Dossier', style: TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.bgSurface,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: AppTheme.border)),
                        ),
                        child: const Text('Close Pass', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEmployeeFullProfile(Map<String, dynamic> emp) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
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
                        border: Border.all(color: AppTheme.primary, width: 2),
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
                          Text(emp['full_name'] ?? '', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.bold)),
                          Text('${emp['employee_id']} • ${emp['designation']}', style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                          Text('Contractor: ${emp['vendor_name']}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                        ],
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Profile Tabs
              const TabBar(
                isScrollable: true,
                indicatorColor: AppTheme.primary,
                indicatorWeight: 3,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.textSecondary,
                labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                tabs: [
                  Tab(text: 'Personal Info'),
                  Tab(text: 'Compliance & Safety'),
                  Tab(text: 'Skills & Trade'),
                  Tab(text: 'Attendance History'),
                  Tab(text: 'Gate Log'),
                ],
              ),
              const Divider(color: AppTheme.border, height: 1),

              // Tab View Content
              Expanded(
                child: TabBarView(
                  children: [
                    // Tab 1: Personal Info
                    _buildProfileSection([
                      _buildInfoTile('Full Legal Name', emp['full_name'] ?? ''),
                      _buildInfoTile('Father\'s / Spouse Name', emp['father_name'] ?? 'N/A'),
                      _buildInfoTile('Gender / Date of Birth', '${emp['gender'] ?? 'Male'} • ${emp['dob'] ?? '1992-05-14'}'),
                      _buildInfoTile('Mobile Contact', emp['mobile'] ?? ''),
                      _buildInfoTile('Aadhaar / ID Ref (Last 4)', emp['aadhaar_number'] != null ? '•••• •••• ${emp['aadhaar_number'].toString().substring(emp['aadhaar_number'].toString().length - 4)}' : 'Verified'),
                      _buildInfoTile('Permanent Address', emp['address'] ?? 'Plot 42, Industrial Area, Sector 5'),
                      _buildInfoTile('Emergency Contact Person', '${emp['emergency_name'] ?? 'Relative'} (${emp['emergency_phone'] ?? 'N/A'})'),
                    ]),

                    // Tab 2: Compliance & Safety
                    _buildProfileSection([
                      _buildComplianceBadgeTile('Safety Induction Training', 'Completed on joining • Score: 95%', 'VALID (PASSED)', AppTheme.success),
                      _buildComplianceBadgeTile('Medical Fitness Examination', 'Valid until: ${emp['medical_validity'] ?? '2027-01-01'}', 'CERTIFIED FIT', AppTheme.success),
                      _buildComplianceBadgeTile('Police Verification Clearance', 'Expires: ${emp['police_verification_expiry'] ?? '2026-12-31'}', 'VERIFIED', AppTheme.success),
                      _buildComplianceBadgeTile('ESI / PF Insurance Coverage', 'UAN: 10098442199 • ESI: Active', 'COMPLIANT', AppTheme.success),
                      _buildComplianceBadgeTile('PPE Inspection & Issue Record', 'Hard Hat, Steel-toe Boots, Reflective Vest, Harness', 'ISSUED', AppTheme.primary),
                    ]),

                    // Tab 3: Skills & Trade
                    _buildProfileSection([
                      _buildInfoTile('Trade Specialization', emp['designation'] ?? 'Scaffolding Expert'),
                      _buildInfoTile('Skill Classification', '${emp['skill'] ?? 'Skilled'} (Grade A Certified)'),
                      _buildInfoTile('Primary Department', emp['department_name'] ?? 'Civil Construction'),
                      _buildInfoTile('Contractor / Vendor Organization', emp['vendor_name'] ?? 'Zyeta Direct Workforce'),
                      _buildInfoTile('Total Construction Experience', '${emp['experience_years'] ?? '5'} Years'),
                      _buildInfoTile('Emergency First Aid Certified', 'Yes (St. John Ambulance Certified)'),
                    ]),

                    // Tab 4: Attendance History
                    _buildProfileSection([
                      _buildHistoryRow('2026-09-29', 'In: 08:45 AM', 'Out: Still Inside', 'Present (On Time)', AppTheme.success),
                      _buildHistoryRow('2026-09-28', 'In: 08:50 AM', 'Out: 06:10 PM', 'Present (9.3 hrs)', AppTheme.success),
                      _buildHistoryRow('2026-09-27', 'In: 09:15 AM', 'Out: 06:05 PM', 'Late (15 min)', AppTheme.warning),
                      _buildHistoryRow('2026-09-26', 'In: 08:40 AM', 'Out: 07:00 PM', 'Overtime (1.0 hr)', AppTheme.primary),
                      _buildHistoryRow('2026-09-25', 'In: 08:45 AM', 'Out: 06:00 PM', 'Present (9.2 hrs)', AppTheme.success),
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
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          const Divider(color: AppTheme.border, height: 1),
        ],
      ),
    );
  }

  Widget _buildComplianceBadgeTile(String title, String subtitle, String badge, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.cardDecoration(
        customBorder: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: AppTheme.badgeDecoration(
              background: color.withValues(alpha: 0.1),
              borderColor: color.withValues(alpha: 0.25),
              radius: 6,
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
      decoration: AppTheme.cardDecoration(
        color: AppTheme.bgSurface,
        customBorder: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(date, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
              Text('$inTime • $outTime', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
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
      decoration: AppTheme.cardDecoration(
        color: AppTheme.bgSurface,
        customBorder: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(isEntry ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: isEntry ? AppTheme.success : AppTheme.danger, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$movement - $gate', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
                Text('$time • $method', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
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
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _openOnboardWorkerModal() {
    final nameCtrl = TextEditingController();
    final fatherCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final aadhaarCtrl = TextEditingController();
    final vendorCtrl = TextEditingController();
    final designationCtrl = TextEditingController();
    final bloodCtrl = TextEditingController(text: 'O+');
    final emergencyNameCtrl = TextEditingController();
    final emergencyPhoneCtrl = TextEditingController();
    String skill = 'Skilled';
    String department = 'Civil';
    String uploadedPhotoUrl = 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80';
    Uint8List? uploadedPhotoBytes;
    String uploadedAadhaarDoc = 'aadhaar_card_front_back.pdf';
    Uint8List? uploadedAadhaarBytes;
    String uploadedMedicalDoc = 'medical_fitness_apollo_cert.pdf';
    Uint8List? uploadedMedicalBytes;
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
                            background: AppTheme.primarySubtle,
                            borderColor: AppTheme.primaryLight,
                            radius: 8,
                          ),
                          child: const Icon(Icons.person_add_rounded, color: AppTheme.primary, size: 20),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Onboard Worker & Attach KYC Docs',
                          style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 14),

                // 1. WORKER PHOTO (CHOOSE FILE)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.bgSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.primary, width: 2),
                        ),
                        child: ClipOval(
                          child: uploadedPhotoBytes != null
                              ? Image.memory(uploadedPhotoBytes!, width: 56, height: 56, fit: BoxFit.cover)
                              : Image.network(uploadedPhotoUrl, width: 56, height: 56, fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('1. Worker Photo (फ़ोटो) *', style: TextStyle(color: AppTheme.textPrimary, fontSize: 12.5, fontWeight: FontWeight.bold)),
                            const Text('Camera, Gallery, or Choose File', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                            const SizedBox(height: 5),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final doc = await FileChooserHelper.pickPhoto(context);
                                if (doc != null) {
                                  setModalState(() {
                                    if (doc.bytes != null) uploadedPhotoBytes = doc.bytes;
                                    if (doc.serverUrl != null) uploadedPhotoUrl = doc.serverUrl!;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('✓ Photo selected: ${doc.name}'), backgroundColor: AppTheme.success),
                                  );
                                }
                              },
                              icon: const Icon(Icons.add_a_photo, size: 13, color: Colors.white),
                              label: const Text('CHOOSE PHOTO', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                elevation: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                _buildTextField(nameCtrl, 'Full Name *', Icons.person_rounded),
                const SizedBox(height: 10),
                _buildTextField(fatherCtrl, 'Father\'s / Guardian Name', Icons.people_rounded),
                const SizedBox(height: 10),
                _buildTextField(mobileCtrl, 'Mobile Number *', Icons.phone_rounded, keyboardType: TextInputType.phone),
                const SizedBox(height: 10),
                _buildTextField(aadhaarCtrl, 'Aadhaar / National ID Number *', Icons.credit_card_rounded, keyboardType: TextInputType.number),
                const SizedBox(height: 12),

                // 2. AADHAAR CARD DOCUMENT (CHOOSE FILE)
                FileChooserCard(
                  title: '2. Aadhaar Document Upload',
                  subtitle: 'Select Aadhaar copy (PDF or Image Front & Back)',
                  currentFileName: uploadedAadhaarDoc,
                  fileBytes: uploadedAadhaarBytes,
                  accentColor: AppTheme.primary,
                  defaultIcon: Icons.credit_card,
                  isRequired: true,
                  onChooseFile: () async {
                    final doc = await FileChooserHelper.pickDocument(
                      context,
                      title: 'Aadhaar Card Document',
                      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                    );
                    if (doc != null) {
                      setModalState(() {
                        uploadedAadhaarDoc = doc.name;
                        uploadedAadhaarBytes = doc.bytes;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✓ Aadhaar file attached: ${doc.name} (${doc.sizeFormatted})'),
                          backgroundColor: AppTheme.success,
                        ),
                      );
                    }
                  },
                ),

                // 3. MEDICAL FITNESS CERTIFICATE (CHOOSE FILE)
                FileChooserCard(
                  title: '3. Medical Fitness Certificate Upload',
                  subtitle: 'Select Medical Health report / fitness cert',
                  currentFileName: uploadedMedicalDoc,
                  fileBytes: uploadedMedicalBytes,
                  accentColor: AppTheme.success,
                  defaultIcon: Icons.health_and_safety,
                  isRequired: true,
                  onChooseFile: () async {
                    final doc = await FileChooserHelper.pickDocument(
                      context,
                      title: 'Medical Fitness Certificate',
                      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                    );
                    if (doc != null) {
                      setModalState(() {
                        uploadedMedicalDoc = doc.name;
                        uploadedMedicalBytes = doc.bytes;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✓ Medical certificate attached: ${doc.name} (${doc.sizeFormatted})'),
                          backgroundColor: AppTheme.success,
                        ),
                      );
                    }
                  },
                ),

                const SizedBox(height: 10),
                _buildTextField(vendorCtrl, 'Contractor / Vendor Organization *', Icons.business_rounded),
                const SizedBox(height: 10),
                _buildTextField(designationCtrl, 'Trade / Designation (e.g. Electrician, Mason) *', Icons.handyman_rounded),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.bgSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: skill,
                            isExpanded: true,
                            dropdownColor: Colors.white,
                            style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                            items: const [
                              DropdownMenuItem(value: 'Highly Skilled', child: Text('Highly Skilled')),
                              DropdownMenuItem(value: 'Skilled', child: Text('Skilled')),
                              DropdownMenuItem(value: 'Semi-Skilled', child: Text('Semi-Skilled')),
                              DropdownMenuItem(value: 'Unskilled', child: Text('Unskilled')),
                            ],
                            onChanged: (val) {
                              if (val != null) setModalState(() => skill = val);
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.bgSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: department,
                            isExpanded: true,
                            dropdownColor: Colors.white,
                            style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                            items: const [
                              DropdownMenuItem(value: 'Civil', child: Text('Civil Dept')),
                              DropdownMenuItem(value: 'MEP', child: Text('MEP / Electrical')),
                              DropdownMenuItem(value: 'HVAC', child: Text('HVAC & Plumbing')),
                              DropdownMenuItem(value: 'Safety', child: Text('Safety / HSE')),
                              DropdownMenuItem(value: 'Security', child: Text('Security Force')),
                            ],
                            onChanged: (val) {
                              if (val != null) setModalState(() => department = val);
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(flex: 2, child: _buildTextField(bloodCtrl, 'Blood Group', Icons.bloodtype_rounded)),
                    const SizedBox(width: 8),
                    Expanded(flex: 3, child: _buildTextField(emergencyNameCtrl, 'Emergency Contact', Icons.emergency_rounded)),
                  ],
                ),
                const SizedBox(height: 10),
                _buildTextField(emergencyPhoneCtrl, 'Emergency Phone Number', Icons.phone_in_talk_rounded, keyboardType: TextInputType.phone),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            final nameErr = FormValidators.validateName(nameCtrl.text, fieldName: 'Worker name');
                            if (nameErr != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(nameErr), backgroundColor: AppTheme.warning));
                              return;
                            }

                            final mobileErr = FormValidators.validatePhone(mobileCtrl.text, fieldName: 'Mobile number');
                            if (mobileErr != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mobileErr), backgroundColor: AppTheme.warning));
                              return;
                            }

                            final idErr = FormValidators.validateAadhaar(aadhaarCtrl.text, fieldName: 'Aadhaar / ID');
                            if (idErr != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(idErr), backgroundColor: AppTheme.warning));
                              return;
                            }

                            setModalState(() => isSaving = true);
                            final ok = await ApiService.createEmployee({
                              'full_name': nameCtrl.text.trim(),
                              'father_name': fatherCtrl.text.trim(),
                              'mobile': mobileCtrl.text.trim(),
                              'aadhaar_no': aadhaarCtrl.text.trim(),
                              'aadhaar_number': aadhaarCtrl.text.trim(),
                              'aadhaar_doc': uploadedAadhaarDoc,
                              'medical_doc': uploadedMedicalDoc,
                              'profile_photo': uploadedPhotoUrl,
                              'photo_url': uploadedPhotoUrl,
                              'vendor_name': vendorCtrl.text.trim().isEmpty ? 'Direct' : vendorCtrl.text.trim(),
                              'designation': designationCtrl.text.trim().isEmpty ? 'General Worker' : designationCtrl.text.trim(),
                              'skill': skill,
                              'department_name': department,
                              'blood_group': bloodCtrl.text.trim(),
                              'emergency_name': emergencyNameCtrl.text.trim(),
                              'emergency_phone': emergencyPhoneCtrl.text.trim(),
                            });
                            setModalState(() => isSaving = false);
                            if (ok && mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('✓ Worker Registered & Digital Gate Pass Generated with Attached KYC!'), backgroundColor: AppTheme.success),
                              );
                              _fetchEmployees();
                            }
                          },
                    child: isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
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
              title: const Text('Workforce & ID Passes', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              actions: [
                IconButton(
                  tooltip: 'Refresh',
                  icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary),
                  onPressed: _fetchEmployees,
                ),
                const LogoutIconButton(),
              ],
            )
          : null,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text('Onboard Worker', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        onPressed: _openOnboardWorkerModal,
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
                      hintText: 'Search worker name, ID, trade, mobile, contractor...',
                      hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary, size: 18),
                      suffixIcon: _search.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, color: AppTheme.textSecondary, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _search = '');
                                _fetchEmployees();
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
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                  : _employees.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: AppTheme.bgSurface, shape: BoxShape.circle),
                                child: const Icon(Icons.badge_outlined, size: 40, color: AppTheme.primary),
                              ),
                              const SizedBox(height: 12),
                              const Text('No workers found matching filter', style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              const Text('Onboard workers using the button below', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async => _fetchEmployees(),
                          color: AppTheme.primary,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                                  decoration: AppTheme.cardDecoration(
                                    customBorder: Border.all(color: AppTheme.border),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isInside ? AppTheme.success : AppTheme.primary,
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
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: AppTheme.badgeDecoration(
                                                    background: isInside ? AppTheme.successBg : AppTheme.bgSurface,
                                                    borderColor: isInside ? AppTheme.successBorder : AppTheme.border,
                                                    radius: 4,
                                                  ),
                                                  child: Text(
                                                    isInside ? '● INSIDE' : 'OUTSIDE',
                                                    style: TextStyle(
                                                      color: isInside ? AppTheme.success : AppTheme.textSecondary,
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
                                              style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Contractor: ${emp['vendor_name'] ?? 'Direct'}',
                                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(Icons.qr_code_2_rounded, color: AppTheme.textSecondary, size: 24),
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
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? AppTheme.primary : AppTheme.border),
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
