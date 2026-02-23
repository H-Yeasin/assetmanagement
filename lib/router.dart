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
// other screens to be imported later.

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  routes: <RouteBase>[
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
      path: '/main', // Fallback for direct MainShell navigation if used previously
      builder: (context, state) => const MainShell(child: HomeDashboardScreen()), 
    ),
  ],
);
