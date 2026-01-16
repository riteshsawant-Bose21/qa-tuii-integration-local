import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/widgets/test_library_screen.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/projects/presentation/project_work_area.dart';
import '../../features/authentication/launcher_sign_in_page.dart';

class Routes {
  static const String launcherSignInPage = '/launcherSignInPage';
  static const String launcherHomePage = '/launcherHomePage';
  static const String projectPage = '/projectPage';
  static const String mylibraryPage = '/mylibraryPage';

  static Route<dynamic> onGenerateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      /// Sign In Page
      case launcherSignInPage:
        return PageRouteBuilder<void>(
          pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) => const LauncherSignInPage(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          settings: const RouteSettings(name: launcherSignInPage),
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
          builder:
              (BuildContext context) => Theme(
                data: FusionAppTheme.lightTheme, //Theme.of(context).copyWith(brightness: Brightness.light),
                child: const ProjectWorkArea(),
              ),
          settings: const RouteSettings(name: projectPage),
        );

      /// My Library Page
      case mylibraryPage:
        return CupertinoPageRoute<void>(
          builder: (BuildContext context) => const LauncherSignInPage(),
          settings: const RouteSettings(name: mylibraryPage),
        );

      default:
        return CupertinoPageRoute<void>(
          builder: (BuildContext context) => const LauncherSignInPage(),
          settings: const RouteSettings(name: launcherSignInPage),
        );
    }
  }
}
