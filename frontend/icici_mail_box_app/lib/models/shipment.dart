class Shipment {
  const Shipment({
    required this.shipmentId,
    required this.direction,
    required this.trackingNumber,
    required this.customerId,
    required this.customerName,
    required this.senderName,
    required this.originBranchId,
    required this.originBranchName,
    required this.destinationBranchId,
    required this.destinationBranchName,
    required this.packageCategoryId,
    required this.packageCategoryName,
    required this.packageWeightKg,
    required this.packageDescription,
    required this.recipientName,
    required this.recipientAddress,
    required this.courierServiceProvider,
    required this.remarks,
    required this.status,
    required this.receivedUtc,
    required this.sentUtc,
    required this.createdByName,
    required this.isDemo,
    required this.createdUtc,
    required this.updatedUtc,
  });

  final int shipmentId;
  final String direction;
  final String trackingNumber;
  final int customerId;
  final String customerName;
  final String? senderName;
  final int originBranchId;
  final String originBranchName;
  final int destinationBranchId;
  final String destinationBranchName;
  final int? packageCategoryId;
  final String packageCategoryName;
  final double? packageWeightKg;
  final String? packageDescription;
  final String recipientName;
  final String recipientAddress;
  final String? courierServiceProvider;
  final String? remarks;
  final String status;
  final DateTime? receivedUtc;
  final DateTime? sentUtc;
  final String createdByName;
  final bool isDemo;
  final DateTime createdUtc;
  final DateTime updatedUtc;

  factory Shipment.fromJson(Map<String, dynamic> json) => Shipment(
    shipmentId: (json['shipmentId'] as num).toInt(),
    direction: json['direction'] as String,
    trackingNumber: json['trackingNumber'] as String,
    customerId: (json['customerId'] as num).toInt(),
    customerName: json['customerName'] as String,
    senderName: json['senderName'] as String?,
    originBranchId: (json['originBranchId'] as num).toInt(),
    originBranchName: json['originBranchName'] as String,
    destinationBranchId: (json['destinationBranchId'] as num).toInt(),
    destinationBranchName: json['destinationBranchName'] as String,
    packageCategoryId: (json['packageCategoryId'] as num?)?.toInt(),
    packageCategoryName: json['packageCategoryName'] as String,
    packageWeightKg: (json['packageWeightKg'] as num?)?.toDouble(),
    packageDescription: json['packageDescription'] as String?,
    recipientName: json['recipientName'] as String,
    recipientAddress: json['recipientAddress'] as String,
    courierServiceProvider: json['courierServiceProvider'] as String?,
    remarks: json['remarks'] as String?,
    status: json['status'] as String,
    receivedUtc: _dateTimeOrNull(json['receivedUtc']),
    sentUtc: _dateTimeOrNull(json['sentUtc']),
    createdByName: json['createdByName'] as String? ?? 'Unknown',
    isDemo: json['isDemo'] as bool? ?? false,
    createdUtc: DateTime.parse(json['createdUtc'] as String).toLocal(),
    updatedUtc: DateTime.parse(json['updatedUtc'] as String).toLocal(),
  );
}

class ShipmentEvent {
  const ShipmentEvent({
    required this.shipmentEventId,
    required this.eventType,
    required this.previousStatus,
    required this.newStatus,
    required this.eventDescription,
    required this.eventUtc,
    required this.changedByName,
  });

  final int shipmentEventId;
  final String eventType;
  final String? previousStatus;
  final String? newStatus;
  final String? eventDescription;
  final DateTime eventUtc;
  final String changedByName;

  factory ShipmentEvent.fromJson(Map<String, dynamic> json) => ShipmentEvent(
    shipmentEventId: (json['shipmentEventId'] as num).toInt(),
    eventType: json['eventType'] as String,
    previousStatus: json['previousStatus'] as String?,
    newStatus: json['newStatus'] as String?,
    eventDescription: json['eventDescription'] as String?,
    eventUtc: DateTime.parse(json['eventUtc'] as String).toLocal(),
    changedByName: json['changedByName'] as String,
  );
}

class CreateShipmentRequest {
  const CreateShipmentRequest({
    required this.direction,
    required this.trackingNumber,
    required this.senderName,
    required this.customerId,
    required this.originBranchId,
    required this.destinationBranchId,
    required this.packageWeightKg,
    required this.packageCategoryId,
    required this.recipientName,
    required this.recipientAddress,
    this.packageDescription,
    this.courierServiceProvider,
    this.remarks,
    this.receivedUtc,
    this.sentUtc,
  });

  final String direction;
  final String trackingNumber;
  final String senderName;
  final int customerId;
  final int originBranchId;
  final int destinationBranchId;
  final double packageWeightKg;
  final int packageCategoryId;
  final String recipientName;
  final String recipientAddress;
  final String? packageDescription;
  final String? courierServiceProvider;
  final String? remarks;
  final DateTime? receivedUtc;
  final DateTime? sentUtc;

  Map<String, dynamic> toJson() => {
    'direction': direction,
    'trackingNumber': trackingNumber,
    'senderName': senderName,
    'customerId': customerId,
    'originBranchId': originBranchId,
    'destinationBranchId': destinationBranchId,
    'packageWeightKg': packageWeightKg,
    'packageCategoryId': packageCategoryId,
    'recipientName': recipientName,
    'recipientAddress': recipientAddress,
    if (packageDescription != null) 'packageDescription': packageDescription,
    if (courierServiceProvider != null)
      'courierServiceProvider': courierServiceProvider,
    if (remarks != null) 'remarks': remarks,
    if (receivedUtc != null)
      'receivedUtc': receivedUtc!.toUtc().toIso8601String(),
    if (sentUtc != null) 'sentUtc': sentUtc!.toUtc().toIso8601String(),
  };
}

DateTime? _dateTimeOrNull(dynamic value) =>
    value is String ? DateTime.parse(value).toLocal() : null;
