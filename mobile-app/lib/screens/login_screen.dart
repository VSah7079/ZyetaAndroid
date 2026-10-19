import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../utils/validators.dart';
import '../utils/app_theme.dart';
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
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppTheme.border, width: 1),
            ),
            title: const Row(
              children: [
                Icon(Icons.dns, color: AppTheme.primary, size: 22),
                SizedBox(width: 8),
                Text('Server Configuration', style: TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Configure the backend API URL for this mobile terminal:',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: serverController,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'http://10.64.56.201:5000/api',
                    hintStyle: const TextStyle(color: AppTheme.textMuted),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
                    prefixIcon: const Icon(Icons.link, color: AppTheme.primary, size: 18),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Quick Presets:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10.5, fontWeight: FontWeight.bold)),
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
                      color: testStatus!.contains('✅') ? AppTheme.success : AppTheme.danger,
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
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
                    : const Text('Test Connection', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                onPressed: () {
                  ApiService.setBaseUrl(serverController.text.trim());
                  setState(() {});
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Server URL set to: ${ApiService.baseUrl}'),
                      backgroundColor: AppTheme.primary,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
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
      label: Text(label, style: const TextStyle(fontSize: 10.5, color: AppTheme.textSecondary)),
      backgroundColor: const Color(0xFFF1F5F9),
      side: const BorderSide(color: AppTheme.border),
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
      backgroundColor: AppTheme.bgPrimary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Top Server Status Indicator Pill
                  Align(
                    alignment: Alignment.topRight,
                    child: InkWell(
                      onTap: _showServerConfigDialog,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.border),
                          boxShadow: AppTheme.softShadow,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.success,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              ApiService.baseUrl.replaceFirst('http://', '').replaceFirst('/api', ''),
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Modern Minimal Brand Icon
                  Container(
                    width: 76,
                    height: 76,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: AppTheme.mediumShadow,
                      border: Border.all(color: AppTheme.primaryLight, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset(
                        'assets/app_logo.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                            ),
                          ),
                          child: const Icon(Icons.shield, color: Colors.white, size: 38),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text(
                    'ZyetaGate OS',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'WORKFORCE, VENDOR & TURNSTILE HUB',
                        style: TextStyle(color: AppTheme.primary, fontSize: 10.5, fontWeight: FontWeight.bold, letterSpacing: 0.6),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.dangerBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.dangerBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.error_outline, color: AppTheme.danger, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(_errorMessage!, style: const TextStyle(color: AppTheme.danger, fontSize: 12.5, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: _showServerConfigDialog,
                            child: const Text(
                              '⚙️ Check Server IP or connection settings',
                              style: TextStyle(color: AppTheme.primary, fontSize: 11, decoration: TextDecoration.underline),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Main Clean Card for Credentials
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: AppTheme.cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _userController,
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            labelText: 'Username or Work Email',
                            labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                            hintText: 'e.g. security_gate1',
                            prefixIcon: const Icon(Icons.person_outline, color: AppTheme.primary, size: 20),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _passController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                            hintText: '••••••••',
                            prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primary, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppTheme.textMuted, size: 18),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Sign In Action
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : () => _handleLogin(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 2,
                              shadowColor: AppTheme.primary.withValues(alpha: 0.35),
                            ),
                            child: _isLoading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text(
                                    'SIGN IN TO GATE TERMINAL',
                                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),
                  Row(
                    children: [
                      const Expanded(child: Divider(color: AppTheme.border)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'FAST ROLE DEMO (TAP TO TEST)',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 10.5, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                      ),
                      const Expanded(child: Divider(color: AppTheme.border)),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 5 Role Buttons formatted as clean compact cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildRoleButton(
                          '👑 Super Admin',
                          'Gate Pass Approval',
                          const Color(0xFFD97706),
                          const Color(0xFFFFFBEB),
                          () => _handleLogin('superadmin', 'admin123'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildRoleButton(
                          '🏢 Site Admin',
                          'KYC & Verification',
                          const Color(0xFF4F46E5),
                          const Color(0xFFEEF2FF),
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
                          const Color(0xFFEA580C),
                          const Color(0xFFFFF7ED),
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
                          const Color(0xFF0284C7),
                          const Color(0xFFF0F9FF),
                          () => _handleLogin('vendor_infra', 'vendor123'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildRoleButton(
                          '🛡️ Security Guard',
                          'Turnstile Scanner',
                          const Color(0xFF059669),
                          const Color(0xFFECFDF5),
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
      ),
    );
  }

  Widget _buildRoleButton(String title, String subtitle, Color color, Color bgColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(title.split(' ').first, style: const TextStyle(fontSize: 14)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      title.substring(title.indexOf(' ') + 1),
                      style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9.5),
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
}
