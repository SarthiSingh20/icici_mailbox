import 'package:flutter/material.dart';

import '../models/app_user.dart';
import 'shipment_screen.dart';

class InboundScreen extends StatelessWidget {
  const InboundScreen({this.user, super.key});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    return ShipmentScreen(
      direction: 'Inbound',
      isMaster: user?.isMaster ?? false,
      assignedBranchId: user?.branchId,
    );
  }
}
