class AppUser {
  const AppUser({
    required this.userId,
    required this.username,
    required this.displayName,
    required this.roleName,
    this.branchId,
    this.branchName,
  });

  final int userId;
  final String username;
  final String displayName;
  final String roleName;
  final int? branchId;
  final String? branchName;

  bool get isMaster => roleName == 'MasterUser';

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    userId: (json['userId'] as num).toInt(),
    username: json['username'] as String,
    displayName: json['displayName'] as String,
    roleName: json['roleName'] as String,
    branchId: (json['branchId'] as num?)?.toInt(),
    branchName: json['branchName'] as String?,
  );
}

class LoginResult {
  const LoginResult({
    required this.accessToken,
    required this.expiresUtc,
    required this.user,
  });

  final String accessToken;
  final DateTime expiresUtc;
  final AppUser user;

  factory LoginResult.fromJson(Map<String, dynamic> json) => LoginResult(
    accessToken: json['accessToken'] as String,
    expiresUtc: DateTime.parse(json['expiresUtc'] as String).toLocal(),
    user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
  );
}
