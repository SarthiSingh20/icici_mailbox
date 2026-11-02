import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:icici_mail_box_app/main.dart';

void main() {
  testWidgets('shows the courier dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: IciciMailBoxApp()));

    expect(find.text('Courier dashboard'), findsOneWidget);
    expect(find.text('Total shipments'), findsOneWidget);
  });
}
