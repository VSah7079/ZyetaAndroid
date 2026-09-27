import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class QRScannerScreen extends StatefulWidget {
  final bool isManual;
  const QRScannerScreen({super.key, this.isManual = false});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final _inputController = TextEditingController();
  bool _isLoading = false;
  VerificationResult? _result;
  String? _errorMessage;
  String? _successMessage;

  void _verify([String? code]) async {
    final query = code ?? _inputController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
      _result = null;
    });

    final res = await ApiService.verifyQR(query);

    setState(() {
      _isLoading = false;
      if (res != null) {
        _result = res;
      } else {
        _errorMessage = 'Code not found or access denied.';
      }
    });
  }

  void _recordMovement(String type) async {
    if (_result == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await ApiService.recordGateMovement(
      entityType: _result!.entityType,
      entityId: _result!.data['id'],
      movementType: type,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      setState(() {
        _successMessage = '${_result!.entityType} Gate $type Successful!';
      });
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) Navigator.pop(context);
      });
    } else if (mounted) {
      setState(() {
        _errorMessage = 'Movement failed or duplicate attempt detected.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Gate Security Verification Terminal', style: TextStyle(color: Colors.white, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Search / Scan Input
            TextField(
              controller: _inputController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Scan QR / Enter Employee, Visitor, DC or Vehicle Plate...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                prefixIcon: const Icon(Icons.qr_code_scanner, color: Color(0xFF6366F1)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.check_circle, color: Color(0xFF10B981)),
                  onPressed: () => _verify(),
                ),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onSubmitted: (val) => _verify(val),
            ),
            const SizedBox(height: 12),

            // Quick Demo Buttons
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _presetChip('EMP-101 (Worker)'),
                  const SizedBox(width: 8),
                  _presetChip('EMP-102 (Flagged)'),
                  const SizedBox(width: 8),
                  _presetChip('VIS-2026-101 (Visitor)'),
                  const SizedBox(width: 8),
                  _presetChip('DC-2026-101 (Material DC)'),
                  const SizedBox(width: 8),
                  _presetChip('KA 01 AB 1234 (Vehicle)'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(color: Color(0xFF6366F1)),
              ),

            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent))),
                  ],
                ),
              ),

            if (_successMessage != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.greenAccent),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.greenAccent, size: 28),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_successMessage!, style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16))),
                  ],
                ),
              ),

            // Result Card
            if (_result != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _result!.verificationStatus == 'DENIED'
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
                    // Header with Entity Badge & Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            _result!.entityType.toUpperCase(),
                            style: const TextStyle(color: Color(0xFF818CF8), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _result!.verificationStatus == 'DENIED'
                                ? Colors.red.withValues(alpha: 0.2)
                                : _result!.complianceWarnings.isNotEmpty
                                    ? Colors.orange.withValues(alpha: 0.2)
                                    : Colors.green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _result!.verificationStatus,
                            style: TextStyle(
                              color: _result!.verificationStatus == 'DENIED'
                                  ? Colors.redAccent
                                  : _result!.complianceWarnings.isNotEmpty
                                      ? Colors.orangeAccent
                                      : Colors.greenAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Details based on Entity Type
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_result!.entityType == 'Employee')
                          CircleAvatar(
                            radius: 28,
                            backgroundImage: NetworkImage(
                              _result!.data['profile_photo'] ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
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
                                    'Entity',
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_result!.data['employee_id'] ?? _result!.data['pass_code'] ?? _result!.data['dc_number'] ?? _result!.data['permit_type'] ?? _result!.data['vehicle_type'] ?? ''}',
                                style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              if (_result!.data['vendor_name'] != null || _result!.data['company'] != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Vendor/Company: ${_result!.data['vendor_name'] ?? _result!.data['company']}',
                                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Compliance Warnings if any
                    if (_result!.complianceWarnings.isNotEmpty) ...[
                      const SizedBox(height: 14),
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
                                Text('Safety & Compliance Flags:', style: TextStyle(color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ..._result!.complianceWarnings.map((w) => Text('• $w', style: const TextStyle(color: Colors.white70, fontSize: 11))),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Presence State
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Gate Presence Status:', style: TextStyle(color: Colors.white54, fontSize: 12)),
                          Text(
                            _result!.isCurrentlyInside ? 'CURRENTLY INSIDE' : 'CURRENTLY OUTSIDE',
                            style: TextStyle(
                              color: _result!.isCurrentlyInside ? Colors.greenAccent : Colors.orangeAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Big Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _result!.verificationStatus == 'DENIED' || _result!.isCurrentlyInside
                                  ? null
                                  : () => _recordMovement('ENTRY'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                disabledBackgroundColor: Colors.white10,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('ALLOW ENTRY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _result!.verificationStatus == 'DENIED' || !_result!.isCurrentlyInside
                                  ? null
                                  : () => _recordMovement('EXIT'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF43F5E),
                                disabledBackgroundColor: Colors.white10,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('ALLOW EXIT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _presetChip(String label) {
    final code = label.split(' ').first;
    return ActionChip(
      backgroundColor: const Color(0xFF1E293B),
      side: const BorderSide(color: Colors.white10),
      label: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      onPressed: () {
        _inputController.text = code;
        _verify(code);
      },
    );
  }
}
