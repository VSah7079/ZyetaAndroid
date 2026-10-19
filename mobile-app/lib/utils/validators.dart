import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../screens/login_screen.dart';
import 'app_theme.dart';

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

  static String? validateAadhaar(String? val, {String fieldName = 'Aadhaar'}) {
    if (val == null || val.trim().isEmpty) return null;
    final clean = val.replaceAll(RegExp(r'\s'), '');
    if (!_aadhaarRegex.hasMatch(clean)) {
      return '$fieldName must be exactly 12 digits';
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

class AuthUtils {
  /// Opens a modern clean confirmation dialog before logging out the active user.
  static Future<bool?> showLogoutDialog(BuildContext context) async {
    final user = ApiService.currentUser;

    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppTheme.border, width: 1),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: AppTheme.badgeDecoration(
                  background: AppTheme.dangerBg,
                  borderColor: AppTheme.dangerBorder,
                  radius: 10,
                ),
                child: const Icon(Icons.logout_rounded, color: AppTheme.danger, size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'Confirm Logout',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (user != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.bgSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppTheme.primarySubtle,
                        child: Text(
                          (user.fullName.isNotEmpty ? user.fullName[0] : 'U').toUpperCase(),
                          style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.fullName,
                              style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${user.role} • ${user.username}',
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              const Text(
                'Are you sure you want to log out from this session? You will be returned to the login screen.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.textSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(ctx).pop(true);
                performLogout(context);
              },
              icon: const Icon(Icons.logout, size: 16, color: Colors.white),
              label: const Text('Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.danger,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Clears credentials and redirects safely to LoginScreen
  static void performLogout(BuildContext context) {
    ApiService.logout();
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}

/// Navigation utility to open root drawer from nested scaffolds
class NavUtils {
  static VoidCallback? openDrawerCallback;
  static void openDrawer() {
    openDrawerCallback?.call();
  }
}

/// Standard reusable Leading button for AppBars
class AppBarLeadingButton extends StatelessWidget {
  final Color? color;
  final VoidCallback? onMenuPressed;

  const AppBarLeadingButton({
    super.key,
    this.color,
    this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (Navigator.canPop(context)) {
      return IconButton(
        tooltip: 'Back',
        icon: Icon(Icons.arrow_back_rounded, color: color ?? AppTheme.textPrimary, size: 22),
        onPressed: () => Navigator.pop(context),
      );
    }
    return IconButton(
      tooltip: 'Open Menu',
      icon: Icon(Icons.menu_rounded, color: color ?? AppTheme.primary, size: 24),
      onPressed: onMenuPressed ?? () => NavUtils.openDrawer(),
    );
  }
}

/// Standard reusable prominent Logout Button for AppBars
class LogoutIconButton extends StatelessWidget {
  final Color? color;
  final double size;
  final String tooltip;
  final bool compact;

  const LogoutIconButton({
    super.key,
    this.color,
    this.size = 17,
    this.tooltip = 'Log Out',
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isExplicitWhite = color == Colors.white;
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => AuthUtils.showLogoutDialog(context),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 9, vertical: 4),
              decoration: BoxDecoration(
                color: isExplicitWhite ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isExplicitWhite ? Colors.white.withValues(alpha: 0.4) : const Color(0xFFFCA5A5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.logout_rounded,
                    color: color ?? AppTheme.danger,
                    size: size,
                  ),
                  if (!compact) ...[
                    const SizedBox(width: 4),
                    Text(
                      'Logout',
                      style: TextStyle(
                        color: color ?? AppTheme.danger,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

