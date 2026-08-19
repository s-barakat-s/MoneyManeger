class BusinessWorkspace {
  const BusinessWorkspace({
    required this.businessId,
    required this.businessName,
    required this.roleId,
    required this.roleName,
    required this.isOwner,
  });

  final String businessId;
  final String businessName;
  final String roleId;
  final String roleName;
  final bool isOwner;
}

class WorkspaceResolution {
  const WorkspaceResolution({
    required this.workspaces,
    this.selectedBusinessId,
  });

  final List<BusinessWorkspace> workspaces;
  final String? selectedBusinessId;

  bool get hasSelectedBusiness => selectedBusinessId != null;

  BusinessWorkspace? get selectedWorkspace {
    final selected = selectedBusinessId;
    if (selected == null) return null;
    for (final workspace in workspaces) {
      if (workspace.businessId == selected) return workspace;
    }
    return null;
  }
}
