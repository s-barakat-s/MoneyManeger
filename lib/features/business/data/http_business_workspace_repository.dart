import '../../../core/backend/authenticated_backend_client.dart';
import '../domain/business_workspace.dart';
import '../domain/repositories/business_workspace_repository.dart';

class HttpBusinessWorkspaceRepository implements BusinessWorkspaceRepository {
  const HttpBusinessWorkspaceRepository({
    required AuthenticatedBackendClient backend,
  }) : _backend = backend;

  final AuthenticatedBackendClient _backend;

  @override
  Future<WorkspaceResolution> resolve() async {
    final data = await _backend.get('/api/workspaces');
    final selected = data['selectedBusinessId'];
    return WorkspaceResolution(
      selectedBusinessId: selected is String && selected.isNotEmpty
          ? selected
          : null,
      workspaces: _mapList(data['workspaces'])
          .map(
            (workspace) => BusinessWorkspace(
              businessId: _requiredString(workspace, 'businessId'),
              businessName: _requiredString(workspace, 'businessName'),
              roleId: _requiredString(workspace, 'roleId'),
              roleName: _requiredString(workspace, 'roleName'),
              isOwner: workspace['isOwner'] == true,
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<String> create({required String name}) async {
    final data = await _backend.post('/api/workspaces', body: {'name': name});
    return _requiredString(data, 'businessId');
  }

  @override
  Future<String> select({required String businessId}) async {
    final data = await _backend.post(
      '/api/workspaces/select',
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
