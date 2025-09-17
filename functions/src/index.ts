import { onDocumentWritten } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

export const updateProductRating = onDocumentWritten(
  "products/{productId}/reviews/{reviewId}",
  async (event) => {
    const { productId } = event.params;      // params is typed automatically

    const reviewsSnap = await db
      .collection("products")
      .doc(productId)
      .collection("reviews")
      .get();

    if (reviewsSnap.empty) {
      await db.collection("products").doc(productId).update({
        avgRating: 0,
        ratingCount: 0,
      });
      return;
    }

    let total = 0;
    let count = 0;

    reviewsSnap.forEach((doc: FirebaseFirestore.QueryDocumentSnapshot) => {
      const rating = doc.get("rating");
      if (typeof rating === "number") {
        total += rating;
        count += 1;
      }
    });

    await db.collection("products").doc(productId).update({
      avgRating: total / count,
      ratingCount: count,
    });
  }
);
