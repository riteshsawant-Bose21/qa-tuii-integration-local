import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fusion_web/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:fusion_web/features/auth/data/datasources/auth0_datasource.dart';
import 'package:fusion_web/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:fusion_web/features/auth/domain/usecases/auth_usecases.dart';
import 'package:fusion_web/core/constants/app_constants.dart';

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
    return Scaffold(
      backgroundColor: context.colorScheme.elevation1,
      body: Stack(
        children: [
          Center(
            child: Container(
              width: 450,
              padding: const EdgeInsets.all(48),
              decoration: BoxDecoration(
                color: context.colorScheme.elevation2,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: context.colorScheme.elevation3,
                  width: 1.2,
                ),
              ),
              child: ListenableBuilder(
                listenable: _viewModel,
                builder: (context, child) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 802 Labs Logo
                      SvgPicture.asset(
                        'assets/images/logo/light/802Labs_Logo_Lockup_Horizontal_Linear_Light00_RGB.svg',
                        height: 80,
                        fit: BoxFit.contain,
                        colorFilter: ColorFilter.mode(
                          context.colorScheme.textPrimary,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Welcome Text
                      Text(
                        'Welcome',
                        style: GoogleFonts.montserrat(
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: context.colorScheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please sign in to access your account',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: context.colorScheme.elevation6,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Error Message
                      if (_viewModel.error != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE57373).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFE57373).withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            'Authentication failed. Please try again.',
                            style: GoogleFonts.montserrat(
                              color: const Color(0xFFE57373),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _viewModel.isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.colorScheme.primaryColor,
                            foregroundColor: context.colorScheme.textPrimary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _viewModel.isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      context.colorScheme.textPrimary,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Sign In',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 44),

                      // Register Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              color: context.colorScheme.elevation6,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Registration feature coming soon. Please contact your administrator for account access.',
                                    style: GoogleFonts.montserrat(
                                      color: context.colorScheme.textPrimary,
                                    ),
                                  ),
                                  backgroundColor:
                                      context.colorScheme.elevation3,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: context.colorScheme.primaryColor,
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Register here',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                color: context.colorScheme.primaryColor,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                                decorationColor:
                                    context.colorScheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
