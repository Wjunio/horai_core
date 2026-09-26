/// Severity of a structured log entry, ordered from least to most severe.
enum HoraiLogLevel {
  /// Diagnostic details for development.
  debug,

  /// General operational information.
  info,

  /// A successful operation worth noting.
  success,

  /// An unexpected condition that did not stop the operation.
  warning,

  /// An operation failed.
  error,

  /// A critical failure requiring immediate attention.
  fatal,
}
