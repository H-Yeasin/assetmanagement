import 'package:anick_giroux/Home_Profile/subscription/subscription_plan_screen.dart';
import 'package:anick_giroux/Home_Profile/subscription/choose_payment_screen.dart';
import 'package:anick_giroux/Home_Profile/subscription/payment_status_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:anick_giroux/Splash_Screen/splash_screen.dart';
import 'package:anick_giroux/Loan_Screen/my_loans_screen.dart';
import 'package:anick_giroux/Loan_Screen/add_loan_screen.dart';
import 'package:anick_giroux/Loan_Screen/upcoming_actions_screen.dart';
import 'package:anick_giroux/Loan_Screen/completed_loans_screen.dart';
import 'package:anick_giroux/Loan_Screen/loan_detail_screen.dart';
import 'package:anick_giroux/Loan_Screen/add_documents_screen.dart';
import 'package:anick_giroux/Home_Dashboard/main_shell.dart';
import 'package:anick_giroux/Home_Dashboard/home_dashboard.dart';
import 'package:anick_giroux/Home_Dashboard/upcoming_reminders_screen.dart';
import 'package:anick_giroux/Home_Vault/vault_screen.dart';
import 'package:anick_giroux/Home_Vault/vault_category_screen.dart';
import 'package:anick_giroux/Home_Vault/vault_subfolder_screen.dart';
import 'package:anick_giroux/Home_Vault/vault_edit_folder_screen.dart';
import 'package:anick_giroux/Home_Vault/vault_create_subfolder_screen.dart';
import 'package:anick_giroux/Home_Profile/profile_screen.dart';
import 'package:anick_giroux/Home_Profile/edit_profile_screen.dart';
import 'package:anick_giroux/Home_Profile/data_security_screen.dart';
import 'package:anick_giroux/Home_Profile/fingerprint_screen.dart';
import 'package:anick_giroux/Home_Profile/set_pin_screen.dart';
import 'package:anick_giroux/Home_Profile/pincode_locked_screen.dart';
import 'package:anick_giroux/Home_Profile/two_factor_screen.dart';
import 'package:anick_giroux/Home_Profile/two_factor_email_screen.dart';
import 'package:anick_giroux/Home_Profile/two_factor_otp_screen.dart';
import 'package:anick_giroux/Home_Profile/faq_screen.dart';
import 'package:anick_giroux/Home_Profile/change_password_screen.dart';
import 'package:anick_giroux/Home_Profile/delete_account_screen.dart';
import 'package:anick_giroux/Home_Profile/fingerprint_success_screen.dart';
import 'package:anick_giroux/Home_Profile/pin_verify_screen.dart';
import 'package:anick_giroux/Home_Dashboard/past_activities.dart';
import 'package:anick_giroux/Loan_Screen/additional_details.dart';
import 'package:anick_giroux/Loan_Screen/upcoming_payments.dart';
import 'package:anick_giroux/Loan_Screen/models/loan_model.dart';
import 'package:anick_giroux/Housing_Living_cost/housing_costs_screen.dart';
import 'package:anick_giroux/Housing_Living_cost/add_housing_cost_screen.dart';
import 'package:anick_giroux/Housing_Living_cost/housing_cost_detail_screen.dart';
import 'package:anick_giroux/Housing_Living_cost/models/housing_cost_model.dart';
import 'package:anick_giroux/Insurance/my_insurances_screen.dart';
import 'package:anick_giroux/Insurance/insurance_detail_screen.dart';
import 'package:anick_giroux/Insurance/add_insurance_screen.dart';
import 'package:anick_giroux/Insurance/insurance_additional_details_screen.dart';
import 'package:anick_giroux/Insurance/edit_insurance_screen.dart';
import 'package:anick_giroux/Insurance/insurance_add_documents_screen.dart';
import 'package:anick_giroux/Insurance/insurance_upcoming_actions_screen.dart';
import 'package:anick_giroux/Insurance/models/insurance_model.dart';
import 'package:anick_giroux/Authentication/forgot_password.dart';
import 'package:anick_giroux/Authentication/verification_code.dart';
import 'package:anick_giroux/Authentication/reset_password.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  routes: <RouteBase>[
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
          builder: (context, state) => const VaultScreen(),
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
      ],
    ),
    GoRoute(
      path: '/data-security',
      builder: (context, state) => const DataSecurityScreen(),
    ),
    GoRoute(
      path: '/subscription-plan',
      builder: (context, state) => const SubscriptionPlanScreen(),
    ),
    GoRoute(
      path: '/choose-payment',
      builder: (context, state) => const ChoosePaymentScreen(),
    ),
    GoRoute(
      path: '/payment-success',
      builder: (context, state) => const PaymentStatusScreen(isSuccess: true),
    ),
    GoRoute(
      path: '/payment-failed',
      builder: (context, state) => const PaymentStatusScreen(isSuccess: false),
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
      builder: (context, state) => const SetPinScreen(),
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
      path: '/upcoming-reminders',
      builder: (context, state) => const UpcomingRemindersScreen(),
    ),
    GoRoute(
      path: '/upcoming-payments',
      builder: (context, state) => const UpcomingPaymentsScreen(),
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
      builder: (context, state) =>
          MainShell(child: HomeDashboardScreen()),
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
    GoRoute(
      path: '/vault-category',
      builder: (context, state) {
        final categoryName = state.extra as String;
        return VaultCategoryScreen(categoryName: categoryName);
      },
    ),
    GoRoute(
      path: '/vault-subfolder',
      builder: (context, state) {
        final folderName = state.extra as String;
        return VaultSubfolderScreen(folderName: folderName);
      },
    ),
    GoRoute(
      path: '/vault-edit-folder',
      builder: (context, state) {
        final folderName = state.extra as String;
        return VaultEditFolderScreen(folderName: folderName);
      },
    ),
    GoRoute(
      path: '/vault-create-subfolder',
      builder: (context, state) {
        final categoryName = state.extra as String;
        return VaultCreateSubfolderScreen(categoryName: categoryName);
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
