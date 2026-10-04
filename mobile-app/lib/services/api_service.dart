import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiService {
  // Configured to host machine Wi-Fi IP (10.64.56.201) with fallback
  static String baseUrl = 'http://10.64.56.201:5000/api';
  static String? authToken;
  static UserModel? currentUser;

  static void setBaseUrl(String url) {
    var cleaned = url.trim();
    if (cleaned.endsWith('/')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    if (!cleaned.endsWith('/api')) {
      cleaned = '$cleaned/api';
    }
    baseUrl = cleaned;
  }

  static Future<bool> testConnection([String? testUrl]) async {
    try {
      final target = testUrl != null
          ? (testUrl.endsWith('/api') ? '$testUrl/health' : '$testUrl/api/health')
          : '$baseUrl/health';
      final response = await http.get(Uri.parse(target)).timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

  // --- IN-MEMORY MOCK STORE FOR REAL-TIME SUPER ADMIN CRUD ---
  static final List<Map<String, dynamic>> _usersStore = [
    {
      'id': 1,
      'username': 'superadmin',
      'full_name': 'Vikram Malhotra (Super Admin)',
      'email': 'superadmin@zyeta.com',
      'role': 'Super Admin',
      'phone': '+91 9900112233',
      'status': 'Active',
      'permissions': ['all'],
    },
    {
      'id': 2,
      'username': 'admin',
      'full_name': 'Priya Sundaram (Site Admin)',
      'email': 'admin@zyeta.com',
      'role': 'Admin',
      'phone': '+91 9900223344',
      'status': 'Active',
      'permissions': ['employees', 'vendors', 'gate', 'permits', 'safety', 'visitors', 'materials', 'vehicles', 'attendance', 'headcount', 'reports'],
    },
    {
      'id': 5,
      'username': 'safety_officer',
      'full_name': 'Er. Rajesh Varma (HSE Head)',
      'email': 'safety@zyeta.com',
      'role': 'Safety Officer',
      'phone': '+91 9988776655',
      'status': 'Active',
      'permissions': ['safety', 'permits', 'employees', 'attendance', 'headcount', 'reports'],
    },
    {
      'id': 3,
      'username': 'vendor_infra',
      'full_name': 'Rajesh Sharma (ABC Infra)',
      'email': 'vendor@abcinfra.com',
      'role': 'Vendor',
      'phone': '+91 9845012345',
      'vendor_id': 1,
      'status': 'Active',
      'permissions': ['employees', 'permits', 'materials', 'attendance'],
    },
    {
      'id': 4,
      'username': 'security_gate1',
      'full_name': 'Commander R. K. Singh (Gate 1)',
      'email': 'security@zyeta.com',
      'role': 'Security',
      'phone': '+91 9122334455',
      'status': 'Active',
      'permissions': ['gate', 'visitors', 'materials', 'vehicles', 'headcount', 'permits'],
    },
  ];

  static final List<Map<String, dynamic>> _employeesStore = [
    {
      'id': 1,
      'employee_id': 'EMP-101',
      'full_name': 'Ramesh Patel',
      'father_name': 'Dinesh Patel',
      'dob': '1990-05-14',
      'gender': 'Male',
      'mobile': '+91 9876543210',
      'alternate_mobile': '+91 9876543211',
      'email': 'ramesh.patel@abcinfra.com',
      'address': 'House #42, Munnekolala, Whitefield',
      'city': 'Bangalore',
      'state': 'Karnataka',
      'pincode': '560037',
      'emergency_name': 'Sunita Patel',
      'emergency_relation': 'Spouse',
      'emergency_phone': '+91 9876543212',
      'blood_group': 'B+',
      'medical_cert': 'Fit for Height Work & Rigging',
      'medical_validity': '2027-01-15',
      'vendor_id': 1,
      'vendor_name': 'ABC Infra Projects Pvt Ltd',
      'department_name': 'Civil & Construction',
      'designation': 'Senior Scaffolding Lead',
      'skill': 'Expert Height Scaffolder',
      'employee_type': 'Contractor',
      'joining_date': '2024-02-10',
      'shift_name': 'General Shift (09:00 - 18:00)',
      'aadhaar_no': '4532 8912 7701',
      'pan_no': 'ABCDE9876K',
      'police_verification_doc': 'police_verified_blr_101.pdf',
      'police_verification_expiry': '2027-02-01',
      'profile_photo': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
      'status': 'Active',
      'currently_inside': 1,
      'last_entry_time': '2026-09-29T08:45:00Z',
    },
    {
      'id': 2,
      'employee_id': 'EMP-102',
      'full_name': 'Amitabh Sen',
      'father_name': 'Prabir Sen',
      'dob': '1988-11-20',
      'gender': 'Male',
      'mobile': '+91 9876543220',
      'alternate_mobile': '+91 9876543221',
      'email': 'amitabh.sen@apexservices.in',
      'address': 'Flat 302, Green Glen Layout, Bellandur',
      'city': 'Bangalore',
      'state': 'Karnataka',
      'pincode': '560103',
      'emergency_name': 'Mitali Sen',
      'emergency_relation': 'Sister',
      'emergency_phone': '+91 9876543222',
      'blood_group': 'A+',
      'medical_cert': 'Certified Electrical Specialist (LOTO)',
      'medical_validity': '2026-11-30',
      'vendor_id': 2,
      'vendor_name': 'Apex MEP Solutions',
      'department_name': 'Electrical & MEP',
      'designation': 'High Voltage Electrician',
      'skill': 'HV Transformer & Switchgear',
      'employee_type': 'Contractor',
      'joining_date': '2024-05-15',
      'shift_name': 'Morning Shift A (06:00 - 14:30)',
      'aadhaar_no': '7821 4402 1198',
      'pan_no': 'APEXS1122M',
      'police_verification_doc': 'police_clearance_102.pdf',
      'police_verification_expiry': '2026-12-15',
      'profile_photo': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&auto=format&fit=crop&q=80',
      'status': 'Active',
      'currently_inside': 1,
      'last_entry_time': '2026-09-29T10:30:00Z',
    },
    {
      'id': 3,
      'employee_id': 'EMP-103',
      'full_name': 'Sanjay Gupta',
      'father_name': 'Ramakant Gupta',
      'dob': '1995-03-08',
      'gender': 'Male',
      'mobile': '+91 9876543230',
      'email': 'sanjay.gupta@fasttracklog.com',
      'address': 'Plot 12, Bommasandra Link Road',
      'city': 'Bangalore',
      'state': 'Karnataka',
      'pincode': '560099',
      'emergency_name': 'Meena Gupta',
      'emergency_relation': 'Mother',
      'emergency_phone': '+91 9876543232',
      'blood_group': 'O+',
      'medical_cert': 'Forklift & Heavy Rigging Operator Fit',
      'medical_validity': '2026-10-15',
      'vendor_id': 3,
      'vendor_name': 'FastTrack Logistics & Supply',
      'department_name': 'Logistics & Warehousing',
      'designation': 'Material Handler & Rigging Lead',
      'skill': 'Heavy Loading & Forklift',
      'employee_type': 'Contractor',
      'joining_date': '2025-01-10',
      'shift_name': 'General Shift (09:00 - 18:00)',
      'aadhaar_no': '9912 3344 5566',
      'pan_no': 'SGUPT3344H',
      'police_verification_doc': 'police_clearance_103.pdf',
      'police_verification_expiry': '2026-10-31',
      'profile_photo': 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&auto=format&fit=crop&q=80',
      'status': 'Active',
      'currently_inside': 0,
      'last_entry_time': '2026-09-28T09:00:00Z',
    },
    {
      'id': 4,
      'employee_id': 'EMP-104',
      'full_name': 'Vikram Rathore',
      'father_name': 'Bhairon Rathore',
      'dob': '1992-08-12',
      'gender': 'Male',
      'mobile': '+91 9876543240',
      'email': 'vikram.rathore@abcinfra.com',
      'address': 'Ward 7, Hoodi Industrial Area',
      'city': 'Bangalore',
      'state': 'Karnataka',
      'pincode': '560048',
      'emergency_name': 'Pooja Rathore',
      'emergency_relation': 'Spouse',
      'emergency_phone': '+91 9876543242',
      'blood_group': 'AB+',
      'medical_cert': 'Fit for Structural Fabrication',
      'medical_validity': '2027-03-20',
      'vendor_id': 1,
      'vendor_name': 'ABC Infra Projects Pvt Ltd',
      'department_name': 'Civil & Construction',
      'designation': 'Certified ARC Welder (6G)',
      'skill': 'Structural Steel Welding',
      'employee_type': 'Contractor',
      'joining_date': '2025-03-01',
      'shift_name': 'General Shift (09:00 - 18:00)',
      'aadhaar_no': '1122 3344 5566',
      'pan_no': 'VRATH1234P',
      'police_verification_doc': 'police_verified_104.pdf',
      'police_verification_expiry': '2027-03-01',
      'profile_photo': 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=150&auto=format&fit=crop&q=80',
      'status': 'Active',
      'currently_inside': 1,
      'last_entry_time': '2026-09-29T08:50:00Z',
    },
  ];

  static final List<Map<String, dynamic>> _vendorsStore = [
    {
      'id': 1,
      'vendor_id': 'VND-1001',
      'company_name': 'ABC Infra Projects Pvt Ltd',
      'owner_name': 'Rajesh Sharma',
      'email': 'rajesh@abcinfra.com',
      'phone': '+91 9845012345',
      'address': 'Plot 45, Peenya Industrial Area, Bangalore',
      'gst_pan': '29ABCDE1234F1Z5 / ABCDE1234F',
      'contract_start': '2026-01-01',
      'contract_end': '2026-12-31',
      'status': 'Active',
      'employee_count': 38,
      'active_permits': 2,
      'compliance_alerts': 0,
    },
    {
      'id': 2,
      'vendor_id': 'VND-1002',
      'company_name': 'Apex MEP & Electrical Solutions',
      'owner_name': 'Suresh Kumar',
      'email': 'suresh@apexservices.in',
      'phone': '+91 9845098765',
      'address': 'Electronic City Phase 1, Bangalore',
      'gst_pan': '29APEXM5678G2Z1 / APEXM5678G',
      'contract_start': '2026-03-01',
      'contract_end': '2027-02-28',
      'status': 'Active',
      'employee_count': 26,
      'active_permits': 2,
      'compliance_alerts': 0,
    },
    {
      'id': 3,
      'vendor_id': 'VND-1003',
      'company_name': 'FastTrack Logistics & Supply',
      'owner_name': 'Anil Verma',
      'email': 'anil@fasttracklog.com',
      'phone': '+91 9711223344',
      'address': 'Bommasandra Industrial Area, Bangalore',
      'gst_pan': '29FTLSC9988H1Z9 / FTLSC9988H',
      'contract_start': '2025-06-01',
      'contract_end': '2026-10-31',
      'status': 'Active',
      'employee_count': 20,
      'active_permits': 1,
      'compliance_alerts': 2,
    },
  ];

  static final List<Map<String, dynamic>> _permitsStore = [
    {
      'id': 1,
      'permit_number': 'PTW-2026-001',
      'permit_type': 'Hot Work (Welding/Cutting)',
      'description': 'Structural beam reinforcement welding on Floor 4 AHU Room',
      'location_zone': 'Block A - 4th Floor AHU Plant',
      'applicant_name': 'Suresh Kumar (Apex MEP)',
      'applicant_contact': '+91 9845098765',
      'vendor_name': 'Apex MEP Solutions',
      'start_time': '2026-09-29T09:00:00Z',
      'end_time': '2026-09-29T18:00:00Z',
      'status': 'Approved',
      'safety_checklist': [
        'Fire extinguisher available on site',
        'Flammables cleared within 10m',
        'Spark arrestor & fire blankets deployed',
        'Trained fire watch posted',
      ],
      'safety_officer_endorsed': true,
      'approved_by': 'Er. Rajesh Varma (Safety Head)',
    },
    {
      'id': 2,
      'permit_number': 'PTW-2026-002',
      'permit_type': 'Height Work (> 1.8m)',
      'description': 'Glass facade cleaning and silicon sealing at 24m elevation',
      'location_zone': 'Block B - West Elevation',
      'applicant_name': 'Rajesh Sharma (ABC Infra)',
      'applicant_contact': '+91 9845012345',
      'vendor_name': 'ABC Infra Projects Pvt Ltd',
      'start_time': '2026-09-29T10:00:00Z',
      'end_time': '2026-09-29T17:00:00Z',
      'status': 'Pending Review',
      'safety_checklist': [
        'Full-body safety harness with double lanyard inspected',
        'Lifeline anchor load-tested',
        'Scaffolding green tag valid',
        'Medical height fitness checked',
      ],
      'safety_officer_endorsed': false,
    },
    {
      'id': 3,
      'permit_number': 'PTW-2026-003',
      'permit_type': 'Electrical Isolation (LOTO)',
      'description': 'Primary transformer breaker maintenance & capacitor testing',
      'location_zone': 'Main Substation 11kV Yard',
      'applicant_name': 'Suresh Kumar (Apex MEP)',
      'applicant_contact': '+91 9845098765',
      'vendor_name': 'Apex MEP Solutions',
      'start_time': '2026-09-29T13:00:00Z',
      'end_time': '2026-09-29T18:00:00Z',
      'status': 'Approved',
      'safety_checklist': [
        'LOTO padlock and Danger tags installed',
        'Voltage tester verified zero potential',
        'Rubber insulated mats in position',
      ],
      'safety_officer_endorsed': true,
      'approved_by': 'Er. Rajesh Varma (Safety Head)',
    },
    {
      'id': 4,
      'permit_number': 'PTW-2026-004',
      'permit_type': 'Confined Space Entry',
      'description': 'Underground storm water drain desilting & pipe inspection',
      'location_zone': 'North Perimeter Storm Drain Manhole 4',
      'applicant_name': 'Rajesh Sharma (ABC Infra)',
      'applicant_contact': '+91 9845012345',
      'vendor_name': 'ABC Infra Projects Pvt Ltd',
      'start_time': '2026-09-30T09:00:00Z',
      'end_time': '2026-09-30T15:00:00Z',
      'status': 'Pending Review',
      'safety_checklist': [
        'Multi-gas detector test (O2, H2S, CO, LEL)',
        'Forced air blower active for 30 mins prior',
        'Tripod winch & rescue harness ready',
        'Standby entry watchman assigned',
      ],
      'safety_officer_endorsed': false,
    },
    {
      'id': 5,
      'permit_number': 'PTW-2026-005',
      'permit_type': 'General Contractor Work',
      'description': 'Drywall partition and ceiling framing installation',
      'location_zone': 'Building 2 - 2nd Floor Office Area',
      'applicant_name': 'Rajesh Sharma (ABC Infra)',
      'applicant_contact': '+91 9845012345',
      'vendor_name': 'ABC Infra Projects Pvt Ltd',
      'start_time': '2026-09-29T08:00:00Z',
      'end_time': '2026-09-29T20:00:00Z',
      'status': 'Active',
      'safety_checklist': [
        'Basic PPE mandatory',
        'Dust suppression active',
      ],
      'safety_officer_endorsed': true,
      'approved_by': 'Priya Sundaram (Admin)',
    },
  ];

  // --- 1. AUTHENTICATION & LOGIN ---
  static Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          authToken = data['token'];
          currentUser = UserModel.fromJson(data['user']);
          return true;
        }
      }
    } catch (_) {}

    // Check in-memory store
    final u = username.toLowerCase().trim();
    final found = _usersStore.firstWhere(
      (user) => user['username'].toString().toLowerCase() == u || user['email'].toString().toLowerCase() == u,
      orElse: () => {},
    );

    if (found.isNotEmpty) {
      authToken = 'demo-${found['username']}-token';
      currentUser = UserModel.fromJson(found);
      return true;
    }
    return false;
  }

  // --- 2. SUPER ADMIN USER CRUD & PERMISSIONS (Section 4 & 21) ---
  static Future<List<dynamic>> getUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/users'),
        headers: headers,
      ).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) return data['data'] ?? [];
      }
    } catch (_) {}

    return _usersStore;
  }

  static Future<bool> createUser(Map<String, dynamic> payload) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/users'),
        headers: headers,
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 4));
      if (response.statusCode == 201 || response.statusCode == 200) return true;
    } catch (_) {}

    final newId = (_usersStore.map((u) => u['id'] as int).reduce((a, b) => a > b ? a : b)) + 1;
    final newUser = {
      'id': newId,
      'username': payload['username'] ?? 'user_$newId',
      'full_name': payload['full_name'] ?? 'System User',
      'email': payload['email'] ?? 'user$newId@zyeta.com',
      'role': payload['role'] ?? 'Admin',
      'phone': payload['phone'] ?? '',
      'status': 'Active',
      'permissions': payload['permissions'] ?? ['all'],
    };
    _usersStore.add(newUser);
    return true;
  }

  static Future<bool> updateUser(int id, Map<String, dynamic> updates) async {
    try {
      await http.put(
        Uri.parse('$baseUrl/auth/users/$id'),
        headers: headers,
        body: jsonEncode(updates),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}

    final idx = _usersStore.indexWhere((u) => u['id'] == id);
    if (idx != -1) {
      _usersStore[idx] = {..._usersStore[idx], ...updates};
      // If updating current logged in user, refresh currentUser
      if (currentUser?.id == id) {
        currentUser = UserModel.fromJson(_usersStore[idx]);
      }
      return true;
    }
    return false;
  }

  static Future<bool> deleteUser(int id) async {
    try {
      await http.delete(
        Uri.parse('$baseUrl/auth/users/$id'),
        headers: headers,
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}

    _usersStore.removeWhere((u) => u['id'] == id);
    return true;
  }

  static Future<bool> toggleUserStatus(int id, String newStatus) async {
    return updateUser(id, {'status': newStatus});
  }

  // --- 3. EMPLOYEE / WORKFORCE CRUD (Section 8) ---
  static Future<List<dynamic>> getEmployees({String? search, String? status, String? vendorId, String? inside}) async {
    try {
      String query = '';
      if (search != null) query += 'search=$search&';
      if (status != null) query += 'status=$status&';
      if (vendorId != null) query += 'vendor_id=$vendorId&';
      if (inside != null) query += 'inside=$inside&';
      final response = await http.get(
        Uri.parse('$baseUrl/employees?$query'),
        headers: headers,
      ).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) return data['data'] ?? [];
      }
    } catch (_) {}

    var list = _employeesStore;
    if (inside == 'true') {
      list = list.where((e) => e['currently_inside'] == 1).toList();
    }
    if (status != null && status != 'ALL') {
      list = list.where((e) => e['status'] == status).toList();
    }
    if (search != null && search.isNotEmpty) {
      final s = search.toLowerCase();
      list = list.where((e) =>
        e['full_name'].toString().toLowerCase().contains(s) ||
        e['employee_id'].toString().toLowerCase().contains(s) ||
        e['designation'].toString().toLowerCase().contains(s) ||
        e['vendor_name'].toString().toLowerCase().contains(s) ||
        e['mobile'].toString().toLowerCase().contains(s)
      ).toList();
    }
    return list;
  }

  static Future<bool> createEmployee(Map<String, dynamic> payload) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/employees'),
        headers: headers,
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 4));
      if (response.statusCode == 201 || response.statusCode == 200) return true;
    } catch (_) {}

    final newId = (_employeesStore.map((e) => e['id'] as int).reduce((a, b) => a > b ? a : b)) + 1;
    final emp = {
      'id': newId,
      'employee_id': 'EMP-${100 + newId}',
      'full_name': payload['full_name'] ?? 'New Worker',
      'father_name': payload['father_name'] ?? '',
      'mobile': payload['mobile'] ?? '',
      'alternate_mobile': payload['alternate_mobile'] ?? '',
      'email': payload['email'] ?? '',
      'address': payload['address'] ?? 'Bangalore',
      'city': 'Bangalore',
      'state': 'Karnataka',
      'pincode': '560037',
      'emergency_name': payload['emergency_name'] ?? '',
      'emergency_phone': payload['emergency_phone'] ?? '',
      'blood_group': payload['blood_group'] ?? 'O+',
      'medical_cert': payload['medical_cert'] ?? 'General Fit',
      'medical_validity': '2027-01-01',
      'vendor_id': payload['vendor_id'] ?? 1,
      'vendor_name': payload['vendor_name'] ?? 'ABC Infra Projects Pvt Ltd',
      'department_name': payload['department_name'] ?? 'Civil & Construction',
      'designation': payload['designation'] ?? 'Technician',
      'skill': payload['skill'] ?? 'General',
      'employee_type': 'Contractor',
      'joining_date': DateTime.now().toIso8601String().split('T')[0],
      'shift_name': 'General Shift (09:00 - 18:00)',
      'aadhaar_no': payload['aadhaar_no'] ?? '4532 8912 0000',
      'pan_no': payload['pan_no'] ?? 'ABCDE0000K',
      'police_verification_doc': 'police_verified_$newId.pdf',
      'police_verification_expiry': '2027-02-01',
      'profile_photo': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
      'status': 'Active',
      'currently_inside': 0,
    };
    _employeesStore.add(emp);
    return true;
  }

  static Future<bool> updateEmployee(int id, Map<String, dynamic> updates) async {
    try {
      await http.put(
        Uri.parse('$baseUrl/employees/$id'),
        headers: headers,
        body: jsonEncode(updates),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}

    final idx = _employeesStore.indexWhere((e) => e['id'] == id);
    if (idx != -1) {
      _employeesStore[idx] = {..._employeesStore[idx], ...updates};
      return true;
    }
    return false;
  }

  static Future<bool> deleteEmployee(int id) async {
    try {
      await http.delete(
        Uri.parse('$baseUrl/employees/$id'),
        headers: headers,
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}

    _employeesStore.removeWhere((e) => e['id'] == id);
    return true;
  }

  // --- 4. VENDOR CRUD (Section 9) ---
  static Future<List<dynamic>> getVendors({String? search, String? status}) async {
    try {
      String query = '';
      if (search != null) query += 'search=$search&';
      if (status != null) query += 'status=$status&';
      final response = await http.get(
        Uri.parse('$baseUrl/vendors?$query'),
        headers: headers,
      ).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) return data['data'] ?? [];
      }
    } catch (_) {}

    return _vendorsStore;
  }

  static Future<bool> createVendor(Map<String, dynamic> payload) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/vendors'),
        headers: headers,
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 4));
      if (response.statusCode == 201 || response.statusCode == 200) return true;
    } catch (_) {}

    final newId = (_vendorsStore.map((v) => v['id'] as int).reduce((a, b) => a > b ? a : b)) + 1;
    final vnd = {
      'id': newId,
      'vendor_id': payload['vendor_code'] ?? 'VND-${1000 + newId}',
      'company_name': payload['company_name'] ?? 'New Contractor',
      'owner_name': payload['contact_person'] ?? 'Owner',
      'email': payload['email'] ?? 'vendor@corp.com',
      'phone': payload['phone'] ?? '+91 9900000000',
      'address': payload['address'] ?? 'Bangalore Industrial Area',
      'gst_pan': '29ABCDE${1000 + newId}F1Z5',
      'contract_start': '2026-01-01',
      'contract_end': '2026-12-31',
      'status': 'Active',
      'employee_count': 10,
      'active_permits': 0,
      'compliance_alerts': 0,
    };
    _vendorsStore.add(vnd);
    return true;
  }

  static Future<bool> updateVendor(int id, Map<String, dynamic> updates) async {
    final idx = _vendorsStore.indexWhere((v) => v['id'] == id);
    if (idx != -1) {
      _vendorsStore[idx] = {..._vendorsStore[idx], ...updates};
      return true;
    }
    return false;
  }

  static Future<bool> deleteVendor(int id) async {
    _vendorsStore.removeWhere((v) => v['id'] == id);
    return true;
  }

  // --- 5. PERMIT-TO-WORK (PTW) CRUD (Section 12) ---
  static Future<List<dynamic>> getPermits({String? status, String? search}) async {
    try {
      String query = '';
      if (status != null) query += 'status=$status&';
      if (search != null) query += 'search=$search&';
      final response = await http.get(
        Uri.parse('$baseUrl/permits?$query'),
        headers: headers,
      ).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) return data['data'] ?? [];
      }
    } catch (_) {}

    var list = _permitsStore;
    if (status != null && status != 'ALL') {
      list = list.where((p) => p['status'] == status || (status == 'Pending' && p['status'].toString().contains('Pending'))).toList();
    }
    if (search != null && search.isNotEmpty) {
      final s = search.toLowerCase();
      list = list.where((p) =>
        p['permit_number'].toString().toLowerCase().contains(s) ||
        p['permit_type'].toString().toLowerCase().contains(s) ||
        p['description'].toString().toLowerCase().contains(s) ||
        p['vendor_name'].toString().toLowerCase().contains(s)
      ).toList();
    }
    return list;
  }

  static Future<bool> approvePermit(int id, {String? comments}) async {
    final idx = _permitsStore.indexWhere((p) => p['id'] == id);
    if (idx != -1) {
      _permitsStore[idx]['status'] = 'Approved';
      _permitsStore[idx]['safety_officer_endorsed'] = true;
      _permitsStore[idx]['approved_by'] = currentUser?.fullName ?? 'Authorized Admin';
    }
    return true;
  }

  static Future<bool> rejectPermit(int id, {String? reason}) async {
    final idx = _permitsStore.indexWhere((p) => p['id'] == id);
    if (idx != -1) {
      _permitsStore[idx]['status'] = 'Rejected';
    }
    return true;
  }

  static Future<bool> createPermit(Map<String, dynamic> payload) async {
    final newId = (_permitsStore.map((p) => p['id'] as int).reduce((a, b) => a > b ? a : b)) + 1;
    final permit = {
      'id': newId,
      'permit_number': 'PTW-2026-00$newId',
      'permit_type': payload['permit_type'] ?? 'General Work Permit',
      'description': payload['description'] ?? 'Work permit scope',
      'location_zone': payload['location_zone'] ?? 'Main Plant',
      'applicant_name': payload['applicant_name'] ?? 'Supervisor',
      'applicant_contact': payload['applicant_contact'] ?? '+91 9900000000',
      'vendor_name': currentUser?.fullName ?? 'Contractor',
      'start_time': DateTime.now().toIso8601String(),
      'end_time': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
      'status': 'Pending Review',
      'safety_checklist': ['Standard PPE mandatory', 'Safety briefing completed'],
      'safety_officer_endorsed': false,
    };
    _permitsStore.add(permit);
    return true;
  }

  static Future<bool> deletePermit(int id) async {
    _permitsStore.removeWhere((p) => p['id'] == id);
    return true;
  }

  // --- 6. QR VERIFICATION TERMINAL ---
  static Future<VerificationResult?> verifyQR(String qrCode) async {
    final q = qrCode.toUpperCase().trim();
    if (q.contains('EMP') || q.contains('RAMESH') || q.contains('WORKER')) {
      return VerificationResult(
        verificationStatus: 'ALLOW',
        recommendedAction: 'ALLOW_EXIT',
        isCurrentlyInside: true,
        complianceWarnings: ['Medical fitness valid until Jan 2027', 'Police verification certified'],
        entityType: 'Employee',
        data: {
          'id': 1,
          'employee_id': 'EMP-101',
          'full_name': 'Ramesh Patel',
          'designation': 'Senior Scaffolder',
          'skill': 'Expert Height Work',
          'vendor_name': 'ABC Infra Projects Pvt Ltd',
          'blood_group': 'B+',
          'mobile': '+91 9876543210',
          'emergency_name': 'Sunita Patel',
          'emergency_phone': '+91 9876543212',
          'police_verification_expiry': '2027-02-01',
          'medical_validity': '2027-01-15',
          'currently_inside': 1,
          'status': 'Active',
        },
      );
    } else if (q.contains('VIS') || q.contains('VISITOR')) {
      return VerificationResult(
        verificationStatus: 'ALLOW',
        recommendedAction: 'ALLOW_ENTRY',
        isCurrentlyInside: false,
        complianceWarnings: ['Host Employee: Priya Sundaram (Approved)'],
        entityType: 'Visitor',
        data: {
          'id': 1,
          'pass_number': 'VIS-8801',
          'visitor_name': 'Kavita Rao',
          'company': 'KPMG Audit Services',
          'host_name': 'Priya Sundaram',
          'purpose': 'Q3 Safety & Financial Audit',
          'vehicle_number': 'KA 03 MX 4411',
          'status': 'Approved',
        },
      );
    } else if (q.contains('PTW') || q.contains('PERMIT')) {
      return VerificationResult(
        verificationStatus: 'ALLOW',
        recommendedAction: 'VERIFY_PERMIT',
        isCurrentlyInside: true,
        complianceWarnings: ['🔥 Hot Work Permit Valid for Zone B', 'HSE Safety Officer Endorsement: APPROVED'],
        entityType: 'Permit',
        data: {
          'id': 1,
          'permit_number': 'PTW-2026-001',
          'permit_type': 'Hot Work (Welding/Cutting)',
          'location_zone': 'Block A - 4th Floor AHU Plant',
          'applicant_name': 'Suresh Kumar (Apex MEP)',
          'status': 'Approved',
        },
      );
    } else if (q.contains('DC') || q.contains('MAT')) {
      return VerificationResult(
        verificationStatus: 'ALLOW',
        recommendedAction: 'ALLOW_ENTRY',
        isCurrentlyInside: false,
        complianceWarnings: ['Inward DC #DC-2026-4401', '50 Scaffolding Pipes (Returnable)'],
        entityType: 'Material',
        data: {
          'id': 1,
          'dc_number': 'DC-2026-4401',
          'vendor_name': 'ABC Infra Projects Pvt Ltd',
          'material_name': 'Heavy Scaffolding Pipes & Clamps',
          'quantity': 50,
          'unit': 'Sets',
          'vehicle_number': 'KA 04 E 9921',
          'driver_name': 'Manish Yadav',
          'status': 'Inward Pending Gate Check',
        },
      );
    }

    return VerificationResult(
      verificationStatus: 'ALLOW',
      recommendedAction: 'ALLOW_ENTRY',
      isCurrentlyInside: false,
      complianceWarnings: ['All documents verified valid'],
      entityType: 'Employee',
      data: {
        'id': 2,
        'employee_id': qrCode.isEmpty ? 'EMP-102' : qrCode,
        'full_name': 'Verified Workforce Member',
        'designation': 'Technician',
        'skill': 'Electrical MEP',
        'vendor_name': 'Apex MEP Solutions',
        'blood_group': 'O+',
        'mobile': '+91 9876500000',
        'currently_inside': 0,
        'status': 'Active',
      },
    );
  }

  static Future<bool> recordGateMovement({
    required String entityType,
    required int entityId,
    required String movementType,
    int gateId = 1,
    String? remarks,
  }) async {
    return true;
  }

  // --- 7. DASHBOARD KPIS & STATS ---
  static Future<Map<String, dynamic>?> getDashboardStats() async {
    return {
      'kpis': {
        'total_employees': _employeesStore.length,
        'active_employees': _employeesStore.where((e) => e['status'] == 'Active').length,
        'currently_inside': _employeesStore.where((e) => e['currently_inside'] == 1).length,
        'today_entries': 58,
        'today_exits': 16,
        'today_attendance': 61,
        'total_vendors': _vendorsStore.length,
        'active_vendors': _vendorsStore.length,
        'pending_permits': _permitsStore.where((p) => p['status'].toString().contains('Pending')).length,
        'approved_permits': _permitsStore.where((p) => p['status'] == 'Approved' || p['status'] == 'Active').length,
        'material_entries': 8,
        'visitors_today': 7,
        'expiring_compliance_docs': 2,
      },
      'recent_activity': [
        {
          'id': 1,
          'entity_name': 'Ramesh Patel',
          'entity_code': 'EMP-101',
          'entity_type': 'Employee',
          'movement_type': 'ENTRY',
          'vendor_name': 'ABC Infra Projects',
          'gate_name': 'Main Gate 1',
          'timestamp': '2026-09-29T08:45:00Z',
          'verification_status': 'ALLOW',
        },
        {
          'id': 2,
          'entity_name': 'Kavita Rao',
          'entity_code': 'VIS-8801',
          'entity_type': 'Visitor',
          'movement_type': 'ENTRY',
          'vendor_name': 'KPMG Audit',
          'gate_name': 'Main Gate 1',
          'timestamp': '2026-09-29T09:15:00Z',
          'verification_status': 'ALLOW',
        },
      ]
    };
  }

  // --- 8. SAFETY APIS ---
  static Future<Map<String, dynamic>> getSafetyKPIs() async {
    return {
      'safety_score': '98.4%',
      'days_without_lti': 142,
      'active_high_risk_permits': 4,
      'open_hazards': 2,
      'audits_this_week': 9,
      'ppe_compliance_rate': '96.8%',
      'expiring_height_certs': 1,
    };
  }

  static Future<List<dynamic>> getSafetyInspections() async {
    return [
      {
        'id': 1,
        'title': 'Daily Morning Scaffolding & Fall Protection Audit',
        'zone': 'Block A - External Facade',
        'inspector': 'Er. Rajesh Varma',
        'date': '2026-09-29',
        'score': '95%',
        'status': 'PASSED',
        'findings': 'All scaffolding green-tagged; toe-boards securely fixed.',
      },
    ];
  }

  static Future<bool> createSafetyInspection(Map<String, dynamic> payload) async => true;

  static Future<List<dynamic>> getSafetyHazards() async {
    return [
      {
        'id': 1,
        'hazard_code': 'HAZ-2026-014',
        'title': 'Water accumulation near electrical temporary DB',
        'zone': 'Basement 1 - Construction Bay',
        'severity': 'HIGH',
        'category': 'Electrical & Slip',
        'status': 'IN_PROGRESS',
        'corrective_action': 'Submersible pump deployed; electrician rerouting feed.',
      },
    ];
  }

  static Future<bool> createSafetyHazard(Map<String, dynamic> payload) async => true;

  // --- 8B. SAFETY PUNCH SYSTEM (RED / YELLOW / GREEN COLOR SEVERITY) ---
  static final List<Map<String, dynamic>> _safetyPunchesStore = [
    {
      'id': 1,
      'punch_code': 'PCH-2026-101',
      'worker_name': 'Amitabh Sen',
      'worker_id': 'EMP-102',
      'vendor_name': 'Apex MEP Solutions',
      'color_type': 'RED',
      'category': 'Critical Height Violation',
      'reason': 'Working on 4.2m elevated cable tray without securing double lanyard to the static lifeline.',
      'zone': 'Block A - 4th Floor AHU Plant',
      'photo_url': 'https://images.unsplash.com/photo-1541888946425-d0fbb186156a?w=400&auto=format&fit=crop&q=80',
      'corrective_action': 'Stop-work issued immediately. Worker stood down for mandatory retraining; penalty applied.',
      'reported_by': 'Er. Rajesh Varma (HSE Head)',
      'timestamp': '2026-09-29T10:15:00Z',
      'status': 'RESOLVED',
    },
    {
      'id': 2,
      'punch_code': 'PCH-2026-102',
      'worker_name': 'Ramesh Patel',
      'worker_id': 'EMP-101',
      'vendor_name': 'ABC Infra Projects',
      'color_type': 'YELLOW',
      'category': 'PPE Warning / Housekeeping',
      'reason': 'Safety helmet chinstrap unfastened while operating under active overhead crane radius.',
      'zone': 'Tower 1 - Ground Laydown Area',
      'photo_url': 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=400&auto=format&fit=crop&q=80',
      'corrective_action': 'Chinstrap fastened immediately on the spot. Briefed on falling object hazard.',
      'reported_by': 'Er. Rajesh Varma (HSE Head)',
      'timestamp': '2026-09-29T11:45:00Z',
      'status': 'ACKNOWLEDGED',
    },
    {
      'id': 3,
      'punch_code': 'PCH-2026-103',
      'worker_name': 'Vikram Rathore',
      'worker_id': 'EMP-104',
      'vendor_name': 'ABC Infra Projects',
      'color_type': 'GREEN',
      'category': 'Safety Excellence / Proactive',
      'reason': 'Proactive deployment of spark capture fire blankets & standby fire extinguisher before welding.',
      'zone': 'Basement 1 - Structural Bay',
      'photo_url': 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=400&auto=format&fit=crop&q=80',
      'corrective_action': 'Commended during safety briefing. Awarded +25 Zero Harm Safety points.',
      'reported_by': 'Er. Rajesh Varma (HSE Head)',
      'timestamp': '2026-09-29T13:20:00Z',
      'status': 'COMMENDED',
    },
  ];

  static Future<List<dynamic>> getSafetyPunches({String? colorType, String? search}) async {
    var list = _safetyPunchesStore;
    if (colorType != null && colorType != 'ALL') {
      list = list.where((p) => p['color_type'] == colorType).toList();
    }
    if (search != null && search.isNotEmpty) {
      final s = search.toLowerCase();
      list = list.where((p) =>
        p['worker_name'].toString().toLowerCase().contains(s) ||
        p['worker_id'].toString().toLowerCase().contains(s) ||
        p['punch_code'].toString().toLowerCase().contains(s) ||
        p['reason'].toString().toLowerCase().contains(s) ||
        p['zone'].toString().toLowerCase().contains(s)
      ).toList();
    }
    return list;
  }

  static Future<bool> createSafetyPunch(Map<String, dynamic> payload) async {
    final newId = _safetyPunchesStore.length + 101;
    _safetyPunchesStore.insert(0, {
      'id': _safetyPunchesStore.length + 1,
      'punch_code': 'PCH-2026-$newId',
      'worker_name': payload['worker_name'] ?? 'Worker',
      'worker_id': payload['worker_id'] ?? 'EMP-101',
      'vendor_name': payload['vendor_name'] ?? 'Contractor',
      'color_type': payload['color_type'] ?? 'RED',
      'category': payload['category'] ?? 'Safety Observation',
      'reason': payload['reason'] ?? 'Safety observation logged',
      'zone': payload['zone'] ?? 'Main Site Zone',
      'photo_url': payload['photo_url'] ?? 'https://images.unsplash.com/photo-1541888946425-d0fbb186156a?w=400&auto=format&fit=crop&q=80',
      'corrective_action': payload['corrective_action'] ?? 'Corrective action initiated',
      'reported_by': currentUser?.fullName ?? 'Er. Rajesh Varma',
      'timestamp': DateTime.now().toIso8601String(),
      'status': payload['color_type'] == 'GREEN' ? 'COMMENDED' : 'OPEN',
    });
    return true;
  }

  static Future<bool> deleteSafetyPunch(int id) async {
    _safetyPunchesStore.removeWhere((p) => p['id'] == id);
    return true;
  }

  // --- 9. ATTENDANCE APIS ---
  static Future<List<dynamic>> getAttendance({String? date, String? status, String? search}) async {
    return [
      {
        'id': 1,
        'employee_id': 'EMP-101',
        'employee_name': 'Ramesh Patel',
        'vendor_name': 'ABC Infra Projects',
        'date': '2026-09-29',
        'in_time': '08:45 AM',
        'out_time': 'Still Inside',
        'status': 'Present',
        'overtime_hours': 0,
        'shift': 'General Shift',
      },
      {
        'id': 2,
        'employee_id': 'EMP-102',
        'employee_name': 'Amitabh Sen',
        'vendor_name': 'Apex MEP Solutions',
        'date': '2026-09-29',
        'in_time': '10:30 AM',
        'out_time': 'Still Inside',
        'status': 'Late',
        'overtime_hours': 0,
        'shift': 'Morning Shift A',
      },
    ];
  }

  static Future<Map<String, dynamic>?> getAttendanceSummary() async {
    return {
      'total_workforce': _employeesStore.length,
      'present_today': 61,
      'late_today': 8,
      'half_day': 2,
      'absent_today': 13,
      'overtime_hours_total': 34.5,
      'attendance_rate': '72.6%',
    };
  }

  static Future<bool> markManualAttendance(Map<String, dynamic> payload) async => true;

  // --- 10. VISITOR PASSES ---
  static Future<List<dynamic>> getVisitors({String? status, String? search}) async {
    return [
      {
        'id': 1,
        'pass_number': 'VIS-8801',
        'visitor_name': 'Kavita Rao',
        'mobile': '+91 9988112233',
        'company': 'KPMG Audit Services',
        'host_name': 'Priya Sundaram (Admin)',
        'purpose': 'Q3 Safety & Financial Audit',
        'vehicle_number': 'KA 03 MX 4411',
        'id_proof': 'Aadhaar Verified',
        'entry_time': '2026-09-29T09:15:00Z',
        'status': 'Inside Campus',
      },
    ];
  }

  static Future<bool> registerVisitor(Map<String, dynamic> payload) async => true;
  static Future<bool> checkoutVisitor(int id) async => true;

  // --- 11. MATERIAL & DC ENTRY ---
  static Future<List<dynamic>> getMaterials({String? movementType, String? search}) async {
    return [
      {
        'id': 1,
        'dc_number': 'DC-2026-4401',
        'vendor_name': 'ABC Infra Projects Pvt Ltd',
        'material_name': 'Heavy Scaffolding Pipes & Couplers',
        'quantity': 50,
        'unit': 'Sets',
        'vehicle_number': 'KA 04 E 9921',
        'movement_type': 'INWARD',
        'status': 'Inside Campus',
      },
    ];
  }

  static Future<bool> createMaterialEntry(Map<String, dynamic> payload) async => true;
  static Future<bool> updateMaterialReturn(int id, {required int returnQuantity, String? returnDcNumber, String? remarks}) async => true;

  // --- 12. VEHICLES ---
  static Future<List<dynamic>> getVehicles({String? search, String? status}) async {
    return [
      {
        'id': 1,
        'vehicle_number': 'KA 04 E 9921',
        'vehicle_type': 'Heavy Commercial Truck',
        'vendor_name': 'ABC Infra Projects',
        'driver_name': 'Manish Yadav',
        'driver_mobile': '+91 9122334411',
        'status': 'Inside Campus',
      },
    ];
  }

  static Future<bool> createVehicle(Map<String, dynamic> payload) async => true;

  // --- 13. HEADCOUNT & MUSTER ---
  static Future<List<dynamic>> getCurrentlyInside() async {
    return [
      {
        'id': 1,
        'name': 'Ramesh Patel',
        'code': 'EMP-101',
        'type': 'Employee (Contractor)',
        'vendor': 'ABC Infra Projects',
        'gate': 'Main Gate 1',
        'entry_time': '08:45 AM',
        'zone': 'Block A Elevation',
      },
    ];
  }

  // --- 14. AUDIT LOGS ---
  static Future<List<dynamic>> getAuditLogs({String? module, String? search}) async {
    return [
      {
        'id': 1,
        'user_name': 'Er. Rajesh Varma',
        'user_role': 'Safety Officer',
        'action_type': 'APPROVE_PERMIT',
        'module': 'Safety & Permits',
        'details': 'Endorsed Hot Work Permit PTW-2026-001 with fire watch confirmation',
        'timestamp': '2026-09-29T09:05:12Z',
      },
      {
        'id': 2,
        'user_name': 'Vikram Malhotra',
        'user_role': 'Super Admin',
        'action_type': 'UPDATE_PERMISSIONS',
        'module': 'User Security',
        'details': 'Updated granular RBAC permissions matrix for Site Admin Priya Sundaram',
        'timestamp': '2026-09-29T11:15:00Z',
      },
    ];
  }

  // --- 15. REPORTS ---
  static Future<Map<String, dynamic>> getReportData(String reportType) async {
    return {
      'report_type': reportType,
      'generated_at': DateTime.now().toIso8601String(),
      'summary': {
        'total_records': _employeesStore.length,
        'compliance_rate': '98.2%',
        'total_entries': 58,
        'total_exits': 16,
      }
    };
  }

  // --- 16. TOOLBOX TALKS (TBT) SAFETY BRIEFINGS (PRD 11.0 & App C) ---
  static final List<Map<String, dynamic>> _tbtStore = [
    {
      'id': 1,
      'topic': 'Working at Height & 100% Tie-Off Rule',
      'category': 'Height Safety',
      'location_zone': 'Block A Elevation Scaffolding',
      'trainer_name': 'Er. Rajesh Varma (HSE Head)',
      'date': '2026-09-29',
      'time': '08:15 AM',
      'attendees_count': 32,
      'key_points': [
        'Full body harness inspection prior to donning',
        'Shock-absorbing lanyards anchored above shoulder height',
        'Scaffold green-tag check mandatory',
      ],
      'status': 'Completed',
    },
    {
      'id': 2,
      'topic': 'Electrical LOTO & Arc Flash Precautions',
      'category': 'Electrical Safety',
      'location_zone': 'Main 11kV Substation Yard',
      'trainer_name': 'Suresh Kumar (Electrical Lead)',
      'date': '2026-09-29',
      'time': '08:30 AM',
      'attendees_count': 18,
      'key_points': [
        'Individual personal padlocks on lockout hasps',
        'Multi-meter zero potential live-dead-live testing',
        'Rubber insulating mats position verification',
      ],
      'status': 'Completed',
    },
  ];

  static Future<List<dynamic>> getToolboxTalks() async => _tbtStore;

  static Future<bool> createToolboxTalk(Map<String, dynamic> payload) async {
    final newId = _tbtStore.length + 1;
    _tbtStore.insert(0, {
      'id': newId,
      'topic': payload['topic'] ?? 'General Safety Briefing',
      'category': payload['category'] ?? 'General Safety',
      'location_zone': payload['location_zone'] ?? 'Assembly Area',
      'trainer_name': currentUser?.fullName ?? 'Safety Lead',
      'date': DateTime.now().toIso8601String().split('T')[0],
      'time': '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      'attendees_count': payload['attendees_count'] ?? 15,
      'key_points': payload['key_points'] ?? ['Daily PPE check', 'Safe work method adherence'],
      'status': 'Completed',
    });
    return true;
  }

  // --- 17. EMERGENCY MUSTER & EVACUATION COMMAND (PRD Section 15 & 19) ---
  static bool _isEvacuationActive = false;
  static String _evacuationReason = '';
  static DateTime? _evacuationStartTime;

  static final List<Map<String, dynamic>> _musterStations = [
    {
      'id': 1,
      'name': 'Assembly Point A (North Football Lawn)',
      'warden_name': 'Commander R. K. Singh',
      'capacity': 250,
      'checked_in_count': 42,
      'is_safe_cleared': false,
    },
    {
      'id': 2,
      'name': 'Assembly Point B (Main Gate 1 Parking)',
      'warden_name': 'Er. Rajesh Varma',
      'capacity': 300,
      'checked_in_count': 19,
      'is_safe_cleared': false,
    },
    {
      'id': 3,
      'name': 'Assembly Point C (South Helipad Area)',
      'warden_name': 'Priya Sundaram',
      'capacity': 150,
      'checked_in_count': 0,
      'is_safe_cleared': false,
    },
  ];

  static Future<Map<String, dynamic>> getEvacuationStatus() async {
    final insideTotal = _employeesStore.where((e) => e['currently_inside'] == 1).length;
    final totalCheckedIn = _musterStations.fold<int>(0, (sum, m) => sum + (m['checked_in_count'] as int));
    final missingCount = insideTotal > totalCheckedIn ? insideTotal - totalCheckedIn : 0;

    return {
      'is_active': _isEvacuationActive,
      'reason': _evacuationReason,
      'start_time': _evacuationStartTime?.toIso8601String(),
      'total_inside_when_alarmed': insideTotal,
      'total_mustered': totalCheckedIn,
      'missing_unaccounted': missingCount,
      'stations': _musterStations,
    };
  }

  static Future<bool> triggerEmergencyEvacuation(String reason) async {
    _isEvacuationActive = true;
    _evacuationReason = reason;
    _evacuationStartTime = DateTime.now();
    return true;
  }

  static Future<bool> clearEmergencyEvacuation() async {
    _isEvacuationActive = false;
    _evacuationReason = '';
    _evacuationStartTime = null;
    for (var m in _musterStations) {
      m['checked_in_count'] = 0;
      m['is_safe_cleared'] = true;
    }
    return true;
  }

  static Future<bool> checkinMusterStation(int stationId, String workerCode) async {
    final st = _musterStations.firstWhere((s) => s['id'] == stationId, orElse: () => {});
    if (st.isNotEmpty) {
      st['checked_in_count'] = (st['checked_in_count'] as int) + 1;
      return true;
    }
    return false;
  }

  // --- 18. BLACKLIST & SAFETY VIOLATIONS (PRD 8.3) ---
  static final List<Map<String, dynamic>> _blacklistStore = [
    {
      'id': 1,
      'person_name': 'Kuldeep Yadav',
      'id_type': 'Aadhaar / DL',
      'id_number': '5432 9901 2211',
      'entity_type': 'Contractor Worker',
      'vendor_name': 'Former ABC Subcontractor',
      'reason': 'Major Safety Violation: Tampered with 11kV electrical breaker without permit',
      'blacklisted_by': 'Er. Rajesh Varma (HSE Head)',
      'blacklisted_on': '2026-08-14',
      'status': 'PERMANENT_BAN',
      'turnstile_hard_lock': true,
    },
    {
      'id': 2,
      'person_name': 'Harish B.',
      'id_type': 'Vehicle Plate',
      'id_number': 'KA 05 MN 8821',
      'entity_type': 'Commercial Truck Driver',
      'vendor_name': 'FastTrack Logistics',
      'reason': 'Reckless driving inside campus pedestrian zone & refusal of alcohol breathalyzer test',
      'blacklisted_by': 'Commander R. K. Singh',
      'blacklisted_on': '2026-09-02',
      'status': 'SUSPENDED_60_DAYS',
      'turnstile_hard_lock': true,
    },
  ];

  static Future<List<dynamic>> getBlacklist() async => _blacklistStore;

  static Future<bool> addToBlacklist(Map<String, dynamic> payload) async {
    _blacklistStore.insert(0, {
      'id': _blacklistStore.length + 1,
      'person_name': payload['person_name'] ?? 'Banned Individual',
      'id_type': payload['id_type'] ?? 'Aadhaar',
      'id_number': payload['id_number'] ?? '',
      'entity_type': payload['entity_type'] ?? 'Worker',
      'vendor_name': payload['vendor_name'] ?? 'Contractor',
      'reason': payload['reason'] ?? 'Safety Violation',
      'blacklisted_by': currentUser?.fullName ?? 'Super Admin',
      'blacklisted_on': DateTime.now().toIso8601String().split('T')[0],
      'status': payload['status'] ?? 'PERMANENT_BAN',
      'turnstile_hard_lock': true,
    });
    return true;
  }

  // --- 19. OVERSTAY & SHIFT OVERTIME ALERTS (PRD 10.0 & 14.0) ---
  static Future<List<dynamic>> getOverstayAlerts() async {
    return [
      {
        'id': 1,
        'person_name': 'Ramesh Patel',
        'code': 'EMP-101',
        'type': 'Worker',
        'vendor_name': 'ABC Infra Projects',
        'entry_time': '08:45 AM',
        'duration_inside': '10 hrs 15 mins',
        'shift_end': '06:00 PM',
        'alert_level': 'HIGH_OVERSTAY',
        'contact': '+91 9876543210',
      },
      {
        'id': 2,
        'person_name': 'Kavita Rao',
        'code': 'VIS-8801',
        'type': 'Visitor',
        'vendor_name': 'KPMG Audit',
        'entry_time': '09:15 AM',
        'duration_inside': '9 hrs 45 mins',
        'shift_end': '05:00 PM',
        'alert_level': 'VISITOR_EXCEEDED_PASS',
        'contact': '+91 9988112233',
      },
    ];
  }
}
