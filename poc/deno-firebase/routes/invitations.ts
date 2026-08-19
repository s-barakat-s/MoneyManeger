import { FieldValue } from "firebase-admin/firestore";

import type { TrustedIdentity } from "../auth/firebase_auth.ts";
import {
  invitationEmailIndexId,
  normalizeInvitationEmail,
} from "../domain/invitation_policy.ts";
import {
  activityData,
  businessRef,
  requireAssignableRole,
  requireBusinessOwner,
  requireBusinessOwnerInTransaction,
} from "../domain/business_policy.ts";
import { getFirebaseServices } from "../firebase/admin.ts";
import { ApiError, readJsonObject, requiredString } from "../http/api.ts";

type RouteMatch =
  | { operation: "list" | "create"; businessId: string }
  | { operation: "revoke"; businessId: string; invitationId: string }
  | { operation: "discover" }
  | { operation: "accept"; invitationId: string };

export async function handleInvitationRoute(
  request: Request,
  pathname: string,
  identity: TrustedIdentity,
): Promise<Record<string, unknown> | null> {
  const route = matchInvitationRoute(request.method, pathname);
  if (route === null) return null;

  switch (route.operation) {
    case "list":
      return await listBusinessInvitations(route.businessId, identity);
    case "create":
      return await createBusinessInvitation(
        request,
        route.businessId,
        identity,
      );
    case "revoke":
      return await revokeBusinessInvitation(
        route.businessId,
        route.invitationId,
        identity,
      );
    case "discover":
      return await discoverMyBusinessInvitations(identity);
    case "accept":
      return await acceptBusinessInvitation(
        request,
        route.invitationId,
        identity,
      );
  }
}

function matchInvitationRoute(
  method: string,
  pathname: string,
): RouteMatch | null {
  if (method === "GET" && pathname === "/api/invitations/mine") {
    return { operation: "discover" };
  }

  const businessInvitations = /^\/api\/businesses\/([^/]+)\/invitations$/
    .exec(pathname);
  if (businessInvitations && (method === "GET" || method === "POST")) {
    return {
      operation: method === "GET" ? "list" : "create",
      businessId: decodePathSegment(businessInvitations[1]),
    };
  }

  const revoke = /^\/api\/businesses\/([^/]+)\/invitations\/([^/]+)\/revoke$/
    .exec(pathname);
  if (method === "POST" && revoke) {
    return {
      operation: "revoke",
      businessId: decodePathSegment(revoke[1]),
      invitationId: decodePathSegment(revoke[2]),
    };
  }

  const accept = /^\/api\/invitations\/([^/]+)\/accept$/.exec(pathname);
  if (method === "POST" && accept) {
    return {
      operation: "accept",
      invitationId: decodePathSegment(accept[1]),
    };
  }
  return null;
}

async function listBusinessInvitations(
  businessId: string,
  identity: TrustedIdentity,
) {
  await requireBusinessOwner(businessId, identity.uid);
  const invitations = await businessRef(businessId)
    .collection("invitations")
    .where("status", "==", "pending")
    .limit(100)
    .get();
  return {
    invitations: invitations.docs.map((invitation) => ({
      id: invitation.id,
      email: invitation.data().emailNormalized,
      roleId: invitation.data().roleId,
      status: invitation.data().status,
      invitedBy: invitation.data().invitedBy,
    })),
  };
}

async function createBusinessInvitation(
  request: Request,
  businessId: string,
  identity: TrustedIdentity,
) {
  const data = await readJsonObject(request);
  const roleId = requiredString(data, "roleId");
  const email = normalizeInvitationEmail(requiredString(data, "email"));
  const { auth, firestore } = getFirebaseServices();
  let existingUid: string | null = null;
  try {
    existingUid = (await auth.getUserByEmail(email)).uid;
  } catch (error) {
    if (firebaseErrorCode(error) !== "auth/user-not-found") {
      throw new ApiError(500, "internal", "Member identity lookup failed.");
    }
  }

  const business = businessRef(businessId);
  const invitation = business.collection("invitations").doc();
  const invitationIndex = business.collection("invitationEmailIndex").doc(
    invitationEmailIndexId(email),
  );
  const activity = business.collection("activityLogs").doc();

  await firestore.runTransaction(async (transaction) => {
    await requireBusinessOwnerInTransaction(
      transaction,
      businessId,
      identity.uid,
    );
    await requireAssignableRole(transaction, businessId, roleId);
    if (existingUid !== null) {
      const existingMember = await transaction.get(
        business.collection("members").doc(existingUid),
      );
      if (
        existingMember.exists && existingMember.data()?.status !== "removed"
      ) {
        throw new ApiError(
          409,
          "already-exists",
          "This person already belongs to the Business.",
        );
      }
    }
    const existingIndex = await transaction.get(invitationIndex);
    if (existingIndex.exists) {
      const existingId = existingIndex.data()?.invitationId;
      if (typeof existingId === "string") {
        const existing = await transaction.get(
          business.collection("invitations").doc(existingId),
        );
        if (existing.data()?.status === "pending") {
          throw new ApiError(
            409,
            "already-exists",
            "A pending invitation already exists for this email.",
          );
        }
      }
    }

    transaction.set(invitation, {
      id: invitation.id,
      emailNormalized: email,
      roleId,
      status: "pending",
      invitedBy: identity.uid,
      invitedAt: FieldValue.serverTimestamp(),
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    transaction.set(invitationIndex, {
      emailNormalized: email,
      invitationId: invitation.id,
      updatedAt: FieldValue.serverTimestamp(),
    });
    transaction.set(
      activity,
      activityData(
        activity.id,
        identity.uid,
        "member.invited",
        "invitation",
        invitation.id,
        { roleId },
      ),
    );
  });
  return { invitationId: invitation.id };
}

async function revokeBusinessInvitation(
  businessId: string,
  invitationId: string,
  identity: TrustedIdentity,
) {
  const { firestore } = getFirebaseServices();
  const business = businessRef(businessId);
  const invitation = business.collection("invitations").doc(invitationId);
  const activity = business.collection("activityLogs").doc();

  await firestore.runTransaction(async (transaction) => {
    await requireBusinessOwnerInTransaction(
      transaction,
      businessId,
      identity.uid,
    );
    const snapshot = await transaction.get(invitation);
    if (!snapshot.exists || snapshot.data()?.status !== "pending") {
      throw new ApiError(
        409,
        "failed-precondition",
        "Invitation is not pending.",
      );
    }
    const email = snapshot.data()?.emailNormalized;
    if (typeof email !== "string") {
      throw new ApiError(500, "data-loss", "Invitation identity is invalid.");
    }
    const index = business.collection("invitationEmailIndex").doc(
      invitationEmailIndexId(email),
    );
    transaction.update(invitation, {
      status: "revoked",
      revokedBy: identity.uid,
      revokedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    transaction.delete(index);
    transaction.set(
      activity,
      activityData(
        activity.id,
        identity.uid,
        "invitation.revoked",
        "invitation",
        invitation.id,
      ),
    );
  });
  return { success: true };
}

async function discoverMyBusinessInvitations(identity: TrustedIdentity) {
  const email = verifiedIdentityEmail(identity);
  const invitations = await getFirebaseServices().firestore
    .collectionGroup("invitations")
    .where("emailNormalized", "==", email)
    .get();
  const pending = invitations.docs.filter(
    (invitation) => invitation.data().status === "pending",
  );
  const values = await Promise.all(pending.map(async (invitation) => {
    const business = invitation.ref.parent.parent;
    if (!business || business.parent.id !== "businesses") return null;
    const [businessSnapshot, roleSnapshot] = await Promise.all([
      business.get(),
      business.collection("roles").doc(invitation.data().roleId).get(),
    ]);
    if (!businessSnapshot.exists || !roleSnapshot.exists) return null;
    return {
      id: invitation.id,
      businessId: business.id,
      businessName: businessSnapshot.data()?.name ?? "Business",
      roleId: roleSnapshot.id,
      roleName: roleSnapshot.data()?.name ?? roleSnapshot.id,
    };
  }));
  return { invitations: values.filter((value) => value !== null) };
}

async function acceptBusinessInvitation(
  request: Request,
  invitationId: string,
  identity: TrustedIdentity,
) {
  const email = verifiedIdentityEmail(identity);
  const data = await readJsonObject(request);
  const bodyInvitationId = data.invitationId;
  if (bodyInvitationId !== undefined && bodyInvitationId !== invitationId) {
    throw new ApiError(400, "invalid-argument", "Invitation ID mismatch.");
  }
  const businessId = requiredString(data, "businessId");
  const { firestore } = getFirebaseServices();
  const business = businessRef(businessId);
  const invitation = business.collection("invitations").doc(invitationId);
  const member = business.collection("members").doc(identity.uid);
  const profile = firestore.collection("userProfiles").doc(identity.uid);
  const activity = business.collection("activityLogs").doc();

  await firestore.runTransaction(async (transaction) => {
    const [invitationSnapshot, businessSnapshot, memberSnapshot] = await Promise
      .all([
        transaction.get(invitation),
        transaction.get(business),
        transaction.get(member),
      ]);
    const invitationData = invitationSnapshot.data();
    if (!invitationSnapshot.exists || invitationData?.status !== "pending") {
      throw new ApiError(
        409,
        "failed-precondition",
        "Invitation is not pending.",
      );
    }
    if (!businessSnapshot.exists) {
      throw new ApiError(404, "not-found", "The Business no longer exists.");
    }
    if (invitationData?.emailNormalized !== email) {
      throw new ApiError(
        403,
        "permission-denied",
        "Invitation identity mismatch.",
      );
    }
    if (businessSnapshot.data()?.ownerUid === identity.uid) {
      throw new ApiError(
        409,
        "failed-precondition",
        "The owner is already a member.",
      );
    }
    const roleId = invitationData.roleId;
    const invitedBy = invitationData.invitedBy;
    if (typeof roleId !== "string" || typeof invitedBy !== "string") {
      throw new ApiError(500, "data-loss", "Invitation role is invalid.");
    }
    await requireAssignableRole(transaction, businessId, roleId);
    if (memberSnapshot.data()?.status === "active") {
      throw new ApiError(
        409,
        "already-exists",
        "You are already an active member.",
      );
    }

    const now = FieldValue.serverTimestamp();
    transaction.set(member, {
      uid: identity.uid,
      roleId,
      status: "active",
      joinedAt: now,
      invitedAt: invitationData.invitedAt ?? now,
      invitedBy,
      ...(memberSnapshot.exists ? {} : { createdAt: now }),
      updatedAt: now,
    }, { merge: memberSnapshot.exists });
    transaction.update(invitation, {
      status: "accepted",
      acceptedAt: now,
      acceptedBy: identity.uid,
      updatedAt: now,
    });
    transaction.set(profile, {
      activeBusinessId: businessId,
      updatedAt: now,
    }, { merge: true });
    transaction.delete(
      business.collection("invitationEmailIndex").doc(
        invitationEmailIndexId(email),
      ),
    );
    transaction.set(
      activity,
      activityData(
        activity.id,
        identity.uid,
        "member.activated",
        "member",
        identity.uid,
        { roleId },
      ),
    );
  });
  return { businessId };
}

function verifiedIdentityEmail(identity: TrustedIdentity): string {
  if (identity.email_verified !== true || typeof identity.email !== "string") {
    throw new ApiError(
      409,
      "failed-precondition",
      "A verified email address is required.",
    );
  }
  return normalizeInvitationEmail(identity.email);
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

function firebaseErrorCode(error: unknown): string | undefined {
  if (typeof error !== "object" || error === null || !("code" in error)) {
    return undefined;
  }
  const code = (error as { code?: unknown }).code;
  return typeof code === "string" ? code : undefined;
}
