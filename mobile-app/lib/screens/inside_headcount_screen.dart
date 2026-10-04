import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'emergency_muster_screen.dart';

class InsideHeadcountScreen extends StatefulWidget {
  const InsideHeadcountScreen({super.key});

  @override
  State<InsideHeadcountScreen> createState() => _InsideHeadcountScreenState();
}

class _InsideHeadcountScreenState extends State<InsideHeadcountScreen> {
  List<dynamic> _insideList = [];
  bool _isLoading = true;
  String _filter = 'ALL';
  String _search = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchInside();
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
    final ok = await ApiService.recordGateMovement(
      entityType: item['type'] ?? 'Employee',
      entityId: item['id'],
      movementType: 'EXIT',
      remarks: 'Emergency / Supervisor manual checkout from mobile',
    );
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item['name']} marked OUT'), backgroundColor: Colors.green),
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

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Text('Live Inside Headcount', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            tooltip: 'Emergency Muster Roll',
            icon: const Icon(Icons.emergency, color: Colors.redAccent),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyMusterScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _fetchInside,
          ),
        ],
      ),
      body: Column(
        children: [
          // Headcount Banner with Muster Link
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF0F172A),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('CURRENTLY ON PREMISES', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          '${_insideList.length} Persons Inside',
                          style: const TextStyle(color: Color(0xFF10B981), fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyMusterScreen()));
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.emergency, color: Colors.redAccent, size: 16),
                            SizedBox(width: 6),
                            Text('Muster Call', style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search inside person, ID, contractor...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 18),
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
                    fillColor: const Color(0xFF1E293B),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                  onChanged: (val) => setState(() => _search = val.trim()),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildFilterChip('ALL', 'All Inside (${_insideList.length})'),
                    const SizedBox(width: 6),
                    _buildFilterChip('WORKERS', 'Workers'),
                    const SizedBox(width: 6),
                    _buildFilterChip('VISITORS', 'Visitors'),
                    const SizedBox(width: 6),
                    _buildFilterChip('VEHICLES', 'Drivers'),
                  ],
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_outline, size: 48, color: Colors.white24),
                            const SizedBox(height: 10),
                            const Text('No persons found matching criteria', style: TextStyle(color: Colors.white54)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => _fetchInside(),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(14),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, idx) {
                            final item = filtered[idx];

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.person, color: Colors.greenAccent, size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['name'] ?? '',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                                        ),
                                        Text(
                                          '${item['code']} • ${item['vendor'] ?? 'Direct'}',
                                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Entry: ${item['entry_time'] != null ? item['entry_time'].toString().split('T').last.substring(0, 5) : 'Active'}',
                                          style: const TextStyle(color: Color(0xFF06B6D4), fontSize: 11, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Color(0xFFF43F5E)),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    ),
                                    onPressed: () => _quickCheckout(item),
                                    child: const Text('OUT', style: TextStyle(color: Color(0xFFF43F5E), fontWeight: FontWeight.bold, fontSize: 11)),
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

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _filter == key;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.white70, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      selectedColor: const Color(0xFF10B981),
      backgroundColor: const Color(0xFF1E293B),
      side: BorderSide(color: isSelected ? const Color(0xFF10B981) : Colors.white12),
      onSelected: (_) => setState(() => _filter = key),
    );
  }
}
