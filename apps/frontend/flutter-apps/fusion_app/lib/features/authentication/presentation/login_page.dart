import 'package:flutter/material.dart';
import 'package:fusion_app/core/router/routes.dart';
import 'package:fusion_app/core/service_locator.dart';
import 'package:fusion_app/core/utils/fusion_utils.dart';
import 'package:fusion_app/features/authentication/viewmodel/auth_view_model.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/button.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/divider.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/neumorphic_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_lib.dart' hide FusionContainer;


class FusionLoginScreen extends StatelessWidget {
  const FusionLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Scaffold(
        body: Stack(
          children: [
            /// Background Texture
            Positioned.fill(
              child: Image.asset("assets/bg.png", fit: BoxFit.cover),
            ),
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.fromRGBO(26, 26, 24, 0.0),
                    Color.fromRGBO(26, 26, 24, 0.79),
                  ],
                  stops: [0.0716, 1.0], // 7.16% → 0.0716
                ),
              ),
            ),
            /// Bottom Glass Card
            Align(alignment: Alignment.bottomCenter, child: _LoginBottomPanel()),
          ],
        ),
      ),
    );
  }
}

class _LoginBottomPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthViewModel, AuthViewModelState>(
      listener: (BuildContext context, AuthViewModelState state) {
        if (state is AuthLoading) {
          MobileFusionUiUtils.showLoader(context);
        } else {
          MobileFusionUiUtils.hideLoader(context);
        }

        if (state is AuthError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        } else if (state is Authenticated) {
          if (!context.mounted) return;
        //  showSuccessPopup(context, () async {
            Navigator.pushNamedAndRemoveUntil(
              context,
              Routes.homePage,
              (Route<dynamic> route) => false,
            );
         // }, durationInMils: 2500);
        }
      },
      builder: (BuildContext context, AuthViewModelState state) {
        final bool isAuthenticated = state is Authenticated;

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          decoration: BoxDecoration(
            color: context.colorScheme.elevation1.withValues(alpha: 0.85),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: context.colorScheme.onPrimary.withValues(alpha: 0.05),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// Login Button
              // GestureDetector(
              //   onTap: () => _handleAuthAction(context, isAuthenticated),
              //   child: FusionContainer(
              //     raised: true,
              //     child: Container(
              //       padding: EdgeInsets.symmetric(vertical: 10),
              //       child: Padding(
              //         padding: const EdgeInsets.symmetric(horizontal: 20),
              //         child: Row(
              //           children: [
              //              Expanded(
              //               child: Text(
              //                 "Log In",
              //                 style: context.textTheme.b2SemiBold.copyWith(
              //                     fontWeight: FontWeight.w600,
              //                     color: context.colorScheme.textPrimary
              //                 ),
              //               ),
              //             ),
              //             Container(
              //               width: 44,
              //               height: 44,
              //               decoration: BoxDecoration(
              //                 color: context.colorScheme.primary,
              //                 borderRadius: BorderRadius.circular(14),
              //               ),
              //               child:  Icon(
              //                 Icons.arrow_forward,
              //                 color: context.colorScheme.iconWhite,
              //               ),
              //             ),
              //           ],
              //         ),
              //       ),
              //     )
              //   ),
              // ),
              CustomButton(
                backGroundColor: context.colorScheme.primary,
                padding: EdgeInsetsGeometry.zero,
                bottomPadding: 0,
                enabled: ValueNotifier(true),
                buttonText: 'Login',
                onPressed: () => _handleAuthAction(context, isAuthenticated),
              ),

              const SizedBox(height: 20),

              /// Register Text
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Text(
                    "Don’t have an account? ",
                    style: context.textTheme.l1Regular.copyWith(
                        fontWeight: FontWeight.w400,
                        color: context.colorScheme.textPrimary
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child:  Text(
                      "Register Now",
                      style: context.textTheme.l1SemiBold.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.colorScheme.textPrimary
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(child: CommonDivider()),
                  Text(
                    "or",
                    style: context.textTheme.b3Regular.copyWith(
                        fontWeight: FontWeight.w400,
                        color: context.colorScheme.textPrimary
                    ),
                  ),
                  Expanded(child: CommonDivider()),
                ],
              ),
              const SizedBox(height: 24),
              CustomButton(
                padding: EdgeInsetsGeometry.zero,
                bottomPadding: 0,
                enabled: ValueNotifier(true),
                buttonText: 'Scan QR for Wall Controllers',
                onPressed: () {
                  Navigator.pushNamed(context, Routes.qrScannerPage);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleAuthAction(BuildContext context, bool isAuthenticated) {
    //TODO: Mobile-Setup-Uncomment This
    final AuthViewModel authViewModel = serviceLocator<AuthViewModel>();
    if (isAuthenticated) {
      authViewModel.logout();
    } else {
      Navigator.pushReplacementNamed(context, Routes.landingPage);
      //authViewModel.login();
    }
  }
}
