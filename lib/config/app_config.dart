class AppConfig {
  const AppConfig._();

  static const bool bypassVaultSubscription = bool.fromEnvironment(
    'BYPASS_VAULT_SUBSCRIPTION',
    defaultValue: false,
  );
}
