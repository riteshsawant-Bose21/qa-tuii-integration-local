import 'package:flutter/material.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/filter_bottom_sheet.dart';
import 'package:fusion_lib/fusion_lib.dart';

class NoProjectsScreen extends StatelessWidget {
  const NoProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const SizedBox(height: 32),
        /// Main Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.colorScheme.elevation2),
            // boxShadow:  [
            //   BoxShadow(
            //     color: context.colorScheme.elevation1,
            //     blurRadius: 1000,
            //     spreadRadius: 1,
            //   )
            // ],
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: context.colorScheme.elevation2,
                child: Icon(Icons.folder_outlined,color: context.colorScheme.onPrimary,size: 32),
              ),
              const SizedBox(height: 24),

              Text(
                "No projects yet",
                style: Theme.of(context).textTheme.h5BoldMobile.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.colorScheme.textPrimary,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                "Create your project on desktop to get started.\nOnce created, you can view and manage your projects here.",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.b3Regular.copyWith(
                  fontWeight: FontWeight.w400,
                  color: context.colorScheme.textSecondary,
                ),
              ),

              const SizedBox(height: 24),

              /// Blue Button
              GestureDetector(
                onTap: (){

                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color:context.colorScheme.infoFill,
                    border: Border.all(color: context.colorScheme.infoStroke),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                       Icon(Icons.desktop_windows_outlined,
                          size: 14, color: context.colorScheme.infoText),
                      const SizedBox(width: 10),
                      Text(
                        "Desktop required to create projects",
                        style: Theme.of(context)
                            .textTheme
                            .b3Medium
                            .copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.colorScheme.infoText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),


        /// Steps
        _StepItem(
          context,
          number: "1",
          title: "Create on Desktop",
          subtitle: "Start a new project on your computer",
        ),
        const SizedBox(height: 24),
        _StepItem(
          context,
          number: "2",
          title: "Design your layout",
          subtitle: "Add Speakers, Sources, Endpoints & more",
        ),
        const SizedBox(height: 24),
        _StepItem(
          context,
          number: "3",
          title: "Monitor & configure on mobile",
          subtitle: "Access and configure your projects anywhere",
        ),
      ],
    );
  }

  Widget _StepItem(
      BuildContext context, {
        required String number,
        required String title,
        required String subtitle,
      }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

          CircleAvatar(
              radius: 24,
              backgroundColor: context.colorScheme.elevation2,
              child: Text(
                number,
                style: Theme.of(context).textTheme.b2Medium.copyWith(
                  fontWeight: FontWeight.w500,
                  color: context.colorScheme.textPrimary,
                ),
              ),
            ),

        const SizedBox(width: 16),

        /// Texts
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.b2SemiBold.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.colorScheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.l1Regular.copyWith(
                  fontWeight: FontWeight.w400,
                  color: context.colorScheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
