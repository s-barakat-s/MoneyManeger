import { cert, initializeApp } from "firebase-admin/app";
import { DecodedIdToken, getAuth } from "firebase-admin/auth";
import { FieldValue, getFirestore } from "firebase-admin/firestore";

let firebaseServices:
  | {
      auth: ReturnType<typeof getAuth>;
      firestore: ReturnType<typeof getFirestore>;
    }
  | undefined;

const allowedOrigins = new Set(
  (Deno.env.get("ALLOWED_ORIGINS") ?? "")
    .split(",")
    .map((origin) => origin.trim())
    .filter(Boolean),
);

Deno.serve(async (request) => {
  const origin = request.headers.get("origin");
  if (origin && !allowedOrigins.has(origin)) {
    return json({ error: "Origin is not allowed." }, 403);
  }

  const corsHeaders: Record<string, string> = origin
    ? {
        "access-control-allow-origin": origin,
        "access-control-allow-headers": "authorization, content-type",
        "access-control-allow-methods": "GET, POST, OPTIONS",
        vary: "Origin",
      }
    : {};

  if (request.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  try {
    const url = new URL(request.url);
    if (request.method === "GET" && url.pathname === "/health") {
      return json({ ok: true, runtime: "deno" }, 200, corsHeaders);
    }

    const identity = await requireIdentity(request);

    if (request.method === "GET" && url.pathname === "/auth-check") {
      return json(safeIdentity(identity), 200, corsHeaders);
    }

    if (
      request.method === "GET" &&
      url.pathname === "/firestore-read-test"
    ) {
      const { firestore } = getFirebaseServices();
      const profile = await firestore
        .collection("userProfiles")
        .doc(identity.uid)
        .get();
      return json(
        {
          uid: identity.uid,
          profileExists: profile.exists,
          profileCompleted: profile.data()?.profileCompleted === true,
        },
        200,
        corsHeaders,
      );
    }

    if (
      request.method === "POST" &&
      url.pathname === "/firestore-write-test"
    ) {
      const { firestore } = getFirebaseServices();
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
      return json({ ok: true, uid: identity.uid, attemptCount }, 200, corsHeaders);
    }

    if (
      request.method === "POST" &&
      url.pathname === "/auth-user-lookup-test"
    ) {
      if (identity.email_verified !== true || typeof identity.email !== "string") {
        return json({ error: "A verified email is required." }, 403, corsHeaders);
      }
      const body = await readJsonObject(request);
      const email = typeof body.email === "string"
        ? body.email.trim().toLowerCase()
        : "";
      const tokenEmail = identity.email.trim().toLowerCase();
      if (!email || email !== tokenEmail) {
        return json(
          { error: "The PoC only permits lookup of the caller's verified email." },
          403,
          corsHeaders,
        );
      }
      const { auth } = getFirebaseServices();
      const user = await auth.getUserByEmail(email);
      return json(
        {
          uidMatchesCaller: user.uid === identity.uid,
          emailVerified: user.emailVerified,
        },
        200,
        corsHeaders,
      );
    }

    return json({ error: "Not found." }, 404, corsHeaders);
  } catch (error) {
    if (error instanceof HttpError) {
      return json({ error: error.message }, error.status, corsHeaders);
    }
    console.error("PoC request failed", error);
    return json({ error: "Request failed." }, 500, corsHeaders);
  }
});

async function requireIdentity(request: Request): Promise<DecodedIdToken> {
  const authorization = request.headers.get("authorization") ?? "";
  const match = /^Bearer\s+(.+)$/i.exec(authorization);
  if (!match) throw new HttpError(401, "A Firebase ID token is required.");
  try {
    const { auth } = getFirebaseServices();
    return await auth.verifyIdToken(match[1], true);
  } catch {
    throw new HttpError(401, "The Firebase ID token is invalid.");
  }
}

function getFirebaseServices() {
  if (firebaseServices) return firebaseServices;
  const projectId = requiredEnv("FIREBASE_PROJECT_ID");
  const clientEmail = requiredEnv("FIREBASE_CLIENT_EMAIL");
  const privateKey = requiredEnv("FIREBASE_PRIVATE_KEY").replaceAll("\\n", "\n");
  const app = initializeApp({
    credential: cert({ projectId, clientEmail, privateKey }),
    projectId,
  });
  const firestore = getFirestore(app);
  // Firestore's supported REST transport avoids relying on a long-lived gRPC
  // channel in an edge runtime. Transactions remain supported.
  firestore.settings({ preferRest: true });
  firebaseServices = { auth: getAuth(app), firestore };
  return firebaseServices;
}

function safeIdentity(identity: DecodedIdToken) {
  return {
    uid: identity.uid,
    email: typeof identity.email === "string" ? identity.email : null,
    emailVerified: identity.email_verified === true,
  };
}

async function readJsonObject(request: Request): Promise<Record<string, unknown>> {
  try {
    const value: unknown = await request.json();
    if (typeof value === "object" && value !== null && !Array.isArray(value)) {
      return value as Record<string, unknown>;
    }
  } catch {
    // Converted into a stable client error below.
  }
  throw new HttpError(400, "A JSON object is required.");
}

function requiredEnv(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`Missing required environment variable: ${name}`);
  return value;
}

function json(
  body: Record<string, unknown>,
  status: number,
  extraHeaders: HeadersInit = {},
): Response {
  return Response.json(body, {
    status,
    headers: { ...extraHeaders, "cache-control": "no-store" },
  });
}

class HttpError extends Error {
  constructor(readonly status: number, message: string) {
    super(message);
  }
}
