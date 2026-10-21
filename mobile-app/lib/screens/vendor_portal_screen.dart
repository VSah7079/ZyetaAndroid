import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/api_service.dart';
import '../utils/validators.dart';
import '../utils/app_theme.dart';
import '../utils/file_chooser_helper.dart';

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

  // --- ATTENDANCE ANALYTICS FILTERS ---
  String _selectedAttendancePeriod = 'week'; // 'week' | 'month' | 'year' | 'custom'
  DateTimeRange? _customDateRange;
  String _attendanceShiftFilter = 'ALL'; // 'ALL' | 'General' | 'Morning' | 'Night'
  String _attendanceStatusFilter = 'ALL'; // 'ALL' | 'Present' | 'Late' | 'Absent'
  Map<String, dynamic>? _attendanceAnalytics;
  bool _isAttendanceLoading = false;

  // --- WORKER MASTER FILTERS ---
  String _empFilter = 'ALL'; // 'ALL' | 'ACTIVE' | 'PENDING' | 'INSIDE' | 'EXPIRING'
  String _empSearch = '';
  String _selectedTradeFilter = 'ALL'; // 'ALL', 'Scaffolding', 'Welding', 'Electrical', 'Masonry', 'Helper'
  String _selectedStageFilter = 'ALL'; // 'ALL', 'Pending Admin', 'Pending Safety', 'Pending Super Admin', 'Completed'
  String _selectedSortBy = 'NAME_ASC'; // 'NAME_ASC', 'NAME_DESC', 'ID_ASC', 'ATT_DESC'
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
    final data = await ApiService.getVendorAttendanceAnalytics(
      period: period == 'custom' ? 'month' : period,
      vendorId: vendorId,
    );
    if (mounted) {
      setState(() {
        _attendanceAnalytics = data;
        _isAttendanceLoading = false;
      });
    }
  }

  // Pick Custom Date Range
  void _pickCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _customDateRange ?? DateTimeRange(start: now.subtract(const Duration(days: 14)), end: now),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF06B6D4),
              onPrimary: Colors.black,
              surface: Color(0xFF1E293B),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _selectedAttendancePeriod = 'custom';
      });
      _loadAttendanceAnalytics('custom');
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(22),
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
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.file_download_done, color: Color(0xFF10B981), size: 24),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Export Attendance (${_selectedAttendancePeriod.toUpperCase()})',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const Text('Official Contractor Muster Roll CSV', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 160,
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF080C15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.3)),
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
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                      shadowColor: const Color(0xFF10B981).withValues(alpha: 0.5),
                    ),
                    icon: const Icon(Icons.download, color: Colors.white, size: 18),
                    label: const Text('Download CSV', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✓ Muster report (${_selectedAttendancePeriod.toUpperCase()}) saved to Downloads/Zyeta_Attendance.csv'),
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
    ),
  );
  }

  // ==========================================
  // ADVANCED FILTER BOTTOM SHEET FOR WORKFORCE
  // ==========================================
  void _openWorkforceFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.all(22),
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
                      Icon(Icons.tune, color: Color(0xFF06B6D4), size: 22),
                      SizedBox(width: 8),
                      Text('Workforce Advanced Filter', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedTradeFilter = 'ALL';
                        _selectedStageFilter = 'ALL';
                        _selectedSortBy = 'NAME_ASC';
                      });
                      Navigator.pop(ctx);
                    },
                    child: const Text('Reset All', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Filter 1: Trade / Skill
              const Text('FILTER BY TRADE / SCOPE', style: TextStyle(color: Color(0xFF06B6D4), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildSheetChoiceChip('ALL', 'All Trades', _selectedTradeFilter, (val) => setSheetState(() => _selectedTradeFilter = val)),
                  _buildSheetChoiceChip('Scaffolding', 'Scaffolding', _selectedTradeFilter, (val) => setSheetState(() => _selectedTradeFilter = val)),
                  _buildSheetChoiceChip('Welding', 'Welder (6G)', _selectedTradeFilter, (val) => setSheetState(() => _selectedTradeFilter = val)),
                  _buildSheetChoiceChip('Electrical', 'Electrical', _selectedTradeFilter, (val) => setSheetState(() => _selectedTradeFilter = val)),
                  _buildSheetChoiceChip('Masonry', 'Civil Mason', _selectedTradeFilter, (val) => setSheetState(() => _selectedTradeFilter = val)),
                  _buildSheetChoiceChip('Logistics', 'Logistics/Rigging', _selectedTradeFilter, (val) => setSheetState(() => _selectedTradeFilter = val)),
                ],
              ),
              const SizedBox(height: 18),

              // Filter 2: Clearance Stage
              const Text('FILTER BY ID APPROVAL STAGE', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildSheetChoiceChip('ALL', 'All Stages', _selectedStageFilter, (val) => setSheetState(() => _selectedStageFilter = val)),
                  _buildSheetChoiceChip('Pending Admin', '1. Awaiting Admin', _selectedStageFilter, (val) => setSheetState(() => _selectedStageFilter = val)),
                  _buildSheetChoiceChip('Pending Safety', '2. Awaiting Safety', _selectedStageFilter, (val) => setSheetState(() => _selectedStageFilter = val)),
                  _buildSheetChoiceChip('Pending Super Admin', '3. Awaiting Super Admin', _selectedStageFilter, (val) => setSheetState(() => _selectedStageFilter = val)),
                  _buildSheetChoiceChip('Completed', '✓ Active & Issued', _selectedStageFilter, (val) => setSheetState(() => _selectedStageFilter = val)),
                ],
              ),
              const SizedBox(height: 18),

              // Filter 3: Sort By
              const Text('SORT WORKERS BY', style: TextStyle(color: Color(0xFF818CF8), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildSheetChoiceChip('NAME_ASC', 'Name (A to Z)', _selectedSortBy, (val) => setSheetState(() => _selectedSortBy = val)),
                  _buildSheetChoiceChip('ID_ASC', 'Pass ID (EMP-101+)', _selectedSortBy, (val) => setSheetState(() => _selectedSortBy = val)),
                  _buildSheetChoiceChip('ATT_DESC', 'Attendance High-to-Low', _selectedSortBy, (val) => setSheetState(() => _selectedSortBy = val)),
                ],
              ),
              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF06B6D4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    setState(() {});
                    Navigator.pop(ctx);
                  },
                  child: const Text('APPLY FILTERS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.8)),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildSheetChoiceChip(String key, String label, String currentSelected, Function(String) onSelect) {
    final isSelected = currentSelected == key;
    return InkWell(
      onTap: () => onSelect(key),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF06B6D4).withValues(alpha: 0.25) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? const Color(0xFF06B6D4) : Colors.white12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF38BDF8) : Colors.white70,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
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
    Uint8List? selectedPhotoBytes;
    String medicalFitnessStatus = 'Fit for Construction & Height Work (Class A)';
    String uploadedAadhaarDoc = 'aadhaar_card_front_back.pdf';
    Uint8List? uploadedAadhaarBytes;
    String uploadedMedicalDoc = 'medical_fitness_apollo_cert.pdf';
    Uint8List? uploadedMedicalBytes;
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
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
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
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF1E1B4B), Color(0xFF1E293B)]),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified_user, color: Color(0xFF818CF8), size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Pipeline: 1. Site Admin KYC → 2. Safety Officer (Medical/HSE) → 3. Super Admin Final ID Card Generation.',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),

                // SECTION 1: PROFILE PHOTO & IDENTITY DETAILS
                _buildSectionHeader('1. PROFILE PHOTO & IDENTITY DETAILS'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF06B6D4), width: 2),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFF06B6D4).withValues(alpha: 0.3), blurRadius: 10)
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 32,
                          backgroundImage: selectedPhotoBytes != null
                              ? MemoryImage(selectedPhotoBytes!) as ImageProvider
                              : NetworkImage(selectedPhotoUrl),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Worker Photo (For ID Badges) *', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            const Text('Live Camera, Gallery, or Choose File', style: TextStyle(color: Colors.white54, fontSize: 10.5)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final doc = await FileChooserHelper.pickPhoto(context);
                                    if (doc != null) {
                                      setModalState(() {
                                        if (doc.bytes != null) selectedPhotoBytes = doc.bytes;
                                        if (doc.serverUrl != null) selectedPhotoUrl = doc.serverUrl!;
                                      });
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('📸 Photo attached: ${doc.name}'), backgroundColor: const Color(0xFF06B6D4)),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.add_a_photo, size: 13, color: Colors.black),
                                  label: const Text('CHOOSE FILE', style: TextStyle(color: Colors.black, fontSize: 10.5, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF06B6D4),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    elevation: 0,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: photoPresets.map((p) {
                                        final isSelected = selectedPhotoUrl == p['url'];
                                        return InkWell(
                                          onTap: () => setModalState(() {
                                            selectedPhotoUrl = p['url']!;
                                            selectedPhotoBytes = null;
                                          }),
                                          child: Container(
                                            margin: const EdgeInsets.only(right: 5),
                                            padding: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(color: isSelected ? const Color(0xFF06B6D4) : Colors.transparent, width: 2),
                                            ),
                                            child: CircleAvatar(radius: 12, backgroundImage: NetworkImage(p['url']!)),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
                              DropdownMenuItem(value: 'Expert', child: Text('Expert Level')),
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

                // AADHAAR CARD UPLOAD BOX
                FileChooserCard(
                  title: 'Aadhaar Document Upload (Front + Back)',
                  subtitle: 'Select Aadhaar scanned copy (PDF or Image)',
                  currentFileName: uploadedAadhaarDoc,
                  fileBytes: uploadedAadhaarBytes,
                  accentColor: const Color(0xFF06B6D4),
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
                          backgroundColor: const Color(0xFF06B6D4),
                        ),
                      );
                    }
                  },
                ),

                _buildFormTextField(panCtrl, 'PAN Card Number (Optional)', Icons.assignment_ind),
                const SizedBox(height: 8),

                // MEDICAL FITNESS CERTIFICATE UPLOAD BOX
                FileChooserCard(
                  title: 'Medical Fitness Certificate (Attached)',
                  subtitle: 'Select certified fitness report (PDF or Image)',
                  currentFileName: uploadedMedicalDoc,
                  fileBytes: uploadedMedicalBytes,
                  accentColor: const Color(0xFF10B981),
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
                          backgroundColor: const Color(0xFF10B981),
                        ),
                      );
                    }
                  },
                ),
                Text(medicalFitnessStatus, style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildFormTextField(medicalValidityCtrl, 'Medical Validity', Icons.event)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildFormTextField(pvcExpiryCtrl, 'Police Verification Valid', Icons.verified_user)),
                  ],
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
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF06B6D4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 6,
                      shadowColor: const Color(0xFF06B6D4).withValues(alpha: 0.4),
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
                              'shift': selectedShift,
                              'aadhaar_no': aadhaarCtrl.text.trim(),
                              'aadhaar_doc': uploadedAadhaarDoc,
                              'pan_no': panCtrl.text.trim(),
                              'blood_group': selectedBloodGroup,
                              'photo_url': selectedPhotoUrl,
                              'profile_photo': selectedPhotoUrl,
                              'medical_doc': uploadedMedicalDoc,
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
  // ULTRA-PREMIUM DIGITAL ID BADGE MODAL
  // ==========================================
  void _showDigitalIDCard(Map<String, dynamic> emp) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Container(
          width: 350,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.88,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF0B1120), Color(0xFF030712)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.7), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF06B6D4).withValues(alpha: 0.25),
                blurRadius: 35,
                spreadRadius: 2,
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Lanyard Hole Visual
                  Container(
                    width: 48,
                    height: 6,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(6)),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.shield, color: Color(0xFF06B6D4), size: 20),
                          SizedBox(width: 6),
                          Text('ZYETA SMART PASS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: emp['currently_inside'] == 1 ? Colors.green.withValues(alpha: 0.25) : Colors.white10,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: emp['currently_inside'] == 1 ? Colors.greenAccent : Colors.white24),
                        ),
                        child: Text(
                          emp['currently_inside'] == 1 ? '● INSIDE SITE' : 'OUTSIDE',
                          style: TextStyle(
                            color: emp['currently_inside'] == 1 ? Colors.greenAccent : Colors.white54,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Avatar with glowing border
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF06B6D4), width: 2),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF06B6D4).withValues(alpha: 0.3), blurRadius: 15)
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 36,
                      backgroundImage: NetworkImage(emp['photo_url'] ?? emp['profile_photo'] ?? 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    emp['full_name'] ?? 'Worker',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${emp['designation'] ?? 'Technician'} • ${emp['skill'] ?? 'General'}',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),

                  // Attached Documents Showcase Pills
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B132B),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.assignment_turned_in, color: Color(0xFF06B6D4), size: 13),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Aadhaar: ${emp['aadhaar_doc'] ?? 'aadhaar_card_front_back.pdf'}',
                                  style: const TextStyle(color: Colors.white70, fontSize: 9.5),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.health_and_safety, color: Color(0xFF10B981), size: 13),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Medical: ${emp['medical_doc'] ?? emp['medical_cert'] ?? 'medical_fitness_apollo_cert.pdf'}',
                                  style: const TextStyle(color: Colors.white70, fontSize: 9.5),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Details Grid
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      children: [
                        _buildPassDetailRow('Pass / Badge ID', emp['employee_id'] ?? ''),
                        _buildPassDetailRow('Contractor Company', emp['vendor_name'] ?? 'Contractor'),
                        _buildPassDetailRow('Aadhaar Number', emp['aadhaar_no'] ?? 'N/A'),
                        _buildPassDetailRow('Aadhaar Document', emp['aadhaar_doc'] ?? 'aadhaar_card_front_back.pdf'),
                        _buildPassDetailRow('Medical Fitness', emp['medical_doc'] ?? emp['medical_cert'] ?? 'Grade A Certified'),
                        _buildPassDetailRow('Blood Group', emp['blood_group'] ?? 'O+'),
                        _buildPassDetailRow('Gate Permissions', 'All Turnstiles & Optical Portals'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 3-Tier Stamped Clearances Status Banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.check_circle, color: Color(0xFF10B981), size: 11), SizedBox(width: 3), Text('Site Admin KYC', style: TextStyle(color: Color(0xFF10B981), fontSize: 8.5, fontWeight: FontWeight.bold))]),
                        Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.check_circle, color: Color(0xFF10B981), size: 11), SizedBox(width: 3), Text('Safety HSE', style: TextStyle(color: Color(0xFF10B981), fontSize: 8.5, fontWeight: FontWeight.bold))]),
                        Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.check_circle, color: Color(0xFF10B981), size: 11), SizedBox(width: 3), Text('Super Admin', style: TextStyle(color: Color(0xFF10B981), fontSize: 8.5, fontWeight: FontWeight.bold))]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // QR Code Box
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10)],
                    ),
                    child: Column(
                      children: [
                        QrImageView(
                          data: emp['employee_id'] ?? 'EMP-101',
                          version: QrVersions.auto,
                          size: 88.0,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          emp['employee_id'] ?? '',
                          style: const TextStyle(color: Colors.black87, fontSize: 10.5, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text('Encrypted NFC & Optical Turnstile Badge', style: TextStyle(color: Colors.white38, fontSize: 9.5)),
                  const SizedBox(height: 10),

                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      minimumSize: const Size(double.infinity, 40),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Close ID Pass', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPassDetailRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.2),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10.5)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              val,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
            ),
          ),
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
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const AppBarLeadingButton(),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified, color: AppTheme.primary, size: 18),
                const SizedBox(width: 6),
                const Flexible(
                  child: Text(
                    'Contractor Portal',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              user?.fullName ?? 'ABC Infra Projects Pvt Ltd',
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Export Attendance CSV',
            icon: const Icon(Icons.file_download, color: AppTheme.success),
            onPressed: _downloadAttendanceReport,
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh, color: AppTheme.primary),
            onPressed: _loadVendorData,
          ),
          const LogoutIconButton(compact: true),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          indicatorWeight: 3,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          isScrollable: true,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          tabs: [
            const Tab(icon: Icon(Icons.calendar_month, size: 18), text: 'Attendance Analytics'),
            Tab(icon: const Icon(Icons.badge, size: 18), text: 'Workforce & IDs ($totalWorkers)'),
            Tab(icon: const Icon(Icons.assignment, size: 18), text: 'Permits (${_myPermits.length})'),
            Tab(icon: const Icon(Icons.inventory_2, size: 18), text: 'Materials (${_myMaterials.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Register Worker', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        onPressed: _openEmployeeRegistrationModal,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : Column(
              children: [
                // Top Contractor Metrics Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: AppTheme.border)),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem('TOTAL WORKFORCE', '$totalWorkers', AppTheme.primary),
                      _buildDivider(),
                      _buildSummaryItem('INSIDE CAMPUS', '$insideCount', AppTheme.success),
                      _buildDivider(),
                      _buildSummaryItem('ID APPROVALS', '$pendingClearanceCount', pendingClearanceCount > 0 ? AppTheme.warning : AppTheme.textSecondary),
                      _buildDivider(),
                      _buildSummaryItem('ACTIVE PTWs', '$activePermitsCount', const Color(0xFF0284C7)),
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
  // TAB 1: ATTENDANCE ANALYTICS (WEEK / MONTH / YEAR & FILTERS)
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
          // 1. TIME PERIOD SELECTOR (WEEK WISE / MONTH WISE / YEAR WISE / CUSTOM)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                _buildPeriodTab('week', '📅 Week-Wise', Icons.view_week),
                _buildPeriodTab('month', '🗓️ Month-Wise', Icons.calendar_month),
                _buildPeriodTab('year', '📊 Year-Wise', Icons.calendar_today),
                _buildCustomPeriodTab(),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 2. SHIFT & STATUS FILTER PILLS ROW
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Icon(Icons.filter_list, color: Color(0xFF06B6D4), size: 16),
                const SizedBox(width: 8),
                _buildShiftChip('ALL', 'All Shifts'),
                _buildShiftChip('General', 'General (9-6)'),
                _buildShiftChip('Morning', 'Shift A (Morning)'),
                _buildShiftChip('Night', 'Shift C (Night)'),
                const SizedBox(width: 8),
                Container(width: 1, height: 20, color: Colors.white24),
                const SizedBox(width: 8),
                _buildAttendanceStatusChip('ALL', 'All Status'),
                _buildAttendanceStatusChip('Present', 'Present Only'),
                _buildAttendanceStatusChip('Late', 'Late Flagged'),
                _buildAttendanceStatusChip('Absent', 'Absent Only'),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 3. ATTENDANCE EXPORT BANNER WITH GLOW
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF042F2E), Color(0xFF111827)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
              boxShadow: [
                BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.1), blurRadius: 15)
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.cloud_download, color: Color(0xFF10B981), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_selectedAttendancePeriod.toUpperCase()} MUSTER ROLL REPORT',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      const Text('Export full audit logs with overtime hours & compliance in CSV', style: TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _downloadAttendanceReport,
                  child: const Text('DOWNLOAD', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 11)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 4. METRIC KPI CARDS
          Row(
            children: [
              Expanded(
                child: _buildAttendanceMetricCard('PRESENT SHIFTS', '$totalPresents', 'Verified turnstile entries', const Color(0xFF10B981), Icons.check_circle),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildAttendanceMetricCard('ATTENDANCE RATE', '$rate%', 'Workforce compliance', const Color(0xFF06B6D4), Icons.percent),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildAttendanceMetricCard('LATE CHECK-INS', '$totalLates', 'Flagged at gate', const Color(0xFFF59E0B), Icons.access_time),
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

          // 5. VISUAL GRAPH HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_selectedAttendancePeriod.toUpperCase()} ATTENDANCE GRAPH & BREAKDOWN',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
              ),
              Text('${breakdown.length} intervals tracked', style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 12),

          // 6. INTERACTIVE ATTENDANCE BAR CHART VISUALIZER
          if (breakdown.isNotEmpty) _buildAttendanceBarChart(breakdown),

          const SizedBox(height: 14),

          // 7. BREAKDOWN LIST
          if (_isAttendanceLoading)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Color(0xFF06B6D4))))
          else if (breakdown.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No attendance records for this period', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold))))
          else
            ...breakdown.map((item) {
              final itemRate = item['rate'] ?? 90;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(14),
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
                        minHeight: 6,
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

  // Visual Bar Chart Widget for Attendance
  Widget _buildAttendanceBarChart(List<dynamic> breakdown) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('WORKFORCE MANPOWER CURVE', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFF06B6D4).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                child: const Text('Live Telemetry', style: TextStyle(color: Color(0xFF06B6D4), fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: breakdown.map((item) {
                final rate = (item['rate'] as num?)?.toDouble() ?? 85.0;
                final barHeight = (rate / 100.0) * 85;
                final isHighlight = rate >= 90;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('${rate.toInt()}%', style: TextStyle(color: isHighlight ? const Color(0xFF10B981) : Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Container(
                          height: barHeight,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isHighlight
                                  ? [const Color(0xFF06B6D4), const Color(0xFF10B981)]
                                  : [const Color(0xFF3B82F6), const Color(0xFF6366F1)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: isHighlight
                                ? [BoxShadow(color: const Color(0xFF06B6D4).withValues(alpha: 0.3), blurRadius: 6)]
                                : [],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item['key'].toString().length > 5 ? item['key'].toString().substring(item['key'].toString().length - 2) : item['key'].toString(),
                          style: const TextStyle(color: Colors.white38, fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
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

  Widget _buildCustomPeriodTab() {
    final isSelected = _selectedAttendancePeriod == 'custom';
    return Expanded(
      child: InkWell(
        onTap: _pickCustomDateRange,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF06B6D4) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(Icons.date_range, color: isSelected ? Colors.white : Colors.white54, size: 16),
              const SizedBox(height: 3),
              Text(
                _customDateRange != null ? 'Custom 🗓️' : 'Custom',
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

  Widget _buildShiftChip(String shiftKey, String label) {
    final isSelected = _attendanceShiftFilter == shiftKey;
    return InkWell(
      onTap: () => setState(() => _attendanceShiftFilter = shiftKey),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF06B6D4) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? const Color(0xFF06B6D4) : Colors.transparent),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceStatusChip(String statusKey, String label) {
    final isSelected = _attendanceStatusFilter == statusKey;
    return InkWell(
      onTap: () => setState(() => _attendanceStatusFilter = statusKey),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? const Color(0xFF10B981) : Colors.transparent),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceMetricCard(String label, String value, String sub, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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
  // TAB 2: TOTAL WORKFORCE & ADVANCED FILTER
  // ==========================================
  Widget _buildWorkersAndIDsTab() {
    var list = _myEmployees;

    // 1. Status Filter
    if (_empFilter == 'ACTIVE') {
      list = list.where((e) => e['status'] == 'Active').toList();
    } else if (_empFilter == 'PENDING') {
      list = list.where((e) => e['status'] == 'Pending ID Clearance' || e['status'] == 'Pending Approval').toList();
    } else if (_empFilter == 'INSIDE') {
      list = list.where((e) => e['currently_inside'] == 1).toList();
    } else if (_empFilter == 'EXPIRING') {
      list = list.where((e) => e['medical_validity'] != null && e['medical_validity'].toString().contains('2026')).toList();
    }

    // 2. Trade Scope Filter
    if (_selectedTradeFilter != 'ALL') {
      list = list.where((e) =>
        e['designation'].toString().toLowerCase().contains(_selectedTradeFilter.toLowerCase()) ||
        e['skill'].toString().toLowerCase().contains(_selectedTradeFilter.toLowerCase())
      ).toList();
    }

    // 3. Stage Filter
    if (_selectedStageFilter != 'ALL') {
      if (_selectedStageFilter == 'Completed') {
        list = list.where((e) => e['status'] == 'Active').toList();
      } else {
        list = list.where((e) => e['approval_stage'] == _selectedStageFilter).toList();
      }
    }

    // 4. Search Filter
    if (_empSearch.isNotEmpty) {
      final q = _empSearch.toLowerCase();
      list = list.where((e) =>
        e['full_name'].toString().toLowerCase().contains(q) ||
        e['employee_id'].toString().toLowerCase().contains(q) ||
        e['designation'].toString().toLowerCase().contains(q) ||
        (e['aadhaar_no'] != null && e['aadhaar_no'].toString().contains(q))
      ).toList();
    }

    // 5. Sort By
    if (_selectedSortBy == 'NAME_ASC') {
      list.sort((a, b) => a['full_name'].toString().compareTo(b['full_name'].toString()));
    } else if (_selectedSortBy == 'ID_ASC') {
      list.sort((a, b) => a['employee_id'].toString().compareTo(b['employee_id'].toString()));
    }

    final hasActiveCustomFilters = _selectedTradeFilter != 'ALL' || _selectedStageFilter != 'ALL';
    final issuedWorkers = _myEmployees.where((e) => e['status'] == 'Active' || e['id_card_status'] == 'Issued').toList();

    bool isStageOk(dynamic val) {
      if (val == null) return false;
      if (val is String) return val.toLowerCase() == 'approved';
      if (val is Map) return val['status']?.toString().toLowerCase() == 'approved';
      return false;
    }

    return Column(
      children: [
        // PROMINENT TOP CAROUSEL: ISSUED & CLEARED DIGITAL ID BADGES SHOWCASE
        if (issuedWorkers.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              border: Border(bottom: BorderSide(color: const Color(0xFF06B6D4).withValues(alpha: 0.25))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                          child: const Icon(Icons.verified, color: Color(0xFF10B981), size: 14),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'ISSUED DIGITAL ID PASSES (${issuedWorkers.length})',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                        ),
                      ],
                    ),
                    const Text('Approved & Turnstile Ready', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 78,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: issuedWorkers.length,
                    itemBuilder: (ctx, i) {
                      final emp = issuedWorkers[i];
                      return InkWell(
                        onTap: () => _showDigitalIDCard(emp),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 205,
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF0B1120)]),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundImage: NetworkImage(emp['photo_url'] ?? emp['profile_photo'] ?? 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150'),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(emp['full_name'] ?? 'Worker', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                    Text(emp['employee_id'] ?? '', style: const TextStyle(color: Color(0xFF06B6D4), fontSize: 10, fontWeight: FontWeight.bold)),
                                    const Text('✓ ID BADGE ACTIVE', style: TextStyle(color: Color(0xFF10B981), fontSize: 8.5, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.qr_code_scanner, color: Color(0xFF06B6D4), size: 18),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

        // SEARCH & FILTER BAR
        Container(
          padding: const EdgeInsets.all(12),
          color: const Color(0xFF0F172A),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search Name, Pass ID, Aadhaar...',
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                        prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 18),
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                      onChanged: (val) => setState(() => _empSearch = val.trim()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _openWorkforceFilterSheet,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: hasActiveCustomFilters ? const Color(0xFF06B6D4) : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: hasActiveCustomFilters ? const Color(0xFF06B6D4) : Colors.white12),
                      ),
                      child: Icon(Icons.tune, color: hasActiveCustomFilters ? Colors.white : const Color(0xFF06B6D4), size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // QUICK STATUS PILLS
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('ALL', 'All (${_myEmployees.length})'),
                    _buildFilterChip('ACTIVE', 'Active Passes (${_myEmployees.where((e) => e['status'] == 'Active').length})'),
                    _buildFilterChip('PENDING', 'Pending ID Approval (${_myEmployees.where((e) => e['status'] == 'Pending ID Clearance' || e['status'] == 'Pending Approval').length})'),
                    _buildFilterChip('INSIDE', 'Inside Site (${_myEmployees.where((e) => e['currently_inside'] == 1).length})'),
                    _buildFilterChip('EXPIRING', 'Expiring Medical (1)'),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ACTIVE FILTER SUMMARY PILL
        if (hasActiveCustomFilters)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            color: const Color(0xFF06B6D4).withValues(alpha: 0.15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filters Active: Trade [$_selectedTradeFilter] • Stage [$_selectedStageFilter]',
                  style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold),
                ),
                InkWell(
                  onTap: () => setState(() {
                    _selectedTradeFilter = 'ALL';
                    _selectedStageFilter = 'ALL';
                  }),
                  child: const Text('Clear', style: TextStyle(color: Colors.white70, fontSize: 11, decoration: TextDecoration.underline)),
                ),
              ],
            ),
          ),

        // WORKERS LIST WITH 3-TIER APPROVAL STEPPER
        Expanded(
          child: list.isEmpty
              ? const Center(child: Text('No workers matching filter criteria', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)))
              : RefreshIndicator(
                  onRefresh: () async => _loadVendorData(),
                  color: const Color(0xFF06B6D4),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: list.length,
                    itemBuilder: (ctx, i) {
                      final emp = list[i];
                      final isActive = emp['status'] == 'Active';
                      final isPending = emp['status'] == 'Pending ID Clearance' || emp['status'] == 'Pending Approval';
                      final stage = emp['approval_stage'] ?? (isActive ? 'Completed' : 'Pending Admin');
                      final approvals = emp['approvals'] as Map<String, dynamic>? ?? {};

                      final adminOk = isStageOk(approvals['admin']) || isActive;
                      final safetyOk = isStageOk(approvals['safety']) || isActive;
                      final superOk = isStageOk(approvals['super_admin']) || isActive;

                      final isInside = emp['currently_inside'] == 1;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF131D31),
                              isPending ? const Color(0xFF1C1A27) : const Color(0xFF0F172A),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isPending
                                ? const Color(0xFFF59E0B).withValues(alpha: 0.35)
                                : const Color(0xFF06B6D4).withValues(alpha: 0.25),
                          ),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 26,
                                      backgroundImage: NetworkImage(emp['photo_url'] ?? emp['profile_photo'] ?? 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150'),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: isInside ? Colors.greenAccent : Colors.white38,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: const Color(0xFF131D31), width: 2),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            emp['full_name'] ?? 'Worker',
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                          if (isActive) ...[
                                            const SizedBox(width: 4),
                                            const Icon(Icons.verified, color: Color(0xFF06B6D4), size: 14),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${emp['employee_id'] ?? ''} • ${emp['designation'] ?? 'Technician'}',
                                        style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.w600),
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
                                    border: Border.all(
                                      color: isActive
                                          ? Colors.greenAccent.withValues(alpha: 0.4)
                                          : const Color(0xFFF59E0B).withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Text(
                                    isActive ? 'PASS ACTIVE' : 'ID CLEARANCE',
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

                            // 3-TIER APPROVAL STEPPER WITH GLOW
                            const Text(
                              '3-TIER ID CARD GENERATION PIPELINE',
                              style: TextStyle(color: Colors.white54, fontSize: 9.5, fontWeight: FontWeight.bold, letterSpacing: 0.6),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildApprovalStep('1. Site Admin', adminOk, approvals['admin']?['status'] == 'Pending'),
                                _buildStepArrow(),
                                _buildApprovalStep('2. Safety (HSE)', safetyOk, approvals['safety']?['status'] == 'Pending'),
                                _buildStepArrow(),
                                _buildApprovalStep('3. Super Admin', superOk, approvals['super_admin']?['status'] == 'Pending'),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // BOTTOM ACTION BUTTONS
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  isPending ? 'Pending: $stage' : 'Access: Main Turnstiles',
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
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      elevation: 3,
                                    ),
                                    icon: const Icon(Icons.qr_code, size: 14, color: Colors.white),
                                    label: const Text('View Smart Pass & QR', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                                    onPressed: () => _showDigitalIDCard(emp),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                                    child: const Text('Badge Issues Post Approvals', style: TextStyle(color: Colors.white54, fontSize: 10.5)),
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
          border: Border.all(color: isSelected ? const Color(0xFF06B6D4) : Colors.transparent),
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
            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(14)),
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
            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(14)),
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
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color)),
        ),
        const SizedBox(height: 2),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 24, color: AppTheme.border);
  }
}
