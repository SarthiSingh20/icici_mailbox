import 'package:flutter/material.dart';

import '../models/app_user.dart';
import 'shipment_screen.dart';

class OutboundScreen extends StatelessWidget {
  const OutboundScreen({this.user, super.key});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    return ShipmentScreen(
      direction: 'Outbound',
      isMaster: user?.isMaster ?? false,
      assignedBranchId: user?.branchId,
    );
  }
}
