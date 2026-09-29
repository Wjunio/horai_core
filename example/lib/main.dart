import 'package:flutter/material.dart';
import 'package:horai_core/horai_core.dart';

void main() => runApp(const HoraiExampleApp());

class HoraiExampleApp extends StatefulWidget {
  const HoraiExampleApp({super.key});

  @override
  State<HoraiExampleApp> createState() => _HoraiExampleAppState();
}

class _HoraiExampleAppState extends State<HoraiExampleApp> {
  HoraiEnvironment _environment = HoraiEnvironment.development;
  late HoraiCore _core = _createCore(_environment);

  HoraiCore _createCore(HoraiEnvironment environment) {
    final defaults = HoraiAlertTheme.horai();
    final theme = HoraiAlertTheme(
      success: defaults.success.copyWith(
        background: const Color(0xFF063C31),
        border: const Color(0xFF18D6A2),
      ),
      error: defaults.error.copyWith(
        background: const Color(0xFF3C1721),
        border: const Color(0xFFFF6177),
      ),
      warning: defaults.warning.copyWith(
        background: const Color(0xFF3B300D),
        border: const Color(0xFFFFC43D),
      ),
      info: defaults.info.copyWith(
        background: const Color(0xFF0A304A),
        border: const Color(0xFF27B5F4),
      ),
    );

    return HoraiCore(
      config: HoraiCoreConfig(
        environment: environment,
        alertConfig: HoraiAlertConfig(
          theme: theme,
          defaultPresentation: HoraiAlertPresentation.snackbar,
        ),
        loggerConfig: environment == HoraiEnvironment.development
            ? const HoraiLoggerConfig(output: HoraiLogOutput.both)
            : HoraiLoggerConfig.forEnvironment(environment),
      ),
    );
  }

  void _changeEnvironment(HoraiEnvironment? environment) {
    if (environment == null) return;
    setState(() {
      _environment = environment;
      _core = _createCore(environment);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF11C99A),
        useMaterial3: true,
      ),
      builder: (context, child) =>
          HoraiAlertHost(core: _core, child: child ?? const SizedBox.shrink()),
      home: _HoraiExamplePage(
        core: _core,
        environment: _environment,
        onEnvironmentChanged: _changeEnvironment,
      ),
    );
  }
}

class _HoraiExamplePage extends StatefulWidget {
  const _HoraiExamplePage({
    required this.core,
    required this.environment,
    required this.onEnvironmentChanged,
  });

  final HoraiCore core;
  final HoraiEnvironment environment;
  final ValueChanged<HoraiEnvironment?> onEnvironmentChanged;

  @override
  State<_HoraiExamplePage> createState() => _HoraiExamplePageState();
}

class _HoraiExamplePageState extends State<_HoraiExamplePage> {
  HoraiAlertPresentation _presentation = HoraiAlertPresentation.auto;
  HoraiAlertPosition _position = HoraiAlertPosition.bottom;

  @override
  Widget build(BuildContext context) {
    final logSink = widget.core.logger.screenSink;
    return Scaffold(
      appBar: AppBar(
        title: const Text('HORAI CORE'),
        actions: [
          DropdownButton<HoraiEnvironment>(
            value: widget.environment,
            underline: const SizedBox.shrink(),
            items: [
              for (final environment in HoraiEnvironment.values)
                DropdownMenuItem(
                  value: environment,
                  child: Text(environment.name),
                ),
            ],
            onChanged: widget.onEnvironmentChanged,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Alert channels',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<HoraiAlertPresentation>(
                initialValue: _presentation,
                decoration: const InputDecoration(labelText: 'Presentation'),
                items: [
                  for (final presentation in HoraiAlertPresentation.values)
                    DropdownMenuItem(
                      value: presentation,
                      child: Text(presentation.name),
                    ),
                ],
                onChanged: (value) => setState(() {
                  _presentation = value ?? HoraiAlertPresentation.auto;
                  if (_presentation == HoraiAlertPresentation.dialog) {
                    _position = HoraiAlertPosition.center;
                  }
                }),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<HoraiAlertPosition>(
                initialValue: _position,
                decoration: InputDecoration(
                  labelText: 'Position',
                  enabled: _presentation != HoraiAlertPresentation.dialog,
                  helperText: _presentation == HoraiAlertPresentation.dialog
                      ? 'Dialog is modal and fixed at center.'
                      : null,
                ),
                items: [
                  for (final position in HoraiAlertPosition.values)
                    DropdownMenuItem(
                      value: position,
                      child: Text(position.name),
                    ),
                ],
                onChanged: _presentation == HoraiAlertPresentation.dialog
                    ? null
                    : (value) => setState(() {
                        _position = value ?? HoraiAlertPosition.bottom;
                      }),
              ),
              const SizedBox(height: 12),
              Builder(
                builder: (alertContext) => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _alertButton(
                      alertContext,
                      HoraiAlertType.success,
                      'Success',
                      Icons.check_circle_outline,
                    ),
                    _alertButton(
                      alertContext,
                      HoraiAlertType.error,
                      'Error',
                      Icons.error_outline,
                    ),
                    _alertButton(
                      alertContext,
                      HoraiAlertType.warning,
                      'Warning',
                      Icons.warning_amber_rounded,
                    ),
                    _alertButton(
                      alertContext,
                      HoraiAlertType.info,
                      'Information',
                      Icons.info_outline,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Confirmation dialogs',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Builder(
                builder: (confirmationContext) => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final type in HoraiAlertType.values)
                      _confirmationButton(confirmationContext, type),
                    FilledButton.tonalIcon(
                      onPressed: () => _showConfirmation(
                        confirmationContext,
                        HoraiAlertType.warning,
                        customizeText: true,
                      ),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Custom warning'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Structured logger',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final level in HoraiLogLevel.values)
                    OutlinedButton(
                      onPressed: () => _writeLog(level),
                      child: Text(level.name.toUpperCase()),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (logSink == null)
                Text(
                  'Screen logging is disabled in ${widget.environment.name}.',
                )
              else
                SizedBox(height: 360, child: HoraiLogConsole(sink: logSink)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _confirmationButton(BuildContext context, HoraiAlertType type) {
    final (label, icon) = switch (type) {
      HoraiAlertType.success => ('Success', Icons.check_circle_outline),
      HoraiAlertType.error => ('Error', Icons.error_outline),
      HoraiAlertType.warning => ('Warning', Icons.warning_amber_rounded),
      HoraiAlertType.info => ('Information', Icons.info_outline),
    };

    return FilledButton.tonalIcon(
      onPressed: () => _showConfirmation(context, type),
      icon: Icon(icon),
      label: Text(label),
    );
  }

  Future<void> _showConfirmation(
    BuildContext context,
    HoraiAlertType type, {
    bool customizeText = false,
  }) async {
    final result = await widget.core.confirmation.show(
      context: context,
      type: type,
      title: customizeText ? 'Custom warning title' : null,
      message: customizeText ? 'Custom warning message' : null,
      confirmLabel: customizeText ? 'Continue anyway' : null,
      cancelLabel: customizeText ? 'Keep editing' : null,
    );
    if (!context.mounted) return;

    final outcome = switch (result) {
      true => 'confirmed',
      false => 'cancelled',
      null => 'closed without choosing',
    };
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Confirmation $outcome')));
  }

  Widget _alertButton(
    BuildContext context,
    HoraiAlertType type,
    String label,
    IconData icon,
  ) {
    return FilledButton.tonalIcon(
      onPressed: () {
        widget.core.alert.show(
          context: context,
          type: type,
          title: label,
          message: 'This alert uses the selected HORAI presentation.',
          presentation: _presentation,
          position: _position,
          actionLabel: 'Acknowledge',
          onAction: () => widget.core.logger.success(
            'Alert acknowledged',
            context: 'ExampleApp',
            metadata: {'alertType': type.name},
          ),
        );
        widget.core.logger.info(
          'Alert requested',
          context: 'ExampleApp',
          metadata: {'alertType': type.name},
        );
      },
      icon: Icon(icon),
      label: Text(label),
    );
  }

  void _writeLog(HoraiLogLevel level) {
    final logger = widget.core.logger;
    switch (level) {
      case HoraiLogLevel.debug:
        logger.debug('Diagnostic event', context: 'ExampleApp');
      case HoraiLogLevel.info:
        logger.info('Application started', context: 'ExampleApp');
      case HoraiLogLevel.success:
        logger.success('Example operation completed', context: 'ExampleApp');
      case HoraiLogLevel.warning:
        logger.warning(
          'Example condition needs attention',
          context: 'ExampleApp',
        );
      case HoraiLogLevel.error:
        logger.error('Example operation failed', context: 'ExampleApp');
      case HoraiLogLevel.fatal:
        logger.fatal('Example critical failure', context: 'ExampleApp');
    }
  }
}
