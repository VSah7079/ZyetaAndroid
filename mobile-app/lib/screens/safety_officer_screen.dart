import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/validators.dart';
import 'inside_headcount_screen.dart';
import 'emergency_muster_screen.dart';
import 'toolbox_talk_screen.dart';

class SafetyOfficerScreen extends StatefulWidget {
  const SafetyOfficerScreen({super.key});

  @override
  State<SafetyOfficerScreen> createState() => _SafetyOfficerScreenState();
}

class _SafetyOfficerScreenState extends State<SafetyOfficerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic>? _safetyKPIs;
  List<dynamic> _permits = [];
  List<dynamic> _inspections = [];
  List<dynamic> _hazards = [];
  List<dynamic> _punches = [];
  String _selectedPunchColorFilter = 'ALL';
  String _punchSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadSafetyData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadSafetyData() async {
    setState(() => _isLoading = true);
    final kpis = await ApiService.getSafetyKPIs();
    final permits = await ApiService.getPermits();
    final inspections = await ApiService.getSafetyInspections();
    final hazards = await ApiService.getSafetyHazards();
    final punches = await ApiService.getSafetyPunches(
      colorType: _selectedPunchColorFilter,
      search: _punchSearchQuery.isEmpty ? null : _punchSearchQuery,
    );

    if (mounted) {
      setState(() {
        _safetyKPIs = kpis;
        _permits = permits;
        _inspections = inspections;
        _hazards = hazards;
        _punches = punches;
        _isLoading = false;
      });
    }
  }

  // ==========================================
  // MODAL 1: RECORD NEW SAFETY PUNCH (RED / YELLOW / GREEN)
  // ==========================================
  void _openNewPunchModal() {
    String selectedColor = 'RED'; // 'RED', 'YELLOW', 'GREEN'
    String selectedWorker = 'Ramesh Patel (EMP-101)';
    String workerId = 'EMP-101';
    String vendorName = 'ABC Infra Projects Pvt Ltd';
    final zoneCtrl = TextEditingController(text: 'Block A - 4th Floor Facade Scaffolding');
    final reasonCtrl = TextEditingController(text: 'Working at 14m scaffold elevation without chin strap and harness hook loose.');
    final actionCtrl = TextEditingController(text: 'Immediate Work Stoppage. Chin-strap fastened & harness dual-lanyards anchored to 100% lifeline.');
    String selectedPhotoUrl = 'https://images.unsplash.com/photo-1541888946425-d0fbb186156a?w=400&auto=format&fit=crop&q=80';
    final customPhotoCtrl = TextEditingController();
    bool isSaving = false;

    final workerOptions = [
      {'name': 'Ramesh Patel', 'id': 'EMP-101', 'vendor': 'ABC Infra Projects Pvt Ltd'},
      {'name': 'Amitabh Sen', 'id': 'EMP-102', 'vendor': 'Apex MEP Solutions'},
      {'name': 'Sanjay Gupta', 'id': 'EMP-103', 'vendor': 'FastTrack Logistics'},
      {'name': 'Vikram Rathore', 'id': 'EMP-104', 'vendor': 'ABC Infra Projects Pvt Ltd'},
      {'name': 'Manoj Sharma', 'id': 'EMP-105', 'vendor': 'Apex MEP Solutions'},
    ];

    final photoPresets = [
      {
        'title': 'Height Scaffolding',
        'url': 'https://images.unsplash.com/photo-1541888946425-d0fbb186156a?w=400&auto=format&fit=crop&q=80',
        'desc': 'Scaffolding / Height safety'
      },
      {
        'title': 'Electrical & PPE',
        'url': 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=400&auto=format&fit=crop&q=80',
        'desc': 'PPE violation / Electrical'
      },
      {
        'title': 'Welding Fire Watch',
        'url': 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=400&auto=format&fit=crop&q=80',
        'desc': 'Spark blanket / Welding safe'
      },
      {
        'title': 'Excavation & Shoring',
        'url': 'https://images.unsplash.com/photo-1589939705384-5185137a7f0f?w=400&auto=format&fit=crop&q=80',
        'desc': 'Trench barricading & shoring'
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          Color accentColor;
          String demeritText;

          if (selectedColor == 'RED') {
            accentColor = const Color(0xFFEF4444);
            demeritText = '⚠️ 🔴 RED PUNCH: Critical Stop-Work Violation • -50 Demerit Points • Disciplinary Stand-Down';
          } else if (selectedColor == 'YELLOW') {
            accentColor = const Color(0xFFF59E0B);
            demeritText = '⚠️ 🟡 YELLOW PUNCH: Moderate Warning • -15 Demerit Points • 24-Hour Rectification Notice';
          } else {
            accentColor = const Color(0xFF10B981);
            demeritText = '🌟 🟢 GREEN PUNCH: Safety Excellence • +25 Zero Harm Points • Commendation Record';
          }

          return Padding(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Modal Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.gps_fixed, color: accentColor, size: 22),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Record Safety Punch',
                                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '3-Color Severity: Red / Yellow / Green',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 1. THREE COLOR SELECTOR (RED / YELLOW / GREEN)
                  const Text(
                    'PUNCH COLOR SEVERITY CLASSIFICATION *',
                    style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // RED PUNCH
                      Expanded(
                        child: InkWell(
                          onTap: () => setModalState(() {
                            selectedColor = 'RED';
                            reasonCtrl.text = 'Working at 14m scaffold elevation without chin strap and harness hook loose.';
                            actionCtrl.text = 'Immediate Work Stoppage. Chin-strap fastened & harness dual-lanyards anchored.';
                          }),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                            decoration: BoxDecoration(
                              color: selectedColor == 'RED'
                                  ? const Color(0xFFEF4444).withValues(alpha: 0.25)
                                  : const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selectedColor == 'RED' ? const Color(0xFFEF4444) : Colors.white12,
                                width: selectedColor == 'RED' ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                const Text('🔴 RED', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 4),
                                Text(
                                  'Stop-Work\nCritical (-50pt)',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: selectedColor == 'RED' ? Colors.white : Colors.white60,
                                    fontSize: 10,
                                    fontWeight: selectedColor == 'RED' ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // YELLOW PUNCH
                      Expanded(
                        child: InkWell(
                          onTap: () => setModalState(() {
                            selectedColor = 'YELLOW';
                            reasonCtrl.text = 'Missing cut-resistant safety gloves & eye protection goggles in active fabrication zone.';
                            actionCtrl.text = 'Provided compliant PPE kit from store and issued 24hr first-warning notice.';
                          }),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                            decoration: BoxDecoration(
                              color: selectedColor == 'YELLOW'
                                  ? const Color(0xFFF59E0B).withValues(alpha: 0.25)
                                  : const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selectedColor == 'YELLOW' ? const Color(0xFFF59E0B) : Colors.white12,
                                width: selectedColor == 'YELLOW' ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                const Text('🟡 YELLOW', style: TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 4),
                                Text(
                                  'Warning\nModerate (-15pt)',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: selectedColor == 'YELLOW' ? Colors.white : Colors.white60,
                                    fontSize: 10,
                                    fontWeight: selectedColor == 'YELLOW' ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // GREEN PUNCH
                      Expanded(
                        child: InkWell(
                          onTap: () => setModalState(() {
                            selectedColor = 'GREEN';
                            reasonCtrl.text = 'Proactive deployment of spark capture fire blankets and standby fire extinguisher before welding.';
                            actionCtrl.text = 'Commended in HSE daily briefing. Awarded +25 Zero Harm Safety points.';
                          }),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                            decoration: BoxDecoration(
                              color: selectedColor == 'GREEN'
                                  ? const Color(0xFF10B981).withValues(alpha: 0.25)
                                  : const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selectedColor == 'GREEN' ? const Color(0xFF10B981) : Colors.white12,
                                width: selectedColor == 'GREEN' ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                const Text('🟢 GREEN', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 4),
                                Text(
                                  'Excellence\nReward (+25pt)',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: selectedColor == 'GREEN' ? Colors.white : Colors.white60,
                                    fontSize: 10,
                                    fontWeight: selectedColor == 'GREEN' ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Consequence / Demerit Info Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      demeritText,
                      style: TextStyle(color: accentColor, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. WORKER SELECTOR
                  const Text(
                    'WORKFORCE CONTRACTOR INVOLVED *',
                    style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedWorker,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF1E293B),
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        items: workerOptions.map((w) {
                          final label = '${w['name']} (${w['id']})';
                          return DropdownMenuItem<String>(
                            value: label,
                            child: Text('$label — ${w['vendor']}'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() {
                              selectedWorker = val;
                              final match = workerOptions.firstWhere((w) => '${w['name']} (${w['id']})' == val);
                              workerId = match['id']!;
                              vendorName = match['vendor']!;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 3. LOCATION / SITE ZONE
                  _buildModalTextField(zoneCtrl, 'Location / Site Zone *', Icons.location_on),
                  const SizedBox(height: 10),

                  // 4. PUNCH REASON / DESCRIPTION
                  TextField(
                    controller: reasonCtrl,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Punch Reason / Observation *',
                      labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                      hintText: 'Describe violation or safe practice observed...',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 30),
                        child: Icon(Icons.rate_review, color: Colors.white54, size: 20),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 5. PHOTO UPLOAD & EVIDENCE PREVIEW
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.camera_alt, color: Color(0xFF06B6D4), size: 16),
                          SizedBox(width: 6),
                          Text(
                            'PHOTO EVIDENCE ATTACHMENT *',
                            style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () {
                          showDialog(
                            context: ctx,
                            builder: (dCtx) => AlertDialog(
                              backgroundColor: const Color(0xFF1E293B),
                              title: const Text('Enter Custom Image URL', style: TextStyle(color: Colors.white, fontSize: 15)),
                              content: TextField(
                                controller: customPhotoCtrl,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                decoration: const InputDecoration(
                                  hintText: 'https://...',
                                  hintStyle: TextStyle(color: Colors.white38),
                                ),
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancel')),
                                ElevatedButton(
                                  onPressed: () {
                                    if (customPhotoCtrl.text.trim().isNotEmpty) {
                                      setModalState(() => selectedPhotoUrl = customPhotoCtrl.text.trim());
                                    }
                                    Navigator.pop(dCtx);
                                  },
                                  child: const Text('Set Photo'),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_photo_alternate, size: 14, color: Color(0xFF06B6D4)),
                        label: const Text('Custom URL', style: TextStyle(color: Color(0xFF06B6D4), fontSize: 11)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Photo presets row
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: photoPresets.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, idx) {
                        final p = photoPresets[idx];
                        final isSelected = selectedPhotoUrl == p['url'];
                        return InkWell(
                          onTap: () => setModalState(() => selectedPhotoUrl = p['url']!),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? accentColor : Colors.white24,
                                width: isSelected ? 2.5 : 1,
                              ),
                              image: DecorationImage(
                                image: NetworkImage(p['url']!),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    gradient: const LinearGradient(
                                      colors: [Colors.black87, Colors.transparent],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 4,
                                  left: 4,
                                  right: 4,
                                  child: Text(
                                    p['title']!,
                                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isSelected)
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
                                      child: const Icon(Icons.check, size: 12, color: Colors.white),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 6. CORRECTIVE ACTION
                  TextField(
                    controller: actionCtrl,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Immediate Action / Rectification *',
                      labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                      hintText: 'Action taken on site by HSE inspector...',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Icon(Icons.handyman, color: Colors.white54, size: 20),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 7. SUBMIT BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              final workerName = selectedWorker.split(' (')[0];
                              final reason = reasonCtrl.text.trim();
                              if (reason.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please enter punch reason / observation'), backgroundColor: Colors.orange),
                                );
                                return;
                              }

                              setModalState(() => isSaving = true);
                              await ApiService.createSafetyPunch({
                                'color_type': selectedColor,
                                'worker_name': workerName,
                                'worker_id': workerId,
                                'vendor_name': vendorName,
                                'zone': zoneCtrl.text.trim(),
                                'reason': reason,
                                'photo_url': selectedPhotoUrl,
                                'corrective_action': actionCtrl.text.trim(),
                                'category': selectedColor == 'RED'
                                    ? 'Critical Stop-Work'
                                    : (selectedColor == 'YELLOW' ? 'PPE Warning' : 'Safety Excellence'),
                              });
                              setModalState(() => isSaving = false);

                              if (mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('✅ Safety Punch [$selectedColor] Recorded Successfully!'),
                                    backgroundColor: selectedColor == 'RED'
                                        ? Colors.red
                                        : (selectedColor == 'YELLOW' ? Colors.orange : Colors.green),
                                  ),
                                );
                                _loadSafetyData();
                              }
                            },
                      child: isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.save, color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'SUBMIT $selectedColor SAFETY PUNCH',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // MODAL 2: ENDORSE WORK PERMIT (PTW)
  // ==========================================
  void _showEndorsePermitModal(Map<String, dynamic> permit) {
    final remarksCtrl = TextEditingController(text: 'Safety precautions verified on-site. Endorsement granted.');
    final checklist = [
      {'title': 'Fire extinguisher & Spark arrestor verified', 'checked': true},
      {'title': 'Full-body harness & Lifeline anchor inspected', 'checked': true},
      {'title': 'Atmospheric multi-gas detector test safe', 'checked': true},
      {'title': 'LOTO electrical isolation lock applied', 'checked': true},
      {'title': 'Trained safety standby person posted', 'checked': true},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
                        Icon(Icons.verified_user, color: Color(0xFFF59E0B), size: 24),
                        SizedBox(width: 8),
                        Text(
                          'HSE Permit Endorsement',
                          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(permit['permit_number'] ?? '', style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(permit['permit_type'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Zone: ${permit['location_zone']}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      Text('Vendor: ${permit['vendor_name']}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'MANDATORY SAFETY PRECAUTIONS VERIFICATION',
                  style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                const SizedBox(height: 8),
                ...checklist.map((item) => CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      activeColor: const Color(0xFF10B981),
                      title: Text(item['title'] as String, style: const TextStyle(color: Colors.white, fontSize: 12)),
                      value: item['checked'] as bool,
                      onChanged: (val) {
                        setModalState(() => item['checked'] = val ?? false);
                      },
                    )),
                const SizedBox(height: 12),
                TextField(
                  controller: remarksCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'HSE Safety Officer remarks...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await ApiService.rejectPermit(permit['id'], reason: 'Failed HSE Safety Inspection');
                          _loadSafetyData();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Permit Rejected on Safety Grounds'), backgroundColor: Colors.red),
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('REJECT', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await ApiService.approvePermit(permit['id'], comments: remarksCtrl.text.trim());
                          _loadSafetyData();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('✅ HSE Safety Endorsement Granted!'), backgroundColor: Colors.green),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('ENDORSE & APPROVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  // ==========================================
  // MODAL 3: REPORT HAZARD
  // ==========================================
  void _openNewHazardModal() {
    final titleCtrl = TextEditingController();
    final zoneCtrl = TextEditingController(text: 'Block B - Facade');
    final actionCtrl = TextEditingController();
    String severity = 'HIGH';
    String category = 'Working at Height';
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
                        Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
                        SizedBox(width: 8),
                        Text('Report Safety Hazard / Near-Miss', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 14),
                _buildModalTextField(titleCtrl, 'Hazard Description *', Icons.warning),
                const SizedBox(height: 10),
                _buildModalTextField(zoneCtrl, 'Location / Zone *', Icons.location_on),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(10)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: severity,
                            isExpanded: true,
                            dropdownColor: const Color(0xFF1E293B),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            items: const [
                              DropdownMenuItem(value: 'CRITICAL', child: Text('🔴 CRITICAL')),
                              DropdownMenuItem(value: 'HIGH', child: Text('🟠 HIGH')),
                              DropdownMenuItem(value: 'MEDIUM', child: Text('🟡 MEDIUM')),
                              DropdownMenuItem(value: 'LOW', child: Text('🟢 LOW')),
                            ],
                            onChanged: (val) {
                              if (val != null) setModalState(() => severity = val);
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(10)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: category,
                            isExpanded: true,
                            dropdownColor: const Color(0xFF1E293B),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            items: const [
                              DropdownMenuItem(value: 'Working at Height', child: Text('🪜 Height')),
                              DropdownMenuItem(value: 'Electrical & Slip', child: Text('⚡ Electrical')),
                              DropdownMenuItem(value: 'Fire & Welding', child: Text('🔥 Fire')),
                              DropdownMenuItem(value: 'Chemical & Hazmat', child: Text('☣️ Chemical')),
                              DropdownMenuItem(value: 'Housekeeping', child: Text('🧹 Housekeeping')),
                            ],
                            onChanged: (val) {
                              if (val != null) setModalState(() => category = val);
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildModalTextField(actionCtrl, 'Immediate Corrective Action Taken *', Icons.handyman),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF43F5E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            final err = FormValidators.validateRequired(titleCtrl.text, fieldName: 'Hazard description', minLength: 5);
                            if (err != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: Colors.orange));
                              return;
                            }
                            setModalState(() => isSaving = true);
                            await ApiService.createSafetyHazard({
                              'title': titleCtrl.text.trim(),
                              'zone': zoneCtrl.text.trim(),
                              'severity': severity,
                              'category': category,
                              'corrective_action': actionCtrl.text.trim(),
                            });
                            setModalState(() => isSaving = false);
                            if (mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Safety Hazard Logged & Alert Dispatched!'), backgroundColor: Colors.green),
                              );
                              _loadSafetyData();
                            }
                          },
                    child: isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('SUBMIT HAZARD REPORT', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // MODAL 4: CONDUCT AUDIT
  // ==========================================
  void _openNewAuditModal() {
    final titleCtrl = TextEditingController(text: 'Routine PPE & Site Safety Audit');
    final zoneCtrl = TextEditingController(text: 'Main Construction Floor 3');
    final notesCtrl = TextEditingController();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
                        Icon(Icons.checklist, color: Color(0xFF10B981)),
                        SizedBox(width: 8),
                        Text('Conduct Site Safety Audit', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 14),
                _buildModalTextField(titleCtrl, 'Audit Title *', Icons.assignment),
                const SizedBox(height: 10),
                _buildModalTextField(zoneCtrl, 'Inspection Zone / Area *', Icons.location_on),
                const SizedBox(height: 10),
                _buildModalTextField(notesCtrl, 'Inspector Findings & Recommendations', Icons.notes),
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
                            setModalState(() => isSaving = true);
                            await ApiService.createSafetyInspection({
                              'title': titleCtrl.text.trim(),
                              'zone': zoneCtrl.text.trim(),
                              'findings': notesCtrl.text.trim(),
                            });
                            setModalState(() => isSaving = false);
                            if (mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Safety Audit Recorded Successfully!'), backgroundColor: Colors.green),
                              );
                              _loadSafetyData();
                            }
                          },
                    child: isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('RECORD SAFETY AUDIT', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showImagePreviewDialog(String imageUrl, String punchCode, String reason) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    imageUrl,
                    height: 260,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      color: Colors.white10,
                      child: const Center(child: Icon(Icons.broken_image, color: Colors.white38, size: 48)),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    radius: 16,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.close, color: Colors.white, size: 18),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📷 Photographic Evidence • $punchCode', style: const TextStyle(color: Color(0xFF06B6D4), fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(reason, style: const TextStyle(color: Colors.white, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModalTextField(TextEditingController ctrl, String hint, IconData icon) {
    return TextField(
      controller: ctrl,
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.health_and_safety, color: Color(0xFFF59E0B), size: 20),
                SizedBox(width: 8),
                Text('HSE & Safety Command', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
            Text(
              ApiService.currentUser?.fullName ?? 'Safety Officer',
              style: const TextStyle(fontSize: 11, color: Colors.white54),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Live Inside Muster',
            icon: const Icon(Icons.groups, color: Color(0xFF06B6D4)),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const InsideHeadcountScreen()));
            },
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadSafetyData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color(0xFFF59E0B),
          indicatorWeight: 3,
          labelColor: const Color(0xFFF59E0B),
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          tabs: [
            const Tab(icon: Icon(Icons.dashboard, size: 18), text: 'Command'),
            Tab(icon: const Icon(Icons.gps_fixed, size: 18), text: '🎯 Punches (${_punches.length})'),
            const Tab(icon: Icon(Icons.assignment_turned_in, size: 18), text: 'PTW Safety'),
            const Tab(icon: Icon(Icons.checklist, size: 18), text: 'Site Audits'),
            const Tab(icon: Icon(Icons.warning, size: 18), text: 'Hazards'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildHSEOverviewTab(),
                _buildSafetyPunchesTab(),
                _buildPTWSafetyTab(),
                _buildAuditsTab(),
                _buildHazardsTab(),
              ],
            ),
    );
  }

  // ==========================================
  // TAB 1: HSE COMMAND & OVERVIEW
  // ==========================================
  Widget _buildHSEOverviewTab() {
    final redCount = _punches.where((p) => p['color_type'] == 'RED').length;
    final yellowCount = _punches.where((p) => p['color_type'] == 'YELLOW').length;
    final greenCount = _punches.where((p) => p['color_type'] == 'GREEN').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ZERO HARM BANNER
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF065F46), Color(0xFF064E3B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.military_tech, color: Colors.amberAccent, size: 36),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ZERO HARM MILESTONE',
                        style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                      Text(
                        '${_safetyKPIs?['days_without_lti'] ?? 142} DAYS LTI FREE',
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Site safety index is optimal. 0 fatal or major incidents.',
                        style: TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // SAFETY PUNCH SYSTEM HIGHLIGHT CARD (RED / YELLOW / GREEN)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.gps_fixed, color: Color(0xFF06B6D4), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'SAFETY PUNCH SYSTEM',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () => _tabController.animateTo(1),
                      icon: const Icon(Icons.arrow_forward, size: 14, color: Color(0xFF06B6D4)),
                      label: const Text('View All', style: TextStyle(color: Color(0xFF06B6D4), fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // RED PUNCH BADGE
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                        ),
                        child: Column(
                          children: [
                            Text('$redCount', style: const TextStyle(color: Color(0xFFEF4444), fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            const Text('🔴 Red Stop-Work', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // YELLOW PUNCH BADGE
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                        ),
                        child: Column(
                          children: [
                            Text('$yellowCount', style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            const Text('🟡 Yellow Warning', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // GREEN PUNCH BADGE
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                        ),
                        child: Column(
                          children: [
                            Text('$greenCount', style: const TextStyle(color: Color(0xFF10B981), fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            const Text('🟢 Green Reward', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF06B6D4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.add, color: Colors.black87, size: 18),
                    label: const Text('RECORD SAFETY PUNCH (PHOTO + REASON)', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 11)),
                    onPressed: _openNewPunchModal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // HSE METRICS GRID
          const Text('SAFETY PERFORMANCE INDICATORS', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildMetricCard('Safety Compliance', _safetyKPIs?['safety_score'] ?? '98.4%', const Color(0xFF10B981), Icons.shield)),
              const SizedBox(width: 10),
              Expanded(child: _buildMetricCard('Active High-Risk PTWs', '${_safetyKPIs?['active_high_risk_permits'] ?? 4}', const Color(0xFFF59E0B), Icons.assignment_late)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildMetricCard('PPE Compliance', _safetyKPIs?['ppe_compliance_rate'] ?? '96.8%', const Color(0xFF06B6D4), Icons.health_and_safety)),
              const SizedBox(width: 10),
              Expanded(child: _buildMetricCard('Open Hazard Logs', '${_safetyKPIs?['open_hazards'] ?? 2}', const Color(0xFFF43F5E), Icons.warning_amber)),
            ],
          ),
          const SizedBox(height: 20),

          // QUICK SAFETY ACTION BUTTONS
          const Text('SAFETY OFFICER ACTIONS', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Safety Punches',
                  Icons.gps_fixed,
                  const Color(0xFF06B6D4),
                  () => _tabController.animateTo(1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionButton(
                  'Conduct Audit',
                  Icons.checklist_rtl,
                  const Color(0xFF10B981),
                  _openNewAuditModal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Report Hazard',
                  Icons.warning_amber,
                  const Color(0xFFF43F5E),
                  _openNewHazardModal,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionButton(
                  'Toolbox Talks (TBT)',
                  Icons.record_voice_over,
                  const Color(0xFFF97316),
                  () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ToolboxTalkScreen()));
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Emergency Evacuation',
                  Icons.emergency,
                  const Color(0xFFE11D48),
                  () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyMusterScreen()));
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: SAFETY PUNCH SYSTEM (RED / YELLOW / GREEN)
  // ==========================================
  Widget _buildSafetyPunchesTab() {
    final redCount = _punches.where((p) => p['color_type'] == 'RED').length;
    final yellowCount = _punches.where((p) => p['color_type'] == 'YELLOW').length;
    final greenCount = _punches.where((p) => p['color_type'] == 'GREEN').length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF06B6D4),
        icon: const Icon(Icons.add_a_photo, color: Colors.black87),
        label: const Text('Record Safety Punch', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        onPressed: _openNewPunchModal,
      ),
      body: Column(
        children: [
          // PUNCH SUMMARY & COLOR FILTER TABS
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF0F172A),
            child: Column(
              children: [
                // SEARCH BAR
                TextField(
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  onChanged: (val) {
                    _punchSearchQuery = val;
                    _loadSafetyData();
                  },
                  decoration: InputDecoration(
                    hintText: 'Search punches by worker, code, reason, zone...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 18),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),

                // 4 FILTER CHIPS (ALL, RED, YELLOW, GREEN)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('ALL', 'All (${_punches.length})', const Color(0xFF64748B)),
                      const SizedBox(width: 8),
                      _buildFilterChip('RED', '🔴 Red Stop-Work ($redCount)', const Color(0xFFEF4444)),
                      const SizedBox(width: 8),
                      _buildFilterChip('YELLOW', '🟡 Yellow Warning ($yellowCount)', const Color(0xFFF59E0B)),
                      const SizedBox(width: 8),
                      _buildFilterChip('GREEN', '🟢 Green Excellence ($greenCount)', const Color(0xFF10B981)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // PUNCH LIST
          Expanded(
            child: _punches.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.gps_fixed, size: 48, color: Colors.white24),
                        const SizedBox(height: 12),
                        const Text('No Safety Punches Found', style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        const Text('Tap "+ Record Safety Punch" to log an on-site observation.', style: TextStyle(color: Colors.white38, fontSize: 12)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _openNewPunchModal,
                          icon: const Icon(Icons.add, color: Colors.black87),
                          label: const Text('Record First Punch', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF06B6D4)),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _punches.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, idx) {
                      final p = _punches[idx];
                      final colorType = p['color_type'] ?? 'RED';
                      Color borderAccent;
                      Color bgGlow;
                      String badgeText;
                      IconData badgeIcon;

                      if (colorType == 'RED') {
                        borderAccent = const Color(0xFFEF4444);
                        bgGlow = const Color(0xFFEF4444).withValues(alpha: 0.1);
                        badgeText = '🔴 CRITICAL STOP-WORK (-50 PTS)';
                        badgeIcon = Icons.dangerous;
                      } else if (colorType == 'YELLOW') {
                        borderAccent = const Color(0xFFF59E0B);
                        bgGlow = const Color(0xFFF59E0B).withValues(alpha: 0.1);
                        badgeText = '🟡 MODERATE WARNING (-15 PTS)';
                        badgeIcon = Icons.warning_amber_rounded;
                      } else {
                        borderAccent = const Color(0xFF10B981);
                        bgGlow = const Color(0xFF10B981).withValues(alpha: 0.1);
                        badgeText = '🟢 SAFETY EXCELLENCE (+25 PTS)';
                        badgeIcon = Icons.verified;
                      }

                      final photoUrl = p['photo_url'];

                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderAccent.withValues(alpha: 0.6), width: 1.5),
                          boxShadow: [
                            BoxShadow(color: borderAccent.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // TOP SEVERITY BANNER
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: bgGlow,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                                border: Border(bottom: BorderSide(color: borderAccent.withValues(alpha: 0.2))),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(badgeIcon, size: 16, color: borderAccent),
                                      const SizedBox(width: 6),
                                      Text(
                                        badgeText,
                                        style: TextStyle(color: borderAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F172A),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: borderAccent.withValues(alpha: 0.4)),
                                    ),
                                    child: Text(
                                      p['punch_code'] ?? '',
                                      style: TextStyle(color: borderAccent, fontWeight: FontWeight.bold, fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // WORKER & VENDOR ROW
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: borderAccent.withValues(alpha: 0.2),
                                        child: Icon(Icons.person, color: borderAccent, size: 20),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  p['worker_name'] ?? 'Worker',
                                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                                ),
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                                  decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(4)),
                                                  child: Text(
                                                    p['worker_id'] ?? '',
                                                    style: const TextStyle(color: Color(0xFF06B6D4), fontSize: 10, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              p['vendor_name'] ?? 'Vendor',
                                              style: const TextStyle(color: Colors.white54, fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Status Chip
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: (p['status'] == 'COMMENDED' || p['status'] == 'RESOLVED')
                                              ? Colors.green.withValues(alpha: 0.2)
                                              : Colors.red.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          p['status'] ?? 'OPEN',
                                          style: TextStyle(
                                            color: (p['status'] == 'COMMENDED' || p['status'] == 'RESOLVED') ? Colors.greenAccent : Colors.redAccent,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // REASON / OBSERVATION QUOTE BOX
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F172A),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.white10),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(Icons.format_quote, size: 14, color: Colors.white38),
                                            SizedBox(width: 4),
                                            Text('OBSERVATION / REASON', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          p['reason'] ?? '',
                                          style: const TextStyle(color: Colors.white, fontSize: 12.5, height: 1.3),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // PHOTO EVIDENCE THUMBNAIL (IF PRESENT)
                                  if (photoUrl != null && photoUrl.toString().isNotEmpty)
                                    InkWell(
                                      onTap: () => _showImagePreviewDialog(photoUrl, p['punch_code'] ?? '', p['reason'] ?? ''),
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        height: 130,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: Colors.white24),
                                          image: DecorationImage(
                                            image: NetworkImage(photoUrl),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        child: Stack(
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(10),
                                                gradient: const LinearGradient(
                                                  colors: [Colors.black54, Colors.transparent],
                                                  begin: Alignment.bottomCenter,
                                                  end: Alignment.topCenter,
                                                ),
                                              ),
                                            ),
                                            const Positioned(
                                              bottom: 8,
                                              left: 10,
                                              child: Row(
                                                children: [
                                                  Icon(Icons.zoom_in, color: Colors.white, size: 16),
                                                  SizedBox(width: 6),
                                                  Text(
                                                    '🔍 Tap to inspect photographic evidence',
                                                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 10),

                                  // CORRECTIVE ACTION
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.black26,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.handyman, size: 14, color: Color(0xFF06B6D4)),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'Corrective Action: ${p['corrective_action'] ?? 'Action in progress'}',
                                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // FOOTER: ZONE + DATE + DELETE BUTTON
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on, size: 13, color: Colors.white38),
                                          const SizedBox(width: 4),
                                          Text(p['zone'] ?? '', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                        ],
                                      ),
                                      IconButton(
                                        tooltip: 'Delete Punch',
                                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.white38),
                                        onPressed: () async {
                                          await ApiService.deleteSafetyPunch(p['id']);
                                          _loadSafetyData();
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Punch Record Removed'), backgroundColor: Colors.red),
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label, Color chipColor) {
    final isSelected = _selectedPunchColorFilter == filterKey;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPunchColorFilter = filterKey;
        });
        _loadSafetyData();
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? chipColor.withValues(alpha: 0.25) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : Colors.white12,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TAB 3: PTW SAFETY ENDORSEMENTS
  // ==========================================
  Widget _buildPTWSafetyTab() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _permits.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, idx) {
        final p = _permits[idx];
        final isApproved = p['status'] == 'Approved';
        final isPending = p['status'].toString().contains('Pending');

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isPending ? const Color(0xFFF59E0B).withValues(alpha: 0.5) : Colors.white10,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.4)),
                    ),
                    child: Text(p['permit_number'] ?? '', style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isApproved ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      p['status'] ?? '',
                      style: TextStyle(
                        color: isApproved ? Colors.greenAccent : Colors.orangeAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                p['permit_type'] ?? '',
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                p['description'] ?? '',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.white38),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${p['location_zone']} • ${p['vendor_name']}',
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (isPending)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.verified_user, size: 16, color: Colors.black87),
                    label: const Text('CONDUCT SAFETY ENDORSEMENT', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12)),
                    onPressed: () => _showEndorsePermitModal(p),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Endorsed by: ${p['approved_by'] ?? 'HSE Officer'}',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 4: SITE AUDITS & INSPECTIONS
  // ==========================================
  Widget _buildAuditsTab() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF10B981),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Site Audit', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        onPressed: _openNewAuditModal,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _inspections.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, idx) {
          final item = _inspections[idx];
          final isPassed = item['status'] == 'PASSED';

          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isPassed ? Colors.green.withValues(alpha: 0.3) : Colors.orange.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item['title'] ?? '',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isPassed ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${item['status']} (${item['score']})',
                        style: TextStyle(
                          color: isPassed ? Colors.greenAccent : Colors.orangeAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('📍 Zone: ${item['zone']}', style: const TextStyle(color: Color(0xFF06B6D4), fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text('Findings: ${item['findings']}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Inspector: ${item['inspector']}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    Text('Date: ${item['date']}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // TAB 5: HAZARDS & INCIDENTS
  // ==========================================
  Widget _buildHazardsTab() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFF43F5E),
        icon: const Icon(Icons.warning, color: Colors.white),
        label: const Text('Log Hazard', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        onPressed: _openNewHazardModal,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _hazards.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, idx) {
          final h = _hazards[idx];
          final isResolved = h['status'] == 'RESOLVED';
          final isHigh = h['severity'] == 'HIGH' || h['severity'] == 'CRITICAL';

          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isHigh ? Colors.redAccent.withValues(alpha: 0.4) : Colors.white10,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(h['hazard_code'] ?? '', style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 12)),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isHigh ? Colors.red.withValues(alpha: 0.2) : Colors.amber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            h['severity'] ?? '',
                            style: TextStyle(
                              color: isHigh ? Colors.redAccent : Colors.amberAccent,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isResolved ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            h['status'] ?? '',
                            style: TextStyle(
                              color: isResolved ? Colors.greenAccent : Colors.orangeAccent,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 6),
                Text(h['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Category: ${h['category']} • Zone: ${h['zone']}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.handyman, size: 14, color: Color(0xFF06B6D4)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Corrective Action: ${h['corrective_action']}',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12), overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}
