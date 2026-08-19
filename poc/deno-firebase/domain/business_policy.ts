import { FieldValue } from "firebase-admin/firestore";
import type {
  DocumentReference,
  DocumentSnapshot,
  Transaction,
} from "firebase-admin/firestore";

import { getFirebaseServices } from "../firebase/admin.ts";
import { ApiError } from "../http/api.ts";
import { assertBusinessOwnerUid } from "./business_owner_policy.ts";
import { protectedOwnerRoleId, systemRoles } from "./system_roles.ts";

export const membersReadPermission = "members.read";

export function businessRef(businessId: string): DocumentReference {
  return getFirebaseServices().firestore.collection("businesses").doc(
    businessId,
  );
}

export async function requireBusinessPermission(
  businessId: string,
  uid: string,
  permission: string,
): Promise<void> {
  const business = businessRef(businessId);
  const member = await business.collection("members").doc(uid).get();
  const roleId = member.data()?.roleId;
  if (member.data()?.status !== "active" || typeof roleId !== "string") {
    throw new ApiError(
      403,
      "permission-denied",
      "Active membership is required.",
    );
  }
  const role = await business.collection("roles").doc(roleId).get();
  const permissions = role.data()?.permissions;
  if (!Array.isArray(permissions) || !permissions.includes(permission)) {
    throw new ApiError(403, "permission-denied", "Permission denied.");
  }
}

export async function requireBusinessOwner(
  businessId: string,
  uid: string,
): Promise<DocumentSnapshot> {
  const business = await businessRef(businessId).get();
  assertBusinessOwner(business, uid);
  return business;
}

export async function requireBusinessOwnerInTransaction(
  transaction: Transaction,
  businessId: string,
  uid: string,
): Promise<DocumentSnapshot> {
  const business = await transaction.get(businessRef(businessId));
  assertBusinessOwner(business, uid);
  return business;
}

function assertBusinessOwner(
  business: DocumentSnapshot,
  uid: string,
): void {
  if (!business.exists) {
    throw new ApiError(404, "not-found", "The Business no longer exists.");
  }
  assertBusinessOwnerUid(business.data()?.ownerUid, uid);
}

export async function requireBusinessPermissionInTransaction(
  transaction: Transaction,
  businessId: string,
  uid: string,
  permission: string,
): Promise<void> {
  const business = businessRef(businessId);
  const member = await transaction.get(business.collection("members").doc(uid));
  const roleId = member.data()?.roleId;
  if (member.data()?.status !== "active" || typeof roleId !== "string") {
    throw new ApiError(
      403,
      "permission-denied",
      "Active membership is required.",
    );
  }
  const role = await transaction.get(business.collection("roles").doc(roleId));
  const permissions = role.data()?.permissions;
  if (!Array.isArray(permissions) || !permissions.includes(permission)) {
    throw new ApiError(403, "permission-denied", "Permission denied.");
  }
}

export async function requireAssignableRole(
  transaction: Transaction,
  businessId: string,
  roleId: string,
): Promise<void> {
  if (roleId === protectedOwnerRoleId) {
    throw new ApiError(
      409,
      "failed-precondition",
      "Owner assignment is protected.",
    );
  }
  const role = await transaction.get(
    businessRef(businessId).collection("roles").doc(roleId),
  );
  if (!role.exists) {
    throw new ApiError(404, "not-found", "The selected role no longer exists.");
  }
}

export async function ensureSystemRoles(businessId: string): Promise<void> {
  const firestore = getFirebaseServices().firestore;
  const business = businessRef(businessId);
  await firestore.runTransaction(async (transaction) => {
    const entries = Object.entries(systemRoles);
    const references = entries.map(([roleId]) =>
      business.collection("roles").doc(roleId)
    );
    const snapshots = await Promise.all(
      references.map((reference) => transaction.get(reference)),
    );
    for (let index = 0; index < entries.length; index++) {
      const [roleId, definition] = entries[index];
      const reference = references[index];
      const snapshot = snapshots[index];
      const stored = snapshot.data();
      const storedPermissions = stored?.permissions;
      const isCurrent = snapshot.exists &&
        stored?.name === definition.name &&
        stored?.isSystem === true &&
        Array.isArray(storedPermissions) &&
        storedPermissions.length === definition.permissions.length &&
        definition.permissions.every((permission) =>
          storedPermissions.includes(permission)
        );
      if (isCurrent) continue;
      transaction.set(
        reference,
        {
          id: roleId,
          name: definition.name,
          permissions: definition.permissions,
          isSystem: true,
          ...(snapshot.exists
            ? {}
            : { createdAt: FieldValue.serverTimestamp() }),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    }
  });
}

export function activityData(
  id: string,
  actorUid: string,
  action: string,
  entityType: string,
  entityId: string,
  metadata: Record<string, unknown> = {},
): Record<string, unknown> {
  return {
    id,
    actorUid,
    action,
    entityType,
    entityId,
    createdAt: FieldValue.serverTimestamp(),
    ...(Object.keys(metadata).length > 0 ? { metadata } : {}),
  };
}
