import 'package:flutter/material.dart';

import '../widgets/screen_placeholder.dart';

class OutboundScreen extends StatelessWidget {
  const OutboundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScreenPlaceholder(
      title: 'Outbound shipments',
      description: 'Create dispatch manifests, update tracking events, and manage handovers here.',
      icon: Icons.local_shipping_outlined,
    );
  }
}
