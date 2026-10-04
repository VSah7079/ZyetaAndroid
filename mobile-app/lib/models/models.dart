class UserModel {
  final int id;
  final String username;
  final String email;
  final String role;
  final String fullName;
  final String? phone;
  final int? vendorId;
  final String status;
  final List<String> permissions;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.fullName,
    this.phone,
    this.vendorId,
    this.status = 'Active',
    this.permissions = const [],
  });

  bool get isSuperAdmin => role == 'Super Admin' || permissions.contains('all');

  bool can(String perm) {
    if (isSuperAdmin) return true;
    return permissions.contains(perm) || permissions.contains('all');
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    List<String> perms = [];
    if (json['permissions'] != null) {
      perms = List<String>.from(json['permissions']);
    } else {
      // Default fallback permissions per role if not explicitly provided
      final r = json['role'] ?? '';
      if (r == 'Super Admin') {
        perms = ['all'];
      } else if (r == 'Admin') {
        perms = ['employees', 'vendors', 'gate', 'permits', 'safety', 'visitors', 'materials', 'vehicles', 'attendance', 'headcount', 'reports'];
      } else if (r == 'Safety Officer') {
        perms = ['safety', 'permits', 'employees', 'attendance', 'headcount', 'reports'];
      } else if (r == 'Vendor') {
        perms = ['employees', 'permits', 'materials', 'attendance'];
      } else if (r == 'Security') {
        perms = ['gate', 'visitors', 'materials', 'vehicles', 'headcount', 'permits'];
      }
    }

    return UserModel(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      fullName: json['full_name'] ?? '',
      phone: json['phone'],
      vendorId: json['vendor_id'],
      status: json['status'] ?? 'Active',
      permissions: perms,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'role': role,
        'full_name': fullName,
        'phone': phone,
        'vendor_id': vendorId,
        'status': status,
        'permissions': permissions,
      };
}

class VerificationResult {
  final String verificationStatus; // ALLOW, FLAGGED, DENIED
  final String recommendedAction; // ALLOW_ENTRY, ALLOW_EXIT
  final bool isCurrentlyInside;
  final List<String> complianceWarnings;
  final Map<String, dynamic>? activePermit;
  final String entityType; // Employee, Visitor, Material, Vehicle, Permit
  final Map<String, dynamic> data;

  VerificationResult({
    required this.verificationStatus,
    required this.recommendedAction,
    required this.isCurrentlyInside,
    required this.complianceWarnings,
    this.activePermit,
    this.entityType = 'Employee',
    required this.data,
  });

  factory VerificationResult.fromJson(Map<String, dynamic> json) {
    return VerificationResult(
      verificationStatus: json['verification_status'] ?? 'DENIED',
      recommendedAction: json['recommended_action'] ?? 'DENIED',
      isCurrentlyInside: json['is_currently_inside'] ?? false,
      complianceWarnings: List<String>.from(json['compliance_warnings'] ?? []),
      activePermit: json['active_permit'],
      entityType: json['entity_type'] ?? 'Employee',
      data: Map<String, dynamic>.from(json['data'] ?? {}),
    );
  }
}
