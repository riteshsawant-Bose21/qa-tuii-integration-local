import 'dart:developer';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/router/routes.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/core/theme/app_theme.dart';
import 'package:fusion_launcher/core/widgets/animated_action_widget.dart';
import 'package:fusion_launcher/core/widgets/app_text_view.dart';
import 'package:fusion_launcher/core/widgets/gradient_action_button.dart';
import 'package:fusion_launcher/features/user_account_setup/presentation/bloc/auth_bloc.dart';
import 'package:fusion_launcher/features/user_account_setup/presentation/widgets/account_creation_success_popup.dart';
import 'package:fusion_launcher/features/user_account_setup/presentation/widgets/launcher_background.dart';

import '../../../../core/widgets/app_textfield.dart';

class LauncherSignUpPage extends StatefulWidget {
  const LauncherSignUpPage({super.key});

  @override
  State<LauncherSignUpPage> createState() => _LauncherSignUpPageState();
}

class _LauncherSignUpPageState extends State<LauncherSignUpPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController(text: "");
  final TextEditingController _passwordController = TextEditingController(text: "");

  bool obscured = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signup() async {
    if (_formKey.currentState!.validate()) {
      serviceLocator<AuthBloc>().add(SignUpRequested(_emailController.text, _passwordController.text));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (BuildContext context, AuthState state) {
        if (state is AuthFailure) {
          log("Sign in Failure: ${state.message}");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        } else if (state is AuthSuccess) {
          log("sign in  success: User created successfully");
          if (!context.mounted) return;
          showSuccessPopup(
            context,
            () async {
              // navigate to sign in
              await Navigator.pushNamedAndRemoveUntil(
                context,
                Routes.launcherSignInPage,
                (Route<dynamic> route) => false,
              );
            },
            durationInMils: 2500,
          );
        } else if (state is AuthInitial) {
          log("AuthInitial state reached");
        }
      },
      builder: (BuildContext context, AuthState state) {
        return Scaffold(
          extendBody: true,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
          ),
          body: LauncherBackground(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: SafeArea(
                  top: false,
                  child: Align(
                    alignment: Alignment.center,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      clipBehavior: Clip.hardEdge,
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 8,
                          sigmaY: 8,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 720),
                            color:
                                Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.025) : Colors.black.withValues(alpha: 0.025),
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.max,
                              children: <Widget>[
                                const SizedBox(height: 12.0),
                                Image.asset(
                                  "assets/images/bose_pro_logo_new.png",
                                  height: 72,
                                  fit: BoxFit.fitHeight,
                                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                                ),
                                const SizedBox(height: 12.0),
                                AppTextView(
                                  text: "Sign up to your Bose Professional account",
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 48.0),
                                AppTextField(
                                  controller: _emailController,
                                  title: "Email address",
                                  onValueChange: (String value) {},
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (String? value) {
                                    if (value == null || value.isEmpty) {
                                      return "Enter email";
                                    }
                                    final RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                                    if (!emailRegex.hasMatch(value)) {
                                      return "Enter a valid email address";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                AppTextField(
                                  controller: _passwordController,
                                  title: "Password",
                                  suffixIcon: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        obscured = !obscured;
                                      });
                                    },
                                    child: Icon(
                                      obscured ? CupertinoIcons.eye_slash_fill : CupertinoIcons.eye_fill,
                                      size: 15,
                                      color: Theme.of(context).colorScheme.primaryColor,
                                    ),
                                  ),
                                  obscureText: obscured,
                                  validator: (String? value) {
                                    if (value == null || value.isEmpty) {
                                      return "Enter password";
                                    }
                                    if (value.trim().length < 8) {
                                      return "Password must be at least 8 digits";
                                    }
                                    return null;
                                  },
                                  onValueChange: (String value) {},
                                ),
                                const SizedBox(height: 36.0),
                                GradientActionButton(
                                  label: 'Sign Up',
                                  height: 50,
                                  width: 200,
                                  onTap: _signup,
                                  trailing: const AnimatedActionWidget(
                                    offset: 0.0,
                                    child: Icon(
                                      Icons.login,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 36),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    const AppTextView(
                                      text: "Already have an account? ",
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: const Text(
                                        "Sign In",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
