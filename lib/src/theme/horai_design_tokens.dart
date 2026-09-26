import 'package:flutter/animation.dart';

/// Immutable spacing, shape, and motion defaults for HORAI widgets.
class HoraiDesignTokens {
  /// Creates design tokens that can be replaced by an application.
  const HoraiDesignTokens({
    this.spacing = const HoraiSpacing(),
    this.radius = const HoraiRadius(),
    this.motion = const HoraiMotion(),
  });

  /// Spacing values used by default widgets.
  final HoraiSpacing spacing;

  /// Corner radii used by default widgets.
  final HoraiRadius radius;

  /// Animation defaults used by default widgets.
  final HoraiMotion motion;
}

/// Standard spacing values in logical pixels.
class HoraiSpacing {
  /// Creates spacing tokens.
  const HoraiSpacing({
    this.xs = 4,
    this.sm = 8,
    this.md = 12,
    this.lg = 16,
    this.xl = 24,
  });

  /// Extra-small spacing.
  final double xs;

  /// Small spacing.
  final double sm;

  /// Medium spacing.
  final double md;

  /// Large spacing.
  final double lg;

  /// Extra-large spacing.
  final double xl;
}

/// Standard corner radii in logical pixels.
class HoraiRadius {
  /// Creates radius tokens.
  const HoraiRadius({this.sm = 4, this.md = 8, this.lg = 12});

  /// Small corner radius.
  final double sm;

  /// Medium corner radius.
  final double md;

  /// Large corner radius.
  final double lg;
}

/// Standard animation duration and curve.
class HoraiMotion {
  /// Creates motion tokens.
  const HoraiMotion({
    this.duration = const Duration(milliseconds: 220),
    this.curve = Curves.easeOutCubic,
  });

  /// Default animation duration.
  final Duration duration;

  /// Default animation curve.
  final Curve curve;
}
