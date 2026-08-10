/// Una persona bloqueada, con lo justo para mostrarla en la lista y poder
/// desbloquearla.
class BlockedUser {
  final String userId;
  final String firstName;
  final String lastName;
  final String? alias;
  final String profileImageUrl;
  final DateTime blockedAt;

  BlockedUser({
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.alias,
    required this.profileImageUrl,
    required this.blockedAt,
  });

  /// Nombre para mostrar. Si viniera vacío —una cuenta a medio completar— se usa
  /// el alias antes que dejar una fila en blanco que nadie sabría identificar.
  String get displayName {
    final completo = '$firstName $lastName'.trim();
    if (completo.isNotEmpty) return completo;
    if (alias != null && alias!.trim().isNotEmpty) return alias!;
    return 'Usuario';
  }

  factory BlockedUser.fromJson(Map<String, dynamic> json) {
    return BlockedUser(
      userId: json['user_id'] as String,
      firstName: (json['first_name'] ?? '') as String,
      lastName: (json['last_name'] ?? '') as String,
      alias: json['alias'] as String?,
      profileImageUrl: (json['profile_image_url'] ?? '') as String,
      blockedAt: DateTime.tryParse(json['blocked_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
