import 'dart:async';

import 'package:desktop_auth0_flutter/desktop_auth0_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/router/navigation_observer.dart';
import 'package:fusion_launcher/core/router/routes.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/authentication/viewmodel/auth_view_model.dart';
import 'package:fusion_launcher/features/authentication/viewmodel/session_view_model.dart';
import 'package:fusion_launcher/features/projects/view_model/project_sync_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:nested/nested.dart' show SingleChildWidget;
import 'package:universal_platform/universal_platform.dart';

import 'core/config/app_config.dart';
import 'features/configuration/presentation/viewmodel/project_view_model.dart';
import 'features/home/presentation/pages/launcher_home_page.dart';
import 'features/dynamic_config/presentation/bloc/panel_bloc.dart';
import 'features/product_query/presentation/viewModel/product_query_view_model_cubit.dart';
import 'features/projects/widget/building/speaker_selection_section/view_model/product_query_view_model.dart';

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);

    await AppConfig.initialize();

    await setupServiceLocator();
    if (UniversalPlatform.isWindows) {
      await initDesktopAuth0Flutter(
        const DesktopAuth0FlutterInitOptions(
          bundleName: 'com.bosepro.fusion',
          auth0Scheme: 'com.bosepro.fusion',
          categories: 'Office;Productivity',
          comment: 'Fusion Launcher',
          name: 'Fusion Launcher',
          iconAssetPath: 'assets/images/splash/splash_app_icon.png',
        ),
      );
    }
    runApp(const MyApp());

    //TODO: Only for web automation build
    //This needs to be conditionally switched on based on some commandline param.
    //Else, this would create the semantics tree everytime misusing computation power.
    SemanticsBinding.instance.ensureSemantics();

    _setupMacOSDeepLinkListener();
  }, reportCrash);
}

Future<void> reportCrash(Object exception, StackTrace stack) async {
  try {
    FusionLogger.log(tag: LogTag.exceptions, message: "Exception: ${exception.toString()} \n, StackTrace: ${stack.toString()} ");
    // FirebaseCrashlytics.instance.recordError(exception, stack);
  } catch (ex) {
    debugPrint("Unable to report crash: $ex");
  }
}

void _setupMacOSDeepLinkListener() {
  if (kIsWeb) {
    return;
  }
  // Use MethodChannel to receive the URL from native code
  const MethodChannel channel = MethodChannel('custom_url_scheme_channel');
  channel.setMethodCallHandler((MethodCall call) async {
    debugPrint(
      'Received method call: ${call.method} with arguments: ${call.arguments}',
    );
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
        BlocProvider<SessionViewModel>.value(
          value: serviceLocator<SessionViewModel>(),
        ),

        BlocProvider<ProductQueryViewModel>.value(
          value: serviceLocator<ProductQueryViewModel>()..loadProducts(),
        ),

        BlocProvider<AuthViewModel>.value(
          value: serviceLocator<AuthViewModel>()..initialize(),
          // lazy: false,
        ),

        BlocProvider<PanelBloc>(
          create: (BuildContext context) => serviceLocator<PanelBloc>(),
        ),
        BlocProvider<ProjectViewModel>(
          create: (BuildContext context) => serviceLocator<ProjectViewModel>(),
        ),
        BlocProvider<ProjectSyncViewModel>(
          create: (BuildContext context) => serviceLocator<ProjectSyncViewModel>(),
        ),
        BlocProvider<ProductQueryCubit>(
          create: (BuildContext context) => serviceLocator<ProductQueryCubit>(),
        ),
        BlocProvider<GuideShowCaseController>(
          create: (BuildContext context) => serviceLocator<GuideShowCaseController>(),
        ),
      ],
      child: FusionThemeBuilder(
        builder: (BuildContext context, ThemeMode mode) {
          return BlocConsumer<SessionViewModel, SessionViewModelState>(
            // Listener: Handle one-off events like errors (optional)
            listener: (BuildContext context, SessionViewModelState state) {
              if (state is SessionExpired) {
                // USAGE: Use the Global Key to navigate
                // pushNamedAndRemoveUntil ensures the user can't go 'back' to the protected page
                globalNavigatorKey.currentState?.pushNamedAndRemoveUntil(
                  Routes.launcherSignInPage,
                  (Route<dynamic> route) => false, // Remove all previous routes
                );
              }
            },
            builder: (BuildContext context, SessionViewModelState state) {
              return MaterialApp(
                title: 'Fusion Launcher',
                debugShowCheckedModeBanner: false,
                theme: FusionAppTheme.lightTheme,
                darkTheme: FusionAppTheme.darkTheme,
                themeMode: ThemeMode.dark,

                home:
                    (state is SessionValid)
                        ? const HomePage()
                        : const Scaffold(
                          body: Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),

                navigatorKey: globalNavigatorKey,
                navigatorObservers: <NavigatorObserver>[
                  AppNavigatorObserver(),
                ],
                onGenerateRoute: (RouteSettings settings) => Routes.onGenerateRoute(settings),
              );
            },
          );
        },
      ),
    );
  }
}
