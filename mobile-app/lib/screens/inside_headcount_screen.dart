import 'package:flutter/material.dart';
import '../services/api_service.dart';

class InsideHeadcountScreen extends StatefulWidget {
  const InsideHeadcountScreen({super.key});

  @override
  State<InsideHeadcountScreen> createState() => _InsideHeadcountScreenState();
}

class _InsideHeadcountScreenState extends State<InsideHeadcountScreen> {
  List<dynamic> _insideList = [];
  bool _isLoading = true;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Text('Live Inside Headcount', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _fetchInside,
          ),
        ],
      ),
      body: Column(
        children: [
          // Headcount Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF0F172A),
            child: Row(
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.circle, color: Colors.greenAccent, size: 8),
                      SizedBox(width: 6),
                      Text('LIVE SYNCED', style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
                : _insideList.isEmpty
                    ? const Center(
                        child: Text('Premises clear. Nobody currently inside.', style: TextStyle(color: Colors.white54)),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => _fetchInside(),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(14),
                          itemCount: _insideList.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, idx) {
                            final item = _insideList[idx];

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
}
