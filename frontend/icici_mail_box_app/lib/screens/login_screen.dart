import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/api_client.dart';
import '../widgets/api_settings_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    required this.onAuthenticated,
    required this.onPreview,
    this.initialErrorMessage,
    super.key,
  });

  final ValueChanged<AppUser> onAuthenticated;
  final ValueChanged<AppUser> onPreview;
  final String? initialErrorMessage;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _apiClient = ApiClient();
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _errorMessage = widget.initialErrorMessage;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final result = await _apiClient.login(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) {
        widget.onAuthenticated(result.user);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = error.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
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
      ],
    ),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.local_post_office_outlined,
                      size: 52,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Secure sign in',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Use your assigned branch operator or head-office account.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _usernameController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Username is required.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      onFieldSubmitted: (_) => _isSubmitting ? null : _login(),
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Password is required.'
                          : null,
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _isSubmitting ? null : _login,
                      icon: _isSubmitting
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.login),
                      label: Text(_isSubmitting ? 'Signing in…' : 'Sign in'),
                    ),
                    if (ApiClient.uiPreviewEnabled) ...[
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'UI preview only · changes are temporary and are not saved to SQL Server.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _isSubmitting
                            ? null
                            : () => widget.onPreview(
                                const AppUser(
                                  userId: 1,
                                  username: 'preview.operator',
                                  displayName: 'Demo Branch Operator',
                                  roleName: 'BranchOperator',
                                  branchId: 1,
                                  branchName: 'Mumbai Hub',
                                ),
                              ),
                        icon: const Icon(Icons.storefront_outlined),
                        label: const Text('Preview as branch operator'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _isSubmitting
                            ? null
                            : () => widget.onPreview(
                                const AppUser(
                                  userId: 5,
                                  username: 'preview.admin',
                                  displayName: 'Demo Head Office Admin',
                                  roleName: 'MasterUser',
                                ),
                              ),
                        icon: const Icon(Icons.admin_panel_settings_outlined),
                        label: const Text('Preview as master user'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
