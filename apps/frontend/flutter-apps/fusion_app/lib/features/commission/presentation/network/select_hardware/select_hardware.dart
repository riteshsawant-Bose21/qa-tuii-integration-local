import 'package:flutter/material.dart';
import 'package:fusion_app/core/router/routes.dart';
import 'package:fusion_app/core/services/loader_service.dart';
import 'package:fusion_app/features/commission/presentation/network/select_hardware/select_hardware_manual.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/app_bar/app_bar.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/bottomsheet_action.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/button.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/text_field/info_field.dart';
import 'package:fusion_lib/fusion_lib.dart';

class SelectHardware extends StatefulWidget {
  SelectHardware({super.key});

  @override
  State<SelectHardware> createState() => _SelectHardwareState();
}
enum HardwareSelection { automatic, manual }
class _SelectHardwareState extends State<SelectHardware> {
  TextEditingController ipController = TextEditingController(text:'' );

  ValueNotifier<bool> buttonNotifier = ValueNotifier(false);
  HardwareSelection selected = HardwareSelection.automatic;
  @override
  Widget build(BuildContext context) {

    return SafeArea(
      bottom: false,
      child: Scaffold(
        backgroundColor: context.colorScheme.primaryBlack,
        appBar: CommonAppBar(title: 'Configure Network'),
        bottomNavigationBar: Container(
          color: context.colorScheme.elevation1,
          height: 104,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomButton(
                enabled: ValueNotifier(true),
                bottomPadding: 12,
                backGroundColor:context.colorScheme.elevation2,
                onPressed: (){

                  if(selected == HardwareSelection.automatic){
                    showBottomSheets(false);
                  }else {
                    GlobalLoader().hide();
                    GlobalLoader().show(context);

                    Future.delayed((Duration(seconds: 1)), () {
                      GlobalLoader().hide();
                      Navigator.pushNamed(
                          context,
                          Routes.configureVIP
                      );
                    }
                    );
                  }

                },
                buttonText: selected == HardwareSelection.automatic ?  'Verify and proceed' : 'Continue',
              )
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:  [
              // 🔹 Screen title
              Text(
                'Set a VIP address for Fusion hardware',
                style:  Theme.of(context).textTheme.b2Medium.copyWith(
                  fontWeight: FontWeight.w500,
                  color: context.colorScheme.textPrimary,
                ),
              ),

              SizedBox(height: 16),
              Text(
                "Select Hardware",
                style: Theme.of(context).textTheme.l1Medium.copyWith(
                  fontWeight: FontWeight.w500,
                  color: context.colorScheme.textPrimary,
                ),
              ),

              const SizedBox(height: 8),

              /// Toggle Buttons
              Row(
                children: [
                  Expanded(
                    child: _selectionTile(
                      title: "Automatically",
                      isSelected: selected == HardwareSelection.automatic,
                      onTap: () {
                        setState(() {
                          selected = HardwareSelection.automatic;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _selectionTile(
                      title: "Manually",
                      isSelected: selected == HardwareSelection.manual,
                      onTap: () {
                        setState(() {
                          selected = HardwareSelection.manual;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if(selected == HardwareSelection.automatic)
                InfoField(
                  label: 'Virtual IP address',
                  controller: ipController,
                  onChanges: (String value){
                    if(value.isEmpty){
                      buttonNotifier.value=false;
                    }else{
                      buttonNotifier.value=true;
                    }
                  },
                  hint: '192.168.0.100')
                else
                Expanded(child: SelectHardwareManual())
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

  void showBottomSheets(bool isSuccess) {
    GlobalLoader().hide();
    GlobalLoader().show(context);

    Future.delayed((Duration(seconds: 1)),(){
      GlobalLoader().hide();

      if(isSuccess) {
        showModalBottomSheet(
          context: context,
          isDismissible: false,
          backgroundColor: Colors.transparent,
          builder: (_) {
            return FusionConfirmationBottomSheet(
              title: "Network Configuration Successful",
              icon: Icons.done_outlined,
              iconBackgroundColor: context.colorScheme.primary,
              subtitle:
              "Next map project devices to physical devices ",
              content: null,
              buttons: [
                FusionBottomSheetButton(
                  text: "Continue",
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(
                        context,
                        Routes.configureMapping
                    );
                  },
                ),

              ],
            );
          },
        );
      }else{
        showModalBottomSheet(
          context: context,
          isDismissible: false,
          backgroundColor: Colors.transparent,
          builder: (_) {
            return FusionConfirmationBottomSheet(
              title: "Network Configuration Unsuccessful",
              icon: Icons.close,
              iconBackgroundColor: context.colorScheme.errorText,
              subtitle: "We couldn’t configure the device. Please try again",
              content: null,
              buttons: [
                FusionBottomSheetButton(
                  text: "Back",
                  onPressed: () {
                    Navigator.pop(context);

                  },
                ),
                FusionBottomSheetButton(
                  text: "Retry",
                  isPrimary: true,
                  onPressed: () {
                    Navigator.pop(context);
                    showBottomSheets(true);
                  },
                ),

              ],
            );
          },
        );
      }
    });

  }
}
