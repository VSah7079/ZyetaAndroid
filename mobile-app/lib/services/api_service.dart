import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiService {
  // Configured to host machine Wi-Fi IP for direct physical Android phone access
  static String baseUrl = 'http://10.87.221.201:5000/api';
  static String? authToken;
  static UserModel? currentUser;

  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

  static Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          authToken = data['token'];
          currentUser = UserModel.fromJson(data['user']);
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  static Future<VerificationResult?> verifyQR(String qrCode) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/gate/verify-qr'),
        headers: headers,
        body: jsonEncode({'qr_data': qrCode}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return VerificationResult.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      print('Verify QR error: $e');
      return null;
    }
  }

  static Future<bool> recordGateMovement({
    required String entityType,
    required int entityId,
    required String movementType,
    int gateId = 1,
    String? remarks,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/gate/movement'),
        headers: headers,
        body: jsonEncode({
          'entity_type': entityType,
          'entity_id': entityId,
          'movement_type': movementType,
          'gate_id': gateId,
          'verification_method': 'MOBILE_APP_SCAN',
          'remarks': remarks ?? 'Mobile Security App Verification',
        }),
      );

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('Record movement error: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getDashboardStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/stats'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      print('Get stats error: $e');
      return null;
    }
  }

  static Future<List<dynamic>> getCurrentlyInside() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/gate/inside'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'] ?? [];
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // --- VISITOR APIS ---
  static Future<List<dynamic>> getVisitors({String? status, String? search}) async {
    try {
      String query = '';
      if (status != null) query += 'status=$status&';
      if (search != null) query += 'search=$search&';
      final response = await http.get(
        Uri.parse('$baseUrl/visitors?$query'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print('getVisitors error: $e');
      return [];
    }
  }

  static Future<bool> registerVisitor(Map<String, dynamic> payload) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/visitors/register'),
        headers: headers,
        body: jsonEncode(payload),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('registerVisitor error: $e');
      return false;
    }
  }

  static Future<bool> checkoutVisitor(int id) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/visitors/$id/checkout'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      print('checkoutVisitor error: $e');
      return false;
    }
  }

  // --- MATERIAL DC APIS ---
  static Future<List<dynamic>> getMaterials({String? movementType, String? search}) async {
    try {
      String query = '';
      if (movementType != null) query += 'movement_type=$movementType&';
      if (search != null) query += 'search=$search&';
      final response = await http.get(
        Uri.parse('$baseUrl/materials?$query'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print('getMaterials error: $e');
      return [];
    }
  }

  static Future<bool> createMaterialEntry(Map<String, dynamic> payload) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/materials/entry'),
        headers: headers,
        body: jsonEncode(payload),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('createMaterialEntry error: $e');
      return false;
    }
  }

  static Future<bool> updateMaterialReturn(int id, {required int returnQuantity, String? returnDcNumber, String? remarks}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/materials/$id/return'),
        headers: headers,
        body: jsonEncode({
          'return_quantity': returnQuantity,
          'return_dc_number': returnDcNumber,
          'remarks': remarks,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('updateMaterialReturn error: $e');
      return false;
    }
  }

  // --- VEHICLE APIS ---
  static Future<List<dynamic>> getVehicles({String? search, String? status}) async {
    try {
      String query = '';
      if (status != null) query += 'status=$status&';
      if (search != null) query += 'search=$search&';
      final response = await http.get(
        Uri.parse('$baseUrl/vehicles?$query'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print('getVehicles error: $e');
      return [];
    }
  }

  static Future<bool> createVehicle(Map<String, dynamic> payload) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/vehicles'),
        headers: headers,
        body: jsonEncode(payload),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('createVehicle error: $e');
      return false;
    }
  }

  // --- PERMIT APIS ---
  static Future<List<dynamic>> getPermits({String? status, String? search}) async {
    try {
      String query = '';
      if (status != null) query += 'status=$status&';
      if (search != null) query += 'search=$search&';
      final response = await http.get(
        Uri.parse('$baseUrl/permits?$query'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print('getPermits error: $e');
      return [];
    }
  }

  static Future<bool> approvePermit(int id, {String? comments}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/permits/$id/approve'),
        headers: headers,
        body: jsonEncode({'comments': comments ?? 'Approved via Mobile'}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('approvePermit error: $e');
      return false;
    }
  }

  static Future<bool> rejectPermit(int id, {String? reason}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/permits/$id/reject'),
        headers: headers,
        body: jsonEncode({'rejection_reason': reason ?? 'Rejected via Mobile'}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('rejectPermit error: $e');
      return false;
    }
  }

  // --- EMPLOYEE APIS ---
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
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print('getEmployees error: $e');
      return [];
    }
  }

  static Future<bool> createEmployee(Map<String, dynamic> payload) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/employees'),
        headers: headers,
        body: jsonEncode(payload),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('createEmployee error: $e');
      return false;
    }
  }

  // --- VENDOR APIS ---
  static Future<List<dynamic>> getVendors({String? search, String? status}) async {
    try {
      String query = '';
      if (search != null) query += 'search=$search&';
      if (status != null) query += 'status=$status&';
      final response = await http.get(
        Uri.parse('$baseUrl/vendors?$query'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print('getVendors error: $e');
      return [];
    }
  }

  static Future<bool> createVendor(Map<String, dynamic> payload) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/vendors'),
        headers: headers,
        body: jsonEncode(payload),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('createVendor error: $e');
      return false;
    }
  }

  // --- ATTENDANCE APIS ---
  static Future<List<dynamic>> getAttendance({String? date, String? status, String? search}) async {
    try {
      String query = '';
      if (date != null) query += 'date=$date&';
      if (status != null) query += 'status=$status&';
      if (search != null) query += 'search=$search&';
      final response = await http.get(
        Uri.parse('$baseUrl/attendance?$query'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print('getAttendance error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getAttendanceSummary() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/attendance/summary'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) return data['data'];
      }
      return null;
    } catch (e) {
      print('getAttendanceSummary error: $e');
      return null;
    }
  }

  static Future<bool> markManualAttendance(Map<String, dynamic> payload) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/attendance/manual'),
        headers: headers,
        body: jsonEncode(payload),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('markManualAttendance error: $e');
      return false;
    }
  }

  // --- PERMIT CREATION ---
  static Future<bool> createPermit(Map<String, dynamic> payload) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/permits'),
        headers: headers,
        body: jsonEncode(payload),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('createPermit error: $e');
      return false;
    }
  }

  // --- AUDIT LOGS & GATE TRANSACTIONS ---
  static Future<List<dynamic>> getAuditLogs({String? module, String? search}) async {
    try {
      String query = '';
      if (module != null) query += 'module=$module&';
      if (search != null) query += 'search=$search&';
      final response = await http.get(
        Uri.parse('$baseUrl/audit/logs?$query'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print('getAuditLogs error: $e');
      return [];
    }
  }

  static Future<List<dynamic>> getGateTransactions({String? search, String? movementType}) async {
    try {
      String query = '';
      if (movementType != null) query += 'movement_type=$movementType&';
      if (search != null) query += 'search=$search&';
      final response = await http.get(
        Uri.parse('$baseUrl/gate/transactions?$query'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print('getGateTransactions error: $e');
      return [];
    }
  }

  // --- USER MANAGEMENT (Super Admin) ---
  static Future<List<dynamic>> getUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/users'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print('getUsers error: $e');
      return [];
    }
  }

  static Future<bool> createUser(Map<String, dynamic> payload) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/users'),
        headers: headers,
        body: jsonEncode(payload),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('createUser error: $e');
      return false;
    }
  }

  // --- REPORTS ---
  static Future<Map<String, dynamic>?> getReportData(String reportType) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reports/data?report_type=$reportType'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('getReportData error: $e');
      return null;
    }
  }
}
