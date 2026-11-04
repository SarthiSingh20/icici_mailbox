import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/audit_log.dart';
import '../models/admin_user.dart';
import '../models/master_option.dart';
import '../services/api_client.dart';

class MastersScreen extends StatefulWidget {
  const MastersScreen({super.key});

  @override
  State<MastersScreen> createState() => _MastersScreenState();
}

class _MastersScreenState extends State<MastersScreen> {
  final _apiClient = ApiClient();
  List<AdminUser> _users = const [];
  List<MasterOption> _branches = const [];
  List<AuditLog> _auditLogs = const [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<Object>([
        _apiClient.getUsers(),
        _apiClient.getBranches(),
        _apiClient.getAuditLogs(),
      ]);
      if (mounted) {
        setState(() {
          _users = results[0] as List<AdminUser>;
          _branches = results[1] as List<MasterOption>;
          _auditLogs = results[2] as List<AuditLog>;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleUser(AdminUser user) async {
    try {
      await _apiClient.setUserActive(user.userId, !user.isActive);
      await _load();
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _showCreateUserDialog() async {
    final username = TextEditingController();
    final displayName = TextEditingController();
    final password = TextEditingController();
    int? branchId = _branches.isEmpty ? null : _branches.first.id;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create branch operator'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: username,
                  decoration: const InputDecoration(labelText: 'Username'),
                ),
                TextField(
                  controller: displayName,
                  decoration: const InputDecoration(labelText: 'Display name'),
                ),
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Temporary password (12+ characters)',
                  ),
                ),
                DropdownButtonFormField<int>(
                  initialValue: branchId,
                  decoration: const InputDecoration(
                    labelText: 'Assigned branch',
                  ),
                  items: _branches
                      .map(
                        (branch) => DropdownMenuItem(
                          value: branch.id,
                          child: Text(branch.label),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) => setDialogState(() => branchId = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: branchId == null
                  ? null
                  : () async {
                      try {
                        await _apiClient.createBranchOperator(
                          username: username.text.trim(),
                          displayName: displayName.text.trim(),
                          password: password.text,
                          branchId: branchId!,
                        );
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext, true);
                        }
                      } catch (error) {
                        if (dialogContext.mounted) _showError(error);
                      }
                    },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
    username.dispose();
    displayName.dispose();
    password.dispose();
    if (saved == true) await _load();
  }

  Future<void> _showCreateBranchDialog() async {
    final code = TextEditingController();
    final name = TextEditingController();
    final city = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create branch'),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: code,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Branch code'),
              ),
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Branch name'),
              ),
              TextField(
                controller: city,
                decoration: const InputDecoration(labelText: 'City'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await _apiClient.createBranch(
                  branchCode: code.text.trim(),
                  branchName: name.text.trim(),
                  city: city.text.trim(),
                );
                if (dialogContext.mounted) Navigator.pop(dialogContext, true);
              } catch (error) {
                if (dialogContext.mounted) _showError(error);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
    code.dispose();
    name.dispose();
    city.dispose();
    if (saved == true) await _load();
  }

  void _showError(Object error) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(error.toString()),
      backgroundColor: Theme.of(context).colorScheme.error,
    ),
  );

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: _load,
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Head-office administration',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            IconButton(
              onPressed: _loading ? null : _load,
              tooltip: 'Refresh administration data',
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Manage branches and branch-operator accounts. Access is enforced by the API for master users only.',
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: _showCreateUserDialog,
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Create branch operator'),
            ),
            OutlinedButton.icon(
              onPressed: _showCreateBranchDialog,
              icon: const Icon(Icons.add_business),
              label: const Text('Create branch'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Registered users', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(48),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_error!),
            ),
          )
        else
          for (final user in _users)
            Card(
              child: ListTile(
                leading: Icon(
                  user.roleName == 'MasterUser'
                      ? Icons.admin_panel_settings
                      : Icons.person_outline,
                ),
                title: Text(user.displayName),
                subtitle: Text(
                  '${user.username} • ${user.roleName}${user.branchName == null ? '' : ' • ${user.branchName}'}',
                ),
                trailing: Switch(
                  value: user.isActive,
                  onChanged: user.roleName == 'BranchOperator'
                      ? (_) => _toggleUser(user)
                      : null,
                ),
              ),
            ),
        const SizedBox(height: 24),
        Text('Active branches', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        for (final branch in _branches)
          Card(
            child: ListTile(
              leading: const Icon(Icons.account_tree_outlined),
              title: Text(branch.label),
              subtitle: Text(branch.code),
            ),
          ),
        const SizedBox(height: 24),
        Text(
          'Recent audit activity',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        if (_auditLogs.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No audit activity is available.'),
            ),
          )
        else
          for (final entry in _auditLogs)
            Card(
              child: ListTile(
                leading: const Icon(Icons.history),
                title: Text(
                  '${entry.action} · ${entry.entityType}${entry.entityId == null ? '' : ' ${entry.entityId}'}',
                ),
                subtitle: Text(
                  '${entry.displayName ?? entry.username ?? 'System'}${entry.detail == null ? '' : ' · ${entry.detail}'}\n${DateFormat('dd MMM yyyy, hh:mm a').format(entry.occurredUtc)}',
                ),
              ),
            ),
      ],
    ),
  );
}
