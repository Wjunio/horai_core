# HORAI CORE

Alertas configuráveis e logging estruturado para Flutter. O package é independente de roteadores e gerenciadores de estado; cada `HoraiCore` mantém sua própria configuração.

## Compatibilidade

- Dart `^3.13.0`
- Flutter `>=3.47.0`

A faixa foi definida com base no ambiente estável usado no desenvolvimento (Flutter 3.47.5, Dart 3.13.4).

## Instalação

Depois da publicação, adicione `horai_core` às dependências Flutter. Durante desenvolvimento local, use uma dependência `path` para este repositório.

## Início rápido

```dart
final horai = HoraiCore(
	config: HoraiCoreConfig(
		environment: HoraiEnvironment.development,
		loggerConfig: const HoraiLoggerConfig(output: HoraiLogOutput.both),
	),
);

MaterialApp(
	builder: (context, child) => HoraiAlertHost(
		core: horai,
		child: child ?? const SizedBox.shrink(),
	),
	home: const MyHomePage(),
);
```

Use o `BuildContext` de um widget descendente do host para apresentar alertas:

```dart
horai.alert.success(
	context: context,
	title: 'Sucesso',
	message: 'Operação concluída.',
);

horai.alert.show(
	context: context,
	type: HoraiAlertType.warning,
	message: 'A conexão está instável.',
	presentation: HoraiAlertPresentation.overlay,
	duration: const Duration(seconds: 5),
	actionLabel: 'Tentar novamente',
	onAction: retry,
);
```

## Alertas

Os atalhos `success`, `error`, `warning` e `info` usam as configurações da instância. `show` aceita os canais `toast`, `snackbar`, `overlay` e `dialog`, além de overrides de cores, ícone, decoração, animação, ação e builder.

O `HoraiAlertHost` deve envolver o conteúdo da aplicação, normalmente no `MaterialApp.builder`. Ele mantém a fila por host, descarta contextos após a chamada, pausa timers em background e ajusta a posição a `viewPadding` e teclado. A fila tem limite configurável e a deduplicação pode ser desligada ou baseada em mensagem, tipo/mensagem ou chave própria.

## Tema

HORAI fornece uma paleta teal/emerald por tipo, com cores separadas para fundo, texto, borda, ícone e ação. O tema pode ser substituído por instância ou por alerta:

```dart
final alertTheme = HoraiAlertTheme.horai();
final customSuccess = alertTheme.success.copyWith(
	background: const Color(0xFF102A1F),
	border: const Color(0xFF36D399),
);
```

Use `HoraiCoreConfig(alertConfig: HoraiAlertConfig(theme: ...))` para definir o tema padrão. `HoraiDesignTokens` permite ajustar espaçamento, raios e movimento dos widgets padrão.

## Logger

```dart
horai.logger.info(
	'Usuário carregado',
	context: 'UserRepository',
	metadata: {'userId': 'demo-42'},
);

horai.logger.error(
	'Falha na requisição',
	error: exception,
	stackTrace: stackTrace,
);
```

O logger tem níveis `debug`, `info`, `success`, `warning`, `error` e `fatal`. Em development, o default usa `dart:developer`; staging e production não criam sinks de saída por padrão. A configuração explícita pode selecionar console, screen, ambos ou nenhum.

Para uma console de desenvolvimento, configure `HoraiLogOutput.screen` ou `both` e monte `HoraiLogConsole(sink: horai.logger.screenSink!)` com altura limitada. A console oferece busca, filtro por nível, detalhes, cópia e limpeza. Não a habilite em produção sem uma decisão explícita.

## Segurança

Metadata passa por redaction recursiva antes de chegar aos sinks. Campos padrão incluem senhas, tokens, authorization, cookies, identificadores pessoais e dados bancários comuns; campos adicionais podem ser informados em `HoraiLogSanitizer`. Valores `Bearer` e atribuições sensíveis reconhecidas em texto livre também são redigidos.

O sanitizer reduz exposição acidental, mas não reconhece todo dado pessoal em texto arbitrário. Evite registrar segredos ou objetos sensíveis diretamente. Objetos metadata não suportados são substituídos, ciclos são marcados e sinks customizados recebem entradas já sanitizadas. Falhas em sinks externos não interrompem o logger; fallback em `dart:developer` ocorre automaticamente apenas em development. Configure `onSinkError` para encaminhar falhas em staging/production.

## Testes

```sh
dart format .
flutter analyze
flutter test
flutter test --coverage
```

Execute os testes de integração no Android com um emulador iniciado, a partir da raiz:

```sh
cd example
flutter test integration_test/horai_core_flow_test.dart -d emulator-5554
```

O arquivo `coverage/lcov.info` pode ser usado por ferramentas locais de cobertura. A cobertura é uma métrica complementar; os testes priorizam comportamento, segurança e regressões.

## Arquitetura

`HoraiCore` compõe configuração imutável e módulos independentes. Alertas dependem do `HoraiAlertHost` apenas na camada de apresentação. O logger usa `HoraiLogEntry` e `HoraiLogSink`, sem dependência de widgets ou contexto. A API pública fica em `lib/horai_core.dart`; implementação em `lib/src/`.

## Exemplo

O app em `example/` demonstra ambientes, canais de alerta, tema personalizado e a console visual. Execute `cd example`, `flutter pub get` e `flutter run -d chrome`.

## Licença

Distribuído sob a licença MIT. Consulte o arquivo `LICENSE`.

## Publicação

A licença MIT foi aprovada e o arquivo `LICENSE` existente foi mantido. O repositório e a documentação (README) estão configurados no `pubspec.yaml`. Homepage e issue tracker permanecem sem URL oficial. Não foi feita publicação.
