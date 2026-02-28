import '../firebase-init.js';
import { z } from 'genkit';
import { ai, openAI } from '../genkit.js';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { haversineDistance, GPS_THRESHOLD_METERS } from '../utils/gps.js';

const db = getFirestore();

const VerificationResultSchema = z.object({
  verified: z.boolean(),
  confidence: z.number(),
  reason: z.string(),
  funFact: z.string(),
  gpsVerified: z.boolean(),
  gpsDistanceMeters: z.number(),
});

function extractCoords(data: Record<string, any>): {
  latitude: number;
  longitude: number;
} {
  if (data.location && typeof data.location.latitude === 'number') {
    return { latitude: data.location.latitude, longitude: data.location.longitude };
  }
  return { latitude: data.latitude ?? 0, longitude: data.longitude ?? 0 };
}

export const verifyPhotoFlow = ai.defineFlow(
  {
    name: 'verifyPhoto',
    inputSchema: z.object({
      challengeId: z.string(),
      imageBase64: z.string().describe('Base64-encoded JPEG image'),
      userLatitude: z.number().describe("User's current GPS latitude"),
      userLongitude: z.number().describe("User's current GPS longitude"),
      userId: z.string().describe('User ID for updating completion status'),
    }),
    outputSchema: VerificationResultSchema,
  },
  async (input) => {
    // 1. Fetch challenge details from Firestore
    const challengeDoc = await db
      .collection('challenges')
      .doc(input.challengeId)
      .get();

    if (!challengeDoc.exists) {
      return {
        verified: false,
        confidence: 0,
        reason: 'Challenge not found in database.',
        funFact: '',
        gpsVerified: false,
        gpsDistanceMeters: -1,
      };
    }

    const challengeData = challengeDoc.data()!;
    const challengeCoords = extractCoords(challengeData);

    // 2. GPS proximity check
    const distance = haversineDistance(
      input.userLatitude,
      input.userLongitude,
      challengeCoords.latitude,
      challengeCoords.longitude,
    );
    const gpsVerified = distance <= GPS_THRESHOLD_METERS;

    if (!gpsVerified) {
      return {
        verified: false,
        confidence: 0,
        reason: `You are ${Math.round(distance)}m away from the challenge location. You need to be within ${GPS_THRESHOLD_METERS}m to complete this challenge.`,
        funFact: '',
        gpsVerified: false,
        gpsDistanceMeters: Math.round(distance),
      };
    }

    // 3. AI photo verification via OpenAI GPT-4o vision
    const challengeTitle = challengeData.title ?? 'Unknown';
    const challengeDescription = challengeData.description ?? '';
    const challengeType = challengeData.type ?? 'photo';

    const prompt = `You are a challenge verification system for a Hong Kong tourism app called HK Explorer.

Challenge: "${challengeTitle}"
Description: "${challengeDescription}"
Challenge type: ${challengeType}
Expected location coordinates: ${challengeCoords.latitude}, ${challengeCoords.longitude}

Analyze this photo and determine:
1. Does the photo appear to be taken at or near the described location in Hong Kong?
2. Is it a real photo (not a screenshot of Google Images or a stock photo)?
3. Does it match the challenge requirements?

Respond ONLY as a JSON object with these exact keys:
- "verified": true or false
- "confidence": a number between 0.0 and 1.0
- "reason": a brief explanation of your decision
- "funFact": a fun fact about this location to share with the user`;

    const { text } = await ai.generate({
      model: openAI.model('gpt-4o'),
      prompt: [
        { media: { url: `data:image/jpeg;base64,${input.imageBase64}` } },
        { text: prompt },
      ],
      output: {
        schema: z.object({
          verified: z.boolean(),
          confidence: z.number(),
          reason: z.string(),
          funFact: z.string(),
        }),
      },
    });

    let aiResult: { verified: boolean; confidence: number; reason: string; funFact: string };
    try {
      aiResult = JSON.parse(text);
    } catch {
      aiResult = { verified: false, confidence: 0, reason: 'AI response could not be parsed.', funFact: '' };
    }

    // 4. If verified, update Firestore
    if (aiResult.verified && aiResult.confidence >= 0.6) {
      const pointsEarned = challengeData.score ?? challengeData.points ?? 100;
      const userRef = db.collection('users').doc(input.userId);
      await userRef.update({
        cum_points: FieldValue.increment(pointsEarned),
        joined_chlgs: FieldValue.arrayRemove([input.challengeId]),
        completed_chlg: FieldValue.arrayUnion([input.challengeId]),
      });
    }

    return {
      verified: aiResult.verified && aiResult.confidence >= 0.6,
      confidence: aiResult.confidence,
      reason: aiResult.reason,
      funFact: aiResult.funFact,
      gpsVerified: true,
      gpsDistanceMeters: Math.round(distance),
    };
  },
);
