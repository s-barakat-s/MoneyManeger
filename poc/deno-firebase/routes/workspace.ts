import { FieldValue } from "firebase-admin/firestore";

import type { TrustedIdentity } from "../auth/firebase_auth.ts";
import { ensureSystemRoles } from "../domain/business_policy.ts";
import { protectedOwnerRoleId, systemRoles } from "../domain/system_roles.ts";
import { getFirebaseServices } from "../firebase/admin.ts";
import { ApiError, readJsonObject, requiredString } from "../http/api.ts";

interface WorkspaceResponse {
  businessId: string;
  businessName: string;
  roleId: string;
  roleName: string;
  isOwner: boolean;
}

export async function resolveWorkspaces(identity: TrustedIdentity) {
  const firestore = getFirebaseServices().firestore;
  const profileRef = firestore.collection("userProfiles").doc(identity.uid);
  const [profile, memberships] = await Promise.all([
    profileRef.get(),
    firestore.collectionGroup("members").where("uid", "==", identity.uid).get(),
  ]);
  const activeMemberships = memberships.docs.filter(
    (membership) => membership.data().status === "active",
  );
  const businessIds = new Set<string>();
  for (const membership of activeMemberships) {
    const business = membership.ref.parent.parent;
    if (business?.parent.id === "businesses") businessIds.add(business.id);
  }
  await Promise.all([...businessIds].map(ensureSystemRoles));

  const workspaces: WorkspaceResponse[] = [];
  for (const membership of activeMemberships) {
    const business = membership.ref.parent.parent;
    if (!business || business.parent.id !== "businesses") continue;
    const roleId = membership.data().roleId;
    if (typeof roleId !== "string") continue;
    const [businessSnapshot, roleSnapshot] = await Promise.all([
      business.get(),
      business.collection("roles").doc(roleId).get(),
    ]);
    if (!businessSnapshot.exists) continue;
    const rawName = businessSnapshot.data()?.name;
    const rawRoleName = roleSnapshot.data()?.name;
    workspaces.push({
      businessId: business.id,
      businessName: typeof rawName === "string" ? rawName : "Business",
      roleId,
      roleName: typeof rawRoleName === "string" ? rawRoleName : roleId,
      isOwner: businessSnapshot.data()?.ownerUid === identity.uid,
    });
  }
  workspaces.sort((left, right) =>
    left.businessName.localeCompare(right.businessName)
  );

  const configuredBusinessId = profile.data()?.activeBusinessId;
  let selectedBusinessId = typeof configuredBusinessId === "string" &&
      workspaces.some((workspace) =>
        workspace.businessId === configuredBusinessId
      )
    ? configuredBusinessId
    : null;
  if (selectedBusinessId === null && workspaces.length === 1) {
    selectedBusinessId = workspaces[0].businessId;
  }

  if (profile.exists && selectedBusinessId !== configuredBusinessId) {
    await profileRef.set(
      {
        activeBusinessId: selectedBusinessId ?? FieldValue.delete(),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  }
  return { selectedBusinessId, workspaces };
}

export async function selectWorkspace(
  request: Request,
  identity: TrustedIdentity,
) {
  const data = await readJsonObject(request);
  const businessId = requiredString(data, "businessId");
  const firestore = getFirebaseServices().firestore;
  const business = firestore.collection("businesses").doc(businessId);
  const member = business.collection("members").doc(identity.uid);
  const [businessSnapshot, memberSnapshot] = await Promise.all([
    business.get(),
    member.get(),
  ]);
  if (!businessSnapshot.exists) {
    throw new ApiError(404, "not-found", "The Business no longer exists.");
  }
  if (!memberSnapshot.exists || memberSnapshot.data()?.status !== "active") {
    throw new ApiError(
      403,
      "permission-denied",
      "Active membership is required.",
    );
  }
  await firestore.collection("userProfiles").doc(identity.uid).set(
    {
      activeBusinessId: businessId,
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
  return { businessId };
}

export async function createWorkspace(
  request: Request,
  identity: TrustedIdentity,
) {
  const data = await readJsonObject(request);
  const name = businessName(requiredString(data, "name"));
  const firestore = getFirebaseServices().firestore;
  let business = firestore.collection("businesses").doc();
  while (business.id === identity.uid) {
    business = firestore.collection("businesses").doc();
  }
  const member = business.collection("members").doc(identity.uid);
  const profile = firestore.collection("userProfiles").doc(identity.uid);
  const activity = business.collection("activityLogs").doc();

  await firestore.runTransaction(async (transaction) => {
    const profileSnapshot = await transaction.get(profile);
    if (
      !profileSnapshot.exists ||
      profileSnapshot.data()?.profileCompleted !== true
    ) {
      throw new ApiError(
        409,
        "failed-precondition",
        "Complete your profile before creating a Business.",
      );
    }
    const now = FieldValue.serverTimestamp();
    transaction.create(business, {
      name,
      ownerUid: identity.uid,
      schemaVersion: 1,
      createdAt: now,
      updatedAt: now,
    });
    for (const [roleId, definition] of Object.entries(systemRoles)) {
      transaction.create(business.collection("roles").doc(roleId), {
        id: roleId,
        name: definition.name,
        permissions: definition.permissions,
        isSystem: true,
        createdAt: now,
        updatedAt: now,
      });
    }
    transaction.create(member, {
      uid: identity.uid,
      roleId: protectedOwnerRoleId,
      status: "active",
      joinedAt: now,
      createdAt: now,
      updatedAt: now,
    });
    transaction.set(
      profile,
      { activeBusinessId: business.id, updatedAt: now },
      { merge: true },
    );
    transaction.create(activity, {
      id: activity.id,
      actorUid: identity.uid,
      action: "business.created",
      entityType: "business",
      entityId: business.id,
      createdAt: now,
    });
  });
  return { businessId: business.id };
}

function businessName(value: string): string {
  const name = value.trim();
  if (name.length < 2 || name.length > 80) {
    throw new ApiError(
      400,
      "invalid-argument",
      "Business name must be between 2 and 80 characters.",
    );
  }
  return name;
}
