import 'dart:convert';

import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/response_callback.dart';

class SessionSyncService {
  final FusionNetworkClient networkClient;

  SessionSyncService({required this.networkClient});

  /// GET /sessions — list all AES67 sessions from the fusion server
  Future<ResponseCallback<List<Aes67SessionEntry>>> getSessions({required String vip}) async {
    try {
      final ResponseCallback<dynamic> response = await networkClient.get(
        api: FusionApiEndpoint.sapSessions,
        baseUrlToOverride: vip,
        isSecure: false,
      );

      if (response.success && response.data != null) {
        // sapSessions returns a raw JSON string — decode it if needed
        final Map<String, dynamic> root = response.data is String
            ? json.decode(response.data as String) as Map<String, dynamic>
            : response.data as Map<String, dynamic>;
        final Map<String, dynamic> sessionsData = root['sessions'] as Map<String, dynamic>;

        final List<Aes67SessionEntry> sessions = sessionsData.entries.map((MapEntry<String, dynamic> entry) {
          final Map<String, dynamic> item = entry.value as Map<String, dynamic>;
          final Map<String, dynamic> desc = item['description'] as Map<String, dynamic>;

          // ── Session name ───────────────────────────────────────
          final String sessionName = desc['SessionName'] as String? ?? entry.key;

          // ── IP address (strip CIDR suffix e.g. /32) ────────────
          final Map<String, dynamic> connInfo = desc['ConnectionInformation'] as Map<String, dynamic>;
          final String ipAddress = (connInfo['Address'] as Map<String, dynamic>)['Address'] as String;

          // ── isDanteDevice (keywds = Dante in top-level Attributes) ─
          final List<dynamic> topAttrs = desc['Attributes'] as List<dynamic>? ?? <dynamic>[];
          final bool isDanteDevice = topAttrs.any((dynamic a) {
            final Map<String, dynamic> attr = a as Map<String, dynamic>;
            return (attr['Key'] as String?)?.toLowerCase() == 'keywds' && (attr['Value'] as String?)?.toLowerCase() == 'dante';
          });

          // ── MediaDescriptions[0] ───────────────────────────────
          final List<dynamic> mediaDescs = desc['MediaDescriptions'] as List<dynamic>? ?? <dynamic>[];
          final Map<String, dynamic>? firstMedia = mediaDescs.isNotEmpty ? mediaDescs.first as Map<String, dynamic> : null;

          // Port
          int port = 5004;
          if (firstMedia != null) {
            final Map<String, dynamic> mediaName = firstMedia['MediaName'] as Map<String, dynamic>;
            final Map<String, dynamic> portObj = mediaName['Port'] as Map<String, dynamic>;
            port = portObj['Value'] as int? ?? 5004;
          }

          // rtpmap → "96 L24/48000/1"  →  bitDepth=24, sampleRate=48000, channels=1
          int channels = 1;
          int bitDepth = 24;
          int sampleRate = 48000;
          String packetTime = '1 ms';

          if (firstMedia != null) {
            final List<dynamic> mediaAttrs = firstMedia['Attributes'] as List<dynamic>? ?? <dynamic>[];

            for (final dynamic a in mediaAttrs) {
              final Map<String, dynamic> attr = a as Map<String, dynamic>;
              final String key = (attr['Key'] as String?) ?? '';
              final String value = (attr['Value'] as String?) ?? '';

              if (key == 'rtpmap') {
                // e.g. "96 L24/48000/1"
                final List<String> parts = value.split(' ');
                if (parts.length >= 2) {
                  final List<String> codecParts = parts[1].split('/');
                  // L24 → 24
                  if (codecParts.isNotEmpty) {
                    final String codec = codecParts[0];
                    final String digits = codec.replaceAll(RegExp(r'[^0-9]'), '');
                    bitDepth = int.tryParse(digits) ?? 24;
                  }
                  // 48000
                  if (codecParts.length >= 2) {
                    sampleRate = int.tryParse(codecParts[1]) ?? 48000;
                  }
                  // channel count
                  if (codecParts.length >= 3) {
                    channels = int.tryParse(codecParts[2]) ?? 1;
                  }
                }
              } else if (key == 'ptime') {
                packetTime = '$value ms';
              }
            }
          }

          // ── Channel labels: SessionName_ch_1, SessionName_ch_2 … ──
          final List<String> channelLabels = List<String>.generate(
            channels,
            (int i) => '${i + 1}',
          );

          return Aes67SessionEntry(
            id: entry.key,
            sessionId: sessionName,
            channels: channels,
            ipVersion: 'IPv4',
            ipAddress: ipAddress,
            port: port,
            bitDepth: bitDepth,
            sampleRate: '$sampleRate Hz',
            packetTime: packetTime,
            isDanteDevice: isDanteDevice,
            channelLabels: channelLabels,
          );
        }).toList();

        return ResponseCallback<List<Aes67SessionEntry>>.success(sessions);
      } else {
        return ResponseCallback<List<Aes67SessionEntry>>.failure(response.message);
      }
    } catch (e) {
      print("error session sync: $e");
      return ResponseCallback<List<Aes67SessionEntry>>.failure(e.toString());
    }
  }
}
