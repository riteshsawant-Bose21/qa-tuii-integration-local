import 'package:flutter/material.dart';
import 'package:fusion_app/core/router/routes.dart';
import 'package:fusion_app/features/commission/widgets/bottomsheet_add_hardwares.dart';
import 'package:fusion_app/features/dashboard/presentation/pages/home_screen.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/app_bar/app_bar.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/bottomsheet_action.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/button/button.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/divider.dart';
import 'package:fusion_lib/fusion_lib.dart';

class ConfigureDevicesScreen extends StatelessWidget {
  const ConfigureDevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return SafeArea(
      bottom: false,
      child: Scaffold(
        backgroundColor: context.colorScheme.primaryBlack,
        appBar: CommonAppBar(title: 'Devices'),
        body: _MappingList(),
        bottomNavigationBar: Container(
          color: context.colorScheme.elevation1,
          height: 104,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsetsGeometry.symmetric(horizontal: 24),
                child: CustomButton(
                  enabled: ValueNotifier(true),
                  backGroundColor:context.colorScheme.elevation1,
                  isNeumorphic: true,
                  onPressed: (){
                    showData=true;
                    Navigator.pushNamedAndRemoveUntil(context, Routes.homePage,
                            (Route<dynamic> route) => route.settings.name == Routes.landingPage);

                  },
                  buttonText: 'Push Configuration',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _MappingList extends StatelessWidget {
  const _MappingList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: const [
        HardwareMappingCard(
          title: 'FM6',
          subtitle: 'FusionMini6 • Equipment location',
          ipAddress: '192.168.0.106',
          firmware: 'v1.1.0',
          assignedName: 'Fusion Mini FM6',
          online: true,
          assigned: true,
        ),
        SizedBox(height: 16),
        HardwareMappingCard(
          title: 'PSM8300-1',
          ipAddress: '192.168.0.101',
          firmware: 'v1.2.0',
          assignedName: 'PowerSmart 8300',
          subtitle: 'PowerSmart 8300 • Equipment location',
          assigned: false,
        ),
        SizedBox(height: 16),
        HardwareMappingCard(
          title: 'PSM8300-2',
          ipAddress: '192.168.0.102',
          firmware: 'v2.2.0',
          assignedName: 'PowerSmart 8300',
          subtitle: 'PowerSmart 8300 • Equipment location',
          assigned: false,
        ),
      ]
    );
  }
}

class HardwareMappingCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String? ipAddress;
  final String? firmware;
  final String? assignedName;
  final bool online;
  final bool assigned;

  const HardwareMappingCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.ipAddress,
    this.firmware,
    this.assignedName,
    this.online = false,
    this.assigned = false,
  });

  @override
  State<HardwareMappingCard> createState() => _HardwareMappingCardState();
}

class _HardwareMappingCardState extends State<HardwareMappingCard> {
  bool assigned=false;
  @override
  void initState() {
    // TODO: implement initState
    assigned = widget.assigned;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colorScheme.elevation1,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeaderRow(widget.title, widget.subtitle, widget.online),
          const SizedBox(height: 12),
          CommonDivider(paddingValue: 0,),
          const SizedBox(height: 12),
          _InfoRow(assigned ? widget.ipAddress : "-", assigned ? widget.firmware : "-"),
          const SizedBox(height: 12),
          CommonDivider(paddingValue: 0),

          const SizedBox(height: 12),
          assigned
              ? _AssignedRow(widget.assignedName ?? "")
              :  _AssignHardwareRow(onSelected: (){
                assigned = true;
                setState(() {

                });
          }),
        ],
      ),
    );
  }

  Widget _HeaderRow(String title, String subtitle, bool online) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              width: 74,
              height: 40,
              decoration: BoxDecoration(
                color: context.colorScheme.primaryWhite,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child:  Icon(Icons.router, color:  context.colorScheme.primaryBlack),
            ),
            Positioned(
              top: 4,
              left: 4,
              child: CircleAvatar(
                radius: 4,
                backgroundColor: online
                    ? context.colorScheme.primary
                    : context.colorScheme.textPlaceholder
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:context.textTheme.b3SemiBold.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.colorScheme.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style:context.textTheme.l1Regular.copyWith(
                  fontWeight: FontWeight.w400,
                  color: context.colorScheme.textBody,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: (){

          },
          child: FusionContainer(
              raised:true,
              borderRadius: 8,
              child: Container(

                  margin: EdgeInsets.all(4),
                  child: Icon(Icons.chevron_right, color: context.colorScheme.iconWhite))),
        ),
      ],
    );
  }

  Widget _InfoRow(String? ip, String? firmware) {
    return Row(
      children: [
        Expanded(
          child: _InfoColumn('IP ADDRESS', ip ?? '-'),
        ),
        Container(
          width: 1,
          height: 36,
          color: context.colorScheme.strokeLight,
        ),
        SizedBox(width: 20,),
        Expanded(
          child: _InfoColumn('FIRMWARE', firmware ?? '-'),
        ),
      ],
    );
  }

  Widget _InfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
            label,
            style:context.textTheme.l2SemiBold.copyWith(
            fontWeight: FontWeight.w600,
            color: context.colorScheme.textBody,
            )
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style:context.textTheme.b3Regular.copyWith(
            fontWeight: FontWeight.w400,
            color: context.colorScheme.textPrimary,
          )
        ),
      ],
    );
  }
}

class _AssignedRow extends StatelessWidget {
  final String name;

  const _AssignedRow(this.name);

  @override
  Widget build(BuildContext context) {
    return FusionContainer(
      raised: true,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style:Theme.of(context).textTheme.b2SemiBold.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.colorScheme.textBody,
                ),
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: context.colorScheme.iconDefault,
                borderRadius: BorderRadius.circular(8),
              ),
              child:  Icon(Icons.link, color:  context.colorScheme.elevation2),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssignHardwareRow extends StatelessWidget {
  Function? onSelected;
  _AssignHardwareRow({this.onSelected});
  final selectedIndex = ValueNotifier<int?>(0);
  @override
  Widget build(BuildContext context) {
    return FusionContainer(
      raised: true,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
             Expanded(
              child: Text(
                'Assign Hardware',
                style: Theme.of(context).textTheme.b2SemiBold.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.colorScheme.textPrimary,
                ),
              ),
            ),
            GestureDetector(
              onTap: (){

                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (_) {
                    return FusionConfirmationBottomSheet(
                      title: "No Hardwares Found",
                      icon: Icons.error_outline_rounded,
                      iconBackgroundColor: context.colorScheme.warningText,
                      subtitle: "Please add hardwares to your project to begin mapping",
                      content: null,
                      buttons: [
                        FusionBottomSheetButton(
                          text: "Add Hardwares",
                          onPressed: () {
                            Navigator.pop(context);
                            showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.transparent,
                                isScrollControlled: true,
                                builder: (_) => SheetContent(
                                  onSelected: (){
                                      onSelected!();
                                  },
                                    selectedIndex: selectedIndex)
                            );
                          },
                        ),

                      ],
                    );
                  },
                );


              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: context.colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child:  Icon(Icons.add, color:  context.colorScheme.onPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



