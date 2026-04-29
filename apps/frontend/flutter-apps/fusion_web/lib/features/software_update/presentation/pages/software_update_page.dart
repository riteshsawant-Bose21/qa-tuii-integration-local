import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_web/core/services/service_locator.dart';
import 'package:fusion_web/features/common-widgets/page_header.dart';
import 'package:fusion_web/features/software_update/data/datasources/firmware_datasource.dart';
import 'package:fusion_web/features/software_update/data/models/firmware_bundle.dart';

class SoftwareUpdatePage extends StatefulWidget {
  const SoftwareUpdatePage({super.key});

  @override
  State<SoftwareUpdatePage> createState() => _SoftwareUpdatePageState();
}

class _SoftwareUpdatePageState extends State<SoftwareUpdatePage> {
  late final FirmwareDataSource _dataSource;
  List<FirmwareBundle> _bundles = [];
  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  int _total = 0;
  final int _limit = 15;
  String _filterStatus = 'All';

  @override
  void initState() {
    super.initState();
    _dataSource = FirmwareDataSource(apiService: ServiceLocator().apiService);
    _loadBundles();
  }

  Future<void> _loadBundles() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _dataSource.getBundles(
        page: _currentPage,
        limit: _limit,
      );
      setState(() {
        _bundles = response.bundles;
        _total = response.total;
        _totalPages = (response.total / _limit).ceil();
        if (_totalPages < 1) _totalPages = 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleAction(FirmwareBundle bundle, String action) async {
    try {
      if (action == 'approve') {
        await _dataSource.approveFirmware(bundle.id);
      } else {
        await _dataSource.revokeFirmware(bundle.id);
      }
      _loadBundles();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to $action: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<FirmwareBundle> get _filteredBundles {
    if (_filterStatus == 'All') return _bundles;
    return _bundles
        .where(
          (b) => b.approvalStatus.toUpperCase() == _filterStatus.toUpperCase(),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.elevation1,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeader(
              title: 'Software Update Manager',
              subtitle: 'Manage software bundles across your devices',
            ),
            const SizedBox(height: 24),
            _buildToolbar(context),
            const SizedBox(height: 16),
            Expanded(child: _buildContent(context)),
            const SizedBox(height: 12),
            _buildPagination(context),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Row(
      children: [
        Text(
          'Filter:',
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colorScheme.elevation6,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: context.colorScheme.elevation2,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: context.colorScheme.strokeLight),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _filterStatus,
              dropdownColor: context.colorScheme.elevation3,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.textPrimary,
              ),
              items: const [
                DropdownMenuItem(value: 'All', child: Text('All')),
                DropdownMenuItem(value: 'PENDING', child: Text('Pending')),
                DropdownMenuItem(value: 'APPROVED', child: Text('Approved')),
                DropdownMenuItem(value: 'REVOKED', child: Text('Revoked')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _filterStatus = value);
                }
              },
            ),
          ),
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: _loadBundles,
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Refresh'),
          style: ElevatedButton.styleFrom(
            backgroundColor: context.colorScheme.primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: context.colorScheme.primaryColor,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(
              'Failed to load firmware bundles',
              style: context.textTheme.titleMedium?.copyWith(
                color: context.colorScheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _error!,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.elevation6,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadBundles,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colorScheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final bundles = _filteredBundles;

    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.elevation2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.colorScheme.strokeLight),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width - 298 - 48,
            ),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                context.colorScheme.elevation3,
              ),
              dataRowColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.hovered)) {
                  return context.colorScheme.elevation3.withValues(alpha: 0.5);
                }
                return Colors.transparent;
              }),
              headingTextStyle: context.textTheme.labelMedium?.copyWith(
                color: context.colorScheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
              dataTextStyle: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.textPrimary,
              ),
              columnSpacing: 24,
              horizontalMargin: 16,
              columns: const [
                DataColumn(label: Text('#')),
                DataColumn(label: Text('Version')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Release Notes')),
                DataColumn(label: Text('Created At')),
                DataColumn(label: Text('Updated At')),
                DataColumn(label: Text('Actions')),
              ],
              rows: List.generate(bundles.length, (index) {
                final bundle = bundles[index];
                final rowNumber = (_currentPage - 1) * _limit + index + 1;
                return _buildDataRow(context, bundle, rowNumber);
              }),
            ),
          ),
        ),
      ),
    );
  }

  DataRow _buildDataRow(
    BuildContext context,
    FirmwareBundle bundle,
    int rowNumber,
  ) {
    final status = bundle.approvalStatus.toUpperCase();
    final Color statusColor;
    switch (status) {
      case 'APPROVED':
        statusColor = Colors.green;
      case 'REVOKED':
        statusColor = Colors.red;
      default:
        statusColor = Colors.orange;
    }
    final statusLabel = bundle.approvalStatus.toUpperCase();

    return DataRow(
      cells: [
        DataCell(Text('$rowNumber')),
        DataCell(SelectableText(bundle.version.split('+').first)),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              statusLabel,
              style: context.textTheme.labelSmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 250),
            child: Text(
              bundle.releaseNotes,
              softWrap: true,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(_buildDateCell(context, bundle.createdAt)),
        DataCell(_buildDateCell(context, bundle.updatedAt)),
        DataCell(_buildActionButton(context, bundle)),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, FirmwareBundle bundle) {
    final isApproved = bundle.approvalStatus.toUpperCase() == 'APPROVED';

    if (isApproved) {
      return SizedBox(
        height: 30,
        child: ElevatedButton(
          onPressed: () => _handleAction(bundle, 'revoke'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          child: Text(
            'Revoke',
            style: context.textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 30,
      child: ElevatedButton(
        onPressed: () => _handleAction(bundle, 'approve'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        child: Text(
          'Approve',
          style: context.textTheme.labelSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildPagination(BuildContext context) {
    return Row(
      children: [
        OutlinedButton(
          onPressed: _currentPage > 1
              ? () {
                  setState(() => _currentPage--);
                  _loadBundles();
                }
              : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: context.colorScheme.textPrimary,
            side: BorderSide(color: context.colorScheme.strokeLight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: const Text('← Prev'),
        ),
        const SizedBox(width: 16),
        Text(
          'Page $_currentPage of $_totalPages ($_total total)',
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colorScheme.elevation6,
          ),
        ),
        const SizedBox(width: 16),
        OutlinedButton(
          onPressed: _currentPage < _totalPages
              ? () {
                  setState(() => _currentPage++);
                  _loadBundles();
                }
              : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: context.colorScheme.textPrimary,
            side: BorderSide(color: context.colorScheme.strokeLight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: const Text('Next →'),
        ),
      ],
    );
  }

  Widget _buildDateCell(BuildContext context, String dateStr) {
    if (dateStr.isEmpty) return const SizedBox.shrink();
    try {
      final dt = DateTime.parse(dateStr);
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final year = dt.year;
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      final second = dt.second.toString().padLeft(2, '0');
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$day/$month/$year'),
          Text(
            '$hour:$minute:$second',
            style: context.textTheme.labelSmall?.copyWith(
              color: context.colorScheme.elevation6,
            ),
          ),
        ],
      );
    } catch (_) {
      return Text(dateStr);
    }
  }
}
