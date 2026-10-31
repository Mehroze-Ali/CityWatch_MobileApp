import 'package:flutter/material.dart';
import 'package:urbanissuesclassifier/screens/onboarding/onboarding_screen.dart';
import 'package:urbanissuesclassifier/screens/onboarding/get_started_screen.dart';
import 'package:urbanissuesclassifier/screens/auth/login_signup_screen.dart';
import 'package:urbanissuesclassifier/screens/citizen/home_dashboard_screen.dart';
import 'package:urbanissuesclassifier/screens/citizen/report_issue_screen.dart';
import 'package:urbanissuesclassifier/screens/citizen/success_screen.dart';
import 'package:urbanissuesclassifier/screens/citizen/issues_history_screen.dart';
import 'package:urbanissuesclassifier/screens/citizen/issue_detail_screen.dart';
import 'package:urbanissuesclassifier/screens/citizen/profile_screen.dart';
import 'package:urbanissuesclassifier/screens/citizen/statistics_screen.dart';
import 'package:urbanissuesclassifier/screens/admin/admin_login_screen.dart';
import 'package:urbanissuesclassifier/screens/admin/admin_dashboard_screen.dart';
import 'package:urbanissuesclassifier/screens/admin/admin_issue_detail_screen.dart';

class AppRoutes {
  // Route names
  static const String onboarding = '/';
  static const String getStarted = '/get-started';
  static const String auth = '/auth';
  static const String home = '/home';
  static const String dashboard = '/dashboard';
  static const String statistics = '/statistics';
  static const String reportIssue = '/report-issue';
  static const String success = '/success';
  static const String issuesHistory = '/issues-history';
  static const String issueDetail = '/issue-detail';
  static const String profile = '/profile';
  static const String adminLogin = '/admin-login';
  static const String adminDashboard = '/admin-dashboard';
  static const String adminIssueDetail = '/admin-issue-detail';

  // Route generator
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case onboarding:
        return _buildRoute(const OnboardingScreen(), settings);
      case getStarted:
        return _buildRoute(const GetStartedScreen(), settings);
      case auth:
        return _buildRoute(const LoginSignupScreen(), settings);
      case dashboard:
        return _buildRoute(const HomeDashboardScreen(), settings);
      case reportIssue:
        return _buildRoute(const ReportIssueScreen(), settings);
      case success:
        return _buildRoute(const SuccessScreen(), settings);
      case issuesHistory:
        return _buildRoute(const IssuesHistoryScreen(), settings);
      case issueDetail:
        return _buildRoute(const IssueDetailScreen(), settings);
      case statistics:
        return _buildRoute(const StatisticsScreen(), settings);
      case profile:
        return _buildRoute(const ProfileScreen(), settings);
      case adminLogin:
        return _buildRoute(const AdminLoginScreen(), settings);
      case adminDashboard:
        return _buildRoute(const AdminDashboardScreen(), settings);
      case adminIssueDetail:
        return _buildRoute(const AdminIssueDetailScreen(), settings);
      default:
        return _buildRoute(
          Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
          settings,
        );
    }
  }

  static PageRouteBuilder _buildRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 400),
    );
  }
}
