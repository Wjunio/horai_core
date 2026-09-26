/// The runtime environment used to choose safe defaults.
enum HoraiEnvironment {
  /// Local development with diagnostic output enabled by default.
  development,

  /// Pre-release deployments with explicitly configurable diagnostics.
  staging,

  /// Production deployments with diagnostic output disabled by default.
  production,
}
