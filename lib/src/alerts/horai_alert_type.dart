/// The semantic category of an alert.
enum HoraiAlertType {
  /// Indicates a successfully completed operation.
  success,

  /// Indicates an operation that could not be completed.
  error,

  /// Indicates a potential issue that may need attention.
  warning,

  /// Provides neutral, supplementary information.
  info,
}
