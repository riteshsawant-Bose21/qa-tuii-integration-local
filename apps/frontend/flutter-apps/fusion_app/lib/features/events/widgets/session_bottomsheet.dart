import 'package:flutter/material.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/button/button.dart';
import 'package:fusion_lib/fusion_lib.dart';

class SkipSessionBottomSheet extends StatelessWidget {
  final Widget eventCard;
  const SkipSessionBottomSheet( {required this.eventCard,super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 24),
      decoration:  BoxDecoration(
        color: context.colorScheme.elevation1,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          /// Blue Icon
          Container(
            width: 72,
            height: 72,
            decoration:  BoxDecoration(
              shape: BoxShape.circle,
              color: context.colorScheme.zone1Fill,
            ),
            alignment: Alignment.center,
            child:  Icon(
              Icons.question_mark,
              size: 32,
              color:  context.colorScheme.primaryBlack,
            ),
          ),

          const SizedBox(height: 24),

          /// Title
          Text(
            "Are you sure?",
            style: Theme.of(context).textTheme.h5Bold.copyWith(
              fontWeight: FontWeight.w700,
              color: context.colorScheme.textPrimary,
            ),
          ),

          const SizedBox(height: 12),

          /// Subtitle
          Text(
            "Are you sure you want to skip the upcoming event\nYoga Session",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.l1Regular.copyWith(
              fontWeight: FontWeight.w400,
              color: context.colorScheme.textBody,
            ),
          ),

          const SizedBox(height: 24),

          /// Event Card
          eventCard,

          const SizedBox(height: 28),

          /// Buttons Row
          Row(
            children: [

              Expanded(
                  child: CustomButton(
                    bottomPadding: 0,
                    backGroundColor: Colors.transparent,
                    enabled: ValueNotifier(true),
                    buttonText: 'Cancel',
                    onPressed: () {

                    },
                  )
              ),
             // const SizedBox(width: 16),

              /// Skip Session
              Expanded(
                child: CustomButton(
                bottomPadding: 0,
                enabled: ValueNotifier(true),
                buttonText: 'Skip Session',
                onPressed: () {

                },
                )
              ),
            ],
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}