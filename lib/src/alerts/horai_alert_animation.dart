import 'package:flutter/animation.dart';

/// The entrance transition used by a built-in alert presentation.
enum HoraiAlertAnimationType {
  /// Fades the alert into view.
  fade,

  /// Slides the alert into view.
  slide,

  /// Scales the alert into view.
  scale,

  /// Combines a fade and slide transition.
  fadeSlide,

  /// Shows the alert without an entrance transition.
  none,
}

/// Immutable alert animation settings.
class HoraiAlertAnimation {
  /// Creates animation settings.
  const HoraiAlertAnimation({
    this.type = HoraiAlertAnimationType.fadeSlide,
    this.duration = const Duration(milliseconds: 220),
    this.curve = Curves.easeOutCubic,
  });

  /// The transition style.
  final HoraiAlertAnimationType type;

  /// The transition duration.
  final Duration duration;

  /// The transition curve.
  final Curve curve;
}
