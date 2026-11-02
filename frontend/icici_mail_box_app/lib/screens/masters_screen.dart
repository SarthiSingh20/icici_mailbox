import 'package:flutter/material.dart';

import '../widgets/screen_placeholder.dart';

class MastersScreen extends StatelessWidget {
  const MastersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScreenPlaceholder(
      title: 'Masters',
      description: 'Maintain branch, customer, service type, and user master records here.',
      icon: Icons.settings_outlined,
    );
  }
}
