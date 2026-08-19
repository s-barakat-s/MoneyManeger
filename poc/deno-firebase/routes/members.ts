import { FieldValue } from "firebase-admin/firestore";

import type { TrustedIdentity } from "../auth/firebase_auth.ts";
import {
  activityData,
  businessRef,
  ensureSystemRoles,
  membersReadPermission,
  requireAssignableRole,
  requireBusinessOwner,
  requireBusinessOwnerInTransaction,
  requireBusinessPermission,
} from "../domain/business_policy.ts";
import { protectedOwnerRoleId } from "../domain/system_roles.ts";
import { resolveMemberMutation } from "../domain/member_management_policy.ts";
import { getFirebaseServices } from "../firebase/admin.ts";
import { ApiError, readJsonObject, requiredString } from "../http/api.ts";

type MemberRoute =
  | { operation: "list" | "assignableRoles"; businessId: string }
  | { operation: "manage"; businessId: string; targetUid: string };

export async function handleMemberRoute(
  request: Request,
  pathname: string,
  identity: TrustedIdentity,
): Promise<Record<string, unknown> | null> {
  const route = matchMemberRoute(request.method, pathname);
  if (route === null) return null;

  switch (route.operation) {
    case "list":
      return await listBusinessMembers(route.businessId, identity);
    case "assignableRoles":
      return await listAssignableBusinessRoles(route.businessId, identity);
    case "manage":
      return await manageBusinessMember(
        request,
        route.businessId,
        route.targetUid,
        identity,
      );
  }
}

function matchMemberRoute(
  method: string,
  pathname: string,
): MemberRoute | null {
  const members = /^\/api\/businesses\/([^/]+)\/members$/.exec(pathname);
  if (method === "GET" && members) {
    return {
      operation: "list",
      businessId: decodePathSegment(members[1]),
    };
  }

  const roles = /^\/api\/businesses\/([^/]+)\/roles\/assignable$/
    .exec(pathname);
  if (method === "GET" && roles) {
    return {
      operation: "assignableRoles",
      businessId: decodePathSegment(roles[1]),
    };
  }

  const manage = /^\/api\/businesses\/([^/]+)\/members\/([^/]+)\/manage$/
    .exec(pathname);
  if (method === "POST" && manage) {
    return {
      operation: "manage",
      businessId: decodePathSegment(manage[1]),
      targetUid: decodePathSegment(manage[2]),
    };
  }
  return null;
}

async function listBusinessMembers(
  businessId: string,
  identity: TrustedIdentity,
) {
  await requireBusinessPermission(
    businessId,
    identity.uid,
    membersReadPermission,
  );

  const firestore = getFirebaseServices().firestore;
  const business = businessRef(businessId);
  const [businessSnapshot, membersSnapshot, rolesSnapshot] = await Promise.all([
    business.get(),
    business.collection("members").get(),
    business.collection("roles").get(),
  ]);
  if (!businessSnapshot.exists) {
    throw new ApiError(404, "not-found", "The Business no longer exists.");
  }
  const profileReferences = membersSnapshot.docs.map((member) =>
    firestore.collection("userProfiles").doc(member.id)
  );
  const profiles = profileReferences.length === 0
    ? []
    : await firestore.getAll(...profileReferences);
  const profileByUid = new Map(
    profiles.map((profile) => [profile.id, profile]),
  );
  const roleNames = new Map(
    rolesSnapshot.docs.map((role) => [role.id, role.data().name]),
  );

  return {
    members: membersSnapshot.docs.map((member) => {
      const data = member.data();
      const profile = profileByUid.get(member.id)?.data();
      return {
        uid: member.id,
        roleId: data.roleId,
        roleName: roleNames.get(data.roleId) ?? data.roleId,
        status: data.status,
        displayName: safeProfileString(profile?.displayName) ??
          safeProfileString(profile?.username) ?? "",
        username: safeProfileString(profile?.username) ?? "",
        email: safeProfileString(profile?.email) ?? "",
        isProtectedOwner: businessSnapshot.data()?.ownerUid === member.id,
      };
    }),
  };
}

async function listAssignableBusinessRoles(
  businessId: string,
  identity: TrustedIdentity,
) {
  await requireBusinessOwner(businessId, identity.uid);
  await ensureSystemRoles(businessId);
  const roles = await businessRef(businessId).collection("roles").get();
  return {
    roles: roles.docs
      .filter((role) => role.id !== protectedOwnerRoleId)
      .map((role) => ({
        id: role.id,
        name: safeProfileString(role.data().name) ?? role.id,
      })),
  };
}

async function manageBusinessMember(
  request: Request,
  businessId: string,
  targetUid: string,
  identity: TrustedIdentity,
) {
  const data = await readJsonObject(request);
  const operation = requiredString(data, "operation");
  const firestore = getFirebaseServices().firestore;
  const business = businessRef(businessId);
  const member = business.collection("members").doc(targetUid);
  const activity = business.collection("activityLogs").doc();

  await firestore.runTransaction(async (transaction) => {
    const businessSnapshot = await requireBusinessOwnerInTransaction(
      transaction,
      businessId,
      identity.uid,
    );
    const memberSnapshot = await transaction.get(member);
    if (!memberSnapshot.exists || memberSnapshot.data()?.status === "removed") {
      throw new ApiError(404, "not-found", "Member is not manageable.");
    }
    if (businessSnapshot.data()?.ownerUid === targetUid) {
      throw new ApiError(
        409,
        "failed-precondition",
        "The original Business owner is protected.",
      );
    }

    const currentStatus = memberSnapshot.data()?.status;
    const currentRoleId = memberSnapshot.data()?.roleId;
    const mutation = resolveMemberMutation(
      operation,
      currentStatus,
      currentRoleId,
      data.roleId,
    );
    if (mutation.roleId !== undefined) {
      await requireAssignableRole(transaction, businessId, mutation.roleId);
    }

    transaction.update(member, {
      ...mutation.updates,
      updatedAt: FieldValue.serverTimestamp(),
    });
    transaction.set(
      activity,
      activityData(
        activity.id,
        identity.uid,
        mutation.action,
        "member",
        targetUid,
        mutation.metadata,
      ),
    );
  });
  return { success: true };
}

function safeProfileString(value: unknown): string | null {
  return typeof value === "string" ? value : null;
}

function decodePathSegment(value: string): string {
  try {
    const decoded = decodeURIComponent(value).trim();
    if (decoded.length > 0 && !decoded.includes("/")) return decoded;
  } catch {
    // Converted into a stable API error below.
  }
  throw new ApiError(400, "invalid-argument", "Invalid route identifier.");
}
