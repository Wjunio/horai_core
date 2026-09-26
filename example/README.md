# HORAI CORE Example

Run the interactive example from this directory:

```sh
flutter pub get
flutter run -d chrome
```

The app demonstrates alert channels and positioning, custom colors, environment-specific logger defaults, and the in-app log console.

Run the end-to-end Android integration suite with an available emulator:

```sh
flutter test integration_test/horai_core_flow_test.dart -d emulator-5554
```
