import 'package:flutter/material.dart';

import '../core/horai_core.dart';
import 'horai_alert_colors.dart';
import 'horai_alert_type.dart';

/// Instance-bound API for confirmation dialogs.
class HoraiConfirmation {
  /// Creates a confirmation API bound to [core].
  HoraiConfirmation(HoraiCore core) : _core = core;

  final HoraiCore _core;

  /// Shows a confirmation dialog and returns `true` for confirm, `false` for
  /// cancel, or `null` when dismissed without choosing an action.
  ///
  /// Titles, messages, and button labels have Portuguese defaults for each
  /// [type] and can be replaced per call.
  Future<bool?> show({
    required BuildContext context,
    HoraiAlertType type = HoraiAlertType.warning,
    String? title,
    String? message,
    String? confirmLabel,
    String? cancelLabel,
    bool? showCancelButton,
    bool barrierDismissible = true,
  }) {
    final defaults = _confirmationDefaults(type);
    final colors = _core.config.alertConfig.effectiveTheme.colorsFor(type);

    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: const Color(0xB8001012),
      builder: (_) => _HoraiConfirmationDialog(
        type: type,
        title: title ?? defaults.title,
        message: message ?? defaults.message,
        confirmLabel: confirmLabel ?? defaults.confirmLabel,
        cancelLabel: cancelLabel ?? defaults.cancelLabel,
        showCancelButton: showCancelButton ?? defaults.cancelLabel != null,
        colors: colors,
      ),
    );
  }
}

class _ConfirmationDefaults {
  const _ConfirmationDefaults({
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.cancelLabel,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String? cancelLabel;
}

_ConfirmationDefaults _confirmationDefaults(HoraiAlertType type) =>
    switch (type) {
      HoraiAlertType.success => const _ConfirmationDefaults(
        title: 'Sucesso!',
        message: 'Sua operação foi concluída com êxito. O que você fez agora já está salvo no sistema.',
        confirmLabel: 'Entendi',
      ),
      HoraiAlertType.error => const _ConfirmationDefaults(
        title: 'Ops! Algo deu errado.',
        message: 'Não foi possível concluir sua solicitação. Tente novamente em instantes ou entre em contato com o suporte.',
        confirmLabel: 'Tentar novamente',
        cancelLabel: 'Fechar',
      ),
      HoraiAlertType.warning => const _ConfirmationDefaults(
        title: 'Atenção!',
        message: 'Essa ação pode causar a perda de dados não salvos. Deseja continuar mesmo assim?',
        confirmLabel: 'Continuar',
        cancelLabel: 'Cancelar',
      ),
      HoraiAlertType.info => const _ConfirmationDefaults(
        title: 'Informação',
        message: 'Este é um lembrete importante para você continuar com a melhor experiência no aplicativo.',
        confirmLabel: 'Ok',
      ),
    };

class _HoraiConfirmationDialog extends StatelessWidget {
  const _HoraiConfirmationDialog({
    required this.type,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.showCancelButton,
    required this.colors,
  });

  final HoraiAlertType type;
  final String title;
  final String message;
  final String confirmLabel;
  final String? cancelLabel;
  final bool showCancelButton;
  final HoraiAlertColors colors;

  IconData get _icon => switch (type) {
    HoraiAlertType.success => Icons.check_rounded,
    HoraiAlertType.error => Icons.close_rounded,
    HoraiAlertType.warning => Icons.warning_amber_rounded,
    HoraiAlertType.info => Icons.info_outline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final darkSurface = Color.lerp(colors.background, Colors.black, 0.48)!;
    final radius = BorderRadius.circular(22);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 380,
          maxHeight: MediaQuery.sizeOf(context).height * 0.82,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: darkSurface,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(colors.background, Colors.white, 0.08)!,
                darkSurface,
              ],
            ),
            border: Border.all(color: colors.border, width: 1),
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: colors.border.withValues(alpha: 0.2),
                blurRadius: 28,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      tooltip: 'Fechar',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      color: const Color(0xFF9BB7C8),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  _StatusIcon(icon: _icon, color: colors.icon),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colors.title,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: colors.message, height: 1.45),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(context).pop(true),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: Text(confirmLabel, textAlign: TextAlign.center),
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.border,
                        foregroundColor: const Color(0xFF001416),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  if (showCancelButton) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.action,
                          side: BorderSide(color: colors.border),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(cancelLabel ?? 'Cancelar'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 22),
        ],
      ),
      child: Center(
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2.5),
          ),
          child: Icon(icon, color: color, size: 36),
        ),
      ),
    );
  }
}
