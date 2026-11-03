import 'package:flutter/material.dart';

import 'shipment_screen.dart';

class InboundScreen extends StatelessWidget {
  const InboundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ShipmentScreen(direction: 'Inbound');
  }
}
