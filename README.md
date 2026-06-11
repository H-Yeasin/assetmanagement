# FFP Vault — Financial Freedom Power

A Flutter mobile application for organizing your finances with clarity and confidence. Track loans, housing costs, and insurance policies in one secure, private vault.

## Features

### Loan Management
- Add and manage multiple loan types: car, business, personal, family, credit resolving, condo, farm/villa, and custom loans
- Track amortization schedules, payment timelines, and upcoming actions
- View completed loans and past activities
- Attach and manage documents per loan

### Housing & Living Costs
- Record housing costs with detailed property information
- Track property taxes, payment timelines, and additional details
- Document storage for housing-related files

### Insurance Tracking
- Manage insurance policies with provider details, coverage dates, and premiums
- Payment timeline visualization and upcoming action reminders
- Document uploads per policy

### Secure Vault
- Encrypted document storage organized by categories and subfolders
- PIN and biometric (fingerprint) access gate with session timeouts
- Create, edit, and manage folders and subfolders
- Upload, download, share, and delete files

### Security & Privacy
- Two-factor authentication (email OTP)
- PIN code lock with session management
- Biometric/fingerprint authentication
- Data security controls
- Account deletion with confirmation

### Subscription & Payments
- Stripe-integrated subscription plans
- Payment sheet with multiple payment methods

### Notifications
- Local notifications for payment reminders
- Firebase Cloud Messaging (FCM) for push notifications

## Tech Stack

| Layer          | Technology                                                    |
| -------------- | ------------------------------------------------------------- |
| Framework      | Flutter (SDK ^3.10.4)                                         |
| Routing        | GoRouter                                                      |
| State Management | Riverpod                                                    |
| Local Storage  | Hive (with Hive Generator), Flutter Secure Storage            |
| Backend        | Firebase (Auth, Firestore, Storage, Cloud Functions, App Check, Messaging) |
| Authentication | Firebase Auth (Email/Password, Google Sign-In, Sign in with Apple) |
| Payments       | Stripe (flutter_stripe)                                       |
| Notifications  | flutter_local_notifications, FCM                              |
| Biometrics     | local_auth                                                    |
| Calendar       | table_calendar                                                |

## Project Structure

```
lib/
├── Authentication/       # Login, sign-up, forgot/reset password, OTP verification
├── Home_Dashboard/       # Main dashboard, upcoming reminders, past activities, widgets
├── Home_Profile/         # Profile, edit profile, security, PIN, 2FA, fingerprint, subscription
├── Home_Vault/           # Vault access gate, category/folder management, session handling
├── Housing_Living_cost/  # Housing cost CRUD, details, payment timeline, documents
├── Insurance/            # Insurance CRUD, details, payment timeline, documents
├── Loan_Screen/          # Loan CRUD, categories, details, amortization, payment timeline
├── Onbording_Screen/     # Onboarding flow
├── Splash_Screen/        # Splash screen
├── providers/            # Riverpod providers
├── services/             # Auth, loan, housing, insurance, vault, storage, biometric, notification, subscription services
├── shared/               # Shared widgets and helpers
├── app.dart              # App entry widget
├── main.dart             # Main entry point
├── router.dart           # GoRouter configuration
└── firebase_options.dart # Firebase configuration
```

## Getting Started

### Prerequisites

- Flutter SDK ^3.10.4
- Firebase project (see `.firebaserc` — project: `ffp-vault-app`)
- Android Studio or VS Code
- A device or emulator running Android/iOS

### Setup

1. **Clone the repository**

   ```bash
   git clone <repo-url>
   cd anick_giroux_frontend
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Configure Firebase**

   Ensure `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are placed in the correct directories. The `firebase_options.dart` file should match your Firebase project configuration.

4. **Run code generation**

   ```bash
   dart run build_runner build
   ```

5. **Run the app**

   ```bash
   flutter run
   ```

### Stripe Configuration

The app uses Stripe for subscription payments. Ensure the Stripe publishable key is configured via the `SubscriptionService`.

## Environment Variables & Configuration

- Firebase project: `ffp-vault-app`
- Stripe URL scheme: `ffpvault`
- App Check: Debug provider enabled for development

## Building

### Android

```bash
flutter build apk --release
# or
flutter build appbundle --release
```

## Contributing

This project follows standard Flutter conventions. Please ensure code generation is up to date before submitting changes:

```bash
dart run build_runner build
```

## License

Private — All rights reserved.
