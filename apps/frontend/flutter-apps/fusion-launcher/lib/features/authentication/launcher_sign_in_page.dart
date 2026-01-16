import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/router/routes.dart';
import 'package:fusion_launcher/features/authentication/viewmodel/auth_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/service_locator.dart';
import '../../core/utils/fusion_utils.dart';
import '../user_account_setup/presentation/widgets/account_creation_success_popup.dart';

class LauncherSignInPage extends StatelessWidget {
  const LauncherSignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LauncherSignInPageView();
  }
}

class _LauncherSignInPageView extends StatelessWidget {
  const _LauncherSignInPageView();

  @override
  Widget build(BuildContext context) {
    final double headlineFontSize = MediaQuery.of(context).size.width * 0.07;
    final double subHeadingFontSize = MediaQuery.of(context).size.width * 0.02;

    return Scaffold(
      body: BlocConsumer<AuthViewModel, AuthViewModelState>(
        listener: (BuildContext context, AuthViewModelState state) {
          if (state is AuthLoading) {
            FusionUiUtils.showLoader(context);
          } else {
            FusionUiUtils.hideLoader(context);
          }

          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is Authenticated) {
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
        builder: (BuildContext context, AuthViewModelState state) {
          final bool isAuthenticated = state is Authenticated;

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
                            onTap: () => _handleAuthAction(context, isAuthenticated),
                            height: 60,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                              ),
                              child: Row(
                                spacing: 10,
                                children: <Widget>[
                                  Expanded(
                                    child: FusionAppText(
                                      text: isAuthenticated ? 'Log out' : 'Log in',
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
                                      isAuthenticated ? LucideIcons.logOut : LucideIcons.arrowRight,
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

  void _handleAuthAction(BuildContext context, bool isAuthenticated) {
    final AuthViewModel authViewModel = serviceLocator<AuthViewModel>();

    if (isAuthenticated) {
      authViewModel.logout();
    } else {
      authViewModel.login();
    }
  }
}

class NeumorphicDarkTextField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final String? hintText;
  final TextStyle? hintStyle;
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
    this.hintStyle,
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
              hintStyle: hintStyle ?? context.textTheme.labelLarge?.copyWith(color: Colors.grey),
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
              color: widget.backgroundColor ?? const Color(0xFF232523),
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
