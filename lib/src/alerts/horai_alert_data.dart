import 'package:flutter/material.dart';

import 'horai_alert_animation.dart';
import 'horai_alert_colors.dart';
import 'horai_alert_presentation.dart';
import 'horai_alert_position.dart';
import 'horai_alert_type.dart';

/// Builder that replaces the built-in visual while retaining alert routing.
typedef HoraiAlertBuilder = Widget Function(
  BuildContext context,
  HoraiAlertData alert,
);

/// Immutable content and per-call overrides for an alert.
class HoraiAlertData {
  /// Creates alert content and optional presentation overrides.
  const HoraiAlertData({
    required this.type,
    required this.message,
    this.title,
    this.icon,
    this.duration,
    this.dismissible = true,
    this.actionLabel,
    this.onAction,
    this.presentation = HoraiAlertPresentation.auto,
    this.position,
    this.animation,
    this.colors,
    this.decoration,
    this.builder,
    this.semanticLabel,
    this.deduplicationKey,
  });

  /// Semantic alert category.
  final HoraiAlertType type;

  /// Main alert message.
  final String message;

  /// Optional title shown above [message].
  final String? title;

  /// Optional replacement status icon.
  final IconData? icon;

  /// Auto-dismiss delay; `null` keeps the alert visible until dismissed.
  final Duration? duration;

  /// Whether the built-in presentation exposes a dismiss control.
  final bool dismissible;

  /// Optional label for [onAction].
  final String? actionLabel;

  /// Optional action invoked by the built-in presentation.
  final VoidCallback? onAction;

  /// Presentation channel, or [HoraiAlertPresentation.auto].
  final HoraiAlertPresentation presentation;

  /// Position override for non-modal presentations.
  final HoraiAlertPosition? position;

  /// Optional animation override.
  final HoraiAlertAnimation? animation;

  /// Optional palette override for this alert.
  final HoraiAlertColors? colors;

  /// Optional decoration override for the built-in alert surface.
  final BoxDecoration? decoration;

  /// Optional complete replacement for the built-in widget.
  final HoraiAlertBuilder? builder;

  /// Optional accessibility announcement label.
  final String? semanticLabel;

  /// Optional key used with custom-key deduplication.
  final String? deduplicationKey;
}
