class AppConfig {
  const AppConfig._();

  // ===========================================================================
  // VAULT SUBSCRIPTION CONFIGURATION
  // ===========================================================================

  /// Set to `true` to skip all subscription checks (dev/debug mode).
  /// Set to `false` to strictly enforce subscriptions in production.
  static const bool bypassVaultSubscription = bool.fromEnvironment(
    'BYPASS_VAULT_SUBSCRIPTION',
    defaultValue: false,
  );

  /// Enables Firebase App Check token generation for Firebase services.
  ///
  /// Keep this enabled for production. For local emulator/debug testing, set
  /// `USE_FIREBASE_APP_CHECK=false` if the device's App Check provider is
  /// failing before OTP Cloud Functions can be called.
  static const bool useFirebaseAppCheck = bool.fromEnvironment(
    'USE_FIREBASE_APP_CHECK',
    defaultValue: false,
  );

  // ── RevenueCat API Keys ─────────────────────────────────────────────────

  /// Default RevenueCat API key used when no `--dart-define` override is set.
  ///
  /// **Important:** This is a test/development key. Replace with your production
  /// key before shipping to the App Store / Google Play.
  ///
  /// The key is only used as a fallback — `--dart-define` takes precedence:
  /// ```sh
  /// flutter run --dart-define=RC_API_KEY=test_UWshnmVmdrmAtFWWZLaSJJgMiQW
  /// ```
  static const String _defaultRcApiKey = 'test_UWshnmVmdrmAtFWWZLaSJJgMiQW';

  /// Unified RevenueCat API key (works across both platforms in RevenueCat v5+).
  ///
  /// Falls back to [_defaultRcApiKey] when no `--dart-define` is provided, so
  /// the SDK always has a key during development.
  static const String rcApiKey = String.fromEnvironment(
    'RC_API_KEY',
    defaultValue: _defaultRcApiKey,
  );

  /// Platform-specific: Apple (App Store) API key.
  ///
  /// Only used when the unified [rcApiKey] is empty AND this key is set.
  static const String revenueCatAppleApiKey = String.fromEnvironment(
    'RC_APPLE_API_KEY',
    defaultValue: '',
  );

  /// Platform-specific: Google (Play Store) API key.
  ///
  /// Only used when the unified [rcApiKey] is empty AND this key is set.
  static const String revenueCatGoogleApiKey = String.fromEnvironment(
    'RC_GOOGLE_API_KEY',
    defaultValue: '',
  );

  // ── Entitlement & Products ──────────────────────────────────────────────

  /// The RevenueCat entitlement identifier that gates vault access.
  ///
  /// Must match the entitlement key configured in the RevenueCat dashboard
  /// (RevenueCat Dashboard → Entitlements).
  ///
  /// The default `'ffpvaultapp_pro'` corresponds to the "FFP Vault Pro"
  /// entitlement. Change it via `--dart-define` if your dashboard uses a
  /// different key:
  /// ```sh
  /// flutter run --dart-define=RC_VAULT_ENTITLEMENT_ID=your_entitlement_key
  /// ```
  static const String vaultEntitlementId = String.fromEnvironment(
    'RC_VAULT_ENTITLEMENT_ID',
    defaultValue: 'ffpvaultapp_pro',
  );

  /// The RevenueCat offering identifier to fetch.
  ///
  /// RevenueCat supports multiple offerings (e.g. "default", "promo", "sale").
  /// Leave empty to use the current default offering from the dashboard.
  ///
  /// Set via `--dart-define=RC_OFFERING_ID=your_offering_id`.
  static const String rcOfferingId = String.fromEnvironment(
    'RC_OFFERING_ID',
    defaultValue: '',
  );

  /// The product/package identifiers your app expects within an offering.
  ///
  /// These must match the package identifiers configured in your RevenueCat
  /// offering (RevenueCat Dashboard → Offerings → Packages).
  static const String monthlyPackageId = 'monthly';

  /// Human-readable plan name shown in the UI.
  static const String planName = 'FFP Vault Pro';

  /// Default plan price (in USD cents) shown when the offering hasn't loaded.
  static const int defaultPlanAmountCents = 699;
  static const String defaultPlanCurrency = 'usd';

  // ── Paywall ─────────────────────────────────────────────────────────────

  /// Controls which purchase UI is presented to the user.
  ///
  /// `false` (default) — Your custom-branded [ChoosePaymentScreen].
  /// `true`  — RevenueCat's native paywall via [RCPaywallScreen].
  ///
  /// Both options use RevenueCat under the hood for purchase processing.
  static const bool useRevenueCatPaywall = bool.fromEnvironment(
    'USE_REVENUECAT_PAYWALL',
    defaultValue: false,
  );

  /// Whether to enable RevenueCat's Customer Center for subscription management.
  ///
  /// When `true`, the "Manage Subscription" flow opens RevenueCat's native
  /// Customer Center (requires `purchases_flutter` ≥ 10.5.0).
  ///
  /// When `false` (or when the SDK version doesn't support it), the app falls
  /// back to the platform subscription settings URL.
  static const bool useCustomerCenter = bool.fromEnvironment(
    'USE_CUSTOMER_CENTER',
    defaultValue: true,
  );
}
