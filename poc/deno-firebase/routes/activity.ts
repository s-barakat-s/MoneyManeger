import { FieldPath, Timestamp } from "firebase-admin/firestore";
import type { Query } from "firebase-admin/firestore";

import type { TrustedIdentity } from "../auth/firebase_auth.ts";
import {
  activityPageSize,
  parseActivityCursor,
  safeActivityMetadata,
} from "../domain/activity_policy.ts";
import { actorDisplayName } from "../domain/actor_identity.ts";
import {
  businessRef,
  requireBusinessPermission,
} from "../domain/business_policy.ts";
import { getFirebaseServices } from "../firebase/admin.ts";
import { ApiError } from "../http/api.ts";

const activityReadPermission = "activity.read";

export async function handleActivityRoute(
  request: Request,
  pathname: string,
  identity: TrustedIdentity,
): Promise<Record<string, unknown> | null> {
  const match = /^\/api\/businesses\/([^/]+)\/activity$/.exec(pathname);
  if (request.method !== "GET" || match === null) return null;
  return await listBusinessActivity(
    request,
    decodePathSegment(match[1]),
    identity,
  );
}

async function listBusinessActivity(
  request: Request,
  businessId: string,
  identity: TrustedIdentity,
) {
  await requireBusinessPermission(
    businessId,
    identity.uid,
    activityReadPermission,
  );
  const cursor = parseActivityCursor(new URL(request.url));
  let query: Query = businessRef(businessId)
    .collection("activityLogs")
    .orderBy("createdAt", "desc")
    .orderBy(FieldPath.documentId(), "desc");
  if (cursor !== null) {
    query = query.startAfter(
      Timestamp.fromMillis(cursor.createdAtMillis),
      cursor.id,
    );
  }

  const snapshot = await query.limit(activityPageSize + 1).get();
  const pageDocuments = snapshot.docs.slice(0, activityPageSize);
  const actorUids = [
    ...new Set(pageDocuments.map((document) => {
      const actorUid = document.data().actorUid;
      return typeof actorUid === "string" && actorUid.length > 0
        ? actorUid
        : "unknown";
    })),
  ];
  const firestore = getFirebaseServices().firestore;
  const profileSnapshots = actorUids.length === 0 ? [] : await firestore.getAll(
    ...actorUids.map((uid) => firestore.collection("userProfiles").doc(uid)),
  );
  const actorNames = new Map(profileSnapshots.map((profile) => [
    profile.id,
    actorDisplayName(profile.data()),
  ]));

  const last = pageDocuments.at(-1);
  const lastCreatedAt = last?.data().createdAt;
  return {
    items: pageDocuments.map((document) => {
      const data = document.data();
      const actorUid =
        typeof data.actorUid === "string" && data.actorUid.length > 0
          ? data.actorUid
          : "unknown";
      const createdAt = data.createdAt;
      const action = safeString(data.action);
      return {
        id: document.id,
        actorUid,
        actorName: actorNames.get(actorUid) ?? "Unknown member",
        action,
        entityType: safeString(data.entityType),
        entityId: safeString(data.entityId),
        createdAtMillis: createdAt instanceof Timestamp
          ? createdAt.toMillis()
          : null,
        metadata: safeActivityMetadata(action, data.metadata),
      };
    }),
    nextCursor: snapshot.docs.length > activityPageSize &&
        last && lastCreatedAt instanceof Timestamp
      ? { createdAtMillis: lastCreatedAt.toMillis(), id: last.id }
      : null,
  };
}

function safeString(value: unknown): string {
  return typeof value === "string" ? value : "";
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
