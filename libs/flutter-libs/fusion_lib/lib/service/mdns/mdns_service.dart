// mdns_service.dart
import 'dart:async';
import 'package:multicast_dns/multicast_dns.dart';

import '../../fusion_lib.dart';

typedef IpFilter = bool Function(String ip);

class MdnsService {
  final String serviceType; // e.g. '_fusion._tcp.local'
  final IpFilter? ipFilter;

  MDnsClient? _client;
  bool _running = false;

  MdnsService({
    required this.serviceType,
    this.ipFilter,
  });

  Stream<MdnsDevice> startDiscovery({
    Duration timeout = const Duration(seconds: 3),
  }) async* {
    if (_running) return;
    _running = true;

    final client = MDnsClient();
    _client = client;

    final seen = <String, MdnsDevice>{};

    try {
      await client.start();

      final ptrQuery = ResourceRecordQuery.serverPointer(serviceType);

      await for (final PtrResourceRecord ptr in client.lookup<PtrResourceRecord>(ptrQuery)) {
        final instanceName = ptr.domainName;

        print("instance name is $instanceName");
        // 1) Resolve service instance -> host + port
        SrvResourceRecord? srvRecord;
        await for (final SrvResourceRecord srv in client.lookup<SrvResourceRecord>(
          ResourceRecordQuery.service(instanceName),
        )) {
          srvRecord = srv;
          break;
        }
        if (srvRecord == null) continue;

        final hostname = srvRecord.target;
        final port = srvRecord.port;

        // 2) Resolve host -> IPv4
        IPAddressResourceRecord? ipRecord;
        await for (final IPAddressResourceRecord ip in client.lookup<IPAddressResourceRecord>(
          ResourceRecordQuery.addressIPv4(hostname),
        )) {
          ipRecord = ip;
          break;
        }
        if (ipRecord == null) continue;

        final ip = ipRecord.address.address;

        // Optional network filter (use only if you know which LAN you want)
        if (ipFilter != null && !ipFilter!(ip)) {
          continue;
        }

        // 3) Resolve TXT metadata (optional but useful)
        final txt = <String, String>{};
        await for (final TxtResourceRecord record in client.lookup<TxtResourceRecord>(
          ResourceRecordQuery.text(instanceName),
        )) {
          txt.addAll(_parseTxt(record.text));
          break;
        }

        // 4) Stable identity:
        // Prefer TXT device id if available, otherwise fall back to hostname.
        final stableId = txt['device_id'] ?? txt['deviceId'] ?? txt['uuid'] ?? txt['serial'] ?? hostname.toLowerCase();

        // IP is still part of the live identity so devices with different IPs show separately.
        final deviceKey = '$stableId|$ip|$port';

        final device = MdnsDevice(
          name: instanceName,
          hostname: hostname,
          ip: ip,
          port: port,
          attributes: txt,
          stableId: stableId,
          lastSeen: DateTime.now(),
        );

        final existing = seen[deviceKey];
        if (existing == null) {
          seen[deviceKey] = device;
          yield device;
        } else {
          final updated = existing.copyWith(
            name: instanceName,
            hostname: hostname,
            ip: ip,
            port: port,
            attributes: txt.isNotEmpty ? txt : existing.attributes,
            lastSeen: DateTime.now(),
          );
          seen[deviceKey] = updated;
          print("Updated device: $updated");
          yield updated;
        }
      }
    } finally {
      client.stop();
      _client = null;
      _running = false;
    }
  }

  void stopDiscovery() {
    _client?.stop();
    _client = null;
    _running = false;
  }

  Map<String, String> _parseTxt(String raw) {
    final result = <String, String>{};

    // TXT strings are usually key=value pairs separated by spaces/commas.
    // Keep it forgiving.
    final chunks = raw.replaceAll('\u0000', ' ').split(RegExp(r'[\s,]+')).where((e) => e.trim().isNotEmpty);

    for (final chunk in chunks) {
      final idx = chunk.indexOf('=');
      if (idx > 0 && idx < chunk.length - 1) {
        final key = chunk.substring(0, idx).trim();
        final value = chunk.substring(idx + 1).trim();
        result[key] = value;
      } else {
        result[chunk.trim()] = 'true';
      }
    }

    return result;
  }
}
