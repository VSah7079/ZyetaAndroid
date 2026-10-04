import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ToolboxTalkScreen extends StatefulWidget {
  const ToolboxTalkScreen({super.key});

  @override
  State<ToolboxTalkScreen> createState() => _ToolboxTalkScreenState();
}

class _ToolboxTalkScreenState extends State<ToolboxTalkScreen> {
  List<dynamic> _talks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTalks();
  }

  void _loadTalks() async {
    setState(() => _isLoading = true);
    final list = await ApiService.getToolboxTalks();
    if (mounted) {
      setState(() {
        _talks = list;
        _isLoading = false;
      });
    }
  }

  void _openNewTBTModal() {
    final topicCtrl = TextEditingController(text: 'Scaffolding & Fall Arrest Systems');
    final locCtrl = TextEditingController(text: 'Block A Ground Assembly');
    final attendeesCtrl = TextEditingController(text: '28');
    String category = 'Height Safety';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.record_voice_over, color: Color(0xFFF97316), size: 22),
                    SizedBox(width: 8),
                    Text('Record Daily Toolbox Talk (TBT)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: topicCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Briefing Topic *',
                labelStyle: const TextStyle(color: Colors.white60, fontSize: 12),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: locCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Zone / Location *',
                      labelStyle: const TextStyle(color: Colors.white60, fontSize: 12),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: attendeesCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Workers Present *',
                      labelStyle: const TextStyle(color: Colors.white60, fontSize: 12),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF97316),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await ApiService.createToolboxTalk({
                    'topic': topicCtrl.text.trim(),
                    'location_zone': locCtrl.text.trim(),
                    'attendees_count': int.tryParse(attendeesCtrl.text.trim()) ?? 20,
                    'category': category,
                  });
                  _loadTalks();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Toolbox Talk recorded & logged to HSE compliance!'), backgroundColor: Colors.green),
                    );
                  }
                },
                child: const Text('SUBMIT & LOG TBT BRIEFING', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: const Row(
          children: [
            Icon(Icons.record_voice_over, color: Color(0xFFF97316), size: 20),
            SizedBox(width: 8),
            Text('Daily Toolbox Talk (TBT) Briefings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white70), onPressed: _loadTalks),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFF97316),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New TBT Session', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: _openNewTBTModal,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF97316)))
          : ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: _talks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final t = _talks[idx];
                final points = (t['key_points'] as List<dynamic>?) ?? [];

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFF97316).withValues(alpha: 0.3)),
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
                              color: const Color(0xFFF97316).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              t['category'] ?? 'Safety Briefing',
                              style: const TextStyle(color: Color(0xFFF97316), fontSize: 10.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text('${t['date']} • ${t['time']}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        t['topic'] ?? '',
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Location: ${t['location_zone']} • Trainer: ${t['trainer_name']}',
                        style: const TextStyle(color: Colors.white54, fontSize: 11.5),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('KEY SAFETY PROTOCOLS BRIEFED:', style: TextStyle(color: Colors.white38, fontSize: 9.5, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            ...points.map((p) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('• ', style: TextStyle(color: Color(0xFFF97316), fontWeight: FontWeight.bold)),
                                      Expanded(child: Text(p.toString(), style: const TextStyle(color: Colors.white70, fontSize: 11.5))),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.people, color: Color(0xFF10B981), size: 16),
                              const SizedBox(width: 6),
                              Text('${t['attendees_count']} Workers Attended', style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                            child: const Text('✓ COMPLIANT', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
