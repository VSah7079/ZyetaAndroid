import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/validators.dart';
import '../utils/responsive.dart';
import '../utils/app_theme.dart';

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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.record_voice_over, color: AppTheme.primary, size: 22),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Record Daily Toolbox Talk (TBT)',
                            style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close, color: AppTheme.textSecondary), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: topicCtrl,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  labelText: 'Briefing Topic *',
                  labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  filled: true,
                  fillColor: AppTheme.bgSurface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: locCtrl,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        labelText: 'Zone / Location *',
                        labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        filled: true,
                        fillColor: AppTheme.bgSurface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: attendeesCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        labelText: 'Workers Present *',
                        labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        filled: true,
                        fillColor: AppTheme.bgSurface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
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
                    backgroundColor: AppTheme.primary,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const AppBarLeadingButton(),
        title: const Row(
          children: [
            Icon(Icons.record_voice_over, color: AppTheme.primary, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Daily Toolbox Talk (TBT)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(tooltip: 'Refresh', icon: const Icon(Icons.refresh, color: AppTheme.primary), onPressed: _loadTalks),
          const LogoutIconButton(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New TBT Session', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: _openNewTBTModal,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : ResponsiveBody(
              padding: EdgeInsets.zero,
              child: ListView.separated(
                padding: const EdgeInsets.all(14),
                itemCount: _talks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, idx) {
                  final t = _talks[idx];
                  final points = (t['key_points'] as List<dynamic>?) ?? [];

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: AppTheme.cardDecoration(customBorder: Border.all(color: AppTheme.border)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: AppTheme.badgeDecoration(color: AppTheme.primary),
                              child: Text(
                                t['category'] ?? 'Safety Briefing',
                                style: const TextStyle(color: AppTheme.primary, fontSize: 10.5, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text('${t['date']} • ${t['time']}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          t['topic'] ?? '',
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Location: ${t['location_zone']} • Trainer: ${t['trainer_name']}',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11.5),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.bgSurface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('KEY SAFETY PROTOCOLS BRIEFED:', style: TextStyle(color: AppTheme.textMuted, fontSize: 9.5, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                              const SizedBox(height: 4),
                              ...points.map((p) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('• ', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                                        Expanded(child: Text(p.toString(), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11.5))),
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
                                const Icon(Icons.people, color: AppTheme.success, size: 16),
                                const SizedBox(width: 6),
                                Text('${t['attendees_count']} Workers Attended', style: const TextStyle(color: AppTheme.success, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: AppTheme.badgeDecoration(color: AppTheme.success),
                              child: const Text('✓ COMPLIANT', style: TextStyle(color: AppTheme.success, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
