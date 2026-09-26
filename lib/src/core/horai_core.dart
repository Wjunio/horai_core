import 'horai_core_config.dart';
import '../alerts/horai_alert.dart';
import '../logger/horai_logger.dart';

/// Composition root for independently usable HORAI modules.
class HoraiCore {
  /// Creates an injectable HORAI configuration scope.
  HoraiCore({this.config = const HoraiCoreConfig()}) {
    alert = HoraiAlert(this);
  }

  /// Configuration owned by this instance.
  final HoraiCoreConfig config;

  /// Alert API bound to this core instance.
  late final HoraiAlert alert;

  HoraiLogger? _logger;

  /// The lazily created logger owned by this instance.
  HoraiLogger get logger => _logger ??= HoraiLogger(
    config: config.effectiveLoggerConfig,
    environment: config.environment,
  );
}
