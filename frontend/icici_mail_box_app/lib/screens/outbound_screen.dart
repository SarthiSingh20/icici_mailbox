import 'package:flutter/material.dart';

import 'shipment_screen.dart';

class OutboundScreen extends StatelessWidget {
  const OutboundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ShipmentScreen(direction: 'Outbound');
  }
}
