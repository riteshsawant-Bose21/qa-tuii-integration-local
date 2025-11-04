import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_launcher/core/router/navigation_observer.dart';
import 'package:fusion_launcher/core/router/routes.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/core/services/user_session_manager.dart';
import 'package:fusion_launcher/features/onboarding/presentation/welcome_page.dart';
import 'package:fusion_launcher/features/user_account_setup/presentation/bloc/auth_bloc.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:nested/nested.dart' show SingleChildWidget;

import 'features/configuration/presentation/viewmodel/project_view_model.dart';
import 'features/dashboard/presentation/pages/dashboard_page.dart';
import 'features/dynamic_config/presentation/bloc/panel_bloc.dart';
import 'features/product_query/presentation/viewModel/product_query_view_model_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.landscapeRight,
    DeviceOrientation.landscapeLeft,
  ]);

  await setupServiceLocator();

  runApp(const MyApp());

  _setupMacOSDeepLinkListener();
}

void _setupMacOSDeepLinkListener() {
  if (kIsWeb) {
    return;
  }
  // Use MethodChannel to receive the URL from native code
  const MethodChannel channel = MethodChannel('custom_url_scheme_channel');
  channel.setMethodCallHandler((MethodCall call) async {
    debugPrint('Received method call: ${call.method} with arguments: ${call.arguments}');
    if (call.method == 'onCustomUrlScheme') {
      final String url = call.arguments as String;
      // Handle the URL here
      debugPrint('Received deep link: $url');
      // You can navigate or update state as needed
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <SingleChildWidget>[
        BlocProvider<AuthBloc>(
          create: (BuildContext context) => serviceLocator<AuthBloc>(),
        ),
        BlocProvider<PanelBloc>(
          create: (BuildContext context) => serviceLocator<PanelBloc>(),
        ),
        BlocProvider<ProjectViewModel>(
          create: (BuildContext context) => serviceLocator<ProjectViewModel>(),
        ),
        BlocProvider<ProductQueryCubit>(
          create: (BuildContext context) => serviceLocator<ProductQueryCubit>(),
        ),
        BlocProvider<GuideShowCaseController>(
          create: (BuildContext context) => GuideShowCaseController(globalNavigatorKey.currentContext!),
        ),
      ],
      child: FusionThemeBuilder(
        builder: (BuildContext context, ThemeMode mode) {
          return MaterialApp(
            title: 'Fusion Launcher',
            debugShowCheckedModeBanner: false,
            theme: FusionAppTheme.lightTheme,
            darkTheme: FusionAppTheme.darkTheme,
            themeMode: mode,
            home: Scaffold(
              body: UserSessionManager.isUserLoggedIn() ? const HomePage() : const WelcomePage(),
            ),
            navigatorKey: globalNavigatorKey,
            navigatorObservers: <NavigatorObserver>[
              AppNavigatorObserver(),
            ],
            onGenerateRoute: (RouteSettings settings) => Routes.onGenerateRoute(settings),
          );
        },
      ),
    );
  }
}
