import 'package:flutter/painting.dart';

/// Immutable colors for each visual part of an alert.
class HoraiAlertColors {
  /// Creates a complete alert color palette.
  const HoraiAlertColors({
    required this.background,
    required this.foreground,
    required this.border,
    required this.icon,
    required this.title,
    required this.message,
    required this.action,
  });

  /// The alert surface color.
  final Color background;

  /// The primary foreground color.
  final Color foreground;

  /// The alert border color.
  final Color border;

  /// The status icon color.
  final Color icon;

  /// The title text color.
  final Color title;

  /// The message text color.
  final Color message;

  /// The action control color.
  final Color action;

  /// Creates a copy with the provided color overrides.
  HoraiAlertColors copyWith({
    Color? background,
    Color? foreground,
    Color? border,
    Color? icon,
    Color? title,
    Color? message,
    Color? action,
  }) {
    return HoraiAlertColors(
      background: background ?? this.background,
      foreground: foreground ?? this.foreground,
      border: border ?? this.border,
      icon: icon ?? this.icon,
      title: title ?? this.title,
      message: message ?? this.message,
      action: action ?? this.action,
    );
  }
}
