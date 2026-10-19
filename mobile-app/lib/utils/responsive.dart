import 'package:flutter/material.dart';

/// Comprehensive Responsive Utilities for Zyeta Workforce & Gate Management OS
class Responsive {
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 1024.0;

  static bool isSmallMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 360.0;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint;

  static bool isLandscape(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape;

  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  /// Clamps width for cards and modals so they don't stretch indefinitely on tablets
  static double maxContentWidth(BuildContext context, {double maxWidth = 640.0}) {
    final width = MediaQuery.of(context).size.width;
    return width > maxWidth ? maxWidth : width;
  }

  /// Calculates dynamic grid columns based on device screen width
  static int gridColumns(BuildContext context, {int mobile = 2, int tablet = 3, int desktop = 4}) {
    final width = MediaQuery.of(context).size.width;
    if (width >= tabletBreakpoint) return desktop;
    if (width >= mobileBreakpoint) return tablet;
    if (width < 340) return 1;
    return mobile;
  }

  /// Returns responsive value based on device size
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
    T? smallMobile,
  }) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360 && smallMobile != null) return smallMobile;
    if (width >= tabletBreakpoint && desktop != null) return desktop;
    if (width >= mobileBreakpoint && tablet != null) return tablet;
    return mobile;
  }

  /// Responsive padding helper
  static EdgeInsets screenPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= tabletBreakpoint) {
      return EdgeInsets.symmetric(horizontal: (width - 800) / 2, vertical: 24);
    }
    if (width >= mobileBreakpoint) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 20);
    }
    if (width < 360) {
      return const EdgeInsets.symmetric(horizontal: 8, vertical: 8);
    }
    return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
  }
}

/// A wrapper widget that ensures content does not over-stretch on larger screens (tablets, foldables)
class ResponsiveBody extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveBody({
    super.key,
    required this.child,
    this.maxWidth = 720.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final effectivePadding = padding ?? (isMobile ? EdgeInsets.zero : Responsive.screenPadding(context));
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: effectivePadding,
          child: child,
        ),
      ),
    );
  }
}
