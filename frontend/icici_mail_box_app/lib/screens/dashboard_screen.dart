import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/dashboard_summary.dart';
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
  const DashboardScreen({super.key});

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    NavigationDestination(
      icon: Icon(Icons.move_to_inbox_outlined),
      selectedIcon: Icon(Icons.move_to_inbox),
      label: 'Inbound',
    ),
    NavigationDestination(
      icon: Icon(Icons.local_shipping_outlined),
      selectedIcon: Icon(Icons.local_shipping),
      label: 'Outbound',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: 'Masters',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(navigationIndexProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ICICI Mail Box'),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {},
            icon: const Badge(child: Icon(Icons.notifications_outlined)),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(child: Text('AD')),
          ),
        ],
      ),
      body: Row(
        children: [
          if (isWide)
            NavigationRail(
              extended: MediaQuery.sizeOf(context).width >= 1150,
              selectedIndex: selectedIndex,
              labelType: NavigationRailLabelType.all,
              onDestinationSelected: (index) =>
                  ref.read(navigationIndexProvider.notifier).select(index),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.move_to_inbox_outlined),
                  selectedIcon: Icon(Icons.move_to_inbox),
                  label: Text('Inbound'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.local_shipping_outlined),
                  selectedIcon: Icon(Icons.local_shipping),
                  label: Text('Outbound'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: Text('Masters'),
                ),
              ],
            ),
          if (isWide) const VerticalDivider(width: 1),
          Expanded(child: _bodyFor(selectedIndex)),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) =>
                  ref.read(navigationIndexProvider.notifier).select(index),
              destinations: _destinations,
            ),
    );
  }

  Widget _bodyFor(int index) {
    return switch (index) {
      0 => const _DashboardOverview(),
      1 => const InboundScreen(),
      2 => const OutboundScreen(),
      _ => const MastersScreen(),
    };
  }
}

class _DashboardOverview extends StatelessWidget {
  const _DashboardOverview();

  @override
  Widget build(BuildContext context) {
    const summary = DashboardSummary.demo;
    final formatter = NumberFormat.decimalPattern();
    final cards = [
      (
        'Total shipments',
        summary.totalShipments,
        Icons.inventory_2_outlined,
        Colors.blue,
      ),
      (
        'Pending pickup',
        summary.pendingShipments,
        Icons.schedule_outlined,
        Colors.orange,
      ),
      (
        'In transit',
        summary.inTransitShipments,
        Icons.local_shipping_outlined,
        Colors.purple,
      ),
      (
        'Delivered',
        summary.deliveredShipments,
        Icons.task_alt_outlined,
        Colors.green,
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Courier dashboard',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        const Text(
          'Operational overview. Live figures will appear after the API base URL is configured.',
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
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
        ),
        const SizedBox(height: 24),
        const Card(
          child: ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Day 1 baseline'),
            subtitle: Text(
              'Inbound, outbound, and masters modules are ready for their first workflows.',
            ),
            trailing: Icon(Icons.arrow_forward),
          ),
        ),
      ],
    );
  }
}
