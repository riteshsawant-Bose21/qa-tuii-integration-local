import 'package:flutter/material.dart';
import 'package:fusion_app/core/services/loader_service.dart';
import 'package:fusion_app/features/devices/models/device_model.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/bottomsheet_action.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/divider.dart';
import 'package:fusion_lib/fusion_lib.dart' hide FusionToast;
import '../../shared/presentation/widgets/common/toast.dart';
class DeviceCard extends StatelessWidget {
  final DeviceModel device;

   DeviceCard({super.key, required this.device});
  bool shouldShowError = true;
  @override
  Widget build(BuildContext context) {
    final isCritical = device.alertType == DeviceAlertType.critical;
    final isWarning = device.alertType == DeviceAlertType.warning;

    return Container(
      decoration: BoxDecoration(
        color:  context.colorScheme.elevation1,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isCritical
              ? context.colorScheme.errorText
              : isWarning
              ? context.colorScheme.warningText
              : context.colorScheme.elevation2,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 8),
            child: Column(
              children: [
                _header(context),
                const SizedBox(height: 12),
                CommonDivider(paddingValue: 0,),
                const SizedBox(height: 12),
                _metrics(context,isCritical,isWarning),
              ],
            ),
          ),

          /// Alert Strip
          if (device.alertType != DeviceAlertType.none)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: isCritical
                    ? const Color(0xFF5A0E0E)
                    : const Color(0xFF5A2E0E),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isCritical ? Icons.shield_outlined : Icons.warning_amber,
                    color: context.colorScheme.iconWhite,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    device.alertText,
                    style:  TextStyle(color: context.colorScheme.textPrimary),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Image placeholder

        Stack(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: context.colorScheme.primaryWhite,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child:  Icon(Icons.router, color: context.colorScheme.primaryBlack),
            ),
            Positioned(
              top: 4,
              left: 4,
              child: CircleAvatar(
                radius: 4,
                backgroundColor: true
                    ? context.colorScheme.primary
                    : context.colorScheme.textPlaceholder
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),

        /// Texts
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(device.title,
                  style:context.textTheme.b3SemiBold.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colorScheme.textPrimary,
                  ),),
              Text(device.subtitle,
                  style:Theme.of(context).textTheme.l1Regular.copyWith(
                    fontWeight: FontWeight.w400,
                    color: context.colorScheme.textSecondary,
                  )),
              const SizedBox(height: 4),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: context.colorScheme.elevation3,
                  borderRadius: BorderRadius.circular(4),
                ),
                child:  Text(
                  "EQUIPMENT LOCATION",
                  style: Theme.of(context).textTheme.l2SemiBold.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                    color: context.colorScheme.textBody,
                  )
                ),
              ),
            ],
          ),
        ),

        /// Action Icons
        Row(
          children:  [
            GestureDetector(
              onTap: (){
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (_) {
                    return FusionConfirmationBottomSheet(
                      title: "Standby",
                      subtitle:
                      "Do you want to set PSM8300-1 device to standby?",
                      content: null,
                      buttons: [
                        FusionBottomSheetButton(
                          text: "Cancel",
                          onPressed: () => Navigator.pop(context),
                        ),
                        FusionBottomSheetButton(
                          text: "Confirm",
                          isPrimary: true,
                          onPressed: () {
                            GlobalLoader().hide();
                            GlobalLoader().show(context,message: 'Device is going to standby',);

                            Future.delayed((Duration(seconds: 1)),(){

                              if(shouldShowError){
                                shouldShowError = false;
                                FusionToast.show(
                                  context,
                                  message: "Unable to set standby ${device.title}",icon: Icons.error,
                                  textColor: context.colorScheme.textPrimary,
                                  iconColor: context.colorScheme.errorText,
                                  backgroundColor: context.colorScheme.errorFill,
                                );
                              }else{
                                FusionToast.show(
                                  context,
                                  message: "${device.title} is in standby",icon: Icons.error,
                                  textColor: context.colorScheme.textPrimary,
                                  iconColor: context.colorScheme.successText,
                                  backgroundColor: context.colorScheme.successFill,
                                );
                              }

                              GlobalLoader().hide();
                              Navigator.pop(context);
                            });
                          },
                        ),
                      ],
                    );
                  },
                );
              },
              child: FusionContainer(
                  raised:true,
                  borderRadius: 8,
                  child: Container(
                      margin: EdgeInsets.all(4),
                      child: Icon(
                          Icons.sync,
                          color: context.colorScheme.iconWhite
                      )
                  )
              ),
            ),
            SizedBox(width: 8),

            GestureDetector(
              onTap: (){
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (_) {
                    return FusionConfirmationBottomSheet(
                      title: "Restart Device",
                      subtitle:
                      "Do you want to restart PSM8300-1 device?",
                      content: null,
                      buttons: [
                        FusionBottomSheetButton(
                          text: "Cancel",
                          onPressed: () => Navigator.pop(context),
                        ),
                        FusionBottomSheetButton(
                          text: "Confirm",
                          isPrimary: true,
                          onPressed: () {
                            GlobalLoader().hide();
                            GlobalLoader().show(context,message: 'Device restarting',);

                            Future.delayed((Duration(seconds: 1)),(){

                              FusionToast.show(
                                context,
                                message: "${device.title} restart successful",icon: Icons.error,
                                textColor: context.colorScheme.textPrimary,
                                iconColor: context.colorScheme.successText,
                                backgroundColor: context.colorScheme.successFill,
                              );

                              GlobalLoader().hide();
                              Navigator.pop(context);
                            });
                          },
                        ),
                      ],
                    );
                  },
                );
              },
              child: FusionContainer(
                  raised:true,
                  borderRadius: 8,
                  child: Container(

                      margin: EdgeInsets.all(4),
                      child: Icon(Icons.refresh, color: context.colorScheme.iconWhite))),
            ),
          ],
        )
      ],
    );
  }

  Widget _metrics(BuildContext context,isCritical,isWarning) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _metricItem(context,"TEMP", device.temperature,Icons.thermostat,isCritical
            ? context.colorScheme.errorText
            : isWarning
            ?  context.colorScheme.warningText
            : context.colorScheme.primary),
        _verticalDivider(context),
        _metricItem(context,"CPU USE", "${device.cpu}%",Icons.speed,isCritical
            ? context.colorScheme.errorText
            : isWarning
            ? context.colorScheme.warningText
            : context.colorScheme.primary),
        _verticalDivider(context),
        _metricItem(context,"DISK USE", "${device.disk}%",Icons.memory,isCritical
            ? context.colorScheme.errorText
            : isWarning
            ? context.colorScheme.warningText
            : context.colorScheme.primary),
      ],
    );
  }

  Widget _metricItem(BuildContext context,String title, String value,IconData icon,Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:Theme.of(context).textTheme.l2SemiBold.copyWith(
                fontWeight: FontWeight.w600,
                color: context.colorScheme.textBody,
              )),
          const SizedBox(height: 8),
          Row(
            children: [
                      Icon(icon,color:color,),
                      SizedBox(width: 8),
                      Text(value,
                      style: Theme.of(context).textTheme.b3Medium.copyWith(
                        fontWeight: FontWeight.w500,
                        color: context.colorScheme.textPrimary,
                      ),),
                    ],
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider(BuildContext context) {
    return Container(
      width: 1,
      height: 48,
      color: context.colorScheme.strokeLight,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
