/// Strategy used to suppress repeated alerts within a time window.
enum HoraiAlertDeduplicationMode {
  /// Every alert is queued independently.
  disabled,

  /// Alerts with the same message are considered duplicates.
  sameMessage,

  /// Alerts with the same type and message are considered duplicates.
  sameTypeAndMessage,

  /// Alerts with the same non-empty custom key are considered duplicates.
  customKey,
}

/// Immutable duplicate suppression settings.
class HoraiAlertDeduplication {
  /// Creates deduplication settings.
  const HoraiAlertDeduplication({
    this.mode = HoraiAlertDeduplicationMode.sameTypeAndMessage,
    this.window = const Duration(milliseconds: 750),
  });

  /// Strategy used to compute duplicate keys.
  final HoraiAlertDeduplicationMode mode;

  /// Time during which a matching alert is suppressed.
  final Duration window;
}
