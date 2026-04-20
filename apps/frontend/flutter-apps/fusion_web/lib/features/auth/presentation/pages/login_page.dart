import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_theme/color_pallette.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fusion_web/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:fusion_web/features/auth/data/datasources/auth0_datasource.dart';
import 'package:fusion_web/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:fusion_web/features/auth/domain/usecases/auth_usecases.dart';
import 'package:fusion_web/core/constants/app_constants.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late AuthViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _initializeViewModel();
  }

  void _initializeViewModel() {
    final dataSource = Auth0DataSource();
    final repository = AuthRepositoryImpl(dataSource: dataSource);

    _viewModel = AuthViewModel(
      loginUseCase: LoginUseCase(repository),
      logoutUseCase: LogoutUseCase(repository),
      getCurrentUserUseCase: GetCurrentUserUseCase(repository),
      isLoggedInUseCase: IsLoggedInUseCase(repository),
      authRepository: repository,
    );

    // Listen to authentication state changes
    _viewModel.addListener(_onAuthStateChanged);
    _viewModel.initialize();

    // Check authentication state after redirect from Auth0
    _checkAuthenticationState();
  }

  void _onAuthStateChanged() {
    if (_viewModel.isLoggedIn && mounted) {
      Navigator.pushReplacementNamed(context, AppConstants.dashboardRoute);
    }
  }

  void _checkAuthenticationState() async {
    // Give some time for Auth0 to process the redirect
    await Future.delayed(const Duration(milliseconds: 500));

    await _viewModel.checkAuthStatus();

    if (_viewModel.isLoggedIn && mounted) {
      Navigator.pushReplacementNamed(context, AppConstants.dashboardRoute);
    }
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onAuthStateChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    // Auth0Web.loginWithRedirect will redirect to Auth0,
    // and then redirect back, so we don't wait for the result here
    await _viewModel.login();

    // Check if login was successful and redirect
    if (_viewModel.isLoggedIn && mounted) {
      Navigator.pushReplacementNamed(context, AppConstants.dashboardRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double headlineFontSize = MediaQuery.of(context).size.width * 0.07;
    final double subHeadingFontSize = MediaQuery.of(context).size.width * 0.02;

    return Scaffold(
      backgroundColor: context.colorScheme.elevation1,
      body: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Row(
          children: [
            /// LEFT SIDE (TEXT)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome to\nFusion',
                    style: context.textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: headlineFontSize > 120 ? 120 : headlineFontSize,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Sign into your Fusion account on the right and\nget started creating dynamic audio experiences',
                    style: context.textTheme.bodyLarge?.copyWith(
                      color: FusionDarkColorPallette.medium50,
                      fontSize: subHeadingFontSize > 16
                          ? 16
                          : subHeadingFontSize,
                    ),
                  ),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                spacing: 10,
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  NeumorphicDarkButton(
                    onTap: () {
                      _handleLogin();
                    },
                    height: 60,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Row(
                        spacing: 10,
                        children: <Widget>[
                          Expanded(
                            child: FusionAppText(
                              text: 'Log in',
                              style: context.textTheme.labelLarge?.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            height: double.infinity,
                            width: 47,
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: FusionDarkColorPallette.green20,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              LucideIcons.arrowRight,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // skip login Ui
                  // const SizedBox(height: 44),
                  // Padding(
                  //   padding: const EdgeInsets.only(right: 10.0),
                  //   child: SemanticHelper.button(
                  //     testId: SemanticHelper.createTestId(
                  //       SemanticTypes.button,
                  //       "skip_login_button",
                  //     ),
                  //     child: TextButton(
                  //       onPressed: () {},
                  //       child: FusionAppText(
                  //         text: "Don't have an account?",
                  //         textAlign: TextAlign.start,
                  //         style: context.textTheme.bodyMedium,
                  //       ),
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
        
          ],
        ),
      ),
    );
  }
}

class NeumorphicDarkButton extends StatefulWidget {
  final String? text;
  final Widget? child;

  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final double borderRadius;
  final Color? backgroundColor;

  const NeumorphicDarkButton({
    super.key,
    this.text,
    this.borderRadius = 12,
    this.child,
    this.onTap,
    this.width,
    this.height,
    this.backgroundColor,
  });

  @override
  State<NeumorphicDarkButton> createState() => _NeumorphicDarkButtonState();
}

class _NeumorphicDarkButtonState extends State<NeumorphicDarkButton> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    assert(widget.text != null || widget.child != null);

    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: FusionNeumorphicButton(
        semanticId: 'launcher_sign_in_button',
        onTap: widget.onTap ?? () {},
        width: widget.width,
        height: widget.height ?? 44,
        borderRadius: widget.borderRadius,
        text: widget.text ?? "",
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Container(
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
            child: Center(
              child: widget.child ?? FusionAppText(text: widget.text ?? ""),
            ),
          ),
        ),
      ),
    );
  }
}
