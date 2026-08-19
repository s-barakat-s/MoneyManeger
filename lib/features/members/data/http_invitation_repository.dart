import '../../../core/backend/authenticated_backend_client.dart';
import '../domain/business_invitation.dart';
import '../domain/repositories/invitation_repository.dart';

class HttpInvitationRepository implements InvitationRepository {
  const HttpInvitationRepository({required AuthenticatedBackendClient backend})
    : _backend = backend;

  final AuthenticatedBackendClient _backend;

  @override
  Future<List<BusinessInvitation>> listBusinessInvitations(
    String businessId,
  ) async {
    final data = await _backend.get(
      '/api/businesses/${Uri.encodeComponent(businessId)}/invitations',
    );
    return _mapList(data['invitations'])
        .map((invitation) {
          final status = InvitationStatus.tryParse(invitation['status']);
          if (status == null) {
            throw const FormatException('An invitation status is invalid.');
          }
          return BusinessInvitation(
            id: _requiredString(invitation, 'id'),
            email: _requiredString(invitation, 'email'),
            roleId: _requiredString(invitation, 'roleId'),
            status: status,
            invitedBy: _requiredString(invitation, 'invitedBy'),
          );
        })
        .toList(growable: false);
  }

  @override
  Future<void> create({
    required String businessId,
    required String email,
    required String roleId,
  }) async {
    await _backend.post(
      '/api/businesses/${Uri.encodeComponent(businessId)}/invitations',
      body: {'email': email, 'roleId': roleId},
    );
  }

  @override
  Future<void> revoke({
    required String businessId,
    required String invitationId,
  }) async {
    await _backend.post(
      '/api/businesses/${Uri.encodeComponent(businessId)}/invitations/'
      '${Uri.encodeComponent(invitationId)}/revoke',
      body: const {},
    );
  }

  @override
  Future<List<InvitationOffer>> discoverMine() async {
    final data = await _backend.get('/api/invitations/mine');
    return _mapList(data['invitations'])
        .map(
          (invitation) => InvitationOffer(
            id: _requiredString(invitation, 'id'),
            businessId: _requiredString(invitation, 'businessId'),
            businessName: _requiredString(invitation, 'businessName'),
            roleId: _requiredString(invitation, 'roleId'),
            roleName: _requiredString(invitation, 'roleName'),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<String> accept({
    required String businessId,
    required String invitationId,
  }) async {
    final data = await _backend.post(
      '/api/invitations/${Uri.encodeComponent(invitationId)}/accept',
      body: {'businessId': businessId},
    );
    return _requiredString(data, 'businessId');
  }
}

List<Map<String, dynamic>> _mapList(Object? value) {
  if (value is! List) {
    throw const FormatException('The server returned an invalid list.');
  }
  return value
      .map((item) {
        if (item is Map) return Map<String, dynamic>.from(item);
        throw const FormatException('The server returned an invalid item.');
      })
      .toList(growable: false);
}

String _requiredString(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is String && value.trim().isNotEmpty) return value.trim();
  throw FormatException('The server response is missing $key.');
}
