import 'package:flutter/material.dart';

import '../widgets/screen_placeholder.dart';

class InboundScreen extends StatelessWidget {
  const InboundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScreenPlaceholder(
      title: 'Inbound shipments',
      description: 'Receive consignments, assign a branch, and capture arrival scans here.',
      icon: Icons.move_to_inbox_outlined,
    );
  }
}
