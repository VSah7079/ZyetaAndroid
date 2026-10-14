import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../utils/validators.dart';
import 'emergency_muster_screen.dart';

class InsideHeadcountScreen extends StatefulWidget {
  const InsideHeadcountScreen({super.key});

  @override
  State<InsideHeadcountScreen> createState() => _InsideHeadcountScreenState();
}

class _InsideHeadcountScreenState extends State<InsideHeadcountScreen> with SingleTickerProviderStateMixin {
  List<dynamic> _insideList = [];
  bool _isLoading = true;
  String _filter = 'ALL'; // 'ALL' | 'WORKERS' | 'VISITORS' | 'VEHICLES'
  String _search = '';
  final TextEditingController _searchController = TextEditingController();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _fetchInside();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _fetchInside() async {
    setState(() => _isLoading = true);
    final list = await ApiService.getCurrentlyInside();
    if (mounted) {
      setState(() {
        _insideList = list;
        _isLoading = false;
      });
    }
  }

  void _quickCheckout(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.exit_to_app, color: Colors.redAccent, size: 22),
            ),
            const SizedBox(width: 10),
            const Text('Confirm Exit', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Mark "${item['name']}" (${item['code'] ?? 'ID'}) as checked OUT through Turnstile Exit Gate?',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF43F5E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('CONFIRM OUT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    HapticFeedback.mediumImpact();
    final ok = await ApiService.recordGateMovement(
      entityType: item['type'] ?? 'Employee',
      entityId: item['id'],
      movementType: 'EXIT',
      remarks: 'Supervisor turnstile mobile checkout',
    );
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ ${item['name']} successfully cleared OUT!'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      _fetchInside();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to record exit'), backgroundColor: Colors.red),
      );
    }
  }

  List<dynamic> get _filteredList {
    return _insideList.where((item) {
      final type = (item['type'] ?? 'Employee').toString().toLowerCase();
      if (_filter == 'WORKERS' && !type.contains('emp') && !type.contains('worker')) return false;
      if (_filter == 'VISITORS' && !type.contains('vis')) return false;
      if (_filter == 'VEHICLES' && !type.contains('veh') && !type.contains('driver')) return false;

      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        final name = (item['name'] ?? '').toString().toLowerCase();
        final code = (item['code'] ?? '').toString().toLowerCase();
        final vendor = (item['vendor'] ?? '').toString().toLowerCase();
        if (!name.contains(q) && !code.contains(q) && !vendor.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredList;
    final totalInside = _insideList.length;
    final workersInside = _insideList.where((i) => (i['type'] ?? '').toString().toLowerCase().contains('emp') || (i['type'] ?? '').toString().toLowerCase().contains('worker')).length;
    final visitorsInside = _insideList.where((i) => (i['type'] ?? '').toString().toLowerCase().contains('vis')).length;
    final vehiclesInside = _insideList.where((i) => (i['type'] ?? '').toString().toLowerCase().contains('veh') || (i['type'] ?? '').toString().toLowerCase().contains('driver')).length;

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Row(
          children: [
            FadeTransition(
              opacity: _pulseAnimation,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Color(0xFF10B981), blurRadius: 8, spreadRadius: 2)],
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text('Live Headcount Telemetry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Emergency Muster Roll',
            icon: const Icon(Icons.emergency, color: Colors.redAccent),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyMusterScreen()));
            },
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh, color: Color(0xFF06B6D4)),
            onPressed: _fetchInside,
          ),
          const LogoutIconButton(),
        ],
      ),
      body: Column(
        children: [
          // RADAR TELEMETRY HERO BANNER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border(bottom: BorderSide(color: const Color(0xFF06B6D4).withValues(alpha: 0.2))),
            ),
            child: Column(
              children: [
                // Live count summary row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.radar, color: Color(0xFF06B6D4), size: 14),
                            SizedBox(width: 6),
                            Text('ACTIVE PREMISES ROSTER', style: TextStyle(color: Colors.white54, fontSize: 10.5, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '$totalInside',
                              style: const TextStyle(color: Color(0xFF10B981), fontSize: 28, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(width: 6),
                            const Text('Souls Inside Site', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () {
                        HapticFeedback.heavyImpact();
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyMusterScreen()));
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFBE123C), Color(0xFF881337)]),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.red.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 3)),
                          ],
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text('MUSTER SOS', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 3 METRIC TILES (Workers, Visitors, Vehicles)
                Row(
                  children: [
                    _buildMetricTile('WORKERS', '$workersInside', const Color(0xFF06B6D4), Icons.engineering),
                    const SizedBox(width: 8),
                    _buildMetricTile('VISITORS', '$visitorsInside', const Color(0xFFF59E0B), Icons.badge),
                    const SizedBox(width: 8),
                    _buildMetricTile('VEHICLES', '$vehiclesInside', const Color(0xFF818CF8), Icons.local_shipping),
                  ],
                ),
                const SizedBox(height: 12),

                // SEARCH BAR
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search by Person Name, Badge Code, Contractor...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF06B6D4), size: 18),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white54, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _search = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFF131D31),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  onChanged: (val) => setState(() => _search = val.trim()),
                ),
                const SizedBox(height: 8),

                // FILTER PILLS
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPill('ALL', 'All Inside ($totalInside)'),
                      _buildPill('WORKERS', '👷 Workers ($workersInside)'),
                      _buildPill('VISITORS', '🪪 Visitors ($visitorsInside)'),
                      _buildPill('VEHICLES', '🚛 Drivers ($vehiclesInside)'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // LIST OF PERSONS CURRENTLY INSIDE
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF06B6D4)))
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: const Color(0xFF1E293B), shape: BoxShape.circle),
                              child: const Icon(Icons.verified_user_outlined, size: 44, color: Color(0xFF06B6D4)),
                            ),
                            const SizedBox(height: 12),
                            const Text('No entities currently inside matching filter', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            const Text('Turnstile gate records synchronize in real-time', style: TextStyle(color: Colors.white38, fontSize: 11)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => _fetchInside(),
                        color: const Color(0xFF06B6D4),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(14),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, idx) {
                            final item = filtered[idx];
                            final type = (item['type'] ?? 'Employee').toString();
                            final isWorker = type.toLowerCase().contains('emp') || type.toLowerCase().contains('worker');
                            final isVisitor = type.toLowerCase().contains('vis');

                            final accentColor = isWorker
                                ? const Color(0xFF06B6D4)
                                : isVisitor
                                    ? const Color(0xFFF59E0B)
                                    : const Color(0xFF818CF8);

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF111827), Color(0xFF0B132B)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: accentColor.withValues(alpha: 0.35)),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 3)),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Avatar
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: accentColor, width: 1.5),
                                      color: accentColor.withValues(alpha: 0.12),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        isWorker
                                            ? Icons.engineering
                                            : isVisitor
                                                ? Icons.badge
                                                : Icons.local_shipping,
                                        color: accentColor,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                item['name'] ?? 'Authorized Person',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                                              ),
                                              child: const Text('INSIDE', style: TextStyle(color: Color(0xFF10B981), fontSize: 8.5, fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '${item['code'] ?? 'ID-100'} • ${item['vendor'] ?? 'Zyeta Direct'}',
                                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.login, color: Color(0xFF06B6D4), size: 12),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Entry: ${item['entry_time'] != null ? item['entry_time'].toString().split('T').last.substring(0, 5) : 'Turnstile 01'}',
                                              style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 10.5, fontWeight: FontWeight.w600),
                                            ),
                                            const SizedBox(width: 8),
                                            const Text('• Zone: Main Core', style: TextStyle(color: Colors.white38, fontSize: 10)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Quick Checkout Button
                                  InkWell(
                                    onTap: () => _quickCheckout(item),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF43F5E).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: const Color(0xFFF43F5E).withValues(alpha: 0.5)),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.logout, size: 14, color: Color(0xFFF43F5E)),
                                          SizedBox(width: 4),
                                          Text('OUT', style: TextStyle(color: Color(0xFFF43F5E), fontWeight: FontWeight.bold, fontSize: 10.5)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
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

  Widget _buildMetricTile(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF131D31),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w900)),
                Text(label, style: const TextStyle(color: Colors.white38, fontSize: 8.5, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPill(String key, String label) {
    final isSelected = _filter == key;
    return InkWell(
      onTap: () => setState(() => _filter = key),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF06B6D4) : const Color(0xFF131D31),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? const Color(0xFF06B6D4) : Colors.white12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
