/// Parsed JSON from `POST /api/oauth/token` (resource-owner password grant).
///
/// Matches backend [OAuthTokenController]: `access_token`, `token_type`, `expires_in`
/// plus merged authentication properties (`userName`, `loai`, `id_don_vi`, etc.).
class OAuthTokenLoginResponse {
  OAuthTokenLoginResponse({
    required this.accessToken,
    this.tokenType,
    this.expiresIn,
    this.issued,
    this.expires,
    this.userName,
    this.displayName,
    this.loai,
    this.idDonVi,
    this.tenDonVi,
    this.isStoreAdmin,
    required this.raw,
  });

  final String accessToken;
  final String? tokenType;
  final int? expiresIn;
  /// From `.issued` in JSON.
  final String? issued;
  /// From `.expires` in JSON.
  final String? expires;
  final String? userName;
  final String? displayName;
  /// String digits from `AspNetUsers.Loai` when present.
  final String? loai;
  /// `id_don_vi` — `DM_DonVi` / `AspNetUsers.DonViId` as string when present.
  final String? idDonVi;
  final String? tenDonVi;
  final String? isStoreAdmin;

  /// Full body for callers that need extra legacy keys.
  final Map<String, dynamic> raw;

  factory OAuthTokenLoginResponse.fromJson(Map<String, dynamic> json) {
    final token = json['access_token'];
    if (token is! String || token.trim().isEmpty) {
      throw const FormatException('Missing access_token');
    }
    int? expiresIn;
    final ei = json['expires_in'];
    if (ei is int) {
      expiresIn = ei;
    } else if (ei is num) {
      expiresIn = ei.round();
    }

    return OAuthTokenLoginResponse(
      accessToken: token.trim(),
      tokenType: json['token_type'] as String?,
      expiresIn: expiresIn,
      issued: json['.issued'] as String?,
      expires: json['.expires'] as String?,
      userName: json['userName'] as String?,
      displayName: json['displayName'] as String?,
      loai: json['loai']?.toString(),
      idDonVi: json['id_don_vi']?.toString(),
      tenDonVi: json['ten_don_vi'] as String?,
      isStoreAdmin: json['isStoreAdmin']?.toString(),
      raw: Map<String, dynamic>.from(json),
    );
  }
}
