/// `GET /api/admin/auth/me` — matches `AdminAuthMeDto` (camelCase JSON).
class AdminAuthMe {
  const AdminAuthMe({
    required this.userName,
    this.displayName,
    this.email,
    this.donViId,
    this.loai,
    this.role,
    this.fullSystemScope = false,
  });

  final String userName;
  final String? displayName;
  final String? email;
  final int? donViId;
  final int? loai;
  final String? role;
  final bool fullSystemScope;

  factory AdminAuthMe.fromJson(Map<String, dynamic> json) {
    return AdminAuthMe(
      userName: json['userName'] as String? ?? '',
      displayName: json['displayName'] as String?,
      email: json['email'] as String?,
      donViId: (json['donViId'] as num?)?.toInt(),
      loai: (json['loai'] as num?)?.toInt(),
      role: json['role'] as String?,
      fullSystemScope: json['fullSystemScope'] as bool? ?? false,
    );
  }
}
