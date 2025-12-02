import 'dart:developer';

import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:auth0_flutter/auth0_flutter_web.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/router/routes.dart';
import 'package:fusion_launcher/features/user_account_setup/presentation/bloc/auth_bloc.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_networking/network/rest_client/dio_client.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/service_locator.dart';
import '../../core/utils/fusion_utils.dart';
import '../user_account_setup/presentation/widgets/account_creation_success_popup.dart';

enum FusionAuth0Env {
  domain("id-dev.boseprofessional.com"),
  clientId("Il2hl1ZQHO4ZFIDtuSLgdaqAlK5mhjLb"),
  customScheme("fusion"),
  redirectUrlWeb("http://localhost:3000"),
  redirectUrlNative("com.bosepro.fusion://id-dev.boseprofessional.com/macos/com.bosepro.fusion/callback");

  final String value;
  const FusionAuth0Env(this.value);
}

class LauncherSignInPage extends StatefulWidget {
  const LauncherSignInPage({super.key});

  @override
  State<LauncherSignInPage> createState() => _LauncherSignInPageState();
}

class _LauncherSignInPageState extends State<LauncherSignInPage> {
  UserProfile? _user;

  late Auth0 auth0;
  late Auth0Web auth0Web;

  @override
  void initState() {
    super.initState();
    auth0 = Auth0(FusionAuth0Env.domain.value, FusionAuth0Env.clientId.value);
    auth0Web = Auth0Web(FusionAuth0Env.domain.value, FusionAuth0Env.clientId.value);

    // Listen for the redirect callback on web.
    if (kIsWeb) auth0Web.onLoad().then(onSuccess);
  }

  Future<void> login() async {
    try {
      if (kIsWeb) return auth0Web.loginWithRedirect(redirectUrl: FusionAuth0Env.redirectUrlWeb.value);

      // Use a Universal Link callback URL on iOS 17.4+ / macOS 14.4+. 'useHTTPS' is ignored on Android.
      final Credentials credentials = await auth0
          .webAuthentication(scheme: FusionAuth0Env.customScheme.value)
          .login(useHTTPS: false, redirectUrl: FusionAuth0Env.redirectUrlNative.value);

      onSuccess(credentials);
    } catch (e) {
      // print(e);
    }
  }

  Future<void> logout() async {
    try {
      if (kIsWeb) {
        await auth0Web.logout(returnToUrl: FusionAuth0Env.redirectUrlWeb.value);
      } else {
        // Use a Universal Link logout URL on iOS 17.4+ / macOS 14.4+. 'useHTTPS' is ignored on Android
        await auth0.webAuthentication(scheme: FusionAuth0Env.customScheme.value).logout(useHTTPS: false, returnTo: FusionAuth0Env.redirectUrlNative.value);
        setState(() => _user = null);
      }
    } catch (e) {
      // print(e);
    }
  }

  Future<void> onSuccess(Credentials? credentials) async {
    _user = credentials?.user;
    log("email: ${credentials?.user.email..toString()}");
    log("address: ${credentials?.user.address.toString()}");
    log("accessToken: ${credentials!.accessToken.toString()}");
    log("idToken: ${credentials.idToken.toString()}");
    log("refreshToken: ${credentials.refreshToken.toString()}");
    setState(() {});

    final DioClient dioClient = serviceLocator<DioClient>();

    // log("Credentials: ${credentials.toString()}");

    // Call get user details API
    final String basedUrl = "http://fusionapi.cloud-dev-external-bpro.in:8080/api/v1";
    final String apiUrl = "$basedUrl/user/me/authorization";

    final Response<dynamic> response = await dioClient.dioInstance.get(
      apiUrl,
      options: Options(
        headers: <String, dynamic>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${credentials.idToken}',
        },
      ),
    );

    // if (response.statusCode == 200) {
    //   log("Response: ${jsonEncode(response.data)}");
    // } else {
    //   log("Failed to fetch user details. Status code: ${response.statusCode}");
    // }

    // /// Normal API flow
    // final ResponseCallback<LoginResponseEntity> responseCallback = await repository.signInWithEmailAndPassword(email: email, password: password);

    // await prefs.setString(SharedPreferenceKeys.userDetails, jsonEncode(responseCallback.data?.toJson()));
    // await prefs.setString(SharedPreferenceKeys.accessToken, responseCallback.data!.accessToken);
    // await prefs.setString(SharedPreferenceKeys.refreshToken, responseCallback.data!.refreshToken);
    // await prefs.setString(SharedPreferenceKeys.expiry, responseCallback.data!.expiry.toString());
    // await prefs.setBool(SharedPreferenceKeys.isLoggedIn, true);
    // await prefs.setBool(SharedPreferenceKeys.adminLogin, false);
  }

  @override
  Widget build(BuildContext context) {
    // Make it scalable for larger screens
    final double headlineFontSize = MediaQuery.of(context).size.width * 0.07;
    final double subHeadingFontSize = MediaQuery.of(context).size.width * 0.02;

    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (BuildContext context, AuthState state) {
          if (state is AuthInProgress) {
            FusionUiUtils.showLoader(context);
          } else {
            FusionUiUtils.hideLoader(context);
          }
          if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
              ),
            );
          } else if (state is AuthSuccess) {
            if (!context.mounted) return;
            showSuccessPopup(
              context,
              () async {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  Routes.launcherHomePage,
                  (Route<dynamic> route) => false,
                );
              },
              durationInMils: 2500,
            );
          }
        },
        builder: (BuildContext context, AuthState state) {
          return Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Expanded(child: SizedBox()),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
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
                              fontSize: subHeadingFontSize > 16 ? 16 : subHeadingFontSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),

                      child: Column(
                        spacing: 10,
                        children: <Widget>[
                          NeumorphicDarkButton(
                            onTap: () {
                              _user == null ? login() : logout();
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
                                    child: const Icon(
                                      LucideIcons.arrowRight,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class NeumorphicDarkTextField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final String? hintText;
  final double borderRadius;
  final Widget? prefix;
  final Widget? suffix;
  final bool isObscured;
  final double? width;
  final EdgeInsetsGeometry? contentPadding;

  const NeumorphicDarkTextField({
    super.key,
    this.controller,
    this.onChanged,
    this.keyboardType,
    this.validator,
    this.hintText,
    this.borderRadius = 12,
    this.prefix,
    this.suffix,
    this.isObscured = false,
    this.width,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: width,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          boxShadow: <BoxShadow>[
            const BoxShadow(color: Colors.black54, blurRadius: 1, offset: Offset(-2, -2), blurStyle: BlurStyle.inner),
            const BoxShadow(color: Colors.white12, blurRadius: 1, offset: Offset(2, 2), blurStyle: BlurStyle.inner),
            const BoxShadow(color: FusionDarkColorPallette.dark70, blurRadius: 4, blurStyle: BlurStyle.inner),
          ],
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: TextFormField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: keyboardType,
            validator: validator,
            style: context.textTheme.labelLarge,
            obscureText: isObscured,
            decoration: InputDecoration(
              prefixIcon: prefix,
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              suffixIcon: suffix,
              suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              filled: true,
              isDense: true,
              fillColor: const Color(0xFF282826),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              hintText: hintText,
              hoverColor: Colors.transparent,
              contentPadding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              hintStyle: context.textTheme.labelLarge?.copyWith(color: Colors.grey),
            ),
          ),
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
  const NeumorphicDarkButton({
    super.key,
    this.text,
    this.borderRadius = 12,
    this.child,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  State<NeumorphicDarkButton> createState() => _NeumorphicDarkButtonState();
}

class _NeumorphicDarkButtonState extends State<NeumorphicDarkButton> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    assert(widget.text != null || widget.child != null);

    return GestureDetector(
      onTapDown: (_) => setState(() => isPressed = true),
      onTapCancel: () => setState(() => isPressed = false),
      onTapUp: (_) {
        setState(() => isPressed = false);
        widget.onTap?.call();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: widget.width,
        height: widget.height ?? 44,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          boxShadow: <BoxShadow>[
            if (isPressed) ...<BoxShadow>[
              const BoxShadow(color: Colors.black54, blurRadius: 1, offset: Offset(-2, -2), blurStyle: BlurStyle.inner),
              const BoxShadow(color: Colors.white12, blurRadius: 1, offset: Offset(2, 2), blurStyle: BlurStyle.inner),
              const BoxShadow(color: FusionDarkColorPallette.dark70, blurRadius: 4, blurStyle: BlurStyle.inner),
            ] else ...<BoxShadow>[
              const BoxShadow(color: Colors.black, blurRadius: 1, offset: Offset(0.5, 1)),
              const BoxShadow(color: Colors.white24, blurRadius: 1, offset: Offset(-0.5, -1)),
            ],
          ],
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF232523),
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
            child: Center(
              child: widget.child ?? FusionAppText(text: widget.text!),
            ),
          ),
        ),
      ),
    );
  }
}


// clean arhitecture - presentation - bloc pattern - auth bloc - login event - login state - login page - login widget
// Authentication Feature
// -- features 
//  -- data
//    -- models
//      -- user_model.dart
//    -- repositories
//      -- auth_repository.dart
//    -- usecases
//      -- sign_in_usecase.dart
// -- domain


