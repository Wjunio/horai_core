import '../alerts/horai_alert_config.dart';
import '../logger/horai_logger_config.dart';
import '../theme/horai_design_tokens.dart';
import 'horai_environment.dart';

/// Immutable configuration shared by the HORAI Core modules.
class HoraiCoreConfig {
  /// Creates configuration for one [HoraiCore] instance.
  const HoraiCoreConfig({
    this.environment = HoraiEnvironment.development,
    this.alertConfig = const HoraiAlertConfig(),
    this.loggerConfig,
    this.designTokens = const HoraiDesignTokens(),
  });

  /// The explicitly selected runtime environment.
  final HoraiEnvironment environment;

  /// Alert behavior and theme configuration for this instance.
  final HoraiAlertConfig alertConfig;

  /// Optional logger overrides; otherwise defaults follow [environment].
  final HoraiLoggerConfig? loggerConfig;

  /// Design tokens used by built-in presentation widgets.
  final HoraiDesignTokens designTokens;

  /// The effective logger configuration for this instance.
  HoraiLoggerConfig get effectiveLoggerConfig =>
      loggerConfig ?? HoraiLoggerConfig.forEnvironment(environment);
}
