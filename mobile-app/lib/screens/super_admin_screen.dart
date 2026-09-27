import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/validators.dart';

class SuperAdminScreen extends StatefulWidget {
  const SuperAdminScreen({super.key});

  @override
  State<SuperAdminScreen> createState() => _SuperAdminScreenState();
}

class _SuperAdminScreenState extends State<SuperAdminScreen> {
  List<dynamic> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  void _fetchUsers() async {
    setState(() => _isLoading = true);
    final users = await ApiService.getUsers();
    if (mounted) {
      setState(() {
        _users = users;
        _isLoading = false;
      });
    }
  }

  void _openCreateUserModal() {
    final userCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String role = 'Admin';
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.person_add_alt, color: Color(0xFF6366F1)),
                        SizedBox(width: 8),
                        Text('Create System User', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 14),
                _buildTextField(nameCtrl, 'Full Name *', Icons.person),
                const SizedBox(height: 10),
                _buildTextField(userCtrl, 'Username *', Icons.account_circle),
                const SizedBox(height: 10),
                _buildTextField(emailCtrl, 'Email Address *', Icons.email, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 10),
                _buildTextField(passCtrl, 'Password *', Icons.lock, isPassword: true),
                const SizedBox(height: 10),
                _buildTextField(phoneCtrl, 'Phone Number', Icons.phone, keyboardType: TextInputType.phone),
                const SizedBox(height: 10),

                // Role Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(10)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: role,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1E293B),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      items: const [
                        DropdownMenuItem(value: 'Super Admin', child: Text('👑 Super Admin')),
                        DropdownMenuItem(value: 'Admin', child: Text('🏢 Site Admin')),
                        DropdownMenuItem(value: 'Security', child: Text('🛡️ Security Guard')),
                        DropdownMenuItem(value: 'Vendor', child: Text('🏗️ Vendor / Contractor')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => role = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            final nameErr = FormValidators.validateName(nameCtrl.text, fieldName: 'Full name');
                            if (nameErr != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(nameErr), backgroundColor: Colors.orange));
                              return;
                            }

                            final userErr = FormValidators.validateRequired(userCtrl.text, fieldName: 'Username', minLength: 3);
                            if (userErr != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(userErr), backgroundColor: Colors.orange));
                              return;
                            }

                            final emailErr = FormValidators.validateEmail(emailCtrl.text);
                            if (emailErr != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(emailErr), backgroundColor: Colors.orange));
                              return;
                            }

                            final passErr = FormValidators.validatePassword(passCtrl.text, minLength: 4);
                            if (passErr != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(passErr), backgroundColor: Colors.orange));
                              return;
                            }

                            final phoneErr = FormValidators.validatePhone(phoneCtrl.text, isRequired: false);
                            if (phoneErr != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(phoneErr), backgroundColor: Colors.orange));
                              return;
                            }

                            setModalState(() => isSaving = true);
                            final ok = await ApiService.createUser({
                              'full_name': nameCtrl.text.trim(),
                              'username': userCtrl.text.trim(),
                              'email': emailCtrl.text.trim(),
                              'password': passCtrl.text.trim(),
                              'phone': phoneCtrl.text.trim(),
                              'role': role,
                            });
                            setModalState(() => isSaving = false);
                            if (ok && mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('System user created successfully!'), backgroundColor: Colors.green),
                              );
                              _fetchUsers();
                            } else if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Failed to create user (User/Email may already exist)'), backgroundColor: Colors.red),
                              );
                            }
                          },
                    child: isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('CREATE SYSTEM ACCOUNT', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon, {TextInputType? keyboardType, bool isPassword = false}) {
    return TextField(
      controller: ctrl,
      obscureText: isPassword,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.white54, size: 20),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Text('Super Admin Suite', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _fetchUsers,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('New User', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        onPressed: _openCreateUserModal,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  color: const Color(0xFF1E293B),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.admin_panel_settings, color: Color(0xFF6366F1), size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('System User Management', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('Total ${_users.length} Active System Accounts', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text('REGISTERED SYSTEM USERS & ROLES', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                ),

                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async => _fetchUsers(),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      itemCount: _users.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, idx) {
                        final u = _users[idx];
                        final role = u['role'] ?? 'User';

                        Color roleColor = role == 'Super Admin'
                            ? const Color(0xFFF59E0B)
                            : role == 'Admin'
                                ? const Color(0xFF6366F1)
                                : role == 'Security'
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF06B6D4);

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: roleColor.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: roleColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.person, color: roleColor, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          u['full_name'] ?? u['username'] ?? '',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: roleColor.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: roleColor.withValues(alpha: 0.4)),
                                          ),
                                          child: Text(
                                            role,
                                            style: TextStyle(color: roleColor, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Username: ${u['username']} • ${u['email']}',
                                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                                    ),
                                    if (u['phone'] != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Phone: ${u['phone']}',
                                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                                      ),
                                    ]
                                  ],
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
}
