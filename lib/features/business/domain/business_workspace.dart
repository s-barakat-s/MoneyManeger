class BusinessWorkspace {
  const BusinessWorkspace({
    required this.businessId,
    required this.businessName,
    required this.roleId,
    required this.roleName,
  });

  final String businessId;
  final String businessName;
  final String roleId;
  final String roleName;
}

class WorkspaceResolution {
  const WorkspaceResolution({
    required this.workspaces,
    this.selectedBusinessId,
  });

  final List<BusinessWorkspace> workspaces;
  final String? selectedBusinessId;

  bool get hasSelectedBusiness => selectedBusinessId != null;
}
