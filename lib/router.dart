import 'package:ffp_vault/Home_Profile/subscription/subscription_plan_screen.dart';
import 'package:ffp_vault/Home_Profile/subscription/choose_payment_screen.dart';
import 'package:ffp_vault/Home_Profile/subscription/rc_paywall_screen.dart';
import 'package:ffp_vault/Home_Profile/subscription/payment_status_screen.dart';
import 'package:ffp_vault/Home_Profile/subscription/models/subscription_confirmation.dart';
import 'package:ffp_vault/config/app_config.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ffp_vault/Splash_Screen/splash_screen.dart';
import 'package:ffp_vault/Loan_Screen/my_loans_screen.dart';
import 'package:ffp_vault/Loan_Screen/add_loan_screen.dart';
import 'package:ffp_vault/Loan_Screen/upcoming_actions_screen.dart';
import 'package:ffp_vault/Loan_Screen/completed_loans_screen.dart';
import 'package:ffp_vault/Loan_Screen/loan_detail_screen.dart';
import 'package:ffp_vault/Loan_Screen/loan_payment_timeline_screen.dart';
import 'package:ffp_vault/Loan_Screen/add_documents_screen.dart';
import 'package:ffp_vault/Home_Dashboard/main_shell.dart';
import 'package:ffp_vault/Home_Dashboard/home_dashboard.dart';
import 'package:ffp_vault/Home_Dashboard/upcoming_reminders_screen.dart';
import 'package:ffp_vault/Home_Vault/vault_screen.dart';
import 'package:ffp_vault/Home_Vault/vault_category_screen.dart';
import 'package:ffp_vault/Home_Vault/vault_subfolder_screen.dart';
import 'package:ffp_vault/Home_Vault/vault_edit_folder_screen.dart';
import 'package:ffp_vault/Home_Vault/vault_create_subfolder_screen.dart';
import 'package:ffp_vault/Home_Vault/vault_access_gate.dart';

import 'package:ffp_vault/Home_Profile/profile_screen.dart';
import 'package:ffp_vault/Home_Profile/edit_profile_screen.dart';
import 'package:ffp_vault/Home_Profile/data_security_screen.dart';
import 'package:ffp_vault/Home_Profile/fingerprint_screen.dart';
import 'package:ffp_vault/Home_Profile/set_pin_screen.dart';
import 'package:ffp_vault/Home_Profile/pincode_locked_screen.dart';
import 'package:ffp_vault/Home_Profile/two_factor_screen.dart';
import 'package:ffp_vault/Home_Profile/two_factor_email_screen.dart';
import 'package:ffp_vault/Home_Profile/two_factor_otp_screen.dart';
import 'package:ffp_vault/Home_Profile/faq_screen.dart';
import 'package:ffp_vault/Home_Profile/change_password_screen.dart';
import 'package:ffp_vault/Home_Profile/delete_account_screen.dart';
import 'package:ffp_vault/Home_Profile/fingerprint_success_screen.dart';
import 'package:ffp_vault/Home_Profile/pin_verify_screen.dart';
import 'package:ffp_vault/Home_Dashboard/past_activities.dart';
import 'package:ffp_vault/Loan_Screen/additional_details.dart';
import 'package:ffp_vault/Loan_Screen/upcoming_payments.dart';
import 'package:ffp_vault/Loan_Screen/models/loan_model.dart';
import 'package:ffp_vault/Housing_Living_cost/housing_costs_screen.dart';
import 'package:ffp_vault/Housing_Living_cost/add_housing_cost_screen.dart';
import 'package:ffp_vault/Housing_Living_cost/housing_cost_detail_screen.dart';
import 'package:ffp_vault/Housing_Living_cost/housing_payment_timeline_screen.dart';
import 'package:ffp_vault/Housing_Living_cost/models/housing_cost_model.dart';
import 'package:ffp_vault/Insurance/my_insurances_screen.dart';
import 'package:ffp_vault/Insurance/insurance_detail_screen.dart';
import 'package:ffp_vault/Insurance/add_insurance_screen.dart';
import 'package:ffp_vault/Insurance/insurance_additional_details_screen.dart';
import 'package:ffp_vault/Insurance/edit_insurance_screen.dart';
import 'package:ffp_vault/Insurance/insurance_add_documents_screen.dart';
import 'package:ffp_vault/Insurance/insurance_payment_timeline_screen.dart';
import 'package:ffp_vault/Insurance/insurance_upcoming_actions_screen.dart';
import 'package:ffp_vault/Insurance/models/insurance_model.dart';
import 'package:ffp_vault/Authentication/forgot_password.dart';
import 'package:ffp_vault/Authentication/verification_code.dart';
import 'package:ffp_vault/Authentication/reset_password.dart';
import 'package:ffp_vault/Authentication/login.dart';
import 'package:ffp_vault/Authentication/sign_in.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(path: '/login', builder: (context, state) => const Login()),
    GoRoute(path: '/signup', builder: (context, state) => const SignIn()),
    GoRoute(
      path: '/insurance-upcoming',
      builder: (context, state) => const InsuranceUpcomingActionsScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) =>
          const SplashScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => HomeDashboardScreen(),
        ),
        GoRoute(
          path: '/my-loans',
          builder: (context, state) => const MyLoansScreen(),
        ),
        GoRoute(
          path: '/vault',
          builder: (context, state) {
            final category = state.extra as String?;
            return VaultAccessGate(
              child: VaultScreen(initialCategory: category),
            );
          },
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/edit-profile',
          builder: (context, state) => const EditProfileScreen(),
        ),

        GoRoute(
          path: '/loan-detail',
          builder: (context, state) {
            final loan = state.extra as Loan;
            return LoanDetailScreen(loan: loan);
          },
        ),
        GoRoute(
          path: '/additional-details',
          builder: (context, state) {
            final loan = state.extra as Loan;
            return AdditionalDetailsScreen(loan: loan);
          },
        ),
        GoRoute(
          path: '/housing-costs',
          builder: (context, state) => const HousingCostsScreen(),
        ),
        GoRoute(
          path: '/housing-cost-detail',
          builder: (context, state) {
            final cost = state.extra as HousingCost;
            return HousingCostDetailScreen(cost: cost);
          },
        ),
        GoRoute(
          path: '/housing-payment-timeline',
          builder: (context, state) =>
              HousingPaymentTimelineScreen(cost: state.extra as HousingCost?),
        ),
        GoRoute(
          path: '/my-insurances',
          builder: (context, state) => const MyInsurancesScreen(),
        ),
        GoRoute(
          path: '/insurance-detail',
          builder: (context, state) {
            final policy = state.extra as InsurancePolicy;
            return InsuranceDetailScreen(policy: policy);
          },
        ),
        GoRoute(
          path: '/insurance-additional-details',
          builder: (context, state) {
            final policy = state.extra as InsurancePolicy;
            return InsuranceAdditionalDetailsScreen(policy: policy);
          },
        ),
        GoRoute(
          path: '/insurance-payment-timeline',
          builder: (context, state) => InsurancePaymentTimelineScreen(
            policy: state.extra as InsurancePolicy?,
          ),
        ),
        GoRoute(
          path: '/upcoming-reminders',
          builder: (context, state) => const UpcomingRemindersScreen(),
        ),
        GoRoute(
          path: '/upcoming-payments',
          builder: (context, state) => const UpcomingPaymentsScreen(),
        ),
        GoRoute(
          path: '/vault-category',
          builder: (context, state) {
            final categoryName = state.extra as String;
            return VaultAccessGate(
              child: VaultCategoryScreen(categoryName: categoryName),
            );
          },
        ),
        GoRoute(
          path: '/vault-subfolder',
          builder: (context, state) {
            final args = state.extra as Map<String, dynamic>? ?? {};
            return VaultAccessGate(
              child: VaultSubfolderScreen(
                folderName: args['folderName'] as String? ?? 'Folder',
                folderId: args['folderId'] as String? ?? '',
                categoryName: args['categoryName'] as String? ?? 'Loans',
              ),
            );
          },
        ),
        GoRoute(
          path: '/vault-edit-folder',
          builder: (context, state) {
            final args = state.extra as Map<String, dynamic>? ?? {};
            return VaultAccessGate(
              child: VaultEditFolderScreen(
                folderName: args['folderName'] as String? ?? 'Folder',
                folderId: args['folderId'] as String? ?? '',
                categoryName: args['categoryName'] as String? ?? 'Loans',
              ),
            );
          },
        ),
        GoRoute(
          path: '/vault-create-subfolder',
          builder: (context, state) {
            final categoryName = state.extra as String;
            return VaultAccessGate(
              child: VaultCreateSubfolderScreen(categoryName: categoryName),
            );
          },
        ),
      ],
    ),
    GoRoute(
      path: '/data-security',
      builder: (context, state) => const DataSecurityScreen(),
    ),
    GoRoute(
      path: '/subscription-plan',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return SubscriptionPlanScreen(
          openedFromVaultGate: extra?['openedFromVaultGate'] == true,
        );
      },
    ),
    GoRoute(
      path: '/choose-payment',
      builder: (context, state) => AppConfig.useRevenueCatPaywall
          ? const RCPaywallScreen()
          : const ChoosePaymentScreen(),
    ),
    GoRoute(
      path: '/payment-success',
      builder: (context, state) {
        final args =
            state.extra as PaymentStatusArgs? ??
            const PaymentStatusArgs(
              isSuccess: true,
              title: 'Payment Successful',
              message:
                  'Welcome to the FFP Vault.\n\nYour subscription is now active and you can start organizing your finances with clarity and confidence.',
              buttonLabel: 'Open the Vault',
            );
        return PaymentStatusScreen(args: args);
      },
    ),
    GoRoute(
      path: '/payment-failed',
      builder: (context, state) {
        final args =
            state.extra as PaymentStatusArgs? ??
            const PaymentStatusArgs(
              isSuccess: false,
              title: 'Payment Failed',
              message: 'We could not complete your payment. Please try again.',
            );
        return PaymentStatusScreen(args: args);
      },
    ),
    GoRoute(
      path: '/change-password',
      builder: (context, state) => const ChangePasswordScreen(),
    ),
    GoRoute(
      path: '/delete-account',
      builder: (context, state) => const DeleteAccountScreen(),
    ),
    GoRoute(
      path: '/fingerprint',
      builder: (context, state) => const FingerprintScreen(),
    ),
    GoRoute(
      path: '/fingerprint-success',
      builder: (context, state) => const FingerprintSuccessScreen(),
    ),
    GoRoute(
      path: '/set-pin',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return SetPinScreen(
          afterSetupRoute: extra?['afterSetupRoute'] as String?,
        );
      },
    ),
    GoRoute(
      path: '/pin-locked',
      builder: (context, state) => const PincodeLocked(),
    ),
    GoRoute(path: '/faq', builder: (context, state) => const FaqScreen()),
    GoRoute(
      path: '/two-factor',
      builder: (context, state) => const TwoFactorScreen(),
    ),
    GoRoute(
      path: '/two-factor-email',
      builder: (context, state) => const TwoFactorEmailScreen(),
    ),
    GoRoute(
      path: '/two-factor-otp',
      builder: (context, state) => const TwoFactorOtpScreen(),
    ),
    GoRoute(
      path: '/pin-verify',
      builder: (context, state) => const PinVerifyScreen(),
    ),
    GoRoute(
      path: '/add-housing-cost',
      builder: (context, state) => const AddHousingCostScreen(),
    ),
    GoRoute(
      path: '/add-loan',
      builder: (context, state) => const AddLoanScreen(),
    ),
    GoRoute(
      path: '/upcoming-actions',
      builder: (context, state) => const UpcomingActionsScreen(),
    ),
    GoRoute(
      path: '/loan-payment-timeline',
      builder: (context, state) =>
          LoanPaymentTimelineScreen(loan: state.extra as Loan?),
    ),
    GoRoute(
      path: '/past-activities',
      builder: (context, state) => const PastActivitiesScreen(),
    ),
    GoRoute(
      path: '/completed-loans',
      builder: (context, state) => const CompletedLoansScreen(),
    ),
    GoRoute(
      path: '/add-documents',
      builder: (context, state) => const AddDocumentsScreen(),
    ),
    GoRoute(
      path: '/add-insurance',
      builder: (context, state) => const AddInsuranceScreen(),
    ),
    GoRoute(
      path:
          '/main', // Fallback for direct MainShell navigation if used previously
      builder: (context, state) => MainShell(child: HomeDashboardScreen()),
    ),
    GoRoute(
      path: '/edit-insurance',
      builder: (context, state) {
        final policy = state.extra as InsurancePolicy;
        return EditInsuranceScreen(policy: policy);
      },
    ),
    GoRoute(
      path: '/insurance-add-documents',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return InsuranceAddDocumentsScreen(
          policy: extra?['policy'] as InsurancePolicy?,
          initialDocuments:
              extra?['initialDocuments'] as List<Map<String, dynamic>>?,
        );
      },
    ),
    // ── Auth flow routes ──────────────────────────────────────────────────────
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPassword(),
    ),
    GoRoute(
      path: '/verify-otp',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return VerificationCodeScreen(
          email: extra['email'] as String? ?? '',
          flow: extra['flow'] as String? ?? 'register',
          initialResendSeconds: extra['initialResendSeconds'] as int? ?? 45,
        );
      },
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return ResetPassword(
          email: extra['email'] as String? ?? '',
          otp: extra['otp'] as String? ?? '',
        );
      },
    ),
  ],
);
