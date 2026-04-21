import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/device_registration/repositories/device_registration_repository.dart';
import 'package:fusion_launcher/features/device_registration/viewmodel/device_registration_vm.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// Opens a dialog that checks the cloud registration status of [hardwareDevices]
/// (via GET /devices) and lists devices that are not yet registered.
/// On confirmation it bulk-registers them then claims each one individually.
Future<void> showUnregisteredDevicesClaimDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    builder: (BuildContext dialogContext) {
      return const _DeviceRegistraionPage();
    },
  );
}

class _DeviceRegistraionPage extends StatefulWidget {
  const _DeviceRegistraionPage();

  @override
  State<_DeviceRegistraionPage> createState() => _DeviceRegistraionPageState();
}

class _DeviceRegistraionPageState extends State<_DeviceRegistraionPage> {
  final GlobalBlockerController _screenBlocker = GlobalBlockerController();

  @override
  void dispose() {
    _screenBlocker.dispose(); // ✅ proper cleanup
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(40),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.elevation1,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: context.colorScheme.strokeLight,
          ),
        ),
        child: BlocProvider<DeviceRegistrationViewModel>(
          create: (BuildContext context) {
            return DeviceRegistrationViewModel(
              DeviceRegistrationRepository(
                vip: serviceLocator<ProjectViewModel>().virtualIP ?? '',
                fusionDeviceService: serviceLocator<FusionDeviceService>(),
              ),
            );
          },
          child: BlocConsumer<DeviceRegistrationViewModel, DeviceRegistrationState>(
            listener: (BuildContext context, DeviceRegistrationState state) {
              if (state.stepBulk == DeviceRegistrationStep.processing) {
                _screenBlocker.show(context, content: const SizedBox());
              } else {
                _screenBlocker.hide();
              }
            },
            builder: (BuildContext context, DeviceRegistrationState state) {
              final List<DeviceSpecificRegistrationState>? devices = state.devices;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildTopHeader(context),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: context.colorScheme.strokeLight,
                  ),
                  Expanded(
                    child: Builder(
                      builder: (BuildContext context) {
                        if (devices == null) {
                          return _buildLoadingState(context);
                        } else {
                          return _buildDeviceBody(context, state, devices);
                        }
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: FusionAppText(
              text: 'REGISTER DEVICES',
              style: context.textTheme.l1Medium,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close,
              size: 18,
              color: context.colorScheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: context.colorScheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildDeviceBody(BuildContext context, DeviceRegistrationState state, List<DeviceSpecificRegistrationState> devices) {
    if (devices.isEmpty) {
      return Center(
        child: FusionAppText(
          text: 'No unregistered devices found.',
          style: context.textTheme.b3Regular.copyWith(
            color: context.colorScheme.textSecondary,
          ),
        ),
      );
    }

    final bool allCompleted = state.allCompleted;

    final bool anyError = devices.any((DeviceSpecificRegistrationState item) => (item.error ?? '').trim().isNotEmpty);
    final int count = devices.length;
    final String countText = count == 1 ? 'One device is' : '$count devices are';

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              _buildSummaryIcon(context, allCompleted),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    FusionAppText(
                      text: allCompleted ? 'Registered Device' : 'Unregistered Device Found',
                      style: context.textTheme.h4SemiBold,
                    ),
                    const SizedBox(height: 4),
                    FusionAppText(
                      text: '$countText not yet registered in the Fusion Cloud and still need to be onboarded.',
                      style: context.textTheme.b3Regular.copyWith(
                        color: context.colorScheme.textBody,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildBulkActionArea(
                context,
                state,
                devices,
                allCompleted,
                anyError,
              ),
            ],
          ),
          const SizedBox(height: 34),
          _buildTableHeader(context),
          Divider(
            height: 1,
            thickness: 1,
            color: context.colorScheme.strokeLight,
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: devices.length,
              separatorBuilder: (_, __) {
                return Divider(
                  height: 1,
                  thickness: 1,
                  color: context.colorScheme.strokeLight,
                );
              },
              itemBuilder: (BuildContext context, int index) {
                final DeviceSpecificRegistrationState item = devices[index];
                return _buildDeviceRow(context, state, item);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryIcon(BuildContext context, bool allCompleted) {
    if (allCompleted) {
      return Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: context.colorScheme.primaryColor,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check,
          color: Colors.white,
          size: 54,
        ),
      );
    }

    return const Icon(
      Icons.error_rounded,
      color: Color(0xFFC97424),
      size: 88,
    );
  }

  Widget _buildBulkActionArea(
    BuildContext context,
    DeviceRegistrationState state,
    List<DeviceSpecificRegistrationState> devices,
    bool allCompleted,
    bool anyError,
  ) {
    final DeviceRegistrationViewModel viewModel = context.read<DeviceRegistrationViewModel>();

    if (allCompleted) {
      return _StatusPill(
        icon: Icons.check_circle,
        text: 'Registered Successfully',
        color: context.colorScheme.primaryColor,
      );
    }

    if (state.stepBulk == DeviceRegistrationStep.processing) {
      final ({double progress, int progressPercent}) progressState = state.progressPercent;

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: 34,
            height: 34,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                CircularProgressIndicator(
                  value: progressState.progress,
                  strokeWidth: 2.2,
                  color: const Color(0xFF20AE6A),
                  backgroundColor: const Color(0x33474747),
                ),
                FusionAppText(
                  text: '${progressState.progressPercent}%',
                  style: context.textTheme.l1Regular.copyWith(
                    fontSize: 9,
                    color: context.colorScheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _BuildAction(
            title: 'Cancel',
            onTap: () => Navigator.of(context).pop(),
            outlined: true,
          ),
        ],
      );
    }

    if (anyError) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const _StatusPill(
            icon: Icons.cancel,
            text: 'Registration Failed',
            color: Color(0xFFFF3B3B),
          ),
          const SizedBox(width: 14),
          _BuildAction(
            title: 'Retry',
            onTap: viewModel.bulkDeviceRegistration,
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _BuildAction(
          title: 'Cancel',
          onTap: () => Navigator.of(context).pop(),
          outlined: true,
        ),
        const SizedBox(width: 10),
        _BuildAction(
          title: 'Register All',
          onTap: viewModel.bulkDeviceRegistration,
        ),
      ],
    );
  }

  Widget _buildTableHeader(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 2,
            child: FusionAppText(
              text: 'DEVICE NAME',
              style: context.textTheme.l1Medium.copyWith(
                color: context.colorScheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: FusionAppText(
              text: 'MODEL NAME',
              style: context.textTheme.l1Medium.copyWith(
                color: context.colorScheme.textSecondary,
              ),
            ),
          ),
          const Expanded(flex: 3, child: SizedBox()),
        ],
      ),
    );
  }

  Widget _buildDeviceRow(BuildContext context, DeviceRegistrationState state, DeviceSpecificRegistrationState item) {
    final bool isCompleted = item.step == DeviceRegistrationStep.completed || item.device.isDeviceCertificateValid;
    final bool hasError = (item.error ?? '').trim().isNotEmpty;

    final DeviceRegistrationViewModel viewModel = context.read<DeviceRegistrationViewModel>();

    final bool canShowLoader = (state.stepBulk == DeviceRegistrationStep.processing && !hasError) || item.step == DeviceRegistrationStep.processing;

    return SizedBox(
      height: 60,
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 2,
            child: FusionAppText(
              text: item.device.name,
              style: context.textTheme.b3Regular.copyWith(
                color: const Color(0xFF178C5A),
                decoration: TextDecoration.underline,
                decorationColor: const Color(0xFF178C5A),
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: FusionAppText(
              text: item.device.modelName,
              style: context.textTheme.b3Regular,
            ),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: Builder(
                builder: (BuildContext context) {
                  if (isCompleted) {
                    return _StatusPill(
                      icon: Icons.check_circle,
                      text: 'Registered Successfully',
                      color: context.colorScheme.primaryColor,
                    );
                  }

                  if (canShowLoader) {
                    return SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        strokeCap: StrokeCap.round,
                        color: context.colorScheme.primaryColor,
                      ),
                    );
                  }

                  if (hasError) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const _StatusPill(
                          icon: Icons.cancel,
                          text: 'Registration Failed',
                          color: Color(0xFFFF3B3B),
                        ),
                        const SizedBox(width: 14),
                        _BuildAction(
                          title: 'Retry',
                          onTap: () => viewModel.singleDeviceRegister(item),
                        ),
                      ],
                    );
                  }

                  return _BuildAction(
                    title: 'Register',
                    onTap: () => viewModel.singleDeviceRegister(item),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _StatusPill({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        FusionAppText(
          text: text,
          style: context.textTheme.l1Medium.copyWith(
            color: color,
          ),
        ),
      ],
    );
  }
}

class _BuildAction extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final bool outlined;
  const _BuildAction({
    required this.title,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 142,
      height: 40,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: outlined ? Colors.transparent : const Color(0xFF2A2A2A),
          foregroundColor: context.colorScheme.textPrimary,
          textStyle: context.textTheme.l1Medium,
          side: BorderSide(color: outlined ? const Color(0xFF4A4A4A) : const Color(0xFF3A3A3A)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: FusionAppText(
          text: title,
          style: context.textTheme.l1Medium,
        ),
      ),
    );
  }
}
