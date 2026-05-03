// DTO khớp backend Features/Auth/Registration (JSON camelCase).

class RegisterRoleOptionDto {
  const RegisterRoleOptionDto({required this.id, required this.name});

  final String id;
  final String name;

  factory RegisterRoleOptionDto.fromJson(Map<String, dynamic> j) {
    return RegisterRoleOptionDto(
      id: j['id']?.toString() ?? '',
      name: j['name']?.toString() ?? '',
    );
  }
}

class RegisterDonViOptionDto {
  const RegisterDonViOptionDto({required this.id, required this.ma, required this.name});

  final int id;
  final String ma;
  final String name;

  factory RegisterDonViOptionDto.fromJson(Map<String, dynamic> j) {
    return RegisterDonViOptionDto(
      id: (j['id'] as num?)?.toInt() ?? 0,
      ma: j['ma']?.toString() ?? '',
      name: j['name']?.toString() ?? '',
    );
  }
}

class RegisterUserNameCheckDto {
  const RegisterUserNameCheckDto({required this.userName, required this.taken});

  final String userName;
  final bool taken;

  factory RegisterUserNameCheckDto.fromJson(Map<String, dynamic> j) {
    return RegisterUserNameCheckDto(
      userName: j['userName']?.toString() ?? '',
      taken: j['taken'] as bool? ?? false,
    );
  }
}

class RoleSelectionDto {
  const RoleSelectionDto({required this.id, required this.name, required this.checked});

  final String id;
  final String name;
  final bool checked;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'checked': checked};
}

class DonViSelectionDto {
  const DonViSelectionDto({required this.id, required this.name, required this.checked});

  final int id;
  final String name;
  final bool checked;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'checked': checked};
}

class RegisterUserRequestDto {
  RegisterUserRequestDto({
    required this.userName,
    required this.displayName,
    required this.password,
    required this.confirmPassword,
    this.email,
    this.phone,
    this.address,
    required this.isActived,
    required this.loai,
    this.donViId,
    required this.roles,
    required this.dVs,
  });

  final String userName;
  final String displayName;
  final String password;
  final String confirmPassword;
  final String? email;
  final String? phone;
  final String? address;
  final bool isActived;
  final int loai;
  final int? donViId;
  final List<RoleSelectionDto> roles;
  final List<DonViSelectionDto> dVs;

  Map<String, dynamic> toJson() => {
        'userName': userName,
        'displayName': displayName,
        'password': password,
        'confirmPassword': confirmPassword,
        'email': email,
        'phone': phone,
        'address': address,
        'isActived': isActived,
        'loai': loai,
        'donViId': donViId,
        'roles': roles.map((e) => e.toJson()).toList(),
        'dVs': dVs.map((e) => e.toJson()).toList(),
      };
}

class RegisterUserResponseDto {
  const RegisterUserResponseDto({required this.userId, required this.userName});

  final String userId;
  final String userName;

  factory RegisterUserResponseDto.fromJson(Map<String, dynamic> j) {
    return RegisterUserResponseDto(
      userId: j['userId']?.toString() ?? '',
      userName: j['userName']?.toString() ?? '',
    );
  }
}
