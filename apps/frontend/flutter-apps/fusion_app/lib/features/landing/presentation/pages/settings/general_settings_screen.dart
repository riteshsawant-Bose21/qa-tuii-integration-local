import 'package:flutter/material.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/app_bar/app_bar.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/dropdown_field.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/fusion_theme_notifier.dart';
class GeneralSettingsScreen extends StatefulWidget {
  const GeneralSettingsScreen({super.key});

  @override
  State<GeneralSettingsScreen> createState() => _GeneralSettingsScreenState();
}
enum ThemeSelection { dark, light }
class _GeneralSettingsScreenState extends State<GeneralSettingsScreen> {
  ThemeSelection selected = ThemeSelection.dark;
  TextEditingController controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Scaffold(
        backgroundColor: context.colorScheme.primaryBlack,
        appBar: const CommonAppBar(title: 'General'),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const SizedBox(height: 20),

              /// Section Title
              Text(
                "Language and Appearance",
                style: Theme.of(context).textTheme.b2Medium!.copyWith(
                  fontWeight: FontWeight.w500,
                  color: context.colorScheme.textPrimary
                ),
              ),

              const SizedBox(height: 24),

              /// Language Dropdown
              CommonDropdownField(
                label: 'Language',
                hint: 'English',
                controller: controller,
              ),

              const SizedBox(height: 20),

              /// Theme Label
              Text(
                "Theme",
                style: Theme.of(context).textTheme.l1Medium!.copyWith(
                  fontWeight: FontWeight.w500,
                  color: context.colorScheme.textSecondary,
                ),
              ),

              const SizedBox(height: 8),
              /// Toggle Buttons
              Row(
                children: [
                  Expanded(
                    child: _selectionTile(
                      title: "Dark",
                      isSelected: selected == ThemeSelection.dark,
                      onTap: () {
                        setState(() {
                          selected = ThemeSelection.dark;
                          FusionThemeController.setThemeMode(ThemeMode.dark);
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _selectionTile(
                      title: "Light",
                      isSelected: selected == ThemeSelection.light,
                      onTap: () {
                        // setState(() {
                        //   selected = ThemeSelection.light;
                        //   FusionThemeController.setThemeMode(ThemeMode.light);
                        // });
                      },
                    ),
                  ),
                ],
              ),


            ],
          ),
        ),
      ),
    );
  }

  Widget _selectionTile({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: isSelected
              ? context.colorScheme.elevation2
              : context.colorScheme.primaryBlack,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? context.colorScheme.elevation2
                : context.colorScheme.strokeLight,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              size: 20,
              color: isSelected
                  ? context.colorScheme.textPrimary
                  : context.colorScheme.textSecondary,
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: Theme.of(context).textTheme.b3Regular.copyWith(
                fontWeight: isSelected
                    ? FontWeight.w500
                    : FontWeight.w400,
                color: isSelected
                    ? context.colorScheme.textPrimary
                    : context.colorScheme.textBody,
              ),
            ),
          ],
        ),
      ),
    );
  }
}