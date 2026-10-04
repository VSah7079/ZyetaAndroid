import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/validators.dart';

class SuperAdminScreen extends StatefulWidget {
  const SuperAdminScreen({super.key});

  @override
  State<SuperAdminScreen> createState() => _SuperAdminScreenState();
}

class _SuperAdminScreenState extends State<SuperAdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _users = [];
  List<dynamic> _employees = [];
  List<dynamic> _vendors = [];
  List<dynamic> _permits = [];
  List<dynamic> _auditLogs = [];
  bool _isLoading = true;

  final Map<String, String> _availablePermissions = {
    'gate': '🛡️ Gate Security Terminal & Camera Scanner',
    'employees': '👷 Workforce Management & ID Passes',
    'vendors': '🏢 Contractor & Vendor Management',
    'permits': '📋 Permits to Work (PTW Reviews & Approvals)',
    'safety': '⛑️ HSE Safety Command & Site Audits',
    'tbt': '🗣️ Daily Toolbox Talks (TBT Briefings)',
    'emergency': '🚨 Emergency Evacuation & Muster Roll',
    'blacklist': '🚫 Blacklist & Disciplinary Watchlist',
    'visitors': '👤 Visitor Passes & Check-in/Checkout',
    'materials': '📦 Material Delivery Challans (DC Inward/Outward)',
    'vehicles': '🚗 Vehicle Fleet & Verification',
    'attendance': '⏱️ Attendance & Shift Muster Roll',
    'headcount': '🟢 Live Campus Inside Headcount',
    'reports': '📈 Reports & Analytics Export Suite',
    'superadmin': '👑 Super Admin Control (Users & System)',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAllMasterData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadAllMasterData() async {
    setState(() => _isLoading = true);
    final users = await ApiService.getUsers();
    final employees = await ApiService.getEmployees();
    final vendors = await ApiService.getVendors();
    final permits = await ApiService.getPermits();
    final logs = await ApiService.getAuditLogs();

    if (mounted) {
      setState(() {
        _users = users;
        _employees = employees;
        _vendors = vendors;
        _permits = permits;
        _auditLogs = logs;
        _isLoading = false;
      });
    }
  }

  // --- USER CREATION & PERMISSION CHECKBOX MODAL ---
  void _openUserModal([Map<String, dynamic>? editUser]) {
    final isEdit = editUser != null;
    final nameCtrl = TextEditingController(text: editUser?['full_name'] ?? '');
    final userCtrl = TextEditingController(text: editUser?['username'] ?? '');
    final emailCtrl = TextEditingController(text: editUser?['email'] ?? '');
    final passCtrl = TextEditingController(text: isEdit ? '••••••••' : '');
    final phoneCtrl = TextEditingController(text: editUser?['phone'] ?? '');

    String role = editUser?['role'] ?? 'Admin';
    String status = editUser?['status'] ?? 'Active';

    // Set selected permissions
    final Set<String> selectedPermissions = {};
    if (isEdit && editUser['permissions'] != null) {
      selectedPermissions.addAll(List<String>.from(editUser['permissions']));
    } else {
      // Pre-fill default role permissions
      _applyRolePermissionPreset(role, selectedPermissions);
    }

    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(isEdit ? Icons.edit_note : Icons.person_add_alt, color: const Color(0xFFF59E0B), size: 24),
                        const SizedBox(width: 8),
                        Text(
                          isEdit ? 'Edit User & Permissions Matrix' : 'Create User & Assign Access',
                          style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 14),

                const Text('USER PROFILE DETAILS', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildTextField(nameCtrl, 'Full Name *', Icons.person),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildTextField(userCtrl, 'Username *', Icons.account_circle)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildTextField(phoneCtrl, 'Mobile Phone', Icons.phone, keyboardType: TextInputType.phone)),
                  ],
                ),
                const SizedBox(height: 8),
                _buildTextField(emailCtrl, 'Email Address *', Icons.email, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 8),
                if (!isEdit) _buildTextField(passCtrl, 'Account Password *', Icons.lock, isPassword: true),

                const SizedBox(height: 14),
                const Text('SYSTEM ROLE & STATUS', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
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
                              DropdownMenuItem(value: 'Safety Officer', child: Text('⛑️ Safety Officer (HSE)')),
                              DropdownMenuItem(value: 'Vendor', child: Text('🏗️ Contractor / Vendor')),
                              DropdownMenuItem(value: 'Security', child: Text('🛡️ Security Guard')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() {
                                  role = val;
                                  _applyRolePermissionPreset(val, selectedPermissions);
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(10)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: status,
                            isExpanded: true,
                            dropdownColor: const Color(0xFF1E293B),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            items: const [
                              DropdownMenuItem(value: 'Active', child: Text('🟢 Active')),
                              DropdownMenuItem(value: 'Suspended', child: Text('🟡 Suspended')),
                              DropdownMenuItem(value: 'Deactivated', child: Text('🔴 Deactivated')),
                            ],
                            onChanged: (val) {
                              if (val != null) setModalState(() => status = val);
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // GRANULAR PERMISSION CHECKBOX MATRIX
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('GRANULAR PERMISSIONS (CHECK TO GRANT ACCESS)', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () {
                        setModalState(() {
                          if (selectedPermissions.length == _availablePermissions.length) {
                            selectedPermissions.clear();
                          } else {
                            selectedPermissions.addAll(_availablePermissions.keys);
                          }
                        });
                      },
                      child: Text(
                        selectedPermissions.length == _availablePermissions.length ? 'Clear All' : 'Select All',
                        style: const TextStyle(color: Color(0xFF06B6D4), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: _availablePermissions.entries.map((entry) {
                      final isChecked = selectedPermissions.contains(entry.key) || selectedPermissions.contains('all');
                      return CheckboxListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                        activeColor: const Color(0xFFF59E0B),
                        title: Text(entry.value, style: const TextStyle(color: Colors.white, fontSize: 12)),
                        value: isChecked,
                        onChanged: (bool? val) {
                          setModalState(() {
                            if (val == true) {
                              selectedPermissions.add(entry.key);
                            } else {
                              selectedPermissions.remove(entry.key);
                              selectedPermissions.remove('all');
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
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

                            setModalState(() => isSaving = true);
                            final payload = {
                              'full_name': nameCtrl.text.trim(),
                              'username': userCtrl.text.trim(),
                              'email': emailCtrl.text.trim(),
                              'password': passCtrl.text.trim(),
                              'phone': phoneCtrl.text.trim(),
                              'role': role,
                              'status': status,
                              'permissions': selectedPermissions.toList(),
                            };

                            if (isEdit) {
                              await ApiService.updateUser(editUser['id'], payload);
                            } else {
                              await ApiService.createUser(payload);
                            }

                            setModalState(() => isSaving = false);
                            if (mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(isEdit ? 'User updated successfully!' : 'User created with custom permissions!'), backgroundColor: Colors.green),
                              );
                              _loadAllMasterData();
                            }
                          },
                    child: isSaving
                        ? const CircularProgressIndicator(color: Colors.black87)
                        : Text(
                            isEdit ? 'UPDATE USER & ACCESS' : 'CREATE ACCOUNT & GRANT ACCESS',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _applyRolePermissionPreset(String role, Set<String> perms) {
    perms.clear();
    if (role == 'Super Admin') {
      perms.add('all');
    } else if (role == 'Admin') {
      perms.addAll(['employees', 'vendors', 'gate', 'permits', 'safety', 'visitors', 'materials', 'vehicles', 'attendance', 'headcount', 'reports']);
    } else if (role == 'Safety Officer') {
      perms.addAll(['safety', 'permits', 'employees', 'attendance', 'headcount', 'reports']);
    } else if (role == 'Vendor') {
      perms.addAll(['employees', 'permits', 'materials', 'attendance']);
    } else if (role == 'Security') {
      perms.addAll(['gate', 'visitors', 'materials', 'vehicles', 'headcount', 'permits']);
    }
  }

  void _deleteUserPrompt(Map<String, dynamic> user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('Delete Account ${user['username']}?', style: const TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to permanently delete user account for ${user['full_name']}?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ApiService.deleteUser(user['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User ${user['username']} deleted'), backgroundColor: Colors.red),
        );
      }
      _loadAllMasterData();
    }
  }

  // --- WORKER EDIT / DELETE MODAL ---
  void _openEditWorkerModal(Map<String, dynamic> emp) {
    final nameCtrl = TextEditingController(text: emp['full_name']);
    final desigCtrl = TextEditingController(text: emp['designation']);
    final tradeCtrl = TextEditingController(text: emp['skill']);
    final mobileCtrl = TextEditingController(text: emp['mobile']);
    String status = emp['status'] ?? 'Active';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Edit Worker ${emp['employee_id']}', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 12),
              _buildTextField(nameCtrl, 'Full Name', Icons.person),
              const SizedBox(height: 8),
              _buildTextField(mobileCtrl, 'Mobile', Icons.phone, keyboardType: TextInputType.phone),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildTextField(desigCtrl, 'Designation', Icons.badge)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildTextField(tradeCtrl, 'Skill / Trade', Icons.handyman)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await ApiService.deleteEmployee(emp['id']);
                        _loadAllMasterData();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Worker record deleted from system'), backgroundColor: Colors.red),
                          );
                        }
                      },
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent)),
                      child: const Text('DELETE WORKER', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await ApiService.updateEmployee(emp['id'], {
                          'full_name': nameCtrl.text.trim(),
                          'mobile': mobileCtrl.text.trim(),
                          'designation': desigCtrl.text.trim(),
                          'skill': tradeCtrl.text.trim(),
                          'status': status,
                        });
                        _loadAllMasterData();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Worker updated successfully!'), backgroundColor: Colors.green),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                      child: const Text('SAVE CHANGES', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- VENDOR EDIT / DELETE MODAL ---
  void _openEditVendorModal(Map<String, dynamic> vnd) {
    final nameCtrl = TextEditingController(text: vnd['company_name']);
    final ownerCtrl = TextEditingController(text: vnd['owner_name']);
    final phoneCtrl = TextEditingController(text: vnd['phone']);
    final emailCtrl = TextEditingController(text: vnd['email']);

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
                Text('Edit Contractor ${vnd['vendor_id']}', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 12),
            _buildTextField(nameCtrl, 'Company Name', Icons.business),
            const SizedBox(height: 8),
            _buildTextField(ownerCtrl, 'Authorized Contact', Icons.person),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildTextField(phoneCtrl, 'Phone', Icons.phone)),
                const SizedBox(width: 8),
                Expanded(child: _buildTextField(emailCtrl, 'Email', Icons.email)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await ApiService.deleteVendor(vnd['id']);
                      _loadAllMasterData();
                    },
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent)),
                    child: const Text('DELETE VENDOR', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await ApiService.updateVendor(vnd['id'], {
                        'company_name': nameCtrl.text.trim(),
                        'owner_name': ownerCtrl.text.trim(),
                        'phone': phoneCtrl.text.trim(),
                        'email': emailCtrl.text.trim(),
                      });
                      _loadAllMasterData();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF06B6D4)),
                    child: const Text('SAVE VENDOR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon, {TextInputType? keyboardType, bool isPassword = false}) {
    return TextField(
      controller: ctrl,
      obscureText: isPassword,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
        prefixIcon: Icon(icon, color: Colors.white54, size: 18),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.admin_panel_settings, color: Color(0xFFF59E0B), size: 20),
                SizedBox(width: 8),
                Text('Super Admin Control Center', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
            Text(
              'Master Database & Granular Access Control (RBAC)',
              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.6)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadAllMasterData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color(0xFFF59E0B),
          indicatorWeight: 3,
          labelColor: const Color(0xFFF59E0B),
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          tabs: [
            Tab(icon: const Icon(Icons.people, size: 18), text: 'Users (${_users.length})'),
            Tab(icon: const Icon(Icons.badge, size: 18), text: 'Workforce (${_employees.length})'),
            Tab(icon: const Icon(Icons.business, size: 18), text: 'Vendors (${_vendors.length})'),
            Tab(icon: const Icon(Icons.assignment, size: 18), text: 'Permits (${_permits.length})'),
            Tab(icon: const Icon(Icons.history_edu, size: 18), text: 'Audit Logs'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildUsersTab(),
                _buildWorkforceTab(),
                _buildVendorsTab(),
                _buildPermitsTab(),
                _buildAuditTab(),
              ],
            ),
    );
  }

  // --- TAB 1: USERS & PERMISSION MATRIX ---
  Widget _buildUsersTab() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFF59E0B),
        icon: const Icon(Icons.person_add, color: Colors.black87),
        label: const Text('Add User & Permissions', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        onPressed: () => _openUserModal(),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: _users.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, idx) {
          final u = _users[idx];
          final role = u['role'] ?? 'Admin';
          final status = u['status'] ?? 'Active';
          final perms = (u['permissions'] as List<dynamic>?) ?? [];
          final isSuperAdmin = role == 'Super Admin';

          Color roleColor = isSuperAdmin
              ? const Color(0xFFF59E0B)
              : role == 'Admin'
                  ? const Color(0xFF6366F1)
                  : role == 'Safety Officer'
                      ? const Color(0xFFF97316)
                      : role == 'Vendor'
                          ? const Color(0xFF06B6D4)
                          : const Color(0xFF10B981);

          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: roleColor.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: roleColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.person, color: roleColor, size: 22),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              u['full_name'] ?? u['username'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                            ),
                            Text(
                              '${u['username']} • ${u['email']}',
                              style: const TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: status == 'Active' ? Colors.green.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: status == 'Active' ? Colors.greenAccent : Colors.redAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Assigned Permissions Chips
                const Text('GRANTED PERMISSIONS (RBAC):', style: TextStyle(color: Colors.white38, fontSize: 9.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: perms.map((p) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(4)),
                      child: Text(
                        p.toString().toUpperCase(),
                        style: TextStyle(color: roleColor, fontSize: 9.5, fontWeight: FontWeight.bold),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 8),

                // Action Buttons: Edit, Permissions, Delete
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.edit_note, size: 16, color: Color(0xFF06B6D4)),
                      label: const Text('Edit & Permissions', style: TextStyle(color: Color(0xFF06B6D4), fontSize: 11, fontWeight: FontWeight.bold)),
                      onPressed: () => _openUserModal(u),
                    ),
                    if (!isSuperAdmin)
                      TextButton.icon(
                        icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                        label: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed: () => _deleteUserPrompt(u),
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

  // --- TAB 2: WORKFORCE MASTER ---
  Widget _buildWorkforceTab() {
    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: _employees.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, idx) {
        final emp = _employees[idx];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(image: NetworkImage(emp['profile_photo'] ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150'), fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(emp['full_name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('${emp['employee_id']} • ${emp['designation']} (${emp['vendor_name']})', style: const TextStyle(color: Color(0xFF06B6D4), fontSize: 11)),
                    Text('Aadhaar: ${emp['aadhaar_no']} • Medical: ${emp['medical_validity']}', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Color(0xFF6366F1), size: 20),
                onPressed: () => _openEditWorkerModal(emp),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- TAB 3: VENDORS MASTER ---
  Widget _buildVendorsTab() {
    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: _vendors.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, idx) {
        final vnd = _vendors[idx];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: const Color(0xFF06B6D4).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.business, color: Color(0xFF06B6D4)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vnd['company_name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('${vnd['vendor_id']} • Owner: ${vnd['owner_name']} (${vnd['phone']})', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    Text('Contract: ${vnd['contract_start']} to ${vnd['contract_end']}', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Color(0xFF06B6D4), size: 20),
                onPressed: () => _openEditVendorModal(vnd),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- TAB 4: PERMITS MASTER ---
  Widget _buildPermitsTab() {
    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: _permits.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, idx) {
        final p = _permits[idx];
        final isApproved = p['status'] == 'Approved' || p['status'] == 'Active';

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(p['permit_number'] ?? '', style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 12)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: isApproved ? Colors.green.withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                    child: Text(p['status'] ?? '', style: TextStyle(color: isApproved ? Colors.greenAccent : Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(p['permit_type'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              Text('Location: ${p['location_zone']} • Contractor: ${p['vendor_name']}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!isApproved)
                    TextButton(
                      onPressed: () async {
                        await ApiService.approvePermit(p['id']);
                        _loadAllMasterData();
                      },
                      child: const Text('Force Approve', style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  TextButton(
                    onPressed: () async {
                      await ApiService.deletePermit(p['id']);
                      _loadAllMasterData();
                    },
                    child: const Text('Delete Permit', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // --- TAB 5: AUDIT LOGS ---
  Widget _buildAuditTab() {
    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: _auditLogs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, idx) {
        final log = _auditLogs[idx];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(log['action_type'] ?? 'AUDIT', style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 11)),
                  Text(log['timestamp'] != null ? log['timestamp'].toString().split('T').first : '', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                ],
              ),
              const SizedBox(height: 4),
              Text(log['details'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 12)),
              const SizedBox(height: 4),
              Text('By: ${log['user_name']} (${log['user_role']})', style: const TextStyle(color: Color(0xFF06B6D4), fontSize: 10)),
            ],
          ),
        );
      },
    );
  }
}
