class AppConfig {
  const AppConfig._();

  // ===========================================================================
  // VAULT SUBSCRIPTION CONFIGURATION
  // ===========================================================================
  // Toggle this flag to easily switch between development and production modes:
  //
  // DEVELOPMENT MODE: Set to `true` to skip subscription checks.
  // PRODUCTION MODE: Set to `false` to strictly enforce subscriptions.
  static const bool bypassVaultSubscription = bool.fromEnvironment(
    'BYPASS_VAULT_SUBSCRIPTION',
    defaultValue: true, // <-- Toggle this value (true for dev, false for prod)
  );
}
