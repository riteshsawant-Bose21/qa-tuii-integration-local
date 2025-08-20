import 'package:flutter/cupertino.dart';
import 'package:fusion_launcher/features/onboarding/presentation/welcome_page.dart';
import 'package:fusion_launcher/features/projects/presentation/project_page.dart';
import 'package:fusion_launcher/features/user_account_setup/presentation/pages/launcher_sign_up_page.dart';

import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/user_account_setup/presentation/pages/launcher_sign_in_page.dart';
import '../widgets/test_library_screen.dart';

class Routes {
  static const String launcherWelcomePage = '/launcherWelcomePage';
  static const String launcherSignInPage = '/launcherSignInPage';
  static const String launcherSignUpPage = '/launcherSignUpPage';
  static const String launcherHomePage = '/launcherHomePage';
  static const String projectPage = '/projectPage';
  static const String mylibraryPage = '/mylibraryPage';

  static Route<dynamic> onGenerateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      /// Welcome Page
      case launcherWelcomePage:
        return CupertinoPageRoute<void>(
          builder: (BuildContext context) => const WelcomePage(),
          settings: const RouteSettings(name: launcherWelcomePage),
        );

      /// Sign In Page
      case launcherSignInPage:
        return CupertinoPageRoute<void>(
          builder: (BuildContext context) => const LauncherSignInPage(),
          settings: const RouteSettings(name: launcherSignInPage),
        );

      /// Sign Up Page
      case launcherSignUpPage:
        return CupertinoPageRoute<void>(
          builder: (BuildContext context) => const LauncherSignUpPage(),
          settings: const RouteSettings(name: launcherSignUpPage),
        );

      /// Home Page
      case launcherHomePage:
        return CupertinoPageRoute<void>(
          builder: (BuildContext context) => const HomePage(),
          settings: const RouteSettings(name: launcherSignInPage),
        );

      /// Project Page
      case projectPage:
        return CupertinoPageRoute<void>(
          builder: (BuildContext context) => const ProjectPage(),
          settings: const RouteSettings(name: projectPage),
        );

      /// My Library Page
      case mylibraryPage:
        return CupertinoPageRoute<void>(
          builder: (BuildContext context) => TestLibraryScreen(),
          settings: const RouteSettings(name: mylibraryPage),
        );

      default:
        return CupertinoPageRoute<void>(
          builder: (BuildContext context) => const WelcomePage(),
          settings: const RouteSettings(name: launcherWelcomePage),
        );
    }
  }
}
