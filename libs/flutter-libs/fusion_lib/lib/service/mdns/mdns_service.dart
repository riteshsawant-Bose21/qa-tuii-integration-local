// mdns_service.dart
import 'package:multicast_dns/multicast_dns.dart';

import '../../fusion_lib.dart';

class MdnsService {
  final String serviceType; // e.g., '_tcp._local'
  MDnsClient? _client;

  MdnsService({required this.serviceType});

  // Returns a Stream of devices as they are found
  Stream<MdnsDevice> startDiscovery() async* {
    _client = MDnsClient();

    // 1. Start the client
    await _client!.start();

    // 2. Query for PTR records (The pointers to the services)
    final query = ResourceRecordQuery.serverPointer(serviceType);

    await for (final PtrResourceRecord ptr in _client!.lookup<PtrResourceRecord>(query)) {
      // 3. For every PTR found, lookup the SRV (Port/Target) and IP
      // Note: We scan specifically for the name found in the PTR record
      final srvQuery = ResourceRecordQuery.service(ptr.domainName);
      final ipQuery = ResourceRecordQuery.addressIPv4(ptr.domainName); // or IPv6

      // We need to bundle these lookups together
      SrvResourceRecord? srvRecord;
      IPAddressResourceRecord? ipRecord;

      // Fetch SRV
      await for (final SrvResourceRecord srv in _client!.lookup<SrvResourceRecord>(srvQuery)) {
        srvRecord = srv;
      }

      // Fetch IP
      await for (final IPAddressResourceRecord ip in _client!.lookup<IPAddressResourceRecord>(ipQuery)) {
        ipRecord = ip;
      }

      // 4. If we have both, yield a device
      if (srvRecord != null && ipRecord != null) {
        yield MdnsDevice(
          name: ptr.domainName,
          ip: ipRecord.address.address,
          port: srvRecord.port,
        );
      }
    }
  }

  void stopDiscovery() {
    _client?.stop();
    _client = null;
  }
}
