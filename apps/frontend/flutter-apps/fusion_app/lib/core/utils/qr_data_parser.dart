import 'dart:convert';

class QRConnectionDetails {
  final String vip;
  final String configId;

  QRConnectionDetails({required this.vip, required this.configId});

  @override
  String toString() => 'QRConnectionDetails(vip: $vip, configId: $configId)';
}

class QRConnectionParser {
  static QRConnectionDetails? parse(String payload) {
    // 1. Try parsing as URI
    try {
      final uri = Uri.parse(payload);
      print("Parsed URI: $uri");

      // Check for Universal Link / App Link (http/https)
      // final isUniversal =
      //     (uri.scheme == 'http' || uri.scheme == 'https') &&
      //         uri.host == AppConfig.universalLinkHost &&
      //         uri.path.startsWith(AppConfig.universalLinkPathPrefix);
      //
      // // Check for Custom Scheme (fusion-byod-wc://connect)
      // final isCustomScheme =
      //     uri.scheme == 'fusion-byod-wc' && uri.host == 'connect';

      if (true/*isUniversal || isCustomScheme*/) {
        // Handle case-insensitive keys (e.g. configid vs configId)
        String? vip = uri.queryParameters['vip'];
        String? configId =
            uri.queryParameters['controller_id'] ?? uri.queryParameters['controller_id'];
        print("Parsed URI - VIP: $vip, Config ID: $configId");
        if (vip != null && configId != null) {
          return QRConnectionDetails(vip: vip, configId: configId);
        }
      }
    } catch (e) {
      print(e);
      // Not a valid URI, continue to JSON parsing
    }

    // 2. Try parsing as JSON (Legacy format)
    try {
      final Map<String, dynamic> data = jsonDecode(payload);
      final vip = data['vip']?.toString();
      final configId = data['configId']?.toString();
      if (vip != null && configId != null) {
        return QRConnectionDetails(vip: vip, configId: configId);
      }
    } catch (e) {
      print(e);
      // Not a valid JSON either
    }

    return null;
  }
}