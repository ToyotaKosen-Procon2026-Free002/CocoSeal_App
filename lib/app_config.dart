class AppConfig {
  const AppConfig._();

  /// 起動時に --dart-define=USE_DEMO_DATA=true を付けると有効になる。
  static const bool useDemoData = bool.fromEnvironment(
    'USE_DEMO_DATA',
    defaultValue: false,
  );
}
