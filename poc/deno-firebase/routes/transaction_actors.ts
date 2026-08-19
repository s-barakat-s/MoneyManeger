import type { TrustedIdentity } from "../auth/firebase_auth.ts";
import { actorDisplayName } from "../domain/actor_identity.ts";
import { requestedTransactionIds } from "../domain/transaction_actor_policy.ts";
import {
  businessRef,
  requireBusinessPermission,
} from "../domain/business_policy.ts";
import { getFirebaseServices } from "../firebase/admin.ts";
import { ApiError, readJsonObject } from "../http/api.ts";

const transactionsReadPermission = "transactions.read";

export async function handleTransactionActorRoute(
  request: Request,
  pathname: string,
  identity: TrustedIdentity,
): Promise<Record<string, unknown> | null> {
  const match = /^\/api\/businesses\/([^/]+)\/transaction-actors\/resolve$/
    .exec(pathname);
  if (request.method !== "POST" || match === null) return null;
  return await resolveTransactionActors(
    request,
    decodePathSegment(match[1]),
    identity,
  );
}

async function resolveTransactionActors(
  request: Request,
  businessId: string,
  identity: TrustedIdentity,
) {
  await requireBusinessPermission(
    businessId,
    identity.uid,
    transactionsReadPermission,
  );
  const data = await readJsonObject(request);
  const transactionIds = requestedTransactionIds(data.transactionIds);
  if (transactionIds.length === 0) return { actors: [] };

  const firestore = getFirebaseServices().firestore;
  const business = businessRef(businessId);
  const transactions = await firestore.getAll(
    ...transactionIds.map((id) => business.collection("transactions").doc(id)),
  );
  const actorUids = [
    ...new Set(transactions.flatMap((transaction) => {
      if (!transaction.exists) return [];
      const data = transaction.data();
      return [data?.createdBy, data?.updatedBy].filter(
        (uid): uid is string => typeof uid === "string" && uid.length > 0,
      );
    })),
  ];
  if (actorUids.length === 0) return { actors: [] };

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

function decodePathSegment(value: string): string {
  try {
    const decoded = decodeURIComponent(value).trim();
    if (decoded.length > 0 && !decoded.includes("/")) return decoded;
  } catch {
    // Converted into a stable API error below.
  }
  throw new ApiError(400, "invalid-argument", "Invalid route identifier.");
}
