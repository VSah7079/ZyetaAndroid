import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/validators.dart';
import '../utils/responsive.dart';
import '../utils/app_theme.dart';
import 'qr_scanner_screen.dart';

class EmergencyMusterScreen extends StatefulWidget {
  const EmergencyMusterScreen({super.key});

  @override
  State<EmergencyMusterScreen> createState() => _EmergencyMusterScreenState();
}

class _EmergencyMusterScreenState extends State<EmergencyMusterScreen> {
  Map<String, dynamic> _status = {};
  bool _isLoading = true;
  final TextEditingController _scanCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  void _loadStatus() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getEvacuationStatus();
    if (mounted) {
      setState(() {
        _status = data;
        _isLoading = false;
      });
    }
  }

  void _triggerAlarm() async {
    final reasonCtrl = TextEditingController(text: 'Fire Alarm & Smoke Detected in Block B');
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: AppTheme.danger),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'TRIGGER SITE EVACUATION',
                style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Broadcasting alarm will trigger sirens across turnstile terminals, open safety gate boom barriers, and initialize live muster stations.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Emergency Reason / Origin',
                labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                filled: true,
                fillColor: AppTheme.bgSurface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('CONFIRM EVACUATION', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final ok = await ApiService.triggerEmergencyEvacuation(reasonCtrl.text.trim());
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Emergency Evacuation Protocol Broadcasted to all Gates!'), backgroundColor: AppTheme.danger),
        );
        _loadStatus();
      }
    }
  }

  void _clearAlarm() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear Emergency Evacuation', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        content: const Text(
          'Confirm all personnel are accounted for and it is safe to reset gates back to normal automated entry?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('DECLARE SITE SAFE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final ok = await ApiService.clearEmergencyEvacuation();
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Emergency Alarm Cleared. Campus returned to normal operations!'), backgroundColor: AppTheme.success),
        );
        _loadStatus();
      }
    }
  }

  void _checkinWorker(int stationId, [String? workerCode]) async {
    final code = (workerCode ?? _scanCtrl.text).trim().toUpperCase();
    if (code.isEmpty) return;

    final ok = await ApiService.checkinMusterStation(stationId, code);
    if (ok && mounted) {
      _scanCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✓ Worker $code safely checked in at Muster Station!'), backgroundColor: AppTheme.success),
      );
      _loadStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _status['is_active'] == true;
    final stations = (_status['stations'] as List<dynamic>?) ?? [];
    final totalInside = _status['total_inside_when_alarmed'] ?? 0;
    final totalMustered = _status['total_mustered'] ?? 0;
    final missing = _status['missing_unaccounted'] ?? 0;

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: isActive ? AppTheme.danger : Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Icon(isActive ? Icons.emergency_rounded : Icons.health_and_safety_rounded, color: isActive ? Colors.white : AppTheme.danger, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isActive ? '🚨 EMERGENCY EVACUATION ACTIVE' : 'Emergency & Muster Roll Hub',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isActive ? Colors.white : AppTheme.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(tooltip: 'Refresh', icon: Icon(Icons.refresh_rounded, color: isActive ? Colors.white : AppTheme.textSecondary), onPressed: _loadStatus),
          const LogoutIconButton(),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.danger))
          : ResponsiveBody(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner Button (Trigger or Clear)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: isActive
                          ? BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE11D48), Color(0xFF9F1239)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: AppTheme.mediumShadow,
                            )
                          : AppTheme.cardDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isActive ? 'CRITICAL EVACUATION ALARM' : 'CAMPUS SAFETY STATUS',
                                style: TextStyle(
                                  color: isActive ? Colors.white : AppTheme.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: AppTheme.badgeDecoration(
                                  background: isActive ? Colors.black26 : AppTheme.successBg,
                                  borderColor: isActive ? Colors.white24 : AppTheme.successBorder,
                                  radius: 6,
                                ),
                                child: Text(
                                  isActive ? '● ALARM ACTIVE' : '● NORMAL OPS',
                                  style: TextStyle(
                                    color: isActive ? Colors.white : AppTheme.success,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isActive ? _status['reason'] ?? 'Emergency Evacuation in progress' : 'All campus zones safe. Muster roll ready for safety drills.',
                            style: TextStyle(color: isActive ? Colors.white : AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isActive ? AppTheme.success : AppTheme.danger,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 2,
                              ),
                              icon: Icon(isActive ? Icons.check_circle_rounded : Icons.warning_amber_rounded, color: Colors.white),
                              label: Text(
                                isActive ? 'DECLARE ALL SAFE (CLEAR ALARM)' : 'SOUND EMERGENCY EVACUATION ALARM',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              onPressed: isActive ? _clearAlarm : _triggerAlarm,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Headcount KPIs
                    Row(
                      children: [
                        Expanded(child: _buildKPI('Total On Site', '$totalInside', AppTheme.primary, Icons.groups_rounded)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildKPI('Safely Mustered', '$totalMustered', AppTheme.success, Icons.verified_user_rounded)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildKPI('Unaccounted', '$missing', AppTheme.danger, Icons.person_off_rounded)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Quick Check-in Worker input (Scanner & Manual)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('MUSTER POINT SCANNER / QUICK CHECK-IN', style: TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.4)),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const QRScannerScreen(isManual: false)),
                            ).then((_) => _loadStatus());
                          },
                          child: const Row(
                            children: [
                              Icon(Icons.qr_code_scanner_rounded, color: AppTheme.primary, size: 14),
                              SizedBox(width: 4),
                              Text('Launch QR Terminal', style: TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _scanCtrl,
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Enter Worker ID (e.g. EMP-101)...',
                              hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                              prefixIcon: const Icon(Icons.badge_rounded, color: AppTheme.textSecondary, size: 18),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
                            ),
                            onSubmitted: (val) => _checkinWorker(1, val),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => _checkinWorker(1),
                          child: const Text('Check In', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildMusterChip('EMP-101 (Ramesh)'),
                        _buildMusterChip('EMP-102 (Vikram)'),
                        _buildMusterChip('EMP-103 (Sunil)'),
                        _buildMusterChip('EMP-104 (Anil)'),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Assembly Points Cards
                    const Text('ASSEMBLY MUSTER STATIONS', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    const SizedBox(height: 10),
                    ...stations.map((st) {
                      final isCleared = st['is_safe_cleared'] == true;
                      final count = st['checked_in_count'] ?? 0;
                      final cap = st['capacity'] ?? 200;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: AppTheme.cardDecoration(
                          customBorder: Border.all(color: AppTheme.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    st['name'] ?? '',
                                    style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: AppTheme.badgeDecoration(
                                    background: isCleared ? AppTheme.successBg : AppTheme.primarySubtle,
                                    borderColor: isCleared ? AppTheme.successBorder : AppTheme.primaryLight,
                                    radius: 6,
                                  ),
                                  child: Text(
                                    isCleared ? '✓ ZONE ALL CLEAR' : '$count / $cap Assembled',
                                    style: TextStyle(
                                      color: isCleared ? AppTheme.success : AppTheme.primary,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Safety Warden: ${st['warden_name']} • Max Zone Capacity: $cap',
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: cap > 0 ? (count / cap).clamp(0.0, 1.0) : 0,
                                backgroundColor: AppTheme.bgSurface,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.success),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildKPI(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.cardDecoration(
        customBorder: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: AppTheme.badgeDecoration(
              background: color.withValues(alpha: 0.1),
              borderColor: color.withValues(alpha: 0.2),
              radius: 6,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 2),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildMusterChip(String label) {
    final code = label.split(' ').first;
    return InkWell(
      onTap: () {
        _scanCtrl.text = code;
        _checkinWorker(1, code);
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: AppTheme.badgeDecoration(
          background: Colors.white,
          borderColor: AppTheme.border,
          radius: 6,
        ),
        child: Text(label, style: const TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
