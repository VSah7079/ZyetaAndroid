import 'package:flutter/material.dart';
import '../services/api_service.dart';

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
        backgroundColor: const Color(0xFF1E293B),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('TRIGGER SITE EVACUATION', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚠️ This will sound site sirens, hard-lock turnstiles in EVACUATION OPEN mode, and initiate real-time muster roll call.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: reasonCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Emergency Reason / Hazard Source',
                labelStyle: const TextStyle(color: Colors.white60),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('SOUND ALARM NOW', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ApiService.triggerEmergencyEvacuation(reasonCtrl.text.trim());
      _loadStatus();
    }
  }

  void _clearAlarm() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Declare Site Safe & Clear Alarm?', style: TextStyle(color: Colors.white)),
        content: const Text('All muster stations have reported headcount. Are you sure you want to end emergency mode?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('CONFIRM ALL CLEAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ApiService.clearEmergencyEvacuation();
      _loadStatus();
    }
  }

  void _checkinWorker(int stationId) async {
    final code = _scanCtrl.text.trim();
    if (code.isEmpty) return;

    final ok = await ApiService.checkinMusterStation(stationId, code);
    if (ok && mounted) {
      _scanCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Worker $code safely checked in!'), backgroundColor: Colors.green),
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
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: isActive ? const Color(0xFF881337) : const Color(0xFF0F172A),
        title: Row(
          children: [
            Icon(isActive ? Icons.emergency : Icons.health_and_safety, color: isActive ? Colors.white : const Color(0xFFF43F5E), size: 22),
            const SizedBox(width: 8),
            Text(
              isActive ? '🚨 EMERGENCY EVACUATION ACTIVE' : 'Emergency & Muster Roll Hub',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white70), onPressed: _loadStatus),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF43F5E)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner Button (Trigger or Clear)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isActive
                            ? [const Color(0xFFE11D48), const Color(0xFF881337)]
                            : [const Color(0xFF1E293B), const Color(0xFF0F172A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isActive ? Colors.redAccent : Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isActive ? 'CRITICAL EVACUATION ALARM' : 'CAMPUS SAFETY STATUS',
                              style: TextStyle(color: isActive ? Colors.white : Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isActive ? Colors.black38 : Colors.green.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isActive ? '● ALARM ACTIVE' : '● NORMAL OPS',
                                style: TextStyle(color: isActive ? Colors.white : Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isActive ? _status['reason'] ?? 'Emergency Evacuation in progress' : 'All campus zones safe. Muster roll ready for safety drills.',
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isActive ? const Color(0xFF10B981) : const Color(0xFFE11D48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: Icon(isActive ? Icons.check_circle : Icons.warning_amber_rounded, color: Colors.white),
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
                      Expanded(child: _buildKPI('Total On Site', '$totalInside', const Color(0xFF6366F1), Icons.groups)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildKPI('Safely Mustered', '$totalMustered', const Color(0xFF10B981), Icons.verified_user)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildKPI('Unaccounted', '$missing', const Color(0xFFF43F5E), Icons.person_off)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Quick Check-in Worker input
                  const Text('MUSTER POINT SCANNER / QUICK CHECK-IN', style: TextStyle(color: Color(0xFF06B6D4), fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _scanCtrl,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Enter Worker ID (e.g. EMP-101)...',
                            hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                            prefixIcon: const Icon(Icons.qr_code_scanner, color: Color(0xFF06B6D4), size: 20),
                            filled: true,
                            fillColor: const Color(0xFF1E293B),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF06B6D4),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _checkinWorker(1),
                        child: const Text('Check In Point A', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Assembly Points Cards
                  const Text('ASSEMBLY MUSTER STATIONS', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ...stations.map((st) {
                    final isCleared = st['is_safe_cleared'] == true;
                    final count = st['checked_in_count'] ?? 0;
                    final cap = st['capacity'] ?? 200;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
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
                              Expanded(
                                child: Text(
                                  st['name'] ?? '',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isCleared ? Colors.green.withValues(alpha: 0.15) : const Color(0xFF10B981).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isCleared ? '✓ ZONE ALL CLEAR' : '$count / $cap Assembled',
                                  style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Safety Warden: ${st['warden_name']} • Max Zone Capacity: $cap',
                            style: const TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                            value: cap > 0 ? (count / cap).clamp(0.0, 1.0) : 0,
                            backgroundColor: Colors.white10,
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }

  Widget _buildKPI(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
