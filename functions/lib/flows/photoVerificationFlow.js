"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.verifyPhotoFlow = void 0;
require("../firebase-init.js");
const genkit_1 = require("genkit");
const genkit_js_1 = require("../genkit.js");
const firestore_1 = require("firebase-admin/firestore");
const gps_js_1 = require("../utils/gps.js");
const db = (0, firestore_1.getFirestore)();
const VerificationResultSchema = genkit_1.z.object({
    verified: genkit_1.z.boolean(),
    confidence: genkit_1.z.number(),
    reason: genkit_1.z.string(),
    funFact: genkit_1.z.string(),
    gpsVerified: genkit_1.z.boolean(),
    gpsDistanceMeters: genkit_1.z.number(),
});
function extractCoords(data) {
    if (data.location && typeof data.location.latitude === 'number') {
        return { latitude: data.location.latitude, longitude: data.location.longitude };
    }
    return { latitude: data.latitude ?? 0, longitude: data.longitude ?? 0 };
}
exports.verifyPhotoFlow = genkit_js_1.ai.defineFlow({
    name: 'verifyPhoto',
    inputSchema: genkit_1.z.object({
        challengeId: genkit_1.z.string(),
        imageBase64: genkit_1.z.string().describe('Base64-encoded JPEG image'),
        userLatitude: genkit_1.z.number().describe("User's current GPS latitude"),
        userLongitude: genkit_1.z.number().describe("User's current GPS longitude"),
        userId: genkit_1.z.string().describe('User ID for updating completion status'),
    }),
    outputSchema: VerificationResultSchema,
}, async (input) => {
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
    const challengeData = challengeDoc.data();
    const challengeCoords = extractCoords(challengeData);
    // 2. GPS proximity check
    const distance = (0, gps_js_1.haversineDistance)(input.userLatitude, input.userLongitude, challengeCoords.latitude, challengeCoords.longitude);
    const gpsVerified = distance <= gps_js_1.GPS_THRESHOLD_METERS;
    if (!gpsVerified) {
        return {
            verified: false,
            confidence: 0,
            reason: `You are ${Math.round(distance)}m away from the challenge location. You need to be within ${gps_js_1.GPS_THRESHOLD_METERS}m to complete this challenge.`,
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
    const { text } = await genkit_js_1.ai.generate({
        model: genkit_js_1.openAI.model('gpt-4o'),
        prompt: [
            { media: { url: `data:image/jpeg;base64,${input.imageBase64}` } },
            { text: prompt },
        ],
        output: {
            schema: genkit_1.z.object({
                verified: genkit_1.z.boolean(),
                confidence: genkit_1.z.number(),
                reason: genkit_1.z.string(),
                funFact: genkit_1.z.string(),
            }),
        },
    });
    let aiResult;
    try {
        aiResult = JSON.parse(text);
    }
    catch {
        aiResult = { verified: false, confidence: 0, reason: 'AI response could not be parsed.', funFact: '' };
    }
    // 4. If verified, update Firestore
    if (aiResult.verified && aiResult.confidence >= 0.6) {
        const pointsEarned = challengeData.score ?? challengeData.points ?? 100;
        const userRef = db.collection('users').doc(input.userId);
        await userRef.update({
            cum_points: firestore_1.FieldValue.increment(pointsEarned),
            joined_chlgs: firestore_1.FieldValue.arrayRemove([input.challengeId]),
            completed_chlg: firestore_1.FieldValue.arrayUnion([input.challengeId]),
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
});
//# sourceMappingURL=photoVerificationFlow.js.map