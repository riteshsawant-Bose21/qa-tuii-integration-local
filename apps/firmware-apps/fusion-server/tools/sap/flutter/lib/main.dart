import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

String getSessionId(Map<String, dynamic> item) => item['id'] as String? ?? '—';

String getOrigin(Map<String, dynamic> item) => item['origin'] as String? ?? '—';

Map<String, dynamic>? getDescription(Map<String, dynamic> item) =>
    item['description'] as Map<String, dynamic>?;

String getConnection(Map<String, dynamic>? desc) {
  if (desc == null) return '—';
  final conn = desc['ConnectionInformation'];
  if (conn is Map<String, dynamic>) {
    final addrInfo = conn['Address'];
    if (addrInfo is Map<String, dynamic> && addrInfo['Address'] is String) {
      return addrInfo['Address'] as String;
    }
  }
  return '—';
}

String getSessionName(Map<String, dynamic>? desc, String defaultId) {
  if (desc == null) return defaultId;
  final sn = desc['SessionName'];
  if (sn is String) return sn;
  if (sn is Map<String, dynamic> && sn['Name'] is String) {
    return sn['Name'] as String;
  }
  return defaultId;
}

List<Map<String, dynamic>> getMediaDescriptions(Map<String, dynamic>? desc) {
  if (desc == null) return [];
  final md = desc['MediaDescriptions'];
  if (md is List) {
    return md.whereType<Map<String, dynamic>>().toList();
  }
  return [];
}

void main() {
  runApp(const SapApp());
}

class SapApp extends StatelessWidget {
  const SapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sessions',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SessionListPage(),
    );
  }
}

class SessionListPage extends StatefulWidget {
  const SessionListPage({super.key});

  @override
  State<SessionListPage> createState() => _SessionListPageState();
}

class _SessionListPageState extends State<SessionListPage> {
  late Future<List<dynamic>> _sessionsFuture;

  @override
  void initState() {
    super.initState();
    _sessionsFuture = fetchSessions();
  }

  Future<List<dynamic>> fetchSessions() async {
    final uri = Uri.parse('http://192.168.2.100:8080/sessions');
    try {
      final resp = await http.get(uri);
      if (resp.statusCode != 200) {
        throw Exception('Failed to load sessions: ${resp.statusCode}');
      }
      final body = jsonDecode(resp.body);
      if (body is Map<String, dynamic> && body.containsKey('sessions')) {
        final sessMap = body['sessions'];
        if (sessMap is Map<String, dynamic>) {
          return sessMap.values.toList();
        }
      }
      if (body is List) return body;
      if (body is Map<String, dynamic>) return body.values.toList();
      throw Exception('Unexpected JSON format: ${body.runtimeType}');
    } catch (err, stack) {
      developer.log(
        'Error fetching sessions',
        error: err,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sessions')),
      body: FutureBuilder<List<dynamic>>(
        future: _sessionsFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            developer.log(
              'Error in FutureBuilder',
              error: snap.error,
              stackTrace: snap.stackTrace,
            );
            return Center(child: Text('Error: ${snap.error}'));
          }

          final sessions = snap.data!;
          if (sessions.isEmpty) {
            return const Center(child: Text('No active sessions'));
          }

          return ListView.builder(
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final item = sessions[index];
              if (item is! Map<String, dynamic>) {
                return const ListTile(
                  title: Text('Unknown session'),
                );
              }
              final id = getSessionId(item);
              final origin = getOrigin(item);
              final desc = getDescription(item);

              final sessionName = getSessionName(desc, id);
              final connection = getConnection(desc);
              final mediaList = getMediaDescriptions(desc);

              // Build media widgets
              final mediaWidgets = mediaList.map((mdRaw) {
                final mediaName = mdRaw['MediaName'] as Map<String, dynamic>?;
                if (mediaName == null) return const SizedBox();
                final mediaType = mediaName['Media'] as String? ?? '—';
                final portInfo = mediaName['Port'] as Map<String, dynamic>?;
                final portVal =
                    (portInfo?['Value'] is int) ? portInfo!['Value'] as int : 0;
                final protos = (mediaName['Protos'] as List<dynamic>?)
                        ?.map((e) => e.toString())
                        .join(', ') ??
                    '—';
                final formats = (mediaName['Formats'] as List<dynamic>?)
                        ?.map((e) => e.toString())
                        .join(', ') ??
                    '—';
                return ListTile(
                  dense: true,
                  title: Text('$mediaType @ $portVal'),
                  subtitle: Text('Protocols: $protos\nFormats: $formats'),
                );
              }).toList();

              final shouldExpand = desc != null || mediaWidgets.isNotEmpty;

              return ExpansionTile(
                key: PageStorageKey<String>(id),
                title: Text(sessionName),
                subtitle: Text('ID: $id\nOrigin: $origin'),
                initiallyExpanded: shouldExpand,
                children: [
                  ListTile(
                    dense: true,
                    title: const Text('Connection'),
                    subtitle: Text(connection),
                  ),
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Media Streams:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ...mediaWidgets,
                ],
              );
            },
          );
        },
      ),
    );
  }
}
