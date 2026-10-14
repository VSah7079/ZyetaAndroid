import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../utils/validators.dart';

class QRScannerScreen extends StatefulWidget {
  final bool isManual;
  const QRScannerScreen({super.key, this.isManual = false});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> with SingleTickerProviderStateMixin {
  late int _activeTab; // 0: Camera Scanner, 1: Manual Search
  late AnimationController _laserAnimController;
  late Animation<double> _laserAnimation;

  final TextEditingController _inputController = TextEditingController();
  bool _isLoading = false;
  bool _isFlashOn = false;
  bool _isFrontCamera = false;
  bool _isScanEffect = false;
  VerificationResult? _result;
  String? _errorMessage;
  String? _successMessage;
  String _manualFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _activeTab = widget.isManual ? 1 : 0;

    _laserAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _laserAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _laserAnimController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  void _verify([String? code]) async {
    final query = (code ?? _inputController.text).trim();
    if (query.isEmpty) {
      setState(() => _errorMessage = 'Please scan a valid QR code or enter an ID');
      return;
    }

    // Trigger visual scanner flash effect
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
      _result = null;
      _isScanEffect = true;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _isScanEffect = false);
    });

    final res = await ApiService.verifyQR(query);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res != null) {
          _result = res;
          _inputController.text = query;
        } else {
          _errorMessage = 'Code "$query" not recognized or pass has expired.';
        }
      });
    }
  }

  void _recordMovement(String type) async {
    if (_result == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final entityId = _result!.data['id'] is int ? _result!.data['id'] as int : 1;
    final success = await ApiService.recordGateMovement(
      entityType: _result!.entityType,
      entityId: entityId,
      movementType: type,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        setState(() {
          _successMessage = '✓ ${_result!.entityType} Gate $type Recorded Successfully!';
          // Update local result state
          _result = VerificationResult(
            verificationStatus: _result!.verificationStatus,
            recommendedAction: type == 'ENTRY' ? 'ALLOW_EXIT' : 'ALLOW_ENTRY',
            isCurrentlyInside: type == 'ENTRY',
            complianceWarnings: _result!.complianceWarnings,
            entityType: _result!.entityType,
            data: _result!.data,
          );
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gate $type verified for ${_result!.data['full_name'] ?? _result!.data['visitor_name'] ?? 'Record'}'),
            backgroundColor: type == 'ENTRY' ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'Failed to register gate movement. Try again.';
        });
      }
    }
  }

  void _resetScanner() {
    setState(() {
      _result = null;
      _errorMessage = null;
      _successMessage = null;
      _inputController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gate Security Verification', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            Text('Camera Scanner & Real-time Turnstile Hub', style: TextStyle(fontSize: 11, color: Colors.white54)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [
          LogoutIconButton(),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // SEGMENTED MODE SELECTOR: CAMERA SCANNER vs MANUAL INPUT
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _activeTab = 0;
                          _errorMessage = null;
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _activeTab == 0 ? const Color(0xFF6366F1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _activeTab == 0
                              ? [BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.qr_code_scanner, size: 18, color: _activeTab == 0 ? Colors.white : Colors.white60),
                            const SizedBox(width: 8),
                            Text(
                              'Live Camera Scanner',
                              style: TextStyle(
                                color: _activeTab == 0 ? Colors.white : Colors.white70,
                                fontWeight: _activeTab == 0 ? FontWeight.bold : FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _activeTab = 1;
                          _errorMessage = null;
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _activeTab == 1 ? const Color(0xFF06B6D4) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _activeTab == 1
                              ? [BoxShadow(color: const Color(0xFF06B6D4).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.keyboard, size: 18, color: _activeTab == 1 ? Colors.white : Colors.white60),
                            const SizedBox(width: 8),
                            Text(
                              'Manual ID Entry',
                              style: TextStyle(
                                color: _activeTab == 1 ? Colors.white : Colors.white70,
                                fontWeight: _activeTab == 1 ? FontWeight.bold : FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // CONDITIONAL VIEW: 0 = CAMERA SCANNER, 1 = MANUAL SEARCH
            if (_activeTab == 0) _buildCameraScannerView() else _buildManualEntryView(),

            const SizedBox(height: 16),

            // FEEDBACK STATUS BANNERS
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(color: Color(0xFF6366F1)),
                ),
              ),

            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),

            if (_successMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.greenAccent),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.greenAccent, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_successMessage!, style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ],
                ),
              ),

            // RESULT CARD
            if (_result != null) _buildResultCard(),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // VIEW 1: LIVE CAMERA SCANNER VIEWPORT
  // ==========================================
  Widget _buildCameraScannerView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Camera Viewfinder Box
        Container(
          height: 280,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _isScanEffect
                  ? const Color(0xFF10B981)
                  : _isFlashOn
                      ? Colors.amberAccent
                      : const Color(0xFF6366F1).withValues(alpha: 0.4),
              width: _isScanEffect ? 3 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _isScanEffect
                    ? const Color(0xFF10B981).withValues(alpha: 0.4)
                    : Colors.black45,
                blurRadius: 16,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Subtle background grid
              Positioned.fill(
                child: Opacity(
                  opacity: 0.15,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        colors: [Color(0xFF38BDF8), Color(0xFF0F172A)],
                        radius: 1.2,
                      ),
                    ),
                  ),
                ),
              ),

              // Scanner Target Frame Box
              Center(
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      // Scanning Corners
                      _buildCorner(top: 0, left: 0, isTop: true, isLeft: true),
                      _buildCorner(top: 0, right: 0, isTop: true, isLeft: false),
                      _buildCorner(bottom: 0, left: 0, isTop: false, isLeft: true),
                      _buildCorner(bottom: 0, right: 0, isTop: false, isLeft: false),

                      // Center QR Icon watermark
                      Center(
                        child: Icon(
                          Icons.qr_code_2,
                          size: 70,
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),

                      // Animated Sweeping Laser Line
                      AnimatedBuilder(
                        animation: _laserAnimation,
                        builder: (context, child) {
                          return Positioned(
                            top: 200 * _laserAnimation.value,
                            left: 10,
                            right: 10,
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Colors.transparent, Color(0xFF06B6D4), Color(0xFF10B981), Color(0xFF06B6D4), Colors.transparent],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF06B6D4).withValues(alpha: 0.8),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Viewfinder Top Bar: Lens / Flash / Status
              Positioned(
                top: 12,
                left: 14,
                right: 14,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF10B981)),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isFrontCamera ? 'FRONT LENS' : 'CAMERA ACTIVE',
                            style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            _isFlashOn ? Icons.flash_on : Icons.flash_off,
                            color: _isFlashOn ? Colors.amberAccent : Colors.white60,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() => _isFlashOn = !_isFlashOn);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(_isFlashOn ? 'Torch turned ON' : 'Torch turned OFF'),
                                duration: const Duration(milliseconds: 600),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 14),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            _isFrontCamera ? Icons.camera_front : Icons.camera_rear,
                            color: Colors.white70,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() => _isFrontCamera = !_isFrontCamera);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Viewfinder Bottom instruction
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Hold QR code or barcode inside frame to scan',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Interactive "Scan Barcode Now / Simulate Camera Capture" Action
        SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
            label: const Text('AUTO-CAPTURE PASS SCAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: () => _verify('EMP-101'),
          ),
        ),

        const SizedBox(height: 14),

        // Quick Scan Code Presets (For one-touch barcode scanning testing)
        const Text(
          'ONE-TOUCH QR CODE BADGES (TAP TO SCAN):',
          style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildQuickScanBadge('👷 Ramesh Patel (EMP-101)', 'EMP-101', const Color(0xFF6366F1)),
            _buildQuickScanBadge('👷 Vikram Malhotra (EMP-102)', 'EMP-102', const Color(0xFF818CF8)),
            _buildQuickScanBadge('👤 Dr. Anand (VIS-2026-101)', 'VIS-2026-101', const Color(0xFF06B6D4)),
            _buildQuickScanBadge('📦 Material DC (DC-2026-098)', 'DC-2026-098', const Color(0xFF10B981)),
            _buildQuickScanBadge('🚗 Fleet Vehicle (KA 01 MJ 8812)', 'KA 01 MJ 8812', const Color(0xFFA855F7)),
            _buildQuickScanBadge('📋 Work Permit (PRM-2026-002)', 'PRM-2026-002', const Color(0xFFF59E0B)),
          ],
        ),
      ],
    );
  }

  Widget _buildCorner({double? top, double? bottom, double? left, double? right, required bool isTop, required bool isLeft}) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          border: Border(
            top: isTop ? const BorderSide(color: Color(0xFF06B6D4), width: 3) : BorderSide.none,
            bottom: !isTop ? const BorderSide(color: Color(0xFF06B6D4), width: 3) : BorderSide.none,
            left: isLeft ? const BorderSide(color: Color(0xFF06B6D4), width: 3) : BorderSide.none,
            right: !isLeft ? const BorderSide(color: Color(0xFF06B6D4), width: 3) : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickScanBadge(String label, String code, Color color) {
    return InkWell(
      onTap: () => _verify(code),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.qr_code, size: 14, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // VIEW 2: MANUAL ENTRY & SEARCH
  // ==========================================
  Widget _buildManualEntryView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search Input Box
        TextField(
          controller: _inputController,
          autofocus: false,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Type Worker ID, Visitor Pass, DC No, Vehicle Plate...',
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
            prefixIcon: const Icon(Icons.search, color: Color(0xFF06B6D4)),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_inputController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                    onPressed: () {
                      _inputController.clear();
                      setState(() {});
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF10B981)),
                  onPressed: () => _verify(),
                ),
              ],
            ),
            filled: true,
            fillColor: const Color(0xFF1E293B),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          onSubmitted: (val) => _verify(val),
          onChanged: (_) => setState(() {}),
        ),

        const SizedBox(height: 12),

        // Quick Category Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterCategory('ALL', 'All Passes'),
              const SizedBox(width: 6),
              _buildFilterCategory('WORKER', '👷 Workers (EMP)'),
              const SizedBox(width: 6),
              _buildFilterCategory('VISITOR', '👤 Visitors (VIS)'),
              const SizedBox(width: 6),
              _buildFilterCategory('MATERIAL', '📦 Material (DC)'),
              const SizedBox(width: 6),
              _buildFilterCategory('VEHICLE', '🚗 Vehicles'),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Directory of Sample Fast-Passes for Manual Entry
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('DIRECT PASS DIRECTORY (CLICK TO VERIFY):', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              if (_manualFilter == 'ALL' || _manualFilter == 'WORKER') ...[
                _buildDirectoryItem('Ramesh Patel', 'EMP-101 • Senior Scaffolding Lead', 'ABC Infra Projects', () => _verify('EMP-101')),
                _buildDirectoryItem('Vikram Malhotra', 'EMP-102 • Electrical Specialist', 'Apex MEP Solutions', () => _verify('EMP-102')),
              ],
              if (_manualFilter == 'ALL' || _manualFilter == 'VISITOR') ...[
                _buildDirectoryItem('Dr. Anand Deshmukh', 'VIS-2026-101 • Consultant Visitor Pass', 'Host: Priya Sundaram', () => _verify('VIS-2026-101')),
              ],
              if (_manualFilter == 'ALL' || _manualFilter == 'MATERIAL') ...[
                _buildDirectoryItem('Structural Material Inward', 'DC-2026-098 • Inward Challan', 'ABC Infra Projects', () => _verify('DC-2026-098')),
              ],
              if (_manualFilter == 'ALL' || _manualFilter == 'VEHICLE') ...[
                _buildDirectoryItem('Heavy Transport Fleet', 'KA 01 MJ 8812 • Verified Vehicle', 'Gate Entry Validated', () => _verify('KA 01 MJ 8812')),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterCategory(String filter, String label) {
    final isSelected = _manualFilter == filter;
    return InkWell(
      onTap: () => setState(() => _manualFilter = filter),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF06B6D4).withValues(alpha: 0.2) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? const Color(0xFF06B6D4) : Colors.transparent),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF38BDF8) : Colors.white60,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildDirectoryItem(String title, String subtitle, String tag, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(subtitle, style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4)),
              child: Text(tag, style: const TextStyle(color: Colors.white70, fontSize: 10)),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.white38, size: 18),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // RESULT CARD: COMPREHENSIVE VERIFICATION & MOVEMENTS
  // ==========================================
  Widget _buildResultCard() {
    final status = _result!.verificationStatus;
    final isAllowed = status != 'DENIED';
    final isInside = _result!.isCurrentlyInside;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: status == 'DENIED'
              ? Colors.redAccent
              : _result!.complianceWarnings.isNotEmpty
                  ? Colors.orangeAccent
                  : const Color(0xFF10B981),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Badges
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _result!.entityType.toUpperCase(),
                  style: const TextStyle(color: Color(0xFF818CF8), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isAllowed ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isAllowed ? '✓ ACCESS GRANTED' : '✕ ACCESS DENIED',
                      style: TextStyle(
                        color: isAllowed ? Colors.greenAccent : Colors.redAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Main Entity Profile row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_result!.entityType == 'Employee')
                CircleAvatar(
                  radius: 28,
                  backgroundImage: NetworkImage(
                    _result!.data['profile_photo'] ?? 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
                  ),
                )
              else
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _result!.entityType == 'Visitor'
                        ? Icons.person_pin
                        : _result!.entityType == 'Vehicle'
                            ? Icons.local_shipping
                            : _result!.entityType == 'Material'
                                ? Icons.inventory_2
                                : Icons.assignment,
                    color: const Color(0xFF38BDF8),
                    size: 30,
                  ),
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _result!.data['full_name'] ??
                          _result!.data['visitor_name'] ??
                          _result!.data['material_name'] ??
                          _result!.data['vehicle_number'] ??
                          _result!.data['permit_number'] ??
                          'Verified Pass',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_result!.data['employee_id'] ?? _result!.data['pass_number'] ?? _result!.data['dc_number'] ?? _result!.data['vehicle_number'] ?? _result!.data['permit_number'] ?? ''} • ${_result!.data['designation'] ?? _result!.data['purpose'] ?? _result!.data['permit_type'] ?? _result!.data['vehicle_type'] ?? ''}',
                      style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Contractor / Company: ${_result!.data['vendor_name'] ?? _result!.data['company'] ?? 'Direct Access'}',
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Compliance & Safety Flags
          if (_result!.complianceWarnings.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orangeAccent, size: 16),
                      SizedBox(width: 6),
                      Text('Safety & Compliance Notes:', style: TextStyle(color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ..._result!.complianceWarnings.map((w) => Text('• $w', style: const TextStyle(color: Colors.white70, fontSize: 11))),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Gate Presence Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Current Gate Presence:', style: TextStyle(color: Colors.white54, fontSize: 12)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isInside ? Colors.green.withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isInside ? '● CURRENTLY INSIDE' : '○ CURRENTLY OUTSIDE',
                    style: TextStyle(
                      color: isInside ? Colors.greenAccent : Colors.orangeAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Action Buttons: ENTRY, EXIT, SCAN NEXT
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      disabledBackgroundColor: Colors.white10,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: !isAllowed || isInside ? null : () => _recordMovement('ENTRY'),
                    icon: const Icon(Icons.login, color: Colors.white, size: 18),
                    label: const Text('ALLOW ENTRY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF43F5E),
                      disabledBackgroundColor: Colors.white10,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: !isAllowed || !isInside ? null : () => _recordMovement('EXIT'),
                    icon: const Icon(Icons.logout, color: Colors.white, size: 18),
                    label: const Text('ALLOW EXIT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Scan Next Pass button
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _resetScanner,
              icon: const Icon(Icons.refresh, color: Colors.white70, size: 16),
              label: const Text('SCAN ANOTHER PASS', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
