import 'package:flutter/material.dart';
import 'package:fusion_app/core/router/routes.dart';
import 'package:fusion_app/core/services/loader_service.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/app_bar/app_bar.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/button/button.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/text_field/info_field.dart';
import 'package:fusion_lib/fusion_lib.dart';

class ConfigureVipScreen extends StatelessWidget {
   ConfigureVipScreen({super.key});

  TextEditingController ipController = TextEditingController(text:'' );
  ValueNotifier<bool> buttonNotifier = ValueNotifier(false);
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
                  GlobalLoader().hide();
                  GlobalLoader().show(context);

                  Future.delayed((Duration(seconds: 1)), () {
                    GlobalLoader().hide();
                    Navigator.pushNamed(
                        context,
                        Routes.configureMapping
                    );
                  }
                  );

                },
                buttonText: 'Verify and proceed',
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
                style:  Theme.of(context).textTheme.b2Medium!.copyWith(
                  fontWeight: FontWeight.w500,
                  color: context.colorScheme.textPrimary,
                ),
              ),

              SizedBox(height: 24),


              // 🔹 IP Input (read-only / disabled style)
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
                  hint: '192.168.0.100'),
            ],
          ),
        ),
      ),
    );
  }
}
