import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/app_user.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'services/api_client.dart';

void main() {
  runApp(const ProviderScope(child: IciciMailBoxApp()));
}

class IciciMailBoxApp extends StatefulWidget {
  const IciciMailBoxApp({super.key});

  @override
  State<IciciMailBoxApp> createState() => _IciciMailBoxAppState();
}

class _IciciMailBoxAppState extends State<IciciMailBoxApp> {
  final _apiClient = ApiClient();
  AppUser? _user;
  String? _sessionError;
  bool _checkingSession = true;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      if (await _apiClient.hasAccessToken()) {
        _user = await _apiClient.getCurrentUser();
      }
    } catch (error) {
      if (error is ApiException && error.statusCode == 401) {
        await _apiClient.clearSession();
      } else {
        _sessionError = error is ApiException ? error.message : 'Could not verify your saved session. Check the API connection and sign in again.';
      }
    }
    if (mounted) {
      setState(() => _checkingSession = false);
    }
  }

  Future<void> _signOut() async {
    ApiClient.endPreviewSession();
    await _apiClient.clearSession();
    if (mounted) {
      setState(() => _user = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFFE77817);

    return MaterialApp(
      title: 'ICICI Mail Box',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: _checkingSession
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _user == null
          ? LoginScreen(
              initialErrorMessage: _sessionError,
              onAuthenticated: (user) => setState(() {
                _user = user;
                _sessionError = null;
              }),
              onPreview: (user) {
                ApiClient.startPreviewSession(user);
                setState(() {
                  _user = user;
                  _sessionError = null;
                });
              },
            )
          : DashboardScreen(user: _user!, onSignOut: _signOut),
    );
  }
}
