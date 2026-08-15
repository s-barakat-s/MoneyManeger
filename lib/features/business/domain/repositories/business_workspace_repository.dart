import '../business_workspace.dart';

abstract interface class BusinessWorkspaceRepository {
  Future<WorkspaceResolution> resolve();

  Future<String> create({required String name});

  Future<String> select({required String businessId});
}
