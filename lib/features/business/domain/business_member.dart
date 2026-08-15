enum MembershipStatus {
  invited,
  active,
  suspended,
  removed;

  static MembershipStatus? tryParse(Object? value) {
    for (final status in MembershipStatus.values) {
      if (status.name == value) return status;
    }
    return null;
  }
}

class BusinessMember {
  const BusinessMember({
    required this.uid,
    required this.roleId,
    required this.status,
    this.joinedAt,
    this.invitedAt,
    this.invitedBy,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String roleId;
  final MembershipStatus status;
  final DateTime? joinedAt;
  final DateTime? invitedAt;
  final String? invitedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
