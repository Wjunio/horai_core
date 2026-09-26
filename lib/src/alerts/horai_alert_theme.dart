import 'package:flutter/painting.dart';

import 'horai_alert_colors.dart';
import 'horai_alert_type.dart';

/// Immutable colors and visual defaults for HORAI alerts.
class HoraiAlertTheme {
  /// Creates a theme with a separate palette for every alert type.
  const HoraiAlertTheme({
    required this.success,
    required this.error,
    required this.warning,
    required this.info,
  });

  /// Success palette.
  final HoraiAlertColors success;

  /// Error palette.
  final HoraiAlertColors error;

  /// Warning palette.
  final HoraiAlertColors warning;

  /// Informational palette.
  final HoraiAlertColors info;

  /// Returns the palette associated with [type].
  HoraiAlertColors colorsFor(HoraiAlertType type) => switch (type) {
    HoraiAlertType.success => success,
    HoraiAlertType.error => error,
    HoraiAlertType.warning => warning,
    HoraiAlertType.info => info,
  };

  /// Creates the default dark teal and emerald HORAI palette.
  factory HoraiAlertTheme.horai() {
    return const HoraiAlertTheme(
      success: HoraiAlertColors(
        background: Color(0xFF073B35),
        foreground: Color(0xFFF4FFFC),
        border: Color(0xFF00CFA5),
        icon: Color(0xFF00D6A3),
        title: Color(0xFFF4FFFC),
        message: Color(0xFFD1E8E2),
        action: Color(0xFF5FFFD3),
      ),
      error: HoraiAlertColors(
        background: Color(0xFF3B1720),
        foreground: Color(0xFFFFF7F8),
        border: Color(0xFFFF5470),
        icon: Color(0xFFFF5470),
        title: Color(0xFFFFF7F8),
        message: Color(0xFFF0DDE0),
        action: Color(0xFFFF9BAA),
      ),
      warning: HoraiAlertColors(
        background: Color(0xFF392D0A),
        foreground: Color(0xFFFFFCF2),
        border: Color(0xFFFFC02E),
        icon: Color(0xFFFFC02E),
        title: Color(0xFFFFFCF2),
        message: Color(0xFFEDE5CC),
        action: Color(0xFFFFD66E),
      ),
      info: HoraiAlertColors(
        background: Color(0xFF0A2F47),
        foreground: Color(0xFFF3FAFF),
        border: Color(0xFF1CAAF2),
        icon: Color(0xFF1CAAF2),
        title: Color(0xFFF3FAFF),
        message: Color(0xFFD6E9F4),
        action: Color(0xFF81D2FF),
      ),
    );
  }
}
