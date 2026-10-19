import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../utils/validators.dart';
import '../utils/app_theme.dart';
import '../utils/responsive.dart';
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: AppTheme.badgeDecoration(
                background: AppTheme.dangerBg,
                borderColor: AppTheme.dangerBorder,
                radius: 10,
              ),
              child: const Icon(Icons.exit_to_app_rounded, color: AppTheme.danger, size: 22),
            ),
            const SizedBox(width: 10),
            const Text('Confirm Exit', style: TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Mark "${item['name']}" (${item['code'] ?? 'ID'}) as checked OUT through Turnstile Exit Gate?',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
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
          backgroundColor: AppTheme.success,
        ),
      );
      _fetchInside();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to record exit'), backgroundColor: AppTheme.danger),
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
      backgroundColor: AppTheme.bgPrimary,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            FadeTransition(
              opacity: _pulseAnimation,
              child: Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: AppTheme.success,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Live Headcount Telemetry',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, letterSpacing: 0.3),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Emergency Muster Roll',
            icon: const Icon(Icons.emergency_rounded, color: AppTheme.danger),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyMusterScreen()));
            },
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary),
            onPressed: _fetchInside,
          ),
          const LogoutIconButton(),
        ],
      ),
      body: ResponsiveBody(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            // RADAR TELEMETRY HERO BANNER
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: AppTheme.cardDecoration(),
              child: Column(
                children: [
                  // Live count summary row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.radar_rounded, color: AppTheme.primary, size: 16),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'ACTIVE PREMISES ROSTER',
                                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.6),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '$totalInside',
                                  style: const TextStyle(color: AppTheme.success, fontSize: 28, fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(width: 8),
                                const Flexible(
                                  child: Text(
                                    'Souls Inside Site',
                                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          HapticFeedback.heavyImpact();
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyMusterScreen()));
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: AppTheme.badgeDecoration(
                            background: AppTheme.dangerBg,
                            borderColor: AppTheme.dangerBorder,
                            radius: 10,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 15),
                              SizedBox(width: 5),
                              Text('MUSTER SOS', style: TextStyle(color: AppTheme.danger, fontSize: 10.5, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 3 METRIC TILES (Workers, Visitors, Vehicles)
                  Row(
                    children: [
                      _buildMetricTile('WORKERS', '$workersInside', const Color(0xFF0284C7), Icons.engineering_rounded),
                      const SizedBox(width: 6),
                      _buildMetricTile('VISITORS', '$visitorsInside', const Color(0xFFD97706), Icons.badge_rounded),
                      const SizedBox(width: 6),
                      _buildMetricTile('VEHICLES', '$vehiclesInside', const Color(0xFF9333EA), Icons.local_shipping_rounded),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // SEARCH BAR
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search by Person Name, Badge Code, Contractor...',
                      hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary, size: 18),
                      suffixIcon: _search.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, color: AppTheme.textSecondary, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _search = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppTheme.bgSurface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppTheme.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppTheme.border),
                      ),
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
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                  : filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: AppTheme.bgSurface, shape: BoxShape.circle),
                                child: const Icon(Icons.verified_user_outlined, size: 40, color: AppTheme.primary),
                              ),
                              const SizedBox(height: 12),
                              const Text('No entities currently inside matching filter', style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              const Text('Turnstile gate records synchronize in real-time', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async => _fetchInside(),
                          color: AppTheme.primary,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, idx) {
                              final item = filtered[idx];
                              final type = (item['type'] ?? 'Employee').toString();
                              final isWorker = type.toLowerCase().contains('emp') || type.toLowerCase().contains('worker');
                              final isVisitor = type.toLowerCase().contains('vis');

                              final accentColor = isWorker
                                  ? AppTheme.primary
                                  : isVisitor
                                      ? const Color(0xFFD97706)
                                      : const Color(0xFF9333EA);

                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: AppTheme.cardDecoration(
                                  customBorder: Border.all(color: AppTheme.border),
                                ),
                                child: Row(
                                  children: [
                                    // Avatar
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: AppTheme.badgeDecoration(
                                        background: accentColor.withValues(alpha: 0.1),
                                        borderColor: accentColor.withValues(alpha: 0.25),
                                        radius: 22,
                                      ),
                                      child: Center(
                                        child: Icon(
                                          isWorker
                                              ? Icons.engineering_rounded
                                              : isVisitor
                                                  ? Icons.badge_rounded
                                                  : Icons.local_shipping_rounded,
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
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: AppTheme.badgeDecoration(
                                                  background: AppTheme.successBg,
                                                  borderColor: AppTheme.successBorder,
                                                  radius: 4,
                                                ),
                                                child: const Text('INSIDE', style: TextStyle(color: AppTheme.success, fontSize: 8.5, fontWeight: FontWeight.bold)),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '${item['code'] ?? 'ID-100'} • ${item['vendor'] ?? 'Zyeta Direct'}',
                                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.login_rounded, color: AppTheme.primary, size: 12),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Entry: ${item['entry_time'] != null ? item['entry_time'].toString().split('T').last.substring(0, 5) : 'Turnstile 01'}',
                                                style: const TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.w600),
                                              ),
                                              const SizedBox(width: 8),
                                              const Text('• Zone: Main Core', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Quick Checkout Button
                                    InkWell(
                                      onTap: () => _quickCheckout(item),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                        decoration: AppTheme.badgeDecoration(
                                          background: AppTheme.dangerBg,
                                          borderColor: AppTheme.dangerBorder,
                                          radius: 8,
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.logout_rounded, size: 14, color: AppTheme.danger),
                                            SizedBox(width: 4),
                                            Text('OUT', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold, fontSize: 10.5)),
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
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: AppTheme.cardDecoration(
          color: AppTheme.bgSurface,
          customBorder: Border.all(color: AppTheme.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: AppTheme.badgeDecoration(
                background: color.withValues(alpha: 0.1),
                borderColor: color.withValues(alpha: 0.2),
                radius: 6,
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900)),
                  ),
                  Text(
                    label,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 8.5, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
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
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
