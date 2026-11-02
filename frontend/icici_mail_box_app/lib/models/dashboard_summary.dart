class DashboardSummary {
  const DashboardSummary({
    required this.totalShipments,
    required this.pendingShipments,
    required this.inTransitShipments,
    required this.deliveredShipments,
  });

  final int totalShipments;
  final int pendingShipments;
  final int inTransitShipments;
  final int deliveredShipments;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      totalShipments: json['totalShipments'] as int? ?? 0,
      pendingShipments: json['pendingShipments'] as int? ?? 0,
      inTransitShipments: json['inTransitShipments'] as int? ?? 0,
      deliveredShipments: json['deliveredShipments'] as int? ?? 0,
    );
  }

  static const demo = DashboardSummary(
    totalShipments: 1248,
    pendingShipments: 86,
    inTransitShipments: 312,
    deliveredShipments: 850,
  );
}
