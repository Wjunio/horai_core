import 'dart:collection';
import 'dart:async';

import 'package:flutter/material.dart';

import '../core/horai_core.dart';
import 'horai_alert_animation.dart';
import 'horai_alert_colors.dart';
import 'horai_alert_config.dart';
import 'horai_alert_data.dart';
import 'horai_alert_deduplication.dart';
import 'horai_alert_presentation.dart';
import 'horai_alert_position.dart';
import 'horai_alert_type.dart';

/// Lifecycle-aware presentation host required by [HoraiCore.alert].
class HoraiAlertHost extends StatefulWidget {
  /// Creates a host that presents alerts for [core] above [child].
  const HoraiAlertHost({required this.core, required this.child, super.key});

  /// Core instance whose alerts are accepted by this host.
  final HoraiCore core;

  /// Application subtree covered by the alert layer.
  final Widget child;

  /// Dispatches an alert to the matching nearest host.
  static bool dispatch(
    BuildContext context,
    HoraiCore core,
    HoraiAlertData alert,
  ) {
    if (!context.mounted) return false;
    final element = context
        .getElementForInheritedWidgetOfExactType<_HoraiAlertHostScope>();
    final scope = element?.widget as _HoraiAlertHostScope?;
    final state = scope?.state;
    if (scope == null || state == null || !state.mounted) {
      throw StateError(
        'Place HoraiAlertHost above the context used to show alerts.',
      );
    }
    if (!identical(scope.core, core)) {
      throw StateError(
        'The nearest HoraiAlertHost belongs to a different HoraiCore instance.',
      );
    }
    return state._enqueue(alert);
  }

  @override
  State<HoraiAlertHost> createState() => _HoraiAlertHostState();
}

class _HoraiAlertHostState extends State<HoraiAlertHost>
    with WidgetsBindingObserver {
  final Queue<_QueuedAlert> _queue = Queue<_QueuedAlert>();
  final Map<String, DateTime> _recentKeys = {};
  _QueuedAlert? _current;
  Timer? _timer;
  DateTime? _deadline;
  Duration? _remaining;
  bool _isPaused = false;
  int _nextId = 0;
  late final OverlayEntry _hostEntry = OverlayEntry(builder: _buildHostContent);

  HoraiAlertConfig get _config => widget.core.config.alertConfig;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(covariant HoraiAlertHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.core, widget.core)) {
      _timer?.cancel();
      _current = null;
      _queue.clear();
      _recentKeys.clear();
      _hostEntry.markNeedsBuild();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final wasPaused = _isPaused;
      _isPaused = false;
      if (wasPaused) _scheduleDismissal(_remaining);
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _isPaused = true;
      final deadline = _deadline;
      if (deadline != null) {
        _remaining = deadline.difference(DateTime.now());
        _timer?.cancel();
        _timer = null;
        _deadline = null;
      }
    }
  }

  bool _enqueue(HoraiAlertData data) {
    if (_queue.length + (_current == null ? 0 : 1) >= _config.maxQueueLength) {
      return false;
    }

    final deduplication = _config.deduplication;
    final key = _deduplicationKey(data, deduplication.mode);
    final now = DateTime.now();
    if (key != null) {
      final previous = _recentKeys[key];
      if (previous != null && now.difference(previous) < deduplication.window) {
        return false;
      }
      _recentKeys[key] = now;
      _recentKeys.removeWhere(
        (_, timestamp) => now.difference(timestamp) > deduplication.window,
      );
    }

    final presentation = data.presentation == HoraiAlertPresentation.auto
        ? _config.defaultPresentation
        : data.presentation;
    final duration = presentation == HoraiAlertPresentation.dialog
        ? data.duration
        : data.duration ?? _config.duration;
    final queued = _QueuedAlert(
      id: _nextId++,
      data: data,
      presentation: presentation,
      position: data.position ?? _config.position,
      animation: data.animation ?? _config.animation,
      duration: duration,
    );

    if (_current == null) {
      setState(() => _current = queued);
      _scheduleDismissal(duration);
    } else {
      setState(() => _queue.addLast(queued));
    }
    _hostEntry.markNeedsBuild();
    return true;
  }

  String? _deduplicationKey(
    HoraiAlertData data,
    HoraiAlertDeduplicationMode mode,
  ) {
    return switch (mode) {
      HoraiAlertDeduplicationMode.disabled => null,
      HoraiAlertDeduplicationMode.sameMessage => 'message:${data.message}',
      HoraiAlertDeduplicationMode.sameTypeAndMessage =>
        '${data.type.name}:${data.message}',
      HoraiAlertDeduplicationMode.customKey => data.deduplicationKey,
    };
  }

  void _scheduleDismissal(Duration? duration) {
    _timer?.cancel();
    _deadline = null;
    _remaining = null;
    if (_isPaused || duration == null || _current == null) return;

    final delay = duration.isNegative ? Duration.zero : duration;
    _remaining = delay;
    _deadline = DateTime.now().add(delay);
    _timer = Timer(delay, () => _dismiss(_current?.id));
  }

  void _dismiss(int? id) {
    if (!mounted || _current == null || _current!.id != id) return;
    _timer?.cancel();
    _timer = null;
    _deadline = null;
    _remaining = null;
    setState(() {
      _current = _queue.isEmpty ? null : _queue.removeFirst();
    });
    _hostEntry.markNeedsBuild();
    _scheduleDismissal(_current?.duration);
  }

  void _runAction(_QueuedAlert alert) {
    try {
      alert.data.onAction?.call();
    } on Object catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'horai_core',
          context: ErrorDescription('while running an alert action'),
        ),
      );
    } finally {
      _dismiss(alert.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _HoraiAlertHostScope(
      core: widget.core,
      state: this,
      child: Overlay(initialEntries: [_hostEntry]),
    );
  }

  Widget _buildHostContent(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_current case final alert?) _buildLayer(alert),
      ],
    );
  }

  Widget _buildLayer(_QueuedAlert alert) {
    final content = _buildAlert(context, alert);
    if (alert.presentation == HoraiAlertPresentation.dialog) {
      return Positioned.fill(
        child: Stack(
          children: [
            ModalBarrier(
              color: Colors.black54,
              dismissible: alert.data.dismissible,
              onDismiss: alert.data.dismissible
                  ? () => _dismiss(alert.id)
                  : null,
              semanticsLabel: alert.data.semanticLabel ?? 'Dismiss alert',
            ),
            Center(
              child: Padding(
                padding: _safeInsets(MediaQuery.of(context)),
                child: content,
              ),
            ),
          ],
        ),
      );
    }

    if (alert.position == HoraiAlertPosition.center) {
      return Positioned.fill(
        child: Padding(
          padding: _safeInsets(MediaQuery.of(context)),
          child: Center(child: content),
        ),
      );
    }

    final mediaQuery = MediaQuery.of(context);
    final safeInsets = _safeInsets(mediaQuery);
    final isTop = alert.position == HoraiAlertPosition.top;
    return Positioned(
      left: 0,
      right: 0,
      top: isTop ? safeInsets.top : null,
      bottom: isTop ? null : safeInsets.bottom,
      child: Padding(
        padding: EdgeInsets.only(
          left: safeInsets.left,
          right: safeInsets.right,
        ),
        child: Align(
          alignment: isTop ? Alignment.topCenter : Alignment.bottomCenter,
          child: content,
        ),
      ),
    );
  }

  Widget _buildAlert(BuildContext context, _QueuedAlert queued) {
    final theme = _config.effectiveTheme;
    final tokens = widget.core.config.designTokens;
    final alert = queued.data;
    final colors = alert.colors ?? theme.colorsFor(alert.type);
    final semanticLabel =
        alert.semanticLabel ??
        '${_alertTypeLabel(alert.type)}: '
            '${alert.title == null ? alert.message : '${alert.title}. ${alert.message}'}';
    final child =
        alert.builder?.call(context, alert) ??
        _HoraiAlertCard(
          alert: alert,
          colors: colors,
          radius: tokens.radius.md,
          onDismiss: () => _dismiss(queued.id),
          onAction: () => _runAction(queued),
          compact: queued.presentation == HoraiAlertPresentation.toast,
        );

    return _HoraiAlertEntrance(
      key: ValueKey<int>(queued.id),
      position: queued.position,
      animation: queued.animation,
      reducedMotion: MediaQuery.disableAnimationsOf(context),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: switch (queued.presentation) {
            HoraiAlertPresentation.toast => 420,
            HoraiAlertPresentation.snackbar => 640,
            _ => 720,
          },
        ),
        child: Semantics(
          container: true,
          explicitChildNodes: true,
          liveRegion: queued.presentation != HoraiAlertPresentation.dialog,
          label: semanticLabel,
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _queue.clear();
    _recentKeys.clear();
    _hostEntry.remove();
    _hostEntry.dispose();
    super.dispose();
  }
}

String _alertTypeLabel(HoraiAlertType type) => switch (type) {
  HoraiAlertType.success => 'Success',
  HoraiAlertType.error => 'Error',
  HoraiAlertType.warning => 'Warning',
  HoraiAlertType.info => 'Information',
};

EdgeInsets _safeInsets(MediaQueryData mediaQuery) => EdgeInsets.fromLTRB(
  mediaQuery.viewPadding.left,
  mediaQuery.viewPadding.top,
  mediaQuery.viewPadding.right,
  mediaQuery.viewInsets.bottom > mediaQuery.viewPadding.bottom
      ? mediaQuery.viewInsets.bottom
      : mediaQuery.viewPadding.bottom,
);

class _HoraiAlertHostScope extends InheritedWidget {
  const _HoraiAlertHostScope({
    required this.core,
    required this.state,
    required super.child,
  });

  final HoraiCore core;
  final _HoraiAlertHostState state;

  @override
  bool updateShouldNotify(_HoraiAlertHostScope oldWidget) =>
      !identical(core, oldWidget.core) || state != oldWidget.state;
}

class _QueuedAlert {
  const _QueuedAlert({
    required this.id,
    required this.data,
    required this.presentation,
    required this.position,
    required this.animation,
    required this.duration,
  });

  final int id;
  final HoraiAlertData data;
  final HoraiAlertPresentation presentation;
  final HoraiAlertPosition position;
  final HoraiAlertAnimation animation;
  final Duration? duration;
}

class _HoraiAlertCard extends StatelessWidget {
  const _HoraiAlertCard({
    required this.alert,
    required this.colors,
    required this.radius,
    required this.onDismiss,
    required this.onAction,
    required this.compact,
  });

  final HoraiAlertData alert;
  final HoraiAlertColors colors;
  final double radius;
  final VoidCallback onDismiss;
  final VoidCallback onAction;
  final bool compact;

  IconData get _defaultIcon => switch (alert.type) {
    HoraiAlertType.success => Icons.check_circle_outline_rounded,
    HoraiAlertType.error => Icons.cancel_outlined,
    HoraiAlertType.warning => Icons.warning_amber_rounded,
    HoraiAlertType.info => Icons.info_outline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final spacing = compact ? 12.0 : 16.0;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: spacing, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration:
              alert.decoration ??
              BoxDecoration(
                color: colors.background,
                border: Border.all(color: colors.border),
                borderRadius: BorderRadius.circular(radius),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 18,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
          child: Row(
            children: [
              Padding(
                padding: EdgeInsets.all(compact ? 12 : 16),
                child: Icon(alert.icon ?? _defaultIcon, color: colors.icon),
              ),
              Container(
                width: 1,
                height: compact ? 36 : 44,
                color: colors.border,
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing,
                    vertical: 12,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (alert.title case final title? when title.isNotEmpty)
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: colors.title,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      Text(
                        alert.message,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: colors.message),
                      ),
                      if (alert.actionLabel != null && alert.onAction != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: onAction,
                            style: TextButton.styleFrom(
                              foregroundColor: colors.action,
                              minimumSize: const Size(48, 48),
                              padding: EdgeInsets.zero,
                            ),
                            child: Text(alert.actionLabel!),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (alert.dismissible)
                IconButton(
                  tooltip: 'Dismiss alert',
                  onPressed: onDismiss,
                  icon: const Icon(Icons.close_rounded),
                  color: colors.foreground,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HoraiAlertEntrance extends StatelessWidget {
  const _HoraiAlertEntrance({
    required this.position,
    required this.animation,
    required this.reducedMotion,
    required this.child,
    super.key,
  });

  final HoraiAlertPosition position;
  final HoraiAlertAnimation animation;
  final bool reducedMotion;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final duration =
        reducedMotion || animation.type == HoraiAlertAnimationType.none
        ? Duration.zero
        : animation.duration;
    final beginOffset = switch (position) {
      HoraiAlertPosition.top => const Offset(0, -0.08),
      HoraiAlertPosition.center => Offset.zero,
      HoraiAlertPosition.bottom => const Offset(0, 0.08),
    };
    final start =
        animation.type == HoraiAlertAnimationType.slide ||
            animation.type == HoraiAlertAnimationType.fadeSlide
        ? beginOffset
        : Offset.zero;
    final startOpacity =
        animation.type == HoraiAlertAnimationType.fade ||
            animation.type == HoraiAlertAnimationType.fadeSlide
        ? 0.0
        : 1.0;
    final startScale = animation.type == HoraiAlertAnimationType.scale
        ? 0.96
        : 1.0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: animation.curve,
      builder: (context, progress, child) => Opacity(
        opacity: startOpacity + (1 - startOpacity) * progress,
        child: Transform.translate(
          offset: Offset.lerp(start, Offset.zero, progress)!,
          child: Transform.scale(
            scale: startScale + (1 - startScale) * progress,
            child: child,
          ),
        ),
      ),
      child: child,
    );
  }
}
