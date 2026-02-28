"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.allTools = exports.searchChallengesByArea = exports.getChallengeParticipants = exports.getActiveEvents = exports.getUserProfile = exports.getChallengeById = exports.getChallenges = void 0;
require("../firebase-init.js");
const genkit_1 = require("genkit");
const genkit_js_1 = require("../genkit.js");
const firestore_1 = require("firebase-admin/firestore");
const gps_js_1 = require("../utils/gps.js");
const db = (0, firestore_1.getFirestore)();
// ─── Zod schemas matching Firestore document shapes ───
const ChallengeSchema = genkit_1.z.object({
    id: genkit_1.z.string(),
    title: genkit_1.z.string(),
    description: genkit_1.z.string(),
    type: genkit_1.z.string(),
    difficulty: genkit_1.z.string(),
    score: genkit_1.z.number().optional(),
    expected_duration: genkit_1.z.string().optional(),
    latitude: genkit_1.z.number(),
    longitude: genkit_1.z.number(),
    joined_people: genkit_1.z.array(genkit_1.z.string()).optional(),
    chlg_pic_url: genkit_1.z.string().optional(),
    sponsor: genkit_1.z
        .object({ name: genkit_1.z.string(), type: genkit_1.z.string() })
        .nullable()
        .optional(),
});
const UserSchema = genkit_1.z.object({
    uid: genkit_1.z.string(),
    name_surname: genkit_1.z.string(),
    email: genkit_1.z.string().optional(),
    cum_points: genkit_1.z.number(),
    joined_chlgs: genkit_1.z.array(genkit_1.z.string()),
    completed_chlg: genkit_1.z.array(genkit_1.z.string()),
    user_pic_url: genkit_1.z.string().optional(),
});
const WeeklyEventSchema = genkit_1.z.object({
    id: genkit_1.z.string(),
    description: genkit_1.z.string(),
    multiplier: genkit_1.z.number(),
    target_category: genkit_1.z.string(),
    start_date: genkit_1.z.string(),
    end_date: genkit_1.z.string(),
});
// ─── Helper: extract lat/lng from Firestore GeoPoint or flat fields ───
function extractCoords(data) {
    if (data.location && typeof data.location.latitude === 'number') {
        return {
            latitude: data.location.latitude,
            longitude: data.location.longitude,
        };
    }
    return {
        latitude: data.latitude ?? 0,
        longitude: data.longitude ?? 0,
    };
}
// ─── Tools ───
exports.getChallenges = genkit_js_1.ai.defineTool({
    name: 'getChallenges',
    description: 'Get available challenges from the database, optionally filtered by type or difficulty',
    inputSchema: genkit_1.z.object({
        type: genkit_1.z.string().optional().describe('Challenge type filter: photo, food, activity, hiking'),
        difficulty: genkit_1.z.string().optional().describe('Difficulty filter: easy, medium, hard'),
    }),
    outputSchema: genkit_1.z.array(ChallengeSchema),
}, async (input) => {
    let query = db.collection('challenges');
    if (input.type)
        query = query.where('type', '==', input.type);
    if (input.difficulty)
        query = query.where('difficulty', '==', input.difficulty);
    const snap = await query.get();
    return snap.docs.map((doc) => {
        const d = doc.data();
        const coords = extractCoords(d);
        return {
            id: doc.id,
            title: d.title ?? '',
            description: d.description ?? '',
            type: d.type ?? '',
            difficulty: d.difficulty ?? '',
            score: d.score,
            expected_duration: d.expected_duration,
            latitude: coords.latitude,
            longitude: coords.longitude,
            joined_people: d.joined_people,
            chlg_pic_url: d.chlg_pic_url,
            sponsor: d.sponsor ?? null,
        };
    });
});
exports.getChallengeById = genkit_js_1.ai.defineTool({
    name: 'getChallengeById',
    description: 'Get a single challenge by its document ID',
    inputSchema: genkit_1.z.object({
        challengeId: genkit_1.z.string().describe('The Firestore document ID of the challenge'),
    }),
    outputSchema: ChallengeSchema.nullable(),
}, async (input) => {
    const doc = await db.collection('challenges').doc(input.challengeId).get();
    if (!doc.exists)
        return null;
    const d = doc.data();
    const coords = extractCoords(d);
    return {
        id: doc.id,
        title: d.title ?? '',
        description: d.description ?? '',
        type: d.type ?? '',
        difficulty: d.difficulty ?? '',
        score: d.score,
        expected_duration: d.expected_duration,
        latitude: coords.latitude,
        longitude: coords.longitude,
        joined_people: d.joined_people,
        chlg_pic_url: d.chlg_pic_url,
        sponsor: d.sponsor ?? null,
    };
});
exports.getUserProfile = genkit_js_1.ai.defineTool({
    name: 'getUserProfile',
    description: 'Get a user profile including points, joined challenges, and completed challenges',
    inputSchema: genkit_1.z.object({
        userId: genkit_1.z.string().describe('The Firestore document ID (uid) of the user'),
    }),
    outputSchema: UserSchema.nullable(),
}, async (input) => {
    const doc = await db.collection('users').doc(input.userId).get();
    if (!doc.exists)
        return null;
    const d = doc.data();
    return {
        uid: doc.id,
        name_surname: d.name_surname ?? '',
        email: d.email,
        cum_points: d.cum_points ?? 0,
        joined_chlgs: d.joined_chlgs ?? [],
        completed_chlg: d.completed_chlg ?? [],
        user_pic_url: d.user_pic_url,
    };
});
exports.getActiveEvents = genkit_js_1.ai.defineTool({
    name: 'getActiveEvents',
    description: 'Get currently active weekly events that offer bonus multipliers',
    inputSchema: genkit_1.z.object({}),
    outputSchema: genkit_1.z.array(WeeklyEventSchema),
}, async () => {
    const now = new Date();
    const snap = await db
        .collection('weekly_events')
        .where('end_date', '>', now)
        .get();
    return snap.docs.map((doc) => {
        const d = doc.data();
        return {
            id: doc.id,
            description: d.description ?? '',
            multiplier: d.multiplier ?? 1,
            target_category: d.target_category ?? '',
            start_date: d.start_date?.toDate?.()?.toISOString?.() ?? '',
            end_date: d.end_date?.toDate?.()?.toISOString?.() ?? '',
        };
    });
});
exports.getChallengeParticipants = genkit_js_1.ai.defineTool({
    name: 'getChallengeParticipants',
    description: 'Get the list of user IDs who have joined a specific challenge',
    inputSchema: genkit_1.z.object({
        challengeId: genkit_1.z.string().describe('The challenge document ID'),
    }),
    outputSchema: genkit_1.z.object({
        challengeId: genkit_1.z.string(),
        participantIds: genkit_1.z.array(genkit_1.z.string()),
        count: genkit_1.z.number(),
    }),
}, async (input) => {
    const doc = await db.collection('challenges').doc(input.challengeId).get();
    const joined = doc.data()?.joined_people ?? [];
    return {
        challengeId: input.challengeId,
        participantIds: joined,
        count: joined.length,
    };
});
exports.searchChallengesByArea = genkit_js_1.ai.defineTool({
    name: 'searchChallengesByArea',
    description: 'Search for challenges near a given GPS coordinate within a radius (in meters)',
    inputSchema: genkit_1.z.object({
        latitude: genkit_1.z.number().describe('Center latitude'),
        longitude: genkit_1.z.number().describe('Center longitude'),
        radiusMeters: genkit_1.z
            .number()
            .optional()
            .describe('Search radius in meters, defaults to 3000'),
    }),
    outputSchema: genkit_1.z.array(ChallengeSchema.extend({ distanceMeters: genkit_1.z.number() })),
}, async (input) => {
    const radius = input.radiusMeters ?? 3000;
    const snap = await db.collection('challenges').get();
    const results = [];
    for (const doc of snap.docs) {
        const d = doc.data();
        const coords = extractCoords(d);
        const dist = (0, gps_js_1.haversineDistance)(input.latitude, input.longitude, coords.latitude, coords.longitude);
        if (dist <= radius) {
            results.push({
                id: doc.id,
                title: d.title ?? '',
                description: d.description ?? '',
                type: d.type ?? '',
                difficulty: d.difficulty ?? '',
                score: d.score,
                expected_duration: d.expected_duration,
                latitude: coords.latitude,
                longitude: coords.longitude,
                joined_people: d.joined_people,
                chlg_pic_url: d.chlg_pic_url,
                sponsor: d.sponsor ?? null,
                distanceMeters: Math.round(dist),
            });
        }
    }
    results.sort((a, b) => a.distanceMeters - b.distanceMeters);
    return results;
});
exports.allTools = [
    exports.getChallenges,
    exports.getChallengeById,
    exports.getUserProfile,
    exports.getActiveEvents,
    exports.getChallengeParticipants,
    exports.searchChallengesByArea,
];
//# sourceMappingURL=firestoreTools.js.map