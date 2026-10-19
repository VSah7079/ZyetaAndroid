import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../utils/validators.dart';
import '../utils/responsive.dart';
import '../utils/app_theme.dart';

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
  late final MobileScannerController _scannerController;
  DateTime? _lastScannedTime;

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

    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

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
    _scannerController.dispose();
    _laserAnimController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_isLoading) return;
    if (_result != null) return; // Prevent re-trigger while a pass is displayed

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    final String? rawValue = barcode.rawValue;
    if (rawValue == null || rawValue.trim().isEmpty) return;

    final query = rawValue.trim();

    // Prevent multi-triggering within 2.5 seconds
    final now = DateTime.now();
    if (_lastScannedTime != null && now.difference(_lastScannedTime!).inMilliseconds < 2500) {
      return;
    }
    _lastScannedTime = now;

    HapticFeedback.heavyImpact();
    _verify(query);
  }

  Future<void> _toggleTorch() async {
    try {
      await _scannerController.toggleTorch();
      setState(() => _isFlashOn = !_isFlashOn);
    } catch (_) {}
  }

  Future<void> _switchCamera() async {
    try {
      await _scannerController.switchCamera();
      setState(() => _isFrontCamera = !_isFrontCamera);
    } catch (_) {}
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
          try {
            _scannerController.stop();
          } catch (_) {}
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
            backgroundColor: type == 'ENTRY' ? AppTheme.success : AppTheme.danger,
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
    try {
      _scannerController.start();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gate Security Verification', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary), overflow: TextOverflow.ellipsis),
            Text('Camera Scanner & Real-time Turnstile Hub', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary), overflow: TextOverflow.ellipsis),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [
          LogoutIconButton(),
        ],
      ),
      body: ResponsiveBody(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // SEGMENTED MODE SELECTOR: CAMERA SCANNER vs MANUAL INPUT
              Container(
                decoration: AppTheme.cardDecoration(
                  customBorder: Border.all(color: AppTheme.border),
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
                          try {
                            _scannerController.start();
                          } catch (_) {}
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                          decoration: BoxDecoration(
                            color: _activeTab == 0 ? AppTheme.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _activeTab == 0 ? AppTheme.softShadow : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.qr_code_scanner_rounded, size: 18, color: _activeTab == 0 ? Colors.white : AppTheme.textSecondary),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Live Camera',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: _activeTab == 0 ? Colors.white : AppTheme.textSecondary,
                                    fontWeight: _activeTab == 0 ? FontWeight.bold : FontWeight.w500,
                                    fontSize: 13,
                                  ),
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
                          try {
                            _scannerController.stop();
                          } catch (_) {}
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                          decoration: BoxDecoration(
                            color: _activeTab == 1 ? AppTheme.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _activeTab == 1 ? AppTheme.softShadow : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.keyboard_rounded, size: 18, color: _activeTab == 1 ? Colors.white : AppTheme.textSecondary),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Manual ID Entry',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: _activeTab == 1 ? Colors.white : AppTheme.textSecondary,
                                    fontWeight: _activeTab == 1 ? FontWeight.bold : FontWeight.w500,
                                    fontSize: 13,
                                  ),
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
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  ),
                ),

              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(12),
                  decoration: AppTheme.badgeDecoration(
                    background: AppTheme.dangerBg,
                    borderColor: AppTheme.dangerBorder,
                    radius: 12,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppTheme.danger, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(_errorMessage!, style: const TextStyle(color: AppTheme.danger, fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),

              if (_successMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: AppTheme.badgeDecoration(
                    background: AppTheme.successBg,
                    borderColor: AppTheme.successBorder,
                    radius: 12,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(_successMessage!, style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ],
                  ),
                ),

              // RESULT CARD
              if (_result != null) _buildResultCard(),
            ],
          ),
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
        // Camera Viewfinder Box with Live Stream
        Container(
          height: 290,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _isScanEffect
                  ? AppTheme.success
                  : _isFlashOn
                      ? Colors.amberAccent
                      : AppTheme.primary.withValues(alpha: 0.5),
              width: _isScanEffect ? 3 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _isScanEffect
                    ? AppTheme.success.withValues(alpha: 0.4)
                    : Colors.black38,
                blurRadius: 16,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // 1. Live Camera Preview via MobileScanner
                Positioned.fill(
                  child: MobileScanner(
                    controller: _scannerController,
                    onDetect: _onBarcodeDetected,
                    errorBuilder: (context, error) {
                      return Container(
                        color: const Color(0xFF0F172A),
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.videocam_off_rounded, color: Colors.orangeAccent, size: 36),
                              const SizedBox(height: 8),
                              const Text(
                                'Camera Access Required',
                                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap below to grant camera permission or retry: ${error.errorCode.name}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white60, fontSize: 10.5),
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton.icon(
                                onPressed: () {
                                  try {
                                    _scannerController.start();
                                  } catch (_) {}
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                ),
                                icon: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                                label: const Text('Start Camera', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // 2. Translucent dark tint around the target
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.22),
                      ),
                    ),
                  ),
                ),

                // 3. Scanner Target Frame Box
                Center(
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(
                      children: [
                        // Scanning Corners
                        _buildCorner(top: 0, left: 0, isTop: true, isLeft: true),
                        _buildCorner(top: 0, right: 0, isTop: true, isLeft: false),
                        _buildCorner(bottom: 0, left: 0, isTop: false, isLeft: true),
                        _buildCorner(bottom: 0, right: 0, isTop: false, isLeft: false),

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
                                    colors: [Colors.transparent, Color(0xFF38BDF8), Color(0xFF10B981), Color(0xFF38BDF8), Colors.transparent],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF38BDF8).withValues(alpha: 0.8),
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

                // 4. Viewfinder Top Controls Bar: Lens / Flash / Status
                Positioned(
                  top: 10,
                  left: 12,
                  right: 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.success),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isFrontCamera ? 'FRONT LENS' : 'LIVE CAMERA ON',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                              color: _isFlashOn ? Colors.amberAccent : Colors.white70,
                              size: 20,
                            ),
                            onPressed: _toggleTorch,
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              _isFrontCamera ? Icons.camera_front_rounded : Icons.camera_rear_rounded,
                              color: Colors.white70,
                              size: 20,
                            ),
                            onPressed: _switchCamera,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 5. Viewfinder Bottom instruction
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Align QR or Barcode inside frame to scan',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Quick Scan Code Presets (For one-touch barcode scanning testing)
        const Text(
          'ONE-TOUCH QR CODE BADGES (TAP TO SCAN):',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildQuickScanBadge('👷 Ramesh Patel (EMP-101)', 'EMP-101', AppTheme.primary),
            _buildQuickScanBadge('👷 Vikram Malhotra (EMP-102)', 'EMP-102', const Color(0xFF0284C7)),
            _buildQuickScanBadge('👤 Dr. Anand (VIS-2026-101)', 'VIS-2026-101', const Color(0xFF0D9488)),
            _buildQuickScanBadge('📦 Material DC (DC-2026-098)', 'DC-2026-098', AppTheme.success),
            _buildQuickScanBadge('🚗 Fleet Vehicle (KA 01 MJ 8812)', 'KA 01 MJ 8812', const Color(0xFF9333EA)),
            _buildQuickScanBadge('📋 Work Permit (PRM-2026-002)', 'PRM-2026-002', const Color(0xFFD97706)),
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
            top: isTop ? const BorderSide(color: Color(0xFF38BDF8), width: 3) : BorderSide.none,
            bottom: !isTop ? const BorderSide(color: Color(0xFF38BDF8), width: 3) : BorderSide.none,
            left: isLeft ? const BorderSide(color: Color(0xFF38BDF8), width: 3) : BorderSide.none,
            right: !isLeft ? const BorderSide(color: Color(0xFF38BDF8), width: 3) : BorderSide.none,
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
        decoration: AppTheme.badgeDecoration(
          background: color.withValues(alpha: 0.08),
          borderColor: color.withValues(alpha: 0.25),
          radius: 8,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.qr_code_rounded, size: 14, color: color),
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
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Type Worker ID, Visitor Pass, DC No, Vehicle Plate...',
            hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_inputController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear_rounded, color: AppTheme.textSecondary, size: 18),
                    onPressed: () {
                      _inputController.clear();
                      setState(() {});
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_rounded, color: AppTheme.primary),
                  onPressed: () => _verify(),
                ),
              ],
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
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
          decoration: AppTheme.cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'DIRECT PASS DIRECTORY (CLICK TO VERIFY):',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.border),
          boxShadow: isSelected ? AppTheme.softShadow : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
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
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: AppTheme.cardDecoration(
          color: AppTheme.bgSurface,
          customBorder: Border.all(color: AppTheme.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.primary, fontSize: 11)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: AppTheme.badgeDecoration(
                background: Colors.white,
                borderColor: AppTheme.border,
                radius: 4,
              ),
              child: Text(tag, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary, size: 18),
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
      decoration: AppTheme.cardDecoration(
        customBorder: Border.all(
          color: status == 'DENIED'
              ? AppTheme.danger
              : _result!.complianceWarnings.isNotEmpty
                  ? AppTheme.warning
                  : AppTheme.success,
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
                decoration: AppTheme.badgeDecoration(
                  background: AppTheme.primarySubtle,
                  borderColor: AppTheme.primaryLight,
                  radius: 6,
                ),
                child: Text(
                  _result!.entityType.toUpperCase(),
                  style: const TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: AppTheme.badgeDecoration(
                      background: isAllowed ? AppTheme.successBg : AppTheme.dangerBg,
                      borderColor: isAllowed ? AppTheme.successBorder : AppTheme.dangerBorder,
                      radius: 6,
                    ),
                    child: Text(
                      isAllowed ? '✓ ACCESS GRANTED' : '✕ ACCESS DENIED',
                      style: TextStyle(
                        color: isAllowed ? AppTheme.success : AppTheme.danger,
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
                  decoration: AppTheme.badgeDecoration(
                    background: AppTheme.primarySubtle,
                    borderColor: AppTheme.primaryLight,
                    radius: 12,
                  ),
                  child: Icon(
                    _result!.entityType == 'Visitor'
                        ? Icons.person_pin_rounded
                        : _result!.entityType == 'Vehicle'
                            ? Icons.local_shipping_rounded
                            : _result!.entityType == 'Material'
                                ? Icons.inventory_2_rounded
                                : Icons.assignment_rounded,
                    color: AppTheme.primary,
                    size: 28,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_result!.data['employee_id'] ?? _result!.data['pass_number'] ?? _result!.data['dc_number'] ?? _result!.data['vehicle_number'] ?? _result!.data['permit_number'] ?? ''} • ${_result!.data['designation'] ?? _result!.data['purpose'] ?? _result!.data['permit_type'] ?? _result!.data['vehicle_type'] ?? ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Contractor / Company: ${_result!.data['vendor_name'] ?? _result!.data['company'] ?? 'Direct Access'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
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
              decoration: AppTheme.badgeDecoration(
                background: AppTheme.warningBg,
                borderColor: AppTheme.warningBorder,
                radius: 8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 16),
                      SizedBox(width: 6),
                      Text('Safety & Compliance Notes:', style: TextStyle(color: AppTheme.warning, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ..._result!.complianceWarnings.map((w) => Text('• $w', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11))),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Gate Presence Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: AppTheme.cardDecoration(
              color: AppTheme.bgSurface,
              customBorder: Border.all(color: AppTheme.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text('Current Gate Presence:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12), overflow: TextOverflow.ellipsis),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: AppTheme.badgeDecoration(
                    background: isInside ? AppTheme.successBg : AppTheme.warningBg,
                    borderColor: isInside ? AppTheme.successBorder : AppTheme.warningBorder,
                    radius: 4,
                  ),
                  child: Text(
                    isInside ? '● CURRENTLY INSIDE' : '○ CURRENTLY OUTSIDE',
                    style: TextStyle(
                      color: isInside ? AppTheme.success : AppTheme.warning,
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
                      backgroundColor: AppTheme.success,
                      disabledBackgroundColor: AppTheme.bgMuted,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: !isAllowed || isInside ? null : () => _recordMovement('ENTRY'),
                    icon: const Icon(Icons.login_rounded, color: Colors.white, size: 18),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('ALLOW ENTRY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.danger,
                      disabledBackgroundColor: AppTheme.bgMuted,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: !isAllowed || !isInside ? null : () => _recordMovement('EXIT'),
                    icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 18),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('ALLOW EXIT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
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
                side: const BorderSide(color: AppTheme.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _resetScanner,
              icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary, size: 16),
              label: const Text('SCAN ANOTHER PASS', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
