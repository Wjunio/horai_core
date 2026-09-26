import 'package:flutter_test/flutter_test.dart';
import 'package:horai_core/horai_core.dart';

void main() {
  group('HoraiLogSanitizer', () {
    final sanitizer = HoraiLogSanitizer(sensitiveKeys: {'private_code'});

    test('redacts sensitive nested fields case-insensitively', () {
      final sanitized =
          sanitizer.sanitizeValue({
                'PASSWORD': 'pw',
                'user': {
                  'token': 'access',
                  'Authorization': 'Bearer refresh',
                  'items': [
                    {'private_code': 'custom'},
                  ],
                },
              })!
              as Map<String, Object?>;
      final user = sanitized['user']! as Map<String, Object?>;
      final items = user['items']! as List<Object?>;

      expect(sanitized['PASSWORD'], '[REDACTED]');
      expect(user['token'], '[REDACTED]');
      expect(user['Authorization'], '[REDACTED]');
      expect(
        (items.single! as Map<String, Object?>)['private_code'],
        '[REDACTED]',
      );
    });

    test('redacts assignments and bearer credentials in free-form text', () {
      final text = sanitizer.sanitizeText(
        'PASSWORD=hunter2 Authorization: Bearer abc.secret token="xyz"',
      );

      expect(text, isNot(contains('hunter2')));
      expect(text, isNot(contains('abc.secret')));
      expect(text, isNot(contains('xyz')));
      expect(text, contains('[REDACTED]'));

      final customAndPersonal = sanitizer.sanitizeText(
        'private_code=custom-secret cpf=12345678901 email=user@example.test',
      );
      expect(customAndPersonal, isNot(contains('custom-secret')));
      expect(customAndPersonal, isNot(contains('12345678901')));
      expect(customAndPersonal, isNot(contains('user@example.test')));
    });

    test('marks cyclic values and does not call arbitrary toString', () {
      final cyclic = <String, Object?>{};
      cyclic['self'] = cyclic;

      final sanitized =
          sanitizer.sanitizeValue({'cycle': cyclic, 'object': _SecretObject()})!
              as Map<String, Object?>;
      final cycle = sanitized['cycle']! as Map<String, Object?>;

      expect(cycle['self'], '[CIRCULAR]');
      expect(sanitized['object'], '[UNSUPPORTED]');
    });
  });

  group('HoraiLogger', () {
    test('uses safe defaults by environment', () {
      final development = HoraiCore().logger;
      final production = HoraiCore(
        config: const HoraiCoreConfig(environment: HoraiEnvironment.production),
      ).logger;

      expect(development.config.output, HoraiLogOutput.console);
      expect(production.config.output, HoraiLogOutput.none);
      expect(production.config.minimumLevel, HoraiLogLevel.warning);
    });

    test('sends sanitized structured entries to a custom sink', () {
      final sink = MemoryLogSink();
      final logger = HoraiLogger(
        config: const HoraiLoggerConfig(output: HoraiLogOutput.none),
        sinks: [sink],
      );

      logger.info(
        'Authorization: Bearer secret-value',
        context: 'AuthRepository',
        metadata: {'access_token': 'private-token', 'attempt': 2},
      );

      final entry = sink.entries.single;
      expect(entry.level, HoraiLogLevel.info);
      expect(entry.context, 'AuthRepository');
      expect(entry.message, isNot(contains('secret-value')));
      expect(entry.metadata['access_token'], '[REDACTED]');
      expect(entry.metadata['attempt'], 2);
      expect(entry.timestamp.isUtc, isTrue);
      expect(entry.environment, 'development');
    });

    test('records the owning core environment on each log entry', () {
      final sink = MemoryLogSink();
      final logger = HoraiLogger(
        config: const HoraiLoggerConfig(output: HoraiLogOutput.none),
        environment: HoraiEnvironment.staging,
        sinks: [sink],
      );

      logger.info('staging event');

      expect(sink.entries.single.environment, 'staging');
    });

    test('does no work when disabled or filtered', () {
      final sink = MemoryLogSink();
      final disabled = HoraiLogger(
        config: const HoraiLoggerConfig(
          enabled: false,
          output: HoraiLogOutput.none,
        ),
        sinks: [sink],
      );
      final filtered = HoraiLogger(
        config: const HoraiLoggerConfig(
          minimumLevel: HoraiLogLevel.error,
          output: HoraiLogOutput.none,
        ),
        sinks: [sink],
      );

      disabled.error('disabled');
      filtered.info('below threshold');

      expect(sink.entries, isEmpty);
    });

    test('continues after a sink throws and calls the failure handler', () {
      var reported = false;
      final nextSink = MemoryLogSink();
      final logger = HoraiLogger(
        config: const HoraiLoggerConfig(output: HoraiLogOutput.none),
        sinks: [_ThrowingSink(), nextSink],
        onSinkError: (sink, error, stackTrace) => reported = true,
      );

      expect(() => logger.error('operation failed'), returnsNormally);
      expect(reported, isTrue);
      expect(nextSink.entries, hasLength(1));
    });

    test('memory sink retains only its configured capacity', () {
      final sink = MemoryLogSink(maxEntries: 2);
      final logger = HoraiLogger(
        config: const HoraiLoggerConfig(output: HoraiLogOutput.none),
        sinks: [sink],
      );

      logger.info('one');
      logger.info('two');
      logger.info('three');

      expect(sink.entries.map((entry) => entry.message), ['two', 'three']);
    });
  });
}

class _SecretObject {
  @override
  String toString() => 'should-not-be-called';
}

class _ThrowingSink implements HoraiLogSink {
  @override
  void write(HoraiLogEntry entry) => throw StateError('sink failure');
}
