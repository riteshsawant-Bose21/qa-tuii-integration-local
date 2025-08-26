import 'package:flutter/material.dart';

import '../../../../core/widgets/custom_form_field.dart';

class AccountSecurityTab extends StatelessWidget {
  final TextEditingController fullNameController;
  final TextEditingController companyController;
  final TextEditingController jobTitleController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool isTwoFactorEnabled;
  final bool enableEmailNotifications;
  final bool enableSMSNotifications;
  final ValueChanged<bool> onTwoFactorChanged;
  final ValueChanged<bool> onEmailNotifChanged;
  final ValueChanged<bool> onSMSNotifChanged;

  const AccountSecurityTab({
    super.key,
    required this.fullNameController,
    required this.companyController,
    required this.jobTitleController,
    required this.emailController,
    required this.phoneController,
    required this.usernameController,
    required this.passwordController,
    required this.isTwoFactorEnabled,
    required this.enableEmailNotifications,
    required this.enableSMSNotifications,
    required this.onTwoFactorChanged,
    required this.onEmailNotifChanged,
    required this.onSMSNotifChanged,
  });

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width <= 800 ? double.infinity : MediaQuery.of(context).size.width * 0.5;

    return SingleChildScrollView(
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: width,
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Profile Picture
                Visibility(
                  visible: false,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Stack(
                      children: <Widget>[
                        Positioned(
                          bottom: 6,
                          right: 6,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // const SizedBox(height: 40),

                // Personal Information Section
                const Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),

                // Full Name
                CustomFormField(
                  label: 'Full Name',
                  controller: fullNameController,
                  hintText: 'Enter your full name',
                ),
                const SizedBox(height: 24),

                /// Company and Job Title Row
                Row(
                  children: <Widget>[
                    Expanded(
                      child: CustomFormField(
                        label: 'Company Name',
                        controller: companyController,
                        hintText: 'Enter your company name',
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: CustomFormField(
                        label: 'Job Title',
                        controller: jobTitleController,
                        hintText: 'Enter your job title',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                /// Email and Phone Row
                Row(
                  children: <Widget>[
                    Expanded(
                      child: CustomFormField(
                        label: 'Email Address',
                        controller: emailController,
                        hintText: 'Enter your email address',
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: CustomFormField(
                        label: 'Phone Number',
                        controller: phoneController,
                        hintText: 'Enter your phone number',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // Security Section
                const Text(
                  'Security',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),

                /// Username and Password Row
                Row(
                  children: <Widget>[
                    Expanded(
                      child: CustomFormField(
                        label: 'Username',
                        controller: usernameController,
                        hintText: 'Enter your username',
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Expanded(
                            child: CustomFormField(
                              label: 'Password',
                              controller: passwordController,
                              hintText: 'Enter your password',
                              isPassword: true,
                            ),
                          ),
                          const SizedBox(width: 0),
                          SizedBox(
                            height: 36,
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[800],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                              ),
                              child: const Text(
                                'Update',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Toggle Switches
                _buildToggleRow(
                  'Enable Two-Factor Authentication',
                  isTwoFactorEnabled,
                  onTwoFactorChanged,
                ),
                const SizedBox(height: 20),
                _buildToggleRow(
                  'Enable Email Notifications & Updates',
                  enableEmailNotifications,
                  onEmailNotifChanged,
                ),
                const SizedBox(height: 20),
                _buildToggleRow(
                  'Enable Text Notifications & Updates',
                  enableSMSNotifications,
                  onSMSNotifChanged,
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleRow(String title, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: <Widget>[
        SizedBox(
          height: 18,
          width: 30,
          child: FittedBox(
            fit: BoxFit.cover,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.white,
              activeTrackColor: const Color(0xFF333333),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: const Color(0xFFE5E5E5),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              splashRadius: 0,
              trackOutlineColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) => Colors.transparent),
              thumbColor: MaterialStateProperty.all(Colors.white),
            ),
          ),
        ),

        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF333333),
              fontWeight: FontWeight.w400,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ],
    );
  }
}
