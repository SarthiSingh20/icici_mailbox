import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:icici_mail_box_app/models/app_user.dart';
import 'package:icici_mail_box_app/screens/dashboard_screen.dart';
import 'package:icici_mail_box_app/screens/login_screen.dart';
import 'package:icici_mail_box_app/services/api_client.dart';

void main() {
  testWidgets('shows secure sign-in for branch and head-office users', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: LoginScreen(onAuthenticated: (_) {}, onPreview: (_) {}),
        ),
      ),
    );

    expect(find.text('Secure sign in'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });

  testWidgets('offers explicitly labeled preview access only when enabled', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(onAuthenticated: (_) {}, onPreview: (_) {}),
      ),
    );

    expect(
      find.text('Preview as branch operator'),
      ApiClient.uiPreviewEnabled ? findsOneWidget : findsNothing,
    );
    expect(
      find.text('Preview as master user'),
      ApiClient.uiPreviewEnabled ? findsOneWidget : findsNothing,
    );
  });

  testWidgets('preview access opens the branch dashboard when enabled', (
    WidgetTester tester,
  ) async {
    if (!ApiClient.uiPreviewEnabled) return;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Builder(
            builder: (context) => LoginScreen(
              onAuthenticated: (_) {},
              onPreview: (user) {
                ApiClient.startPreviewSession(user);
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        DashboardScreen(user: user, onSignOut: () async {}),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.ensureVisible(find.text('Preview as branch operator'));
    await tester.tap(find.text('Preview as branch operator'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.textContaining('PREVIEW MODE'), findsOneWidget);
    expect(find.text('Mumbai Hub dashboard'), findsOneWidget);
    expect(find.text('Total shipments'), findsOneWidget);
  });

  testWidgets('master preview opens the consolidated dashboard when enabled', (
    WidgetTester tester,
  ) async {
    if (!ApiClient.uiPreviewEnabled) return;

    await tester.pumpWidget(_previewApp());
    await tester.ensureVisible(find.text('Preview as master user'));
    await tester.tap(find.text('Preview as master user'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.textContaining('PREVIEW MODE'), findsOneWidget);
    expect(find.text('Head office dashboard'), findsOneWidget);
    expect(
      find.text('Consolidated organisation-wide shipment operations.'),
      findsOneWidget,
    );
    expect(find.text('Administration'), findsOneWidget);
  });

  test('preview data is temporary, role-scoped demo data', () async {
    ApiClient.startPreviewSession(
      const AppUser(
        userId: 5,
        username: 'preview.admin',
        displayName: 'Demo Head Office Admin',
        roleName: 'MasterUser',
      ),
    );
    final api = ApiClient();
    final allShipments = await api.getShipments();
    expect(allShipments, hasLength(20));
    expect(allShipments.every((shipment) => shipment.isDemo), isTrue);

    ApiClient.startPreviewSession(
      const AppUser(
        userId: 1,
        username: 'preview.operator',
        displayName: 'Demo Branch Operator',
        roleName: 'BranchOperator',
        branchId: 1,
        branchName: 'Mumbai Hub',
      ),
    );
    final branchShipments = await api.getShipments();
    expect(branchShipments, isNotEmpty);
    expect(
      branchShipments.every(
        (shipment) => shipment.direction == 'Inbound'
            ? shipment.destinationBranchId == 1
            : shipment.originBranchId == 1,
      ),
      isTrue,
    );
    ApiClient.endPreviewSession();
  });
}

Widget _previewApp() => ProviderScope(
  child: MaterialApp(
    home: Builder(
      builder: (context) => LoginScreen(
        onAuthenticated: (_) {},
        onPreview: (user) {
          ApiClient.startPreviewSession(user);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) =>
                  DashboardScreen(user: user, onSignOut: () async {}),
            ),
          );
        },
      ),
    ),
  ),
);
