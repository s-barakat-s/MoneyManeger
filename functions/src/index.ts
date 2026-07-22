import {initializeApp} from "firebase-admin/app";
import {getFirestore} from "firebase-admin/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";

initializeApp();

const usernamePattern = /^[a-z0-9_]{3,20}$/;
const genericNotFoundMessage = "Incorrect email/username or password.";

export const resolveUsernameEmail = onCall(
  {region: "europe-west1"},
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
