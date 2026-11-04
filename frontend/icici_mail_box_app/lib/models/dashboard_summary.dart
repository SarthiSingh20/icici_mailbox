class DashboardSummary {
  const DashboardSummary({
    required this.totalShipments,
    required this.totalInbound,
    required this.totalOutbound,
    required this.pendingShipments,
    required this.inTransitShipments,
    required this.deliveredShipments,
    required this.receivedToday,
    required this.dispatchedToday,
    required this.activeBranches,
    required this.activeOperators,
  });

  final int totalShipments;
  final int totalInbound;
  final int totalOutbound;
  final int pendingShipments;
  final int inTransitShipments;
  final int deliveredShipments;
  final int receivedToday;
  final int dispatchedToday;
  final int activeBranches;
  final int activeOperators;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      totalShipments: json['totalShipments'] as int? ?? 0,
      totalInbound: json['totalInbound'] as int? ?? 0,
      totalOutbound: json['totalOutbound'] as int? ?? 0,
      pendingShipments: json['pendingShipments'] as int? ?? 0,
      inTransitShipments: json['inTransitShipments'] as int? ?? 0,
      deliveredShipments: json['deliveredShipments'] as int? ?? 0,
      receivedToday: json['receivedToday'] as int? ?? 0,
      dispatchedToday: json['dispatchedToday'] as int? ?? 0,
      activeBranches: json['activeBranches'] as int? ?? 0,
      activeOperators: json['activeOperators'] as int? ?? 0,
    );
  }
}

class BranchShipmentSummary {
  const BranchShipmentSummary({
    required this.branchId,
    required this.branchCode,
    required this.branchName,
    required this.totalShipments,
    required this.inboundShipments,
    required this.outboundShipments,
    required this.pendingShipments,
    required this.deliveredShipments,
  });

  final int branchId;
  final String branchCode;
  final String branchName;
  final int totalShipments;
  final int inboundShipments;
  final int outboundShipments;
  final int pendingShipments;
  final int deliveredShipments;

  factory BranchShipmentSummary.fromJson(Map<String, dynamic> json) =>
      BranchShipmentSummary(
        branchId: (json['branchId'] as num).toInt(),
        branchCode: json['branchCode'] as String,
        branchName: json['branchName'] as String,
        totalShipments: (json['totalShipments'] as num).toInt(),
        inboundShipments: (json['inboundShipments'] as num).toInt(),
        outboundShipments: (json['outboundShipments'] as num).toInt(),
        pendingShipments: (json['pendingShipments'] as num).toInt(),
        deliveredShipments: (json['deliveredShipments'] as num).toInt(),
      );
}
