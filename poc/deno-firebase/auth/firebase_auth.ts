import type { DecodedIdToken } from "firebase-admin/auth";

import { getFirebaseServices } from "../firebase/admin.ts";
import { ApiError } from "../http/api.ts";

export type TrustedIdentity = DecodedIdToken & {
  uid: string;
};

export async function requireIdentity(
  request: Request,
): Promise<TrustedIdentity> {
  const authorization = request.headers.get("authorization") ?? "";
  const match = /^Bearer\s+(.+)$/i.exec(authorization);
  if (!match) {
    throw new ApiError(
      401,
      "unauthenticated",
      "A Firebase ID token is required.",
    );
  }

  try {
    return await getFirebaseServices().auth.verifyIdToken(match[1], true);
  } catch {
    throw new ApiError(
      401,
      "unauthenticated",
      "The Firebase ID token is invalid.",
    );
  }
}

export function requireVerifiedIdentity(identity: TrustedIdentity): void {
  if (identity.email_verified !== true) {
    throw new ApiError(
      409,
      "failed-precondition",
      "A verified email address is required.",
    );
  }
}

export function safeIdentity(identity: TrustedIdentity) {
  return {
    uid: identity.uid,
    email: typeof identity.email === "string" ? identity.email : null,
    emailVerified: identity.email_verified === true,
  };
}
