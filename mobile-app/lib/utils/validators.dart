class FormValidators {
  static final RegExp _phoneRegex = RegExp(r'^[6-9]\d{9}$');
  static final RegExp _emailRegex = RegExp(r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$');
  static final RegExp _aadhaarRegex = RegExp(r'^\d{12}$');
  static final RegExp _vehicleRegex = RegExp(r'^[A-Z0-9\s-]{6,15}$');

  static String? validateName(String? val, {String fieldName = 'Name'}) {
    if (val == null || val.trim().isEmpty) {
      return '$fieldName is required';
    }
    if (val.trim().length < 2) {
      return '$fieldName must be at least 2 characters';
    }
    return null;
  }

  static String? validatePhone(String? val, {bool isRequired = true, String fieldName = 'Mobile number'}) {
    if (val == null || val.trim().isEmpty) {
      if (isRequired) return '$fieldName is required';
      return null;
    }
    final clean = val.replaceAll(RegExp(r'[\s+-]'), '');
    final last10 = clean.length >= 10 ? clean.substring(clean.length - 10) : clean;
    if (!_phoneRegex.hasMatch(last10)) {
      return 'Enter a valid 10-digit mobile number (starts with 6-9)';
    }
    return null;
  }

  static String? validateEmail(String? val, {bool isRequired = true}) {
    if (val == null || val.trim().isEmpty) {
      if (isRequired) return 'Email address is required';
      return null;
    }
    if (!_emailRegex.hasMatch(val.trim())) {
      return 'Enter a valid email address (e.g., name@company.com)';
    }
    return null;
  }

  static String? validateAadhaar(String? val) {
    if (val == null || val.trim().isEmpty) return null;
    final clean = val.replaceAll(RegExp(r'\s'), '');
    if (!_aadhaarRegex.hasMatch(clean)) {
      return 'Aadhaar must be exactly 12 digits';
    }
    return null;
  }

  static String? validatePositiveNumber(String? val, {String fieldName = 'Quantity'}) {
    if (val == null || val.trim().isEmpty) {
      return '$fieldName is required';
    }
    final num = double.tryParse(val.trim());
    if (num == null || num <= 0) {
      return '$fieldName must be a valid positive number';
    }
    return null;
  }

  static String? validateVehicleNumber(String? val, {bool isRequired = true}) {
    if (val == null || val.trim().isEmpty) {
      if (isRequired) return 'Vehicle number is required';
      return null;
    }
    final clean = val.trim().toUpperCase();
    if (clean.length < 5 || !_vehicleRegex.hasMatch(clean)) {
      return 'Enter a valid vehicle plate (e.g., KA 01 AB 1234)';
    }
    return null;
  }

  static String? validateRequired(String? val, {String fieldName = 'This field', int minLength = 2}) {
    if (val == null || val.trim().isEmpty) {
      return '$fieldName is required';
    }
    if (val.trim().length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    return null;
  }

  static String? validatePassword(String? val, {int minLength = 4}) {
    if (val == null || val.isEmpty) {
      return 'Password is required';
    }
    if (val.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    return null;
  }
}
