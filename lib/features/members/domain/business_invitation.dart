enum InvitationStatus {
  pending,
  accepted,
  revoked;

  static InvitationStatus? tryParse(Object? value) {
    for (final status in InvitationStatus.values) {
      if (status.name == value) return status;
    }
    return null;
  }
}

class BusinessInvitation {
  const BusinessInvitation({
    required this.id,
    required this.email,
    required this.roleId,
    required this.status,
    required this.invitedBy,
  });

  final String id;
  final String email;
  final String roleId;
  final InvitationStatus status;
  final String invitedBy;
}

class InvitationOffer {
  const InvitationOffer({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.roleId,
    required this.roleName,
  });

  final String id;
  final String businessId;
  final String businessName;
  final String roleId;
  final String roleName;
}
