class AuditLog {
  const AuditLog({
    required this.auditLogId,
    required this.username,
    required this.displayName,
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.detail,
    required this.occurredUtc,
  });

  final int auditLogId;
  final String? username;
  final String? displayName;
  final String action;
  final String entityType;
  final String? entityId;
  final String? detail;
  final DateTime occurredUtc;

  factory AuditLog.fromJson(Map<String, dynamic> json) => AuditLog(
    auditLogId: (json['auditLogId'] as num).toInt(),
    username: json['username'] as String?,
    displayName: json['displayName'] as String?,
    action: json['action'] as String,
    entityType: json['entityType'] as String,
    entityId: json['entityId'] as String?,
    detail: json['detail'] as String?,
    occurredUtc: DateTime.parse(json['occurredUtc'] as String).toLocal(),
  );
}
