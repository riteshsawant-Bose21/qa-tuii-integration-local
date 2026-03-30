import 'package:flutter/material.dart';
import 'package:fusion_app/core/router/navigation_observer.dart';
import 'package:fusion_app/core/router/routes.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/app_bar/app_bar.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/box_state_card.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/button/button.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/divider.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/empty_state.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/menu_item.dart';
import 'package:fusion_lib/fusion_lib.dart';

class UpdatesScreen extends StatefulWidget {
  const UpdatesScreen({super.key});

  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();

  static void navigate(page) {
    Navigator.pushNamed(globalNavigatorKey.currentState!.context, page);
  }
}

class _UpdatesScreenState extends State<UpdatesScreen> {
  bool updateAvailable = false;
  bool noInternet = true;

  @override
  void initState() {
    // TODO: implement initState

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Scaffold(
        backgroundColor: context.colorScheme.primaryBlack,
        appBar: const CommonAppBar(title: 'Updates'),
        body: updateAvailable
            ? Column(
                children: [
                  SizedBox(height: 24),
                  BoxStateCard(
                    icon: Icons.cloud_download_outlined,
                    title: "New Update available",
                    description: '''VERSION 1.3.4
          A newer version of Fusion is available on the App Store. Please navigate to the store to install it.''',
                    buttonText: "Update Now",
                    onPressed: () {
                      Future.delayed(Duration(seconds: 1), () {
                        updateAvailable = false;
                        setState(() {});
                      });
                    },
                  ),
                ],
              )
            : otherState(),
      ),
    );
  }

  Widget otherState() {
    if (noInternet) {
      return noInternetState();
    }

    return CommonEmptyState(
      icon: Icons.cloud_download_outlined,
      title: 'You app is up-to-date',
      subtitle: 'Currently Running Version 1.3.4',
    );
  }

  Widget noInternetState() {
    return CommonEmptyState(
      icon: Icons.cloud_off_outlined,
      title: 'No Internet Connection',
      subtitle: 'Please check your network',
      action: Container(
        width: 150,
        child: CustomButton(
          enabled: ValueNotifier(true),
          buttonText: 'Try Again',
          onPressed: () {
            Future.delayed(Duration(seconds: 1), () {
              noInternet = false;
              updateAvailable = true;
              setState(() {});
            });
          },
        ),
      ),
    );
  }
}
