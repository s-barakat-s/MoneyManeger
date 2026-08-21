import type { TrustedIdentity } from "../auth/firebase_auth.ts";
import { actorDisplayName } from "../domain/actor_identity.ts";
import {
  businessRef,
} from "../domain/business_policy.ts";
import { getFirebaseServices } from "../firebase/admin.ts";
import { ApiError, readJsonObject } from "../http/api.ts";

export async function handleActorNamesRoute(
  request: Request,
  pathname: string,
  identity: TrustedIdentity,
): Promise<Record<string, unknown> | null> {
  const match = /^\/api\/businesses\/([^/]+)\/actor-names\/resolve$/.exec(pathname);
  if (request.method !== "POST" || match === null) return null;
  const businessId = decodePathSegment(match[1]);
  await requireActiveBusinessMembership(businessId, identity.uid);
  const actorUids = requestedActorUids((await readJsonObject(request)).actorUids);
  if (actorUids.length === 0) return { actors: [] };

  const firestore = getFirebaseServices().firestore;
  const profiles = await firestore.getAll(
    ...actorUids.map((uid) => firestore.collection("userProfiles").doc(uid)),
  );
  return {
    actors: profiles.map((profile) => ({
      uid: profile.id,
      name: actorDisplayName(profile.data()),
    })),
  };
}

async function requireActiveBusinessMembership(
  businessId: string,
  uid: string,
): Promise<void> {
  const member = await businessRef(businessId).collection("members").doc(uid)
    .get();
  if (member.data()?.status !== "active") {
    throw new ApiError(403, "permission-denied", "Active membership is required.");
  }
}

function requestedActorUids(value: unknown): string[] {
  if (!Array.isArray(value) || value.length > 100) invalidActorUids();
  return [...new Set(value.map((item) => {
    if (typeof item !== "string") invalidActorUids();
    const uid = item.trim();
    if (uid.length === 0 || uid.length > 150 || uid.includes("/")) invalidActorUids();
    return uid;
  }))];
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

function invalidActorUids(): never {
  throw new ApiError(400, "invalid-argument", "Invalid actor identifiers.");
}
