enum AppRole {
  admin,
  external;

  static AppRole fromDb(String value) {
    return AppRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => AppRole.external,
    );
  }
}

class AppUserProfile {
  const AppUserProfile({
    required this.id,
    required this.role,
    required this.name,
    required this.email,
  });

  factory AppUserProfile.fromMap(Map<String, dynamic> map) {
    return AppUserProfile(
      id: map['ID'] as String,
      role: AppRole.fromDb(map['ROLE'] as String? ?? 'external'),
      name: map['NAME'] as String? ?? '',
      email: map['EMAIL'] as String? ?? '',
    );
  }

  final String id;
  final AppRole role;
  final String name;
  final String email;

  bool get isAdmin => role == AppRole.admin;
}
