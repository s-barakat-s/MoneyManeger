import {initializeApp} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";
import {
  DocumentReference,
  FieldPath,
  FieldValue,
  Query,
  Timestamp,
  Transaction,
  getFirestore,
} from "firebase-admin/firestore";
import {
  CallableRequest,
  HttpsError,
  onCall,
} from "firebase-functions/v2/https";
import {createHash} from "node:crypto";

initializeApp();

const usernamePattern = /^[a-z0-9_]{3,20}$/;
const genericNotFoundMessage = "Incorrect email/username or password.";
const region = "europe-west1";
const membersRead = "members.read";
const membersManage = "members.manage";
const activityRead = "activity.read";
const protectedOwnerRoleId = "owner";

type AuthenticatedRequest = CallableRequest<unknown> & {
  auth: NonNullable<CallableRequest<unknown>["auth"]>;
};

const systemRoles: Record<string, {name: string; permissions: string[]}> = {
  owner: {
    name: "Owner",
    permissions: [
      "members.read", "members.manage", "roles.read", "roles.manage",
      "owners.read", "owners.create", "owners.update", "owners.archive",
      "transactions.read", "transactions.create", "transactions.update",
      "transactions.archive", "transfers.read", "transfers.create",
      "transfers.correct", "transfers.archive", "debts.read", "debts.create",
      "debts.update", "debts.archive", "receivables.read",
      "receivables.create", "receivables.update", "receivables.archive",
      "assets.read", "assets.create", "assets.update", "assets.archive",
      "reports.read", "activity.read", "business.settings",
    ],
  },
  admin: {
    name: "Admin",
    permissions: [
      "members.read", "members.manage", "roles.read", "owners.read",
      "owners.create", "owners.update", "owners.archive",
      "transactions.read", "transactions.create", "transactions.update",
      "transactions.archive", "transfers.read", "transfers.create",
      "transfers.correct", "transfers.archive", "debts.read", "debts.create",
      "debts.update", "debts.archive", "receivables.read",
      "receivables.create", "receivables.update", "receivables.archive",
      "assets.read", "assets.create", "assets.update", "assets.archive",
      "reports.read", "activity.read", "business.settings",
    ],
  },
  accountant: {
    name: "Accountant",
    permissions: [
      "owners.read", "transactions.read", "transactions.create",
      "transactions.update", "transfers.read", "transfers.create",
      "debts.read", "debts.create", "debts.update", "receivables.read",
      "receivables.create", "receivables.update", "assets.read",
      "reports.read", "activity.read",
    ],
  },
  viewer: {
    name: "Viewer",
    permissions: [
      "members.read", "owners.read", "transactions.read", "transfers.read",
      "debts.read", "receivables.read", "assets.read", "reports.read",
    ],
  },
};

export const resolveUsernameEmail = onCall(
  {region},
  async (request): Promise<{email: string}> => {
    const suppliedUsername = request.data?.username;
    if (typeof suppliedUsername !== "string") {
      throw new HttpsError("invalid-argument", "Invalid login identifier.");
    }

    const username = suppliedUsername.trim().toLowerCase();
    if (!usernamePattern.test(username)) {
      throw new HttpsError("invalid-argument", "Invalid login identifier.");
    }

    try {
      const firestore = getFirestore();
      const reservation = await firestore
        .collection("usernames")
        .doc(username)
        .get();
      const uid = reservation.data()?.uid;
      if (!reservation.exists || typeof uid !== "string" || uid.length === 0) {
        throw new HttpsError("not-found", genericNotFoundMessage);
      }

      const profile = await firestore.collection("users").doc(uid).get();
      const email = profile.data()?.email;
      if (!profile.exists || typeof email !== "string" || !email.includes("@")) {
        throw new HttpsError("not-found", genericNotFoundMessage);
      }

      return {email: email.trim().toLowerCase()};
    } catch (error) {
      if (error instanceof HttpsError) {
        throw error;
      }
      throw new HttpsError("internal", "Username login is unavailable.");
    }
  },
);

function requireAuthenticated(
  request: CallableRequest<unknown>,
): AuthenticatedRequest {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication is required.");
  }
  return request as AuthenticatedRequest;
}

function requiredString(data: unknown, key: string): string {
  if (typeof data !== "object" || data === null) {
    throw new HttpsError("invalid-argument", `Missing ${key}.`);
  }
  const value = (data as Record<string, unknown>)[key];
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new HttpsError("invalid-argument", `Invalid ${key}.`);
  }
  return value.trim();
}

function normalizeEmail(value: string): string {
  const normalized = value.trim().toLowerCase();
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(normalized)) {
    throw new HttpsError("invalid-argument", "Enter a valid email address.");
  }
  return normalized;
}

function emailIndexId(email: string): string {
  return createHash("sha256").update(email).digest("hex");
}

function verifiedEmail(request: AuthenticatedRequest): string {
  const email = request.auth.token.email;
  if (request.auth.token.email_verified !== true || typeof email !== "string") {
    throw new HttpsError(
      "failed-precondition",
      "A verified email address is required.",
    );
  }
  return normalizeEmail(email);
}

function businessRef(businessId: string): DocumentReference {
  return getFirestore().collection("businesses").doc(businessId);
}

function businessName(value: string): string {
  const name = value.trim();
  if (name.length < 2 || name.length > 80) {
    throw new HttpsError(
      "invalid-argument",
      "Business name must be between 2 and 80 characters.",
    );
  }
  return name;
}

async function requirePermission(
  businessId: string,
  uid: string,
  permission: string,
): Promise<void> {
  const business = businessRef(businessId);
  const member = await business.collection("members").doc(uid).get();
  const roleId = member.data()?.roleId;
  if (member.data()?.status !== "active" || typeof roleId !== "string") {
    throw new HttpsError("permission-denied", "Active membership is required.");
  }
  const role = await business.collection("roles").doc(roleId).get();
  const permissions = role.data()?.permissions;
  if (!Array.isArray(permissions) || !permissions.includes(permission)) {
    throw new HttpsError("permission-denied", "Permission denied.");
  }
}

async function requirePermissionInTransaction(
  transaction: Transaction,
  businessId: string,
  uid: string,
  permission: string,
): Promise<void> {
  const business = businessRef(businessId);
  const member = await transaction.get(business.collection("members").doc(uid));
  const roleId = member.data()?.roleId;
  if (member.data()?.status !== "active" || typeof roleId !== "string") {
    throw new HttpsError("permission-denied", "Active membership is required.");
  }
  const role = await transaction.get(business.collection("roles").doc(roleId));
  const permissions = role.data()?.permissions;
  if (!Array.isArray(permissions) || !permissions.includes(permission)) {
    throw new HttpsError("permission-denied", "Permission denied.");
  }
}

function activityData(
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
    ...(Object.keys(metadata).length > 0 ? {metadata} : {}),
  };
}

async function ensureSystemRoles(businessId: string): Promise<void> {
  const business = businessRef(businessId);
  const firestore = getFirestore();
  await firestore.runTransaction(async (transaction) => {
    const entries = Object.entries(systemRoles);
    const references = entries.map(([roleId]) =>
      business.collection("roles").doc(roleId),
    );
    const snapshots = await Promise.all(
      references.map((reference) => transaction.get(reference)),
    );
    for (let index = 0; index < entries.length; index++) {
      const [roleId, definition] = entries[index];
      const ref = references[index];
      const snapshot = snapshots[index];
      const stored = snapshot.data();
      const storedPermissions = stored?.permissions;
      const isCurrent = snapshot.exists &&
        stored?.name === definition.name &&
        stored?.isSystem === true &&
        Array.isArray(storedPermissions) &&
        storedPermissions.length === definition.permissions.length &&
        definition.permissions.every((permission) =>
          storedPermissions.includes(permission),
        );
      if (isCurrent) continue;
      transaction.set(ref, {
        id: roleId,
        name: definition.name,
        permissions: definition.permissions,
        isSystem: true,
        ...(snapshot.exists ? {} : {createdAt: FieldValue.serverTimestamp()}),
        updatedAt: FieldValue.serverTimestamp(),
      }, {merge: true});
    }
  });
}

async function requireAssignableRole(
  transaction: Transaction,
  businessId: string,
  roleId: string,
): Promise<void> {
  if (roleId === protectedOwnerRoleId) {
    throw new HttpsError("failed-precondition", "Owner assignment is protected.");
  }
  const role = await transaction.get(
    businessRef(businessId).collection("roles").doc(roleId),
  );
  if (!role.exists) {
    throw new HttpsError("not-found", "The selected role no longer exists.");
  }
}

export const resolveMyBusinessWorkspaces = onCall({region}, async (request) => {
  const authenticated = requireAuthenticated(request);
  const firestore = getFirestore();
  const uid = authenticated.auth.uid;
  const [profile, memberships] = await Promise.all([
    firestore.collection("userProfiles").doc(uid).get(),
    firestore.collectionGroup("members").where("uid", "==", uid).get(),
  ]);
  const activeMemberships = memberships.docs.filter(
    (membership) => membership.data().status === "active",
  );
  const activeBusinessIds = new Set(activeMemberships.map((membership) => {
    const business = membership.ref.parent.parent;
    return business?.parent.id === "businesses" ? business.id : null;
  }).filter((businessId): businessId is string => businessId !== null));
  await Promise.all([...activeBusinessIds].map(ensureSystemRoles));
  const workspaces = (await Promise.all(activeMemberships.map(
    async (membership) => {
      const business = membership.ref.parent.parent;
      if (!business || business.parent.id !== "businesses") return null;
      const roleId = membership.data().roleId;
      if (typeof roleId !== "string") return null;
      const [businessSnapshot, roleSnapshot] = await Promise.all([
        business.get(),
        business.collection("roles").doc(roleId).get(),
      ]);
      if (!businessSnapshot.exists) return null;
      return {
        businessId: business.id,
        businessName: businessSnapshot.data()?.name ?? "Business",
        roleId,
        roleName: roleSnapshot.data()?.name ?? roleId,
      };
    },
  ))).filter((workspace) => workspace !== null).sort((left, right) =>
    left.businessName.localeCompare(right.businessName),
  );

  const configuredBusinessId = profile.data()?.activeBusinessId;
  let selectedBusinessId = typeof configuredBusinessId === "string" &&
    workspaces.some((workspace) => workspace.businessId === configuredBusinessId) ?
    configuredBusinessId : null;
  if (selectedBusinessId === null && workspaces.length === 1) {
    selectedBusinessId = workspaces[0].businessId;
  }

  if (profile.exists && selectedBusinessId !== configuredBusinessId) {
    await profile.ref.set({
      activeBusinessId: selectedBusinessId ?? FieldValue.delete(),
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
  }
  return {selectedBusinessId, workspaces};
});

export const selectBusinessWorkspace = onCall({region}, async (request) => {
  const authenticated = requireAuthenticated(request);
  const businessId = requiredString(request.data, "businessId");
  const firestore = getFirestore();
  const member = await businessRef(businessId)
    .collection("members")
    .doc(authenticated.auth.uid)
    .get();
  if (!member.exists || member.data()?.status !== "active") {
    throw new HttpsError("permission-denied", "Active membership is required.");
  }
  await firestore.collection("userProfiles").doc(authenticated.auth.uid).set({
    activeBusinessId: businessId,
    updatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});
  return {businessId};
});

export const createBusinessWorkspace = onCall({region}, async (request) => {
  const authenticated = requireAuthenticated(request);
  const name = businessName(requiredString(request.data, "name"));
  const firestore = getFirestore();
  const business = firestore.collection("businesses").doc();
  const member = business.collection("members").doc(authenticated.auth.uid);
  const profile = firestore.collection("userProfiles").doc(authenticated.auth.uid);
  const activity = business.collection("activityLogs").doc();

  await firestore.runTransaction(async (transaction) => {
    const profileSnapshot = await transaction.get(profile);
    if (!profileSnapshot.exists ||
      profileSnapshot.data()?.profileCompleted !== true) {
      throw new HttpsError(
        "failed-precondition",
        "Complete your profile before creating a Business.",
      );
    }
    const now = FieldValue.serverTimestamp();
    transaction.create(business, {
      name,
      ownerUid: authenticated.auth.uid,
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
      uid: authenticated.auth.uid,
      roleId: protectedOwnerRoleId,
      status: "active",
      joinedAt: now,
      createdAt: now,
      updatedAt: now,
    });
    transaction.set(profile, {
      activeBusinessId: business.id,
      updatedAt: now,
    }, {merge: true});
    transaction.create(activity, activityData(
      activity.id,
      authenticated.auth.uid,
      "business.created",
      "business",
      business.id,
    ));
  });
  return {businessId: business.id};
});

export const listBusinessActivity = onCall({region}, async (request) => {
  const authenticated = requireAuthenticated(request);
  const businessId = requiredString(request.data, "businessId");
  await requirePermission(businessId, authenticated.auth.uid, activityRead);

  const rawCursor = typeof request.data === "object" && request.data !== null ?
    (request.data as Record<string, unknown>).cursor : null;
  let query: Query = businessRef(businessId)
    .collection("activityLogs")
    .orderBy("createdAt", "desc")
    .orderBy(FieldPath.documentId(), "desc");
  if (rawCursor !== null && rawCursor !== undefined) {
    const cursorMillis = typeof rawCursor === "object" && rawCursor !== null ?
      (rawCursor as Record<string, unknown>).createdAtMillis : null;
    const cursorId = typeof rawCursor === "object" && rawCursor !== null ?
      (rawCursor as Record<string, unknown>).id : null;
    if (typeof rawCursor !== "object" ||
      typeof cursorMillis !== "number" ||
      !Number.isSafeInteger(cursorMillis) ||
      cursorMillis < 0 ||
      typeof cursorId !== "string" ||
      cursorId.length === 0 ||
      cursorId.includes("/")) {
      throw new HttpsError("invalid-argument", "Invalid activity cursor.");
    }
    query = query.startAfter(
      Timestamp.fromMillis(cursorMillis),
      cursorId,
    );
  }

  const pageSize = 30;
  const snapshot = await query.limit(pageSize + 1).get();
  const pageDocuments = snapshot.docs.slice(0, pageSize);
  const actorUids = [...new Set(pageDocuments.map((document) =>
    document.data().actorUid,
  ).filter((uid): uid is string => typeof uid === "string"))];
  const profileSnapshots = actorUids.length === 0 ? [] :
    await getFirestore().getAll(...actorUids.map((uid) =>
      getFirestore().collection("userProfiles").doc(uid),
    ));
  const actorNames = new Map(profileSnapshots.map((profile) => {
    const data = profile.data();
    const displayName = data?.displayName;
    const username = data?.username;
    const name = typeof displayName === "string" && displayName.trim() ?
      displayName.trim() :
      typeof username === "string" && username.trim() ? username.trim() : null;
    return [profile.id, name];
  }));

  const last = pageDocuments.at(-1);
  const lastCreatedAt = last?.data().createdAt;
  return {
    activities: pageDocuments.map((document) => {
      const data = document.data();
      const createdAt = data.createdAt;
      return {
        id: document.id,
        actorUid: data.actorUid,
        actorName: actorNames.get(data.actorUid) ?? null,
        action: data.action,
        entityType: data.entityType,
        entityId: data.entityId,
        createdAtMillis: createdAt instanceof Timestamp ?
          createdAt.toMillis() : null,
        metadata: data.metadata ?? {},
      };
    }),
    nextCursor: snapshot.docs.length > pageSize &&
      last && lastCreatedAt instanceof Timestamp ? {
        createdAtMillis: lastCreatedAt.toMillis(),
        id: last.id,
      } : null,
  };
});

export const listBusinessMembers = onCall({region}, async (request) => {
  const authenticated = requireAuthenticated(request);
  const businessId = requiredString(request.data, "businessId");
  await requirePermission(businessId, authenticated.auth.uid, membersRead);

  const business = businessRef(businessId);
  const [businessSnapshot, membersSnapshot, rolesSnapshot] = await Promise.all([
    business.get(),
    business.collection("members").get(),
    business.collection("roles").get(),
  ]);
  const profiles = await getFirestore().getAll(
    ...membersSnapshot.docs.map((member) =>
      getFirestore().collection("userProfiles").doc(member.id),
    ),
  );
  const profileByUid = new Map(profiles.map((profile) => [profile.id, profile]));
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
        displayName: profile?.displayName ?? profile?.username ?? "",
        username: profile?.username ?? "",
        email: profile?.email ?? "",
        isProtectedOwner: businessSnapshot.data()?.ownerUid === member.id,
      };
    }),
  };
});

export const listAssignableBusinessRoles = onCall({region}, async (request) => {
  const authenticated = requireAuthenticated(request);
  const businessId = requiredString(request.data, "businessId");
  await requirePermission(businessId, authenticated.auth.uid, membersManage);
  await ensureSystemRoles(businessId);
  const roles = await businessRef(businessId).collection("roles").get();
  return {
    roles: roles.docs
      .filter((role) => role.id !== protectedOwnerRoleId)
      .map((role) => ({id: role.id, name: role.data().name ?? role.id})),
  };
});

export const listBusinessInvitations = onCall({region}, async (request) => {
  const authenticated = requireAuthenticated(request);
  const businessId = requiredString(request.data, "businessId");
  await requirePermission(businessId, authenticated.auth.uid, membersManage);
  const invitations = await businessRef(businessId)
    .collection("invitations")
    .where("status", "==", "pending")
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
});

export const createBusinessInvitation = onCall({region}, async (request) => {
  const authenticated = requireAuthenticated(request);
  const businessId = requiredString(request.data, "businessId");
  const roleId = requiredString(request.data, "roleId");
  const email = normalizeEmail(requiredString(request.data, "email"));
  let existingUid: string | null = null;
  try {
    existingUid = (await getAuth().getUserByEmail(email)).uid;
  } catch (error) {
    const code = (error as {code?: string}).code;
    if (code !== "auth/user-not-found") {
      throw new HttpsError("internal", "Member identity lookup failed.");
    }
  }
  const firestore = getFirestore();
  const business = businessRef(businessId);
  const invitation = business.collection("invitations").doc();
  const invitationIndex = business.collection("invitationEmailIndex").doc(
    emailIndexId(email),
  );
  const activity = business.collection("activityLogs").doc();

  await firestore.runTransaction(async (transaction) => {
    await requirePermissionInTransaction(
      transaction,
      businessId,
      authenticated.auth.uid,
      membersManage,
    );
    await requireAssignableRole(transaction, businessId, roleId);
    if (existingUid !== null) {
      const existingMember = await transaction.get(
        business.collection("members").doc(existingUid),
      );
      if (existingMember.exists && existingMember.data()?.status !== "removed") {
        throw new HttpsError(
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
          throw new HttpsError(
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
      invitedBy: authenticated.auth.uid,
      invitedAt: FieldValue.serverTimestamp(),
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    transaction.set(invitationIndex, {
      emailNormalized: email,
      invitationId: invitation.id,
      updatedAt: FieldValue.serverTimestamp(),
    });
    transaction.set(activity, activityData(
      activity.id,
      authenticated.auth.uid,
      "member.invited",
      "invitation",
      invitation.id,
      {roleId},
    ));
  });
  return {invitationId: invitation.id};
});

export const revokeBusinessInvitation = onCall({region}, async (request) => {
  const authenticated = requireAuthenticated(request);
  const businessId = requiredString(request.data, "businessId");
  const invitationId = requiredString(request.data, "invitationId");
  const firestore = getFirestore();
  const business = businessRef(businessId);
  const invitation = business.collection("invitations").doc(invitationId);
  const activity = business.collection("activityLogs").doc();

  await firestore.runTransaction(async (transaction) => {
    await requirePermissionInTransaction(
      transaction,
      businessId,
      authenticated.auth.uid,
      membersManage,
    );
    const snapshot = await transaction.get(invitation);
    if (!snapshot.exists || snapshot.data()?.status !== "pending") {
      throw new HttpsError("failed-precondition", "Invitation is not pending.");
    }
    const email = snapshot.data()?.emailNormalized;
    if (typeof email !== "string") {
      throw new HttpsError("data-loss", "Invitation identity is invalid.");
    }
    const index = business.collection("invitationEmailIndex").doc(
      emailIndexId(email),
    );
    transaction.update(invitation, {
      status: "revoked",
      revokedBy: authenticated.auth.uid,
      revokedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    transaction.delete(index);
    transaction.set(activity, activityData(
      activity.id,
      authenticated.auth.uid,
      "invitation.revoked",
      "invitation",
      invitation.id,
    ));
  });
  return {success: true};
});

export const discoverMyBusinessInvitations = onCall(
  {region},
  async (request) => {
    const authenticated = requireAuthenticated(request);
    const email = verifiedEmail(authenticated);
    const invitations = await getFirestore()
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
    return {invitations: values.filter((value) => value !== null)};
  },
);

export const acceptBusinessInvitation = onCall({region}, async (request) => {
  const authenticated = requireAuthenticated(request);
  const email = verifiedEmail(authenticated);
  const businessId = requiredString(request.data, "businessId");
  const invitationId = requiredString(request.data, "invitationId");
  const firestore = getFirestore();
  const business = businessRef(businessId);
  const invitation = business.collection("invitations").doc(invitationId);
  const member = business.collection("members").doc(authenticated.auth.uid);
  const profile = firestore.collection("userProfiles").doc(authenticated.auth.uid);
  const activity = business.collection("activityLogs").doc();

  await firestore.runTransaction(async (transaction) => {
    const [invitationSnapshot, businessSnapshot, memberSnapshot] =
      await Promise.all([
        transaction.get(invitation),
        transaction.get(business),
        transaction.get(member),
      ]);
    const data = invitationSnapshot.data();
    if (!invitationSnapshot.exists || data?.status !== "pending") {
      throw new HttpsError("failed-precondition", "Invitation is not pending.");
    }
    if (data?.emailNormalized !== email) {
      throw new HttpsError("permission-denied", "Invitation identity mismatch.");
    }
    if (businessSnapshot.data()?.ownerUid === authenticated.auth.uid) {
      throw new HttpsError("failed-precondition", "The owner is already a member.");
    }
    const roleId = data.roleId;
    const invitedBy = data.invitedBy;
    if (typeof roleId !== "string" || typeof invitedBy !== "string") {
      throw new HttpsError("data-loss", "Invitation role is invalid.");
    }
    await requireAssignableRole(transaction, businessId, roleId);
    if (memberSnapshot.data()?.status === "active") {
      throw new HttpsError("already-exists", "You are already an active member.");
    }
    const now = FieldValue.serverTimestamp();
    transaction.set(member, {
      uid: authenticated.auth.uid,
      roleId,
      status: "active",
      joinedAt: now,
      invitedAt: data.invitedAt ?? now,
      invitedBy,
      ...(memberSnapshot.exists ? {} : {createdAt: now}),
      updatedAt: now,
    }, {merge: memberSnapshot.exists});
    transaction.update(invitation, {
      status: "accepted",
      acceptedAt: now,
      acceptedBy: authenticated.auth.uid,
      updatedAt: now,
    });
    transaction.set(profile, {
      activeBusinessId: businessId,
      updatedAt: now,
    }, {merge: true});
    const index = business.collection("invitationEmailIndex").doc(
      emailIndexId(email),
    );
    transaction.delete(index);
    transaction.set(activity, activityData(
      activity.id,
      authenticated.auth.uid,
      "member.activated",
      "member",
      authenticated.auth.uid,
      {roleId},
    ));
  });
  return {businessId};
});

export const manageBusinessMember = onCall({region}, async (request) => {
  const authenticated = requireAuthenticated(request);
  const businessId = requiredString(request.data, "businessId");
  const targetUid = requiredString(request.data, "targetUid");
  const operation = requiredString(request.data, "operation");
  const firestore = getFirestore();
  const business = businessRef(businessId);
  const member = business.collection("members").doc(targetUid);
  const activity = business.collection("activityLogs").doc();

  await firestore.runTransaction(async (transaction) => {
    await requirePermissionInTransaction(
      transaction,
      businessId,
      authenticated.auth.uid,
      membersManage,
    );
    const [businessSnapshot, memberSnapshot] = await Promise.all([
      transaction.get(business),
      transaction.get(member),
    ]);
    if (!memberSnapshot.exists || memberSnapshot.data()?.status === "removed") {
      throw new HttpsError("not-found", "Member is not manageable.");
    }
    if (businessSnapshot.data()?.ownerUid === targetUid) {
      throw new HttpsError(
        "failed-precondition",
        "The original Business owner is protected.",
      );
    }

    const currentStatus = memberSnapshot.data()?.status;
    const currentRoleId = memberSnapshot.data()?.roleId;
    let action: string;
    let updates: Record<string, unknown>;
    let metadata: Record<string, unknown> = {};
    if (operation === "changeRole") {
      if (typeof currentRoleId !== "string") {
        throw new HttpsError("data-loss", "Member role is invalid.");
      }
      const roleId = requiredString(request.data, "roleId");
      await requireAssignableRole(transaction, businessId, roleId);
      action = "member.roleChanged";
      updates = {roleId};
      metadata = {fromRoleId: currentRoleId, toRoleId: roleId};
    } else if (operation === "suspend" && currentStatus === "active") {
      action = "member.suspended";
      updates = {status: "suspended"};
    } else if (operation === "reactivate" && currentStatus === "suspended") {
      action = "member.reactivated";
      updates = {status: "active"};
    } else if (operation === "remove" && currentStatus !== "removed") {
      action = "member.removed";
      updates = {status: "removed"};
    } else {
      throw new HttpsError("failed-precondition", "Invalid member transition.");
    }
    transaction.update(member, {
      ...updates,
      updatedAt: FieldValue.serverTimestamp(),
    });
    transaction.set(activity, activityData(
      activity.id,
      authenticated.auth.uid,
      action,
      "member",
      targetUid,
      metadata,
    ));
  });
  return {success: true};
});
