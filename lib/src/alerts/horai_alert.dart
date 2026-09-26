import 'package:flutter/material.dart';

import '../core/horai_core.dart';
import 'horai_alert_animation.dart';
import 'horai_alert_colors.dart';
import 'horai_alert_data.dart';
import 'horai_alert_host.dart';
import 'horai_alert_presentation.dart';
import 'horai_alert_position.dart';
import 'horai_alert_type.dart';

/// Instance-bound alert API.
class HoraiAlert {
  /// Creates an alert facade bound to [core].
  HoraiAlert(HoraiCore core) : _core = core;

  final HoraiCore _core;

  /// Shows an alert with complete per-call customization.
  bool show({
    required BuildContext context,
    required HoraiAlertType type,
    required String message,
    String? title,
    IconData? icon,
    Duration? duration,
    bool dismissible = true,
    String? actionLabel,
    VoidCallback? onAction,
    HoraiAlertPresentation presentation = HoraiAlertPresentation.auto,
    HoraiAlertPosition? position,
    HoraiAlertAnimation? animation,
    HoraiAlertColors? colors,
    BoxDecoration? decoration,
    HoraiAlertBuilder? builder,
    String? semanticLabel,
    String? deduplicationKey,
  }) {
    final data = HoraiAlertData(
      type: type,
      message: message,
      title: title,
      icon: icon,
      duration: duration,
      dismissible: dismissible,
      actionLabel: actionLabel,
      onAction: onAction,
      presentation: presentation,
      position: position,
      animation: animation,
      colors: colors,
      decoration: decoration,
      builder: builder,
      semanticLabel: semanticLabel,
      deduplicationKey: deduplicationKey,
    );
    return HoraiAlertHost.dispatch(context, _core, data);
  }

  /// Shows a success alert with HORAI defaults.
  bool success({
    required BuildContext context,
    required String message,
    String? title,
  }) => show(
    context: context,
    type: HoraiAlertType.success,
    title: title,
    message: message,
  );

  /// Shows an error alert with HORAI defaults.
  bool error({
    required BuildContext context,
    required String message,
    String? title,
  }) => show(
    context: context,
    type: HoraiAlertType.error,
    title: title,
    message: message,
  );

  /// Shows a warning alert with HORAI defaults.
  bool warning({
    required BuildContext context,
    required String message,
    String? title,
  }) => show(
    context: context,
    type: HoraiAlertType.warning,
    title: title,
    message: message,
  );

  /// Shows an informational alert with HORAI defaults.
  bool info({
    required BuildContext context,
    required String message,
    String? title,
  }) => show(
    context: context,
    type: HoraiAlertType.info,
    title: title,
    message: message,
  );
}
