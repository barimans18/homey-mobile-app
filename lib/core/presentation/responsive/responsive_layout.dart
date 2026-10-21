import 'package:flutter/material.dart';

/// Breakpoints standar untuk Homey Web & Mobile
class ResponsiveBreakpoints {
  ResponsiveBreakpoints._();

  static const double mobileMax = 767.0;
  static const double tabletMin = 768.0;
  static const double tabletMax = 1023.0;
  static const double desktopMin = 1024.0;
  static const double maxContentWidth = 1240.0;
}

/// Helper extension untuk BuildContext
extension ResponsiveExtension on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  bool get isMobile => screenWidth < ResponsiveBreakpoints.tabletMin;
  bool get isTablet =>
      screenWidth >= ResponsiveBreakpoints.tabletMin &&
      screenWidth < ResponsiveBreakpoints.desktopMin;
  bool get isDesktop => screenWidth >= ResponsiveBreakpoints.desktopMin;
  bool get isWideScreen => screenWidth >= ResponsiveBreakpoints.tabletMin;
}

/// Widget untuk merender widget berbeda berdasarkan ukuran layar
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= ResponsiveBreakpoints.desktopMin) {
          return desktop;
        } else if (constraints.maxWidth >= ResponsiveBreakpoints.tabletMin) {
          return tablet ?? desktop;
        } else {
          return mobile;
        }
      },
    );
  }
}

/// Widget pembungkus konten agar tidak melar pada monitor desktop lebar
class ResponsiveContentContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  const ResponsiveContentContainer({
    super.key,
    required this.child,
    this.maxWidth = ResponsiveBreakpoints.maxContentWidth,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
