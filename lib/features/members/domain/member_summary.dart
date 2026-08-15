import '../../business/domain/business_member.dart';

class MemberSummary {
  const MemberSummary({
    required this.uid,
    required this.roleId,
    required this.roleName,
    required this.status,
    required this.isProtectedOwner,
    this.displayName,
    this.username,
    this.email,
  });

  final String uid;
  final String roleId;
  final String roleName;
  final MembershipStatus status;
  final bool isProtectedOwner;
  final String? displayName;
  final String? username;
  final String? email;

  String get primaryLabel {
    return _firstNonEmpty([displayName, username, email]) ?? uid;
  }

  String? get secondaryLabel {
    return _firstNonEmpty([email, username]);
  }

  static String? _firstNonEmpty(Iterable<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }
}
