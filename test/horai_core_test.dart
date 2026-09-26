import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horai_core/horai_core.dart';

void main() {
  group('HoraiCoreConfig', () {
    test('uses development and HORAI theme defaults', () {
      const config = HoraiCoreConfig();

      expect(config.environment, HoraiEnvironment.development);
      expect(
        config.alertConfig.effectiveTheme
            .colorsFor(HoraiAlertType.success)
            .border,
        const Color(0xFF00CFA5),
      );
    });

    test('keeps configuration isolated per HoraiCore instance', () {
      final development = HoraiCore();
      final production = HoraiCore(
        config: HoraiCoreConfig(environment: HoraiEnvironment.production),
      );

      expect(development.config.environment, HoraiEnvironment.development);
      expect(production.config.environment, HoraiEnvironment.production);
    });
  });

  group('HoraiAlertTheme', () {
    test('returns the palette for each alert type', () {
      final theme = HoraiAlertTheme.horai();

      expect(theme.colorsFor(HoraiAlertType.success), same(theme.success));
      expect(theme.colorsFor(HoraiAlertType.error), same(theme.error));
      expect(theme.colorsFor(HoraiAlertType.warning), same(theme.warning));
      expect(theme.colorsFor(HoraiAlertType.info), same(theme.info));
    });

    test('copies a palette with only requested overrides', () {
      const original = HoraiAlertColors(
        background: Color(0xFF000000),
        foreground: Color(0xFFFFFFFF),
        border: Color(0xFF111111),
        icon: Color(0xFF222222),
        title: Color(0xFF333333),
        message: Color(0xFF444444),
        action: Color(0xFF555555),
      );

      final customized = original.copyWith(icon: Color(0xFFABCDEF));

      expect(customized.icon, const Color(0xFFABCDEF));
      expect(customized.background, original.background);
      expect(customized.title, original.title);

      final complete = original.copyWith(
        background: const Color(0xFF000001),
        foreground: const Color(0xFF000002),
        border: const Color(0xFF000003),
        icon: const Color(0xFF000004),
        title: const Color(0xFF000005),
        message: const Color(0xFF000006),
        action: const Color(0xFF000007),
      );
      expect(complete.background, const Color(0xFF000001));
      expect(complete.foreground, const Color(0xFF000002));
      expect(complete.border, const Color(0xFF000003));
      expect(complete.icon, const Color(0xFF000004));
      expect(complete.title, const Color(0xFF000005));
      expect(complete.message, const Color(0xFF000006));
      expect(complete.action, const Color(0xFF000007));
    });
  });
}
