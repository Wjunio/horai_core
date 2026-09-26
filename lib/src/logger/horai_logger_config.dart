import '../core/horai_environment.dart';
import 'horai_log_level.dart';
import 'horai_log_output.dart';
import 'horai_log_sanitizer.dart';

/// Immutable logger behavior and output configuration.
class HoraiLoggerConfig {
  /// Creates explicit logger configuration.
  const HoraiLoggerConfig({
    this.enabled = true,
    this.minimumLevel = HoraiLogLevel.debug,
    this.output = HoraiLogOutput.console,
    this.sanitizer,
    this.maxScreenEntries = 500,
  }) : assert(maxScreenEntries > 0);

  /// Creates conservative defaults for [environment].
  factory HoraiLoggerConfig.forEnvironment(HoraiEnvironment environment) {
    return switch (environment) {
      HoraiEnvironment.development => const HoraiLoggerConfig(),
      HoraiEnvironment.staging => const HoraiLoggerConfig(
        minimumLevel: HoraiLogLevel.info,
        output: HoraiLogOutput.none,
      ),
      HoraiEnvironment.production => const HoraiLoggerConfig(
        minimumLevel: HoraiLogLevel.warning,
        output: HoraiLogOutput.none,
      ),
    };
  }

  /// Whether log calls are processed.
  final bool enabled;

  /// Lowest-severity entry accepted by the logger.
  final HoraiLogLevel minimumLevel;

  /// Built-in output destinations.
  final HoraiLogOutput output;

  /// Optional custom sanitizer; defaults to [HoraiLogSanitizer].
  final HoraiLogSanitizer? sanitizer;

  /// Maximum number of entries retained by the screen sink.
  final int maxScreenEntries;

  /// Effective sanitizer for this configuration.
  HoraiLogSanitizer get effectiveSanitizer => sanitizer ?? HoraiLogSanitizer();
}
