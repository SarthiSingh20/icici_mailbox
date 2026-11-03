class Shipment {
  const Shipment({
    required this.shipmentId,
    required this.direction,
    required this.trackingNumber,
    required this.customerId,
    required this.customerName,
    required this.originBranchId,
    required this.originBranchName,
    required this.destinationBranchId,
    required this.destinationBranchName,
    required this.recipientName,
    required this.recipientAddress,
    required this.status,
    required this.createdUtc,
    required this.updatedUtc,
  });

  final int shipmentId;
  final String direction;
  final String trackingNumber;
  final int customerId;
  final String customerName;
  final int originBranchId;
  final String originBranchName;
  final int destinationBranchId;
  final String destinationBranchName;
  final String recipientName;
  final String recipientAddress;
  final String status;
  final DateTime createdUtc;
  final DateTime updatedUtc;

  factory Shipment.fromJson(Map<String, dynamic> json) => Shipment(
    shipmentId: (json['shipmentId'] as num).toInt(),
    direction: json['direction'] as String,
    trackingNumber: json['trackingNumber'] as String,
    customerId: (json['customerId'] as num).toInt(),
    customerName: json['customerName'] as String,
    originBranchId: (json['originBranchId'] as num).toInt(),
    originBranchName: json['originBranchName'] as String,
    destinationBranchId: (json['destinationBranchId'] as num).toInt(),
    destinationBranchName: json['destinationBranchName'] as String,
    recipientName: json['recipientName'] as String,
    recipientAddress: json['recipientAddress'] as String,
    status: json['status'] as String,
    createdUtc: DateTime.parse(json['createdUtc'] as String).toLocal(),
    updatedUtc: DateTime.parse(json['updatedUtc'] as String).toLocal(),
  );
}

class CreateShipmentRequest {
  const CreateShipmentRequest({
    required this.direction,
    required this.trackingNumber,
    required this.customerId,
    required this.originBranchId,
    required this.destinationBranchId,
    required this.recipientName,
    required this.recipientAddress,
  });

  final String direction;
  final String trackingNumber;
  final int customerId;
  final int originBranchId;
  final int destinationBranchId;
  final String recipientName;
  final String recipientAddress;

  Map<String, dynamic> toJson() => {
    'direction': direction,
    'trackingNumber': trackingNumber,
    'customerId': customerId,
    'originBranchId': originBranchId,
    'destinationBranchId': destinationBranchId,
    'recipientName': recipientName,
    'recipientAddress': recipientAddress,
  };
}
