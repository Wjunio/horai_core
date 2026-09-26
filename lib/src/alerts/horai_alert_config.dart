import 'horai_alert_animation.dart';
import 'horai_alert_deduplication.dart';
import 'horai_alert_presentation.dart';
import 'horai_alert_position.dart';
import 'horai_alert_theme.dart';

/// Default alert behavior and theme for one [HoraiCore] instance.
class HoraiAlertConfig {
  /// Creates alert defaults.
  const HoraiAlertConfig({
    this.theme,
    this.defaultPresentation = HoraiAlertPresentation.snackbar,
    this.position = HoraiAlertPosition.bottom,
    this.duration = const Duration(seconds: 4),
    this.animation = const HoraiAlertAnimation(),
    this.deduplication = const HoraiAlertDeduplication(),
    this.maxQueueLength = 50,
  }) : assert(maxQueueLength > 0);

  /// Optional theme override; otherwise the HORAI theme is used.
  final HoraiAlertTheme? theme;

  /// Presentation selected when a call uses `auto`.
  final HoraiAlertPresentation defaultPresentation;

  /// Default non-modal position.
  final HoraiAlertPosition position;

  /// Default auto-dismiss delay for non-modal alerts.
  final Duration duration;

  /// Default entrance animation.
  final HoraiAlertAnimation animation;

  /// Duplicate suppression policy for this host.
  final HoraiAlertDeduplication deduplication;

  /// Maximum number of pending alerts retained by one host.
  final int maxQueueLength;

  /// Effective theme used by built-in presentations.
  HoraiAlertTheme get effectiveTheme => theme ?? HoraiAlertTheme.horai();
}
