// mdns_service.dart
import 'dart:async';
import 'dart:io' show InternetAddress, InternetAddressType, NetworkInterface, Platform, RawDatagramSocket;
import 'package:multicast_dns/multicast_dns.dart';

import '../../fusion_lib.dart';

typedef IpFilter = bool Function(String ip);

class MdnsService {
  final String serviceType; // e.g. '_fusion._tcp.local'
  final IpFilter? ipFilter;

  MDnsClient? _client;
  bool _running = false;
  Completer<void>? _teardownCompleter;

  MdnsService({
    required this.serviceType,
    this.ipFilter,
  });

  Stream<MdnsDevice> startDiscovery({
    Duration timeout = const Duration(seconds: 3),
  }) async* {
    // If a previous scan is still tearing down (singleton scenario — e.g. the
    // dialog was closed and reopened quickly), wait for its `finally` block to
    // run before we touch `_client` / `_running` again. Without this guard the
    // old generator would null out the new client and the new scan would
    // silently produce zero devices.
    if (_running) {
      // Ask the previous run to stop, then await its teardown.
      final Completer<void>? pending = _teardownCompleter;
      final MDnsClient? prevClient = _client;
      _client = null;
      try {
        prevClient?.stop();
      } catch (_) {}
      if (pending != null && !pending.isCompleted) {
        await pending.future;
      }
    }

    _running = true;
    final Completer<void> teardown = Completer<void>();
    _teardownCompleter = teardown;

    final client = MDnsClient(
      rawDatagramSocketFactory:
          (
            dynamic host,
            int port, {
            bool reuseAddress = true,
            bool reusePort = true,
            int ttl = 1,
          }) {
            // Windows does not support SO_REUSEPORT; force it off there.
            return RawDatagramSocket.bind(
              host,
              port,
              reuseAddress: reuseAddress,
              reusePort: Platform.isWindows ? false : reusePort,
              ttl: ttl,
            );
          },
    );
    _client = client;

    final seen = <String, MdnsDevice>{};

    try {
      await client.start(
        listenAddress: InternetAddress.anyIPv4,
        interfacesFactory: _interfacesFactory,
      );

      final ptrQuery = ResourceRecordQuery.serverPointer(serviceType);

      await for (final PtrResourceRecord ptr in client.lookup<PtrResourceRecord>(ptrQuery)) {
        // Bail out if we were stopped externally or superseded by a new scan.
        if (!identical(_client, client)) break;
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
      try {
        client.stop();
      } catch (_) {}
      // Only clear shared state if we still own it (i.e. we weren't
      // superseded by a newer startDiscovery() call).
      if (identical(_client, client)) {
        _client = null;
      }
      _running = false;
      if (identical(_teardownCompleter, teardown)) {
        _teardownCompleter = null;
      }
      if (!teardown.isCompleted) teardown.complete();
    }
  }

  void stopDiscovery() {
    final MDnsClient? client = _client;
    _client = null;
    try {
      client?.stop();
    } catch (_) {}
    // Do NOT touch `_running` here — let the async generator's `finally` flip
    // it once teardown is complete. This prevents a brand-new startDiscovery()
    // call from racing past the `_running` guard while the previous run is
    // still unwinding.
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

  /// Returns network interfaces suitable for IPv4 multicast.
  ///
  /// On Windows, [NetworkInterface.list] returns many virtual adapters
  /// (Hyper-V, WSL, VPN, Loopback Pseudo-Interface, vEthernet, Bluetooth PAN,
  /// etc.) that don't support `IP_ADD_MEMBERSHIP`; trying to `joinMulticast`
  /// on them throws `WSAENOPROTOOPT (errno 10042)` and aborts the whole
  /// `MDnsClient.start()`. We filter those out here.
  static Future<Iterable<NetworkInterface>> _interfacesFactory(
    InternetAddressType type,
  ) async {
    final interfaces = await NetworkInterface.list(
      includeLoopback: false,
      includeLinkLocal: false,
      type: type,
    );

    if (!Platform.isWindows) return interfaces;

    final blocked = RegExp(
      r'(vethernet|hyper-?v|vmware|virtualbox|vbox|wsl|loopback|bluetooth|tap|tunnel|isatap|teredo|wan miniport)',
      caseSensitive: false,
    );

    return interfaces.where((i) {
      if (blocked.hasMatch(i.name)) return false;
      return i.addresses.any(
        (a) => a.type == InternetAddressType.IPv4 && !a.isLinkLocal,
      );
    });
  }
}
