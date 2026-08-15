import 'package:cloud_functions/cloud_functions.dart';

import '../../../core/firebase/callable_response.dart';
import '../domain/business_workspace.dart';
import '../domain/repositories/business_workspace_repository.dart';

class CallableBusinessWorkspaceRepository
    implements BusinessWorkspaceRepository {
  const CallableBusinessWorkspaceRepository({
    required FirebaseFunctions functions,
  }) : _functions = functions;

  final FirebaseFunctions _functions;

  @override
  Future<WorkspaceResolution> resolve() async {
    final result = await _functions
        .httpsCallable('resolveMyBusinessWorkspaces')
        .call();
    final data = callableMap(result.data);
    final selected = data['selectedBusinessId'];
    return WorkspaceResolution(
      selectedBusinessId: selected is String && selected.isNotEmpty
          ? selected
          : null,
      workspaces: callableMapList(data['workspaces'])
          .map(
            (workspace) => BusinessWorkspace(
              businessId: requiredResponseString(workspace, 'businessId'),
              businessName: requiredResponseString(workspace, 'businessName'),
              roleId: requiredResponseString(workspace, 'roleId'),
              roleName: requiredResponseString(workspace, 'roleName'),
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<String> create({required String name}) async {
    final result = await _functions
        .httpsCallable('createBusinessWorkspace')
        .call({'name': name});
    return requiredResponseString(callableMap(result.data), 'businessId');
  }

  @override
  Future<String> select({required String businessId}) async {
    final result = await _functions
        .httpsCallable('selectBusinessWorkspace')
        .call({'businessId': businessId});
    return requiredResponseString(callableMap(result.data), 'businessId');
  }
}
