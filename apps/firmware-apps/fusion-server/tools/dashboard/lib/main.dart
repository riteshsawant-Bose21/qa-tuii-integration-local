import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MetricsApp());
}

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      // For web, we'll use the full URL directly
      return 'http://192.168.2.100:8080';
    }
    return 'http://192.168.2.100:8080';
  }

  static Future<Map<String, dynamic>> fetchMetrics() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/metrics'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      );

      // Debug information
      developer.log('Response status code: ${response.statusCode}');
      developer.log('Response headers: ${response.headers}');
      developer.log(
          'Response body: ${response.body.substring(0, math.min(200, response.body.length))}...');

      if (response.statusCode == 200) {
        try {
          return json.decode(response.body);
        } catch (e) {
          throw Exception(
              'Failed to parse JSON response: $e\nResponse body: ${response.body.substring(0, math.min(200, response.body.length))}...');
        }
      } else {
        throw HttpException(
            'Server returned ${response.statusCode}: ${response.body.substring(0, math.min(200, response.body.length))}...');
      }
    } catch (e) {
      throw Exception('Network error: ${e.toString()}');
    }
  }
}

class MetricsApp extends StatelessWidget {
  const MetricsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Metrics Dashboard',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0F1E), // Deeper blue-black
        cardColor: const Color(0xFF1A1F35), // Rich navy blue
      ),
      home: const MetricsDashboard(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Metrics {
  final double clusterHealth;
  final int memberCount;
  final int configKeys;
  final int currentConns;
  final int totalRequests;
  final double cpuUsage;
  final double memoryUsage;
  final List<ClusterMember> members;
  final DateTime timestamp;

  Metrics({
    required this.clusterHealth,
    required this.memberCount,
    required this.configKeys,
    required this.currentConns,
    required this.totalRequests,
    required this.cpuUsage,
    required this.memoryUsage,
    required this.members,
    required this.timestamp,
  });

  factory Metrics.fromJson(Map<String, dynamic> json) {
    return Metrics(
      clusterHealth: json['cluster']['cluster_health'].toDouble(),
      memberCount: json['cluster']['member_count'],
      configKeys: json['config_keys'],
      currentConns: json['haproxy']?['current_conns'] ?? 0,
      totalRequests: json['haproxy']?['total_requests'] ?? 0,
      cpuUsage: json['cpu_usage'].toDouble(),
      memoryUsage: json['memory_usage'] / 1024 / 1024,
      members: (json['cluster']['members'] as List)
          .map((m) => ClusterMember.fromJson(m))
          .toList(),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class ClusterMember {
  final String name;
  final String state;

  ClusterMember({required this.name, required this.state});

  factory ClusterMember.fromJson(Map<String, dynamic> json) {
    return ClusterMember(
      name: json['name'],
      state: json['state'],
    );
  }

  Color get stateColor {
    switch (state) {
      case 'ALIVE':
        return const Color(0xFF00C49F);
      case 'SUSPECT':
        return const Color(0xFFFFBB28);
      case 'DEAD':
        return const Color(0xFFFF8042);
      default:
        return Colors.grey;
    }
  }
}

class MetricsDashboard extends StatefulWidget {
  const MetricsDashboard({super.key});

  @override
  State<MetricsDashboard> createState() => _MetricsDashboardState();
}

class _MetricsDashboardState extends State<MetricsDashboard> {
  Metrics? metrics;
  String? error;
  List<Metrics> history = [];
  Timer? _timer;
  final NumberFormat _numberFormat = NumberFormat("#,##0", "en_US");

  @override
  void initState() {
    super.initState();
    _fetchMetrics();
    _startMetricsTimer();
  }

  void _startMetricsTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchMetrics();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchMetrics() async {
    try {
      final data = await ApiService.fetchMetrics();
      setState(() {
        metrics = Metrics.fromJson(data);
        history = [...history, metrics!].take(20).toList();
        error = null;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        developer.log('Error details: $e');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (error != null)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF7F1D1D),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  error!,
                  style: const TextStyle(color: Color(0xFFFCA5A5)),
                ),
              ),
            if (metrics != null) ...[
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _buildMetricCard(
                    'Cluster Health',
                    '${metrics!.clusterHealth.toStringAsFixed(1)}%',
                    '${metrics!.memberCount} Total Nodes',
                  ),
                  _buildMetricCard(
                    'Config Keys',
                    metrics!.configKeys.toString(),
                    'Active Configuration Keys',
                  ),
                  _buildMetricCard(
                    'HAProxy Connections',
                    metrics!.currentConns.toString(),
                    'Current Connections',
                  ),
                  _buildMetricCard(
                    'Total Requests',
                    _numberFormat.format(metrics!.totalRequests),
                    'HAProxy Requests',
                  ),
                  _buildSystemMetricsChart(),
                  _buildHAProxyChart(),
                ],
              ),
              const SizedBox(height: 16),
              _buildClusterStatus(),
            ] else
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, String label) {
    return Card(
      elevation: 8, // Added shadow
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Rounded corners
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            // Subtle gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1F35), Color(0xFF252B4A)],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFFE2E8F0), // Lighter text
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF60A5FA), // Bright blue for emphasis
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFCBD5E1), // Softer gray
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemMetricsChart() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1F35), Color(0xFF252B4A)],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'System Metrics History',
              style: TextStyle(
                color: Color(0xFFE2E8F0),
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    getDrawingHorizontalLine: (value) {
                      return const FlLine(
                        color: Color(0xFF2D3B55),
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return const FlLine(
                        color: Color(0xFF2D3B55),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: 20,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 4, // Show every fourth time label
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < history.length) {
                            return const Text(""
                                // DateFormat('HH:mm:ss')
                                //     .format(history[value.toInt()].timestamp),
                                // style: const TextStyle(
                                //   color: Color(0xFFCBD5E1),
                                //   fontSize: 11,
                                // ),
                                );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: const Color(0xFF2D3B55)),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: history.asMap().entries.map((entry) {
                        return FlSpot(
                            entry.key.toDouble(), entry.value.cpuUsage);
                      }).toList(),
                      color: const Color(0xFF60A5FA),
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0x1A60A5FA),
                      ),
                    ),
                    LineChartBarData(
                      spots: history.asMap().entries.map((entry) {
                        return FlSpot(
                            entry.key.toDouble(), entry.value.memoryUsage / 10);
                      }).toList(),
                      color: const Color(0xFF34D399),
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0x1A34D399),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClusterStatus() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1F35), Color(0xFF252B4A)],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cluster Status',
              style: TextStyle(
                color: Color(0xFFE2E8F0),
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                childAspectRatio: 1.5,
                crossAxisSpacing: 12, // Increased spacing
                mainAxisSpacing: 12,
              ),
              itemCount: metrics!.members.length,
              itemBuilder: (context, index) {
                final member = metrics!.members[index];
                return Container(
                  decoration: BoxDecoration(
                    color: member.stateColor
                        .withValues(alpha: 0.9), // Slightly transparent
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: member.stateColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        member.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        member.state,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12, // Smaller state text
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHAProxyChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'HAProxy Connections History',
              style: TextStyle(
                color: Color(0xFFD1D5DB),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < history.length) {
                            return const Text("");
                            //   DateFormat('HH:mm:ss')
                            //       .format(history[value.toInt()].timestamp),
                            //   style: const TextStyle(color: Color(0xFF9CA3AF)),
                            // );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: history.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(),
                            entry.value.currentConns.toDouble());
                      }).toList(),
                      color: const Color(0xFFF97316),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
