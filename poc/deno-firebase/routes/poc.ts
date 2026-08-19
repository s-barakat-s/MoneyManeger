import { FieldValue } from "firebase-admin/firestore";

import { safeIdentity, type TrustedIdentity } from "../auth/firebase_auth.ts";
import { getFirebaseServices } from "../firebase/admin.ts";
import { ApiError, readJsonObject } from "../http/api.ts";

const paths = new Set([
  "/auth-check",
  "/firestore-read-test",
  "/firestore-write-test",
  "/auth-user-lookup-test",
]);

export function isPocPath(pathname: string): boolean {
  return paths.has(pathname);
}

export function pocEndpointsEnabled(): boolean {
  return Deno.env.get("ENABLE_POC_ENDPOINTS")?.trim().toLowerCase() === "true";
}

export async function handlePocRoute(
  request: Request,
  pathname: string,
  identity: TrustedIdentity,
) {
  const { auth, firestore } = getFirebaseServices();
  if (request.method === "GET" && pathname === "/auth-check") {
    return safeIdentity(identity);
  }
  if (request.method === "GET" && pathname === "/firestore-read-test") {
    const profile = await firestore.collection("userProfiles").doc(identity.uid)
      .get();
    return {
      uid: identity.uid,
      profileExists: profile.exists,
      profileCompleted: profile.data()?.profileCompleted === true,
    };
  }
  if (request.method === "POST" && pathname === "/firestore-write-test") {
    const reference = firestore.collection("_backendPoc").doc(identity.uid);
    const attemptCount = await firestore.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(reference);
      const previous = snapshot.data()?.attemptCount;
      const next = typeof previous === "number" ? previous + 1 : 1;
      transaction.set(
        reference,
        {
          uid: identity.uid,
          attemptCount: next,
          testedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      return next;
    });
    return { ok: true, uid: identity.uid, attemptCount };
  }
  if (request.method === "POST" && pathname === "/auth-user-lookup-test") {
    if (
      identity.email_verified !== true || typeof identity.email !== "string"
    ) {
      throw new ApiError(
        403,
        "permission-denied",
        "A verified email is required.",
      );
    }
    const body = await readJsonObject(request);
    const email = typeof body.email === "string"
      ? body.email.trim().toLowerCase()
      : "";
    if (!email || email !== identity.email.trim().toLowerCase()) {
      throw new ApiError(
        403,
        "permission-denied",
        "The PoC only permits lookup of the caller's verified email.",
      );
    }
    const user = await auth.getUserByEmail(email);
    return {
      uidMatchesCaller: user.uid === identity.uid,
      emailVerified: user.emailVerified,
    };
  }
  throw new ApiError(404, "not-found", "Not found.");
}
