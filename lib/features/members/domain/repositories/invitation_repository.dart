import '../business_invitation.dart';

abstract interface class InvitationRepository {
  Future<List<BusinessInvitation>> listBusinessInvitations(String businessId);

  Future<void> create({
    required String businessId,
    required String email,
    required String roleId,
  });

  Future<void> revoke({
    required String businessId,
    required String invitationId,
  });

  Future<List<InvitationOffer>> discoverMine();

  Future<String> accept({
    required String businessId,
    required String invitationId,
  });
}
