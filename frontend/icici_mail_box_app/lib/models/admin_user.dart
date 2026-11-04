class AdminUser {
  const AdminUser({
    required this.userId,
    required this.username,
    required this.displayName,
    required this.isActive,
    required this.roleName,
    this.branchId,
    this.branchName,
  });

  final int userId;
  final String username;
  final String displayName;
  final bool isActive;
  final String roleName;
  final int? branchId;
  final String? branchName;

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
    userId: (json['userId'] as num).toInt(),
    username: json['username'] as String,
    displayName: json['displayName'] as String,
    isActive: json['isActive'] as bool,
    roleName: json['roleName'] as String,
    branchId: (json['branchId'] as num?)?.toInt(),
    branchName: json['branchName'] as String?,
  );
}
