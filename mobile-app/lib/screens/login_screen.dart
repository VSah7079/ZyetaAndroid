import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../utils/validators.dart';
import 'main_navigation_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  void _handleLogin([String? u, String? p]) async {
    HapticFeedback.lightImpact();
    final username = u ?? _userController.text.trim();
    final password = p ?? _passController.text.trim();

    final userErr = FormValidators.validateRequired(username, fieldName: 'Username or email', minLength: 3);
    if (userErr != null) {
      setState(() => _errorMessage = userErr);
      return;
    }

    final passErr = FormValidators.validatePassword(password, minLength: 4);
    if (passErr != null) {
      setState(() => _errorMessage = passErr);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await ApiService.login(username, password);

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } else if (mounted) {
      setState(() => _errorMessage = 'Invalid login credentials or server unreachable');
    }
  }

  void _showServerConfigDialog() {
    final serverController = TextEditingController(text: ApiService.baseUrl);
    bool isTesting = false;
    String? testStatus;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFF06B6D4), width: 1.5),
            ),
            title: const Row(
              children: [
                Icon(Icons.dns, color: Color(0xFF06B6D4), size: 22),
                SizedBox(width: 8),
                Text('Server Configuration', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Configure the backend API URL for this mobile terminal:',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: serverController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'http://10.64.56.201:5000/api',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF070B14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.link, color: Color(0xFF06B6D4), size: 18),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Quick Presets:', style: TextStyle(color: Colors.white54, fontSize: 10.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildPresetChip('📱 Wi-Fi IP (Current)', 'http://10.64.56.201:5000/api', serverController, setDialogState),
                    _buildPresetChip('💻 Localhost', 'http://127.0.0.1:5000/api', serverController, setDialogState),
                    _buildPresetChip('🤖 Android Emulator', 'http://10.0.2.2:5000/api', serverController, setDialogState),
                  ],
                ),
                if (testStatus != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    testStatus!,
                    style: TextStyle(
                      color: testStatus!.contains('✅') ? Colors.greenAccent : Colors.redAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: isTesting
                    ? null
                    : () async {
                        setDialogState(() {
                          isTesting = true;
                          testStatus = 'Testing connection...';
                        });
                        final ok = await ApiService.testConnection(serverController.text.trim());
                        setDialogState(() {
                          isTesting = false;
                          testStatus = ok ? '✅ Connected successfully!' : '❌ Failed to reach server (Will use offline demo mode)';
                        });
                      },
                child: isTesting
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Test Connection', style: TextStyle(color: Color(0xFF06B6D4), fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                onPressed: () {
                  ApiService.setBaseUrl(serverController.text.trim());
                  setState(() {});
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Server URL set to: ${ApiService.baseUrl}'),
                      backgroundColor: const Color(0xFF06B6D4),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF06B6D4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Save & Apply', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPresetChip(String label, String url, TextEditingController controller, StateSetter setDialogState) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 10.5, color: Colors.white70)),
      backgroundColor: const Color(0xFF1E293B),
      side: const BorderSide(color: Color(0xFF334155)),
      onPressed: () {
        setDialogState(() {
          controller.text = url;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Top Server Status Indicator Button
                Align(
                  alignment: Alignment.topRight,
                  child: InkWell(
                    onTap: _showServerConfigDialog,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.dns, size: 14, color: Color(0xFF06B6D4)),
                          const SizedBox(width: 6),
                          Text(
                            ApiService.baseUrl.replaceFirst('http://', '').replaceFirst('/api', ''),
                            style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Glowing Biometric Hologram Shield Logo
                Container(
                  width: 86,
                  height: 86,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF06B6D4), Color(0xFF6366F1), Color(0xFF10B981)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF06B6D4).withValues(alpha: 0.45),
                        blurRadius: 30,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(23),
                    child: Image.asset(
                      'assets/app_logo.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
                          ),
                        ),
                        child: const Icon(Icons.shield, color: Color(0xFF06B6D4), size: 44),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                const Text(
                  'ZyetaGate OS',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'TURNSTILE & WORKFORCE COMMAND SYSTEM',
                      style: TextStyle(color: Color(0xFF06B6D4), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 12.5)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: _showServerConfigDialog,
                          child: const Text(
                            '⚙️ Tap here to check Server IP / Offline mode',
                            style: TextStyle(color: Color(0xFF06B6D4), fontSize: 11, decoration: TextDecoration.underline),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Form Fields
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: TextField(
                    controller: _userController,
                    style: const TextStyle(color: Colors.white, fontSize: 13.5),
                    decoration: const InputDecoration(
                      hintText: 'Username or Email',
                      hintStyle: TextStyle(color: Colors.white38, fontSize: 12.5),
                      prefixIcon: Icon(Icons.person_outline, color: Color(0xFF06B6D4), size: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: TextField(
                    controller: _passController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: Colors.white, fontSize: 13.5),
                    decoration: InputDecoration(
                      hintText: 'Security Password',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 12.5),
                      prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF06B6D4), size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white38, size: 18),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Sign In Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _handleLogin(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF06B6D4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 6,
                      shadowColor: const Color(0xFF06B6D4).withValues(alpha: 0.4),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'SIGN IN TO GATE TERMINAL',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.8),
                          ),
                  ),
                ),

                const SizedBox(height: 26),
                Row(
                  children: [
                    const Expanded(child: Divider(color: Colors.white10)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'FAST ROLE PRESETS (ONE-TAP DEMO)',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                      ),
                    ),
                    const Expanded(child: Divider(color: Colors.white10)),
                  ],
                ),
                const SizedBox(height: 14),

                // 5 ROLES PRESET BUTTONS
                Row(
                  children: [
                    Expanded(
                      child: _buildRoleButton(
                        '👑 Super Admin',
                        'Gate Pass Approval',
                        const Color(0xFFF59E0B),
                        () => _handleLogin('superadmin', 'admin123'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildRoleButton(
                        '🏢 Site Admin',
                        'KYC & Verification',
                        const Color(0xFF6366F1),
                        () => _handleLogin('admin', 'admin123'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildRoleButton(
                        '⛑️ Safety Officer (HSE)',
                        'Medical Clearance',
                        const Color(0xFFF97316),
                        () => _handleLogin('safety_officer', 'safety123'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildRoleButton(
                        '🏗️ Vendor Portal',
                        'Workforce & Badges',
                        const Color(0xFF06B6D4),
                        () => _handleLogin('vendor_infra', 'vendor123'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildRoleButton(
                        '🛡️ Security Guard',
                        'Turnstile Scanner',
                        const Color(0xFF10B981),
                        () => _handleLogin('security_gate1', 'security123'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(String title, String subtitle, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.bold)),
            const SizedBox(height: 1),
            Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 9)),
          ],
        ),
      ),
    );
  }
}
