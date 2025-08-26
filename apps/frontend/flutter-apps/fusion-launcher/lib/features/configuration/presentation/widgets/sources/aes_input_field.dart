import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/core/services/project_manager.dart';
import 'package:fusion_lib/fusion_networking/network/fusion_network_client.dart';
import 'package:fusion_lib/models/response_callback.dart';

import '../../../../../core/constants.dart';
import '../common/vip_configuration.dart';

class IPAddressField extends StatefulWidget {
  final String? initialValue;
  final Function(String) onChanged;
  final bool isControlMode;

  const IPAddressField({
    super.key,
    required this.initialValue,
    required this.onChanged,
    required this.isControlMode,
  });

  @override
  State<IPAddressField> createState() => _IPAddressFieldState();
}

class _IPAddressFieldState extends State<IPAddressField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _controller.text = widget.initialValue!;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<List<SessionData>> _fetchSessions() async {
    try {
      // Fetch sessions from the API

      final ResponseCallback<dynamic> responseCallback = await serviceLocator<FusionNetworkClient>().get(api: FusionApiEndpoint.sapSessions);

      if (responseCallback.success && responseCallback.data != null) {
        final Map<String, dynamic> data = json.decode(responseCallback.data);
        final Map<String, dynamic> sessions = data['sessions'] as Map<String, dynamic>;

        final List<SessionData> sessionData =
            sessions.entries.map((MapEntry<String, dynamic> entry) {
              final Map<String, dynamic> sessionData = entry.value;
              final String multicastAddress = (sessionData['description']['ConnectionInformation']['Address']['Address'] as String).split('/').first;
              return SessionData(
                id: sessionData['id'],
                multicastAddress: multicastAddress,
                sessionName: sessionData['description']['SessionName'] ?? 'Unknown Session',
              );
            }).toList();

        return sessionData;
      }
    } catch (e) {
      // Handle error - you might want to show a snackbar or dialog
      print('Error fetching sessions: $e');
      return <SessionData>[];
    }
    return <SessionData>[];
  }

  void _onSessionSelected(SessionData? session) {
    if (session != null) {
      _controller.text = session.multicastAddress;
      widget.onChanged(session.multicastAddress);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 10, bottom: 10.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Expanded(
            child: TextFormField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'IP Address',
                border: UnderlineInputBorder(),
                isDense: true,
                labelStyle: TextStyle(fontSize: 14),
              ),
              validator: (String? val) {
                if (val == null || val.isEmpty) {
                  return 'IP Address cannot be empty';
                }
                // Validate IPv4 address format
                final RegExp ipRegex = RegExp(
                  r'^(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)\.){3}(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)$',
                );
                if (!ipRegex.hasMatch(val)) {
                  return 'Invalid IP Address format';
                }
                return null;
              },
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              onFieldSubmitted: widget.onChanged,
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<SessionData>(
            tooltip: 'Show devices',
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
            offset: const Offset(0, 40),
            color: AppColors.cardSoft,
            itemBuilder: (BuildContext context) {
              if (serviceLocator<ProjectManager>().value.virtualIP == null || serviceLocator<ProjectManager>().value.virtualIP!.isEmpty) {
                return <PopupMenuEntry<SessionData>>[
                  PopupMenuItem<SessionData>(
                    enabled: false,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Center(
                            child: Text(
                              'VIP is not configured yet\n Configure VIP to list available devices',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: colors.tertiary, fontSize: 12),
                            ),
                          ),

                          const SizedBox(height: 8),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              foregroundColor: colors.primary,
                              backgroundColor: colors.primaryContainer,
                              disabledBackgroundColor: colors.primaryContainer,
                              disabledForegroundColor: colors.primary,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              configureVip(context);
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text("Setup VIP", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colors.primary)),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward,
                                  size: 14,
                                  color: colors.primary,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ];
              } else {
                return <PopupMenuEntry<SessionData>>[
                  PopupMenuItem<SessionData>(
                    enabled: false,
                    child: SizedBox(
                      width: 300,
                      child: FutureBuilder<List<SessionData>>(
                        future: _fetchSessions(),
                        builder: (BuildContext context, AsyncSnapshot<List<SessionData>> snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 12),
                                Text('Loading...'),
                              ],
                            );
                          } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Icon(Icons.inbox_outlined, color: colors.onSurfaceVariant),
                                const SizedBox(width: 8),
                                Text('No devices available', style: TextStyle(color: colors.onSurfaceVariant)),
                              ],
                            );
                          } else {
                            final List<MapEntry<int, SessionData>> availableDevices = snapshot.data!.asMap().entries.toList();

                            return Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colors.surface,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Container(
                                        width: 4,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: AppColors.primarySoft,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Available Devices',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: colors.onSurface,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),
                                  if (availableDevices.isEmpty) ...<Widget>[
                                    // Device count indicator
                                    Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: AppColors.primarySoft.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: const Text(
                                          '0 devices',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.primarySoft,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ] else ...<Widget>[
                                    //filter devices, show devices expect widget.fusionDeviceToMap and widget.allFusionDevicesInProject which has status completed
                                    ...availableDevices.map((MapEntry<int, SessionData> entry) {
                                      final int index = entry.key;
                                      final SessionData device = entry.value;
                                      return buildSAPSessionCard(index, context, device, colors, () {
                                        _onSessionSelected(device);
                                        Navigator.pop(context);
                                      });
                                    }),
                                  ],

                                  // Add some bottom padding for better spacing
                                  const SizedBox(height: 8),
                                ],
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ];
              }
            },
            child: IconButton(
              onPressed: null,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: colors.primaryContainer,
                disabledBackgroundColor: colors.primaryContainer,
                foregroundColor: colors.primary,
                disabledForegroundColor: colors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.all(5),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }

  AnimatedContainer buildSAPSessionCard(
    int index,
    BuildContext context,
    SessionData device,
    ColorScheme colors,
    Function() onTap, {
    bool showUnAssign = false,
    bool disable = false,
  }) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200 + (index * 50)),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.primarySoft.withAlpha((0.1 * 255).toInt()),
          highlightColor: AppColors.primarySoft.withAlpha((0.05 * 255).toInt()),
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colors.outline.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: colors.shadow.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                // Enhanced device icon with background
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.network_wifi,
                      size: 20,
                      color: colors.primary,
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Device information
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        device.sessionName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 6),

                      Row(
                        children: <Widget>[
                          Icon(
                            Icons.network_cell,
                            size: 12,
                            color: colors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            device.id!,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              color: colors.outline,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: Colors.green.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SessionData {
  final String id;
  final String multicastAddress;
  final String sessionName;

  SessionData({
    required this.id,
    required this.multicastAddress,
    required this.sessionName,
  });
}

// Usage example:
