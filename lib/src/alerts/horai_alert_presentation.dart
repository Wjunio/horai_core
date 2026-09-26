/// Channel used to present an alert.
enum HoraiAlertPresentation {
  /// Uses the configured default presentation.
  auto,

  /// Presents a compact, transient notification.
  toast,

  /// Presents a message in a snackbar-style surface.
  snackbar,

  /// Presents a floating alert over the application content.
  overlay,

  /// Presents a modal alert above the application content.
  dialog,
}
