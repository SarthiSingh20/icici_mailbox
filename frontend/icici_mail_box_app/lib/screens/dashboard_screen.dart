import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/app_user.dart';
import '../models/dashboard_summary.dart';
import '../models/shipment.dart';
import '../services/api_client.dart';
import '../widgets/api_settings_dialog.dart';
import '../widgets/stat_card.dart';
import 'inbound_screen.dart';
import 'masters_screen.dart';
import 'outbound_screen.dart';

final navigationIndexProvider = NotifierProvider<NavigationIndexNotifier, int>(
  NavigationIndexNotifier.new,
);

class NavigationIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index;
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({
    required this.user,
    required this.onSignOut,
    super.key,
  });

  final AppUser user;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(navigationIndexProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    final isExtendedRail = MediaQuery.sizeOf(context).width >= 1150;
    final destinations = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      const NavigationDestination(
        icon: Icon(Icons.move_to_inbox_outlined),
        selectedIcon: Icon(Icons.move_to_inbox),
        label: 'Inbound',
      ),
      const NavigationDestination(
        icon: Icon(Icons.local_shipping_outlined),
        selectedIcon: Icon(Icons.local_shipping),
        label: 'Outbound',
      ),
      if (user.isMaster)
        const NavigationDestination(
          icon: Icon(Icons.admin_panel_settings_outlined),
          selectedIcon: Icon(Icons.admin_panel_settings),
          label: 'Administration',
        ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('ICICI Mail Box'),
        actions: [
          IconButton(
            tooltip: 'API connection settings',
            onPressed: () => showDialog<void>(
              context: context,
              builder: (context) => const ApiSettingsDialog(),
            ),
            icon: const Icon(Icons.dns_outlined),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: PopupMenuButton<String>(
              tooltip: 'Account menu',
              onSelected: (value) {
                if (value == 'signOut') {
                  onSignOut();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  enabled: false,
                  value: 'profile',
                  child: Text(
                    '${user.displayName}\n${user.roleName}${user.branchName == null ? '' : '\n${user.branchName}'}',
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(value: 'signOut', child: Text('Sign out')),
              ],
              child: CircleAvatar(
                child: Text(
                  user.displayName.isEmpty
                      ? '?'
                      : user.displayName.substring(0, 1).toUpperCase(),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (ApiClient.uiPreviewEnabled && ApiClient.previewMode)
            Container(
              width: double.infinity,
              color: Theme.of(context).colorScheme.tertiaryContainer,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'PREVIEW MODE · Demo data only. Changes are temporary and are not saved to SQL Server.',
                style: Theme.of(context).textTheme.labelMedium,
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: Row(
              children: [
                if (isWide)
                  NavigationRail(
                    extended: isExtendedRail,
                    selectedIndex: selectedIndex.clamp(
                      0,
                      destinations.length - 1,
                    ),
                    labelType: isExtendedRail
                        ? NavigationRailLabelType.none
                        : NavigationRailLabelType.all,
                    onDestinationSelected: (index) => ref
                        .read(navigationIndexProvider.notifier)
                        .select(index),
                    destinations: [
                      const NavigationRailDestination(
                        icon: Icon(Icons.dashboard_outlined),
                        selectedIcon: Icon(Icons.dashboard),
                        label: Text('Dashboard'),
                      ),
                      const NavigationRailDestination(
                        icon: Icon(Icons.move_to_inbox_outlined),
                        selectedIcon: Icon(Icons.move_to_inbox),
                        label: Text('Inbound'),
                      ),
                      const NavigationRailDestination(
                        icon: Icon(Icons.local_shipping_outlined),
                        selectedIcon: Icon(Icons.local_shipping),
                        label: Text('Outbound'),
                      ),
                      if (user.isMaster)
                        const NavigationRailDestination(
                          icon: Icon(Icons.admin_panel_settings_outlined),
                          selectedIcon: Icon(Icons.admin_panel_settings),
                          label: Text('Administration'),
                        ),
                    ],
                  ),
                if (isWide) const VerticalDivider(width: 1),
                Expanded(
                  child: _bodyFor(
                    selectedIndex,
                    user,
                    (index) => ref
                        .read(navigationIndexProvider.notifier)
                        .select(index),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: selectedIndex.clamp(0, destinations.length - 1),
              onDestinationSelected: (index) =>
                  ref.read(navigationIndexProvider.notifier).select(index),
              destinations: destinations,
            ),
    );
  }

  Widget _bodyFor(
    int index,
    AppUser currentUser,
    ValueChanged<int> onNavigate,
  ) {
    if (index == 0) {
      return _DashboardOverview(user: currentUser, onNavigate: onNavigate);
    }
    if (index == 1) return InboundScreen(user: currentUser);
    if (index == 2) return OutboundScreen(user: currentUser);
    return currentUser.isMaster
        ? const MastersScreen()
        : _DashboardOverview(user: currentUser, onNavigate: onNavigate);
  }
}

class _DashboardOverview extends StatefulWidget {
  const _DashboardOverview({required this.user, required this.onNavigate});

  final AppUser user;
  final ValueChanged<int> onNavigate;

  @override
  State<_DashboardOverview> createState() => _DashboardOverviewState();
}

class _DashboardOverviewState extends State<_DashboardOverview> {
  final _apiClient = ApiClient();
  DashboardSummary? _summary;
  List<BranchShipmentSummary> _branchSummaries = const [];
  List<Shipment> _recentShipments = const [];
  String? _errorMessage;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait<Object>([
        _apiClient.getDashboardSummary(),
        _apiClient.getShipments(limit: 10),
        if (widget.user.isMaster) _apiClient.getBranchShipmentSummary(),
      ]);
      if (mounted) {
        setState(() {
          _summary = results[0] as DashboardSummary;
          _recentShipments = results[1] as List<Shipment>;
          _branchSummaries = widget.user.isMaster
              ? results[2] as List<BranchShipmentSummary>
              : const [];
        });
      }
    } catch (error) {
      if (mounted) setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;
    final formatter = NumberFormat.decimalPattern();
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.user.isMaster
                      ? 'Head office dashboard'
                      : '${widget.user.branchName ?? 'Branch'} dashboard',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              IconButton(
                onPressed: _loading ? null : _load,
                tooltip: 'Refresh dashboard',
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            widget.user.isMaster
                ? 'Consolidated organisation-wide shipment operations.'
                : 'Shipment operations for your assigned branch only.',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: () => widget.onNavigate(1),
                icon: const Icon(Icons.move_to_inbox_outlined),
                label: const Text('Quick add inbound'),
              ),
              OutlinedButton.icon(
                onPressed: () => widget.onNavigate(2),
                icon: const Icon(Icons.local_shipping_outlined),
                label: const Text('Quick add outbound'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_errorMessage != null)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Live dashboard data is unavailable. Check the API, SQL Server connection, and your session.\n$_errorMessage',
                ),
              ),
            )
          else if (summary != null) ...[
            _DashboardCards(
              summary: summary,
              formatter: formatter,
              isMaster: widget.user.isMaster,
            ),
            if (widget.user.isMaster) ...[
              const SizedBox(height: 28),
              _BranchSummaryTable(branches: _branchSummaries),
            ],
            const SizedBox(height: 28),
            _RecentShipments(shipments: _recentShipments),
          ],
        ],
      ),
    );
  }
}

class _BranchSummaryTable extends StatelessWidget {
  const _BranchSummaryTable({required this.branches});

  final List<BranchShipmentSummary> branches;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Branch-wise distribution',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 12),
      if (branches.isEmpty)
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('No active branch data is available.'),
          ),
        )
      else
        Card(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Branch')),
                DataColumn(label: Text('Total'), numeric: true),
                DataColumn(label: Text('Inbound'), numeric: true),
                DataColumn(label: Text('Outbound'), numeric: true),
                DataColumn(label: Text('Pending'), numeric: true),
                DataColumn(label: Text('Delivered'), numeric: true),
              ],
              rows: [
                for (final branch in branches)
                  DataRow(
                    cells: [
                      DataCell(
                        Text('${branch.branchName} (${branch.branchCode})'),
                      ),
                      DataCell(Text('${branch.totalShipments}')),
                      DataCell(Text('${branch.inboundShipments}')),
                      DataCell(Text('${branch.outboundShipments}')),
                      DataCell(Text('${branch.pendingShipments}')),
                      DataCell(Text('${branch.deliveredShipments}')),
                    ],
                  ),
              ],
            ),
          ),
        ),
    ],
  );
}

class _RecentShipments extends StatelessWidget {
  const _RecentShipments({required this.shipments});

  final List<Shipment> shipments;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Recent shipment activity',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 12),
      if (shipments.isEmpty)
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('No shipment activity is available.'),
          ),
        )
      else
        for (final shipment in shipments)
          Card(
            child: ListTile(
              leading: Icon(
                shipment.direction == 'Inbound'
                    ? Icons.move_to_inbox_outlined
                    : Icons.local_shipping_outlined,
              ),
              title: Text('${shipment.trackingNumber} · ${shipment.status}'),
              subtitle: Text(
                '${shipment.senderName ?? shipment.customerName} → ${shipment.recipientName} · ${DateFormat('dd MMM yyyy, hh:mm a').format(shipment.createdUtc)}${shipment.isDemo ? ' · Demo record' : ''}',
              ),
            ),
          ),
    ],
  );
}

class _DashboardCards extends StatelessWidget {
  const _DashboardCards({
    required this.summary,
    required this.formatter,
    required this.isMaster,
  });

  final DashboardSummary summary;
  final NumberFormat formatter;
  final bool isMaster;

  @override
  Widget build(BuildContext context) {
    final cards = [
      (
        'Total shipments',
        summary.totalShipments,
        Icons.inventory_2_outlined,
        Colors.blue,
      ),
      (
        'Inbound',
        summary.totalInbound,
        Icons.move_to_inbox_outlined,
        Colors.indigo,
      ),
      (
        'Outbound',
        summary.totalOutbound,
        Icons.local_shipping_outlined,
        Colors.deepPurple,
      ),
      (
        'Pending',
        summary.pendingShipments,
        Icons.schedule_outlined,
        Colors.orange,
      ),
      (
        'Delivered',
        summary.deliveredShipments,
        Icons.task_alt_outlined,
        Colors.green,
      ),
      (
        'Received today',
        summary.receivedToday,
        Icons.call_received_outlined,
        Colors.teal,
      ),
      (
        'Dispatched today',
        summary.dispatchedToday,
        Icons.send_outlined,
        Colors.purple,
      ),
      if (isMaster)
        (
          'Active branches',
          summary.activeBranches,
          Icons.account_tree_outlined,
          Colors.brown,
        ),
      if (isMaster)
        (
          'Active operators',
          summary.activeOperators,
          Icons.groups_outlined,
          Colors.cyan,
        ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 1100
            ? (constraints.maxWidth - 48) / 4
            : constraints.maxWidth >= 650
            ? (constraints.maxWidth - 24) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final card in cards)
              SizedBox(
                width: width,
                child: StatCard(
                  label: card.$1,
                  value: formatter.format(card.$2),
                  icon: card.$3,
                  color: card.$4,
                ),
              ),
          ],
        );
      },
    );
  }
}
