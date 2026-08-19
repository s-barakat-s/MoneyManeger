import { cert, initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore } from "firebase-admin/firestore";

let services:
  | {
    auth: ReturnType<typeof getAuth>;
    firestore: ReturnType<typeof getFirestore>;
  }
  | undefined;

export function getFirebaseServices() {
  if (services) return services;

  const projectId = requiredEnv("FIREBASE_PROJECT_ID");
  const clientEmail = requiredEnv("FIREBASE_CLIENT_EMAIL");
  const privateKey = requiredEnv("FIREBASE_PRIVATE_KEY").replaceAll(
    "\\n",
    "\n",
  );
  const app = initializeApp({
    credential: cert({ projectId, clientEmail, privateKey }),
    projectId,
  });
  const firestore = getFirestore(app);
  firestore.settings({ preferRest: true });
  services = { auth: getAuth(app), firestore };
  return services;
}

function requiredEnv(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`Missing required environment variable: ${name}`);
  return value;
}
