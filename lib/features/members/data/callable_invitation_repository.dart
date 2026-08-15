import 'package:cloud_functions/cloud_functions.dart';

import '../../../core/firebase/callable_response.dart';
import '../domain/business_invitation.dart';
import '../domain/repositories/invitation_repository.dart';

class CallableInvitationRepository implements InvitationRepository {
  const CallableInvitationRepository({required FirebaseFunctions functions})
    : _functions = functions;

  final FirebaseFunctions _functions;

  @override
  Future<List<BusinessInvitation>> listBusinessInvitations(
    String businessId,
  ) async {
    final result = await _functions
        .httpsCallable('listBusinessInvitations')
        .call({'businessId': businessId});
    return callableMapList(callableMap(result.data)['invitations'])
        .map((data) {
          final status = InvitationStatus.tryParse(data['status']);
          if (status == null) {
            throw const FormatException('An invitation status is invalid.');
          }
          return BusinessInvitation(
            id: requiredResponseString(data, 'id'),
            email: requiredResponseString(data, 'email'),
            roleId: requiredResponseString(data, 'roleId'),
            status: status,
            invitedBy: requiredResponseString(data, 'invitedBy'),
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
    await _functions.httpsCallable('createBusinessInvitation').call({
      'businessId': businessId,
      'email': email,
      'roleId': roleId,
    });
  }

  @override
  Future<void> revoke({
    required String businessId,
    required String invitationId,
  }) async {
    await _functions.httpsCallable('revokeBusinessInvitation').call({
      'businessId': businessId,
      'invitationId': invitationId,
    });
  }

  @override
  Future<List<InvitationOffer>> discoverMine() async {
    final result = await _functions
        .httpsCallable('discoverMyBusinessInvitations')
        .call();
    return callableMapList(callableMap(result.data)['invitations'])
        .map(
          (data) => InvitationOffer(
            id: requiredResponseString(data, 'id'),
            businessId: requiredResponseString(data, 'businessId'),
            businessName: requiredResponseString(data, 'businessName'),
            roleId: requiredResponseString(data, 'roleId'),
            roleName: requiredResponseString(data, 'roleName'),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<String> accept({
    required String businessId,
    required String invitationId,
  }) async {
    final result = await _functions
        .httpsCallable('acceptBusinessInvitation')
        .call({'businessId': businessId, 'invitationId': invitationId});
    return requiredResponseString(callableMap(result.data), 'businessId');
  }
}
