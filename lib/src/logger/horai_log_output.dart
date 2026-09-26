/// Default destinations used by a [HoraiLogger].
enum HoraiLogOutput {
  /// Send entries to the developer console.
  console,

  /// Keep entries in a bounded in-memory store for a screen console.
  screen,

  /// Send entries to both built-in destinations.
  both,

  /// Do not create built-in output sinks.
  none,
}
