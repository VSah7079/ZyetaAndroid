class UserModel {
  final int id;
  final String username;
  final String email;
  final String role;
  final String fullName;
  final String? phone;
  final int? vendorId;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.fullName,
    this.phone,
    this.vendorId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      fullName: json['full_name'] ?? '',
      phone: json['phone'],
      vendorId: json['vendor_id'],
    );
  }
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
