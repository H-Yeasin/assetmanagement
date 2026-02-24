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
import 'package:anick_giroux/Home_Vault/vault_screen.dart';
import 'package:anick_giroux/Home_Profile/profile_screen.dart';
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
      builder: (BuildContext context, GoRouterState state) => const SplashScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeDashboardScreen(),
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
      path: '/main', // Fallback for direct MainShell navigation if used previously
      builder: (context, state) => const MainShell(child: HomeDashboardScreen()), 
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
          initialDocuments: extra?['initialDocuments'] as List<Map<String, dynamic>>?,
        );
      },
    ),
  ],
);
