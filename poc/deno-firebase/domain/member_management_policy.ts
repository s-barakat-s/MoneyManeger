import { ApiError } from "../http/api.ts";

export interface MemberMutation {
  action: string;
  updates: Record<string, unknown>;
  metadata: Record<string, unknown>;
  roleId?: string;
}

export function resolveMemberMutation(
  operation: string,
  currentStatus: unknown,
  currentRoleId: unknown,
  requestedRoleId: unknown,
): MemberMutation {
  if (operation === "changeRole") {
    if (typeof currentRoleId !== "string") {
      throw new ApiError(500, "data-loss", "Member role is invalid.");
    }
    if (
      typeof requestedRoleId !== "string" ||
      requestedRoleId.trim().length === 0
    ) {
      throw new ApiError(400, "invalid-argument", "Invalid roleId.");
    }
    const roleId = requestedRoleId.trim();
    return {
      action: "member.roleChanged",
      updates: { roleId },
      metadata: { fromRoleId: currentRoleId, toRoleId: roleId },
      roleId,
    };
  }
  if (operation === "suspend" && currentStatus === "active") {
    return {
      action: "member.suspended",
      updates: { status: "suspended" },
      metadata: {},
    };
  }
  if (operation === "reactivate" && currentStatus === "suspended") {
    return {
      action: "member.reactivated",
      updates: { status: "active" },
      metadata: {},
    };
  }
  if (operation === "remove" && currentStatus !== "removed") {
    return {
      action: "member.removed",
      updates: { status: "removed" },
      metadata: {},
    };
  }
  throw new ApiError(
    409,
    "failed-precondition",
    "Invalid member transition.",
  );
}
