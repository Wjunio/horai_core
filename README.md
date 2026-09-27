# HORAI CORE

Alertas configuráveis e logging estruturado para Flutter. O package é independente de roteadores e gerenciadores de estado; cada `HoraiCore` mantém sua própria configuração.

## Compatibilidade

- Dart `^3.13.0`
- Flutter `>=3.47.0`

A faixa foi definida com base no ambiente estável usado no desenvolvimento (Flutter 3.47.5, Dart 3.13.4).

## Instalação

Adicione o package ao seu projeto Flutter:

```sh
flutter pub add horai_core
```

Depois, importe a API pública:

```dart
import 'package:horai_core/horai_core.dart';
```

Durante o desenvolvimento local deste repositório, use uma dependência `path`:

```yaml
dependencies:
	horai_core:
		path: ../horai_core
```

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

## Demonstração

### Alertas

![Alerta de sucesso](https://raw.githubusercontent.com/Wjunio/horai_core/main/doc/screenshots/alert-sucesso.png)
![Alerta de erro](https://raw.githubusercontent.com/Wjunio/horai_core/main/doc/screenshots/alert-error.png)
![Alerta de aviso](https://raw.githubusercontent.com/Wjunio/horai_core/main/doc/screenshots/alert_warning.png)
![Alerta em diálogo](https://raw.githubusercontent.com/Wjunio/horai_core/main/doc/screenshots/alert-dialog-error.png)

### Console de logs

![Console de logs do HORAI](https://raw.githubusercontent.com/Wjunio/horai_core/main/doc/screenshots/console.log.png)

## Licença

Distribuído sob a licença MIT. Consulte o arquivo `LICENSE`.

## Para mantenedores

Antes de publicar uma nova versão, execute as validações na raiz do package:

```sh
dart format .
flutter analyze
flutter test
dart pub publish --dry-run
```

Se a simulação terminar sem warnings, atualize a versão em `pubspec.yaml`, registre a versão e as mudanças em `CHANGELOG.md` e publique:

```sh
dart pub publish
```

O comando solicitará confirmação e autenticação no pub.dev quando necessário. A publicação de uma versão é permanente; versões já publicadas não podem ser reutilizadas.
