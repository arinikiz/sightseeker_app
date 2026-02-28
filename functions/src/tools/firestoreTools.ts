import { z } from 'genkit';
import { ai } from '../genkit.js';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { haversineDistance } from '../utils/gps.js';

const db = getFirestore();

// ─── Zod schemas matching Firestore document shapes ───

const ChallengeSchema = z.object({
  id: z.string(),
  title: z.string(),
  description: z.string(),
  type: z.string(),
  difficulty: z.string(),
  score: z.number().optional(),
  expected_duration: z.string().optional(),
  latitude: z.number(),
  longitude: z.number(),
  joined_people: z.array(z.string()).optional(),
  chlg_pic_url: z.string().optional(),
  sponsor: z
    .object({ name: z.string(), type: z.string() })
    .nullable()
    .optional(),
});

const UserSchema = z.object({
  uid: z.string(),
  name_surname: z.string(),
  email: z.string().optional(),
  cum_points: z.number(),
  joined_chlgs: z.array(z.string()),
  completed_chlg: z.array(z.string()),
  user_pic_url: z.string().optional(),
});

const WeeklyEventSchema = z.object({
  id: z.string(),
  description: z.string(),
  multiplier: z.number(),
  target_category: z.string(),
  start_date: z.string(),
  end_date: z.string(),
});

// ─── Helper: extract lat/lng from Firestore GeoPoint or flat fields ───

function extractCoords(data: Record<string, any>): {
  latitude: number;
  longitude: number;
} {
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

export const getChallenges = ai.defineTool(
  {
    name: 'getChallenges',
    description:
      'Get available challenges from the database, optionally filtered by type or difficulty',
    inputSchema: z.object({
      type: z.string().optional().describe('Challenge type filter: photo, food, activity, hiking'),
      difficulty: z.string().optional().describe('Difficulty filter: easy, medium, hard'),
    }),
    outputSchema: z.array(ChallengeSchema),
  },
  async (input) => {
    let query: FirebaseFirestore.Query = db.collection('challenges');
    if (input.type) query = query.where('type', '==', input.type);
    if (input.difficulty) query = query.where('difficulty', '==', input.difficulty);
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
  },
);

export const getChallengeById = ai.defineTool(
  {
    name: 'getChallengeById',
    description: 'Get a single challenge by its document ID',
    inputSchema: z.object({
      challengeId: z.string().describe('The Firestore document ID of the challenge'),
    }),
    outputSchema: ChallengeSchema.nullable(),
  },
  async (input) => {
    const doc = await db.collection('challenges').doc(input.challengeId).get();
    if (!doc.exists) return null;
    const d = doc.data()!;
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
  },
);

export const getUserProfile = ai.defineTool(
  {
    name: 'getUserProfile',
    description:
      'Get a user profile including points, joined challenges, and completed challenges',
    inputSchema: z.object({
      userId: z.string().describe('The Firestore document ID (uid) of the user'),
    }),
    outputSchema: UserSchema.nullable(),
  },
  async (input) => {
    const doc = await db.collection('users').doc(input.userId).get();
    if (!doc.exists) return null;
    const d = doc.data()!;
    return {
      uid: doc.id,
      name_surname: d.name_surname ?? '',
      email: d.email,
      cum_points: d.cum_points ?? 0,
      joined_chlgs: d.joined_chlgs ?? [],
      completed_chlg: d.completed_chlg ?? [],
      user_pic_url: d.user_pic_url,
    };
  },
);

export const getActiveEvents = ai.defineTool(
  {
    name: 'getActiveEvents',
    description: 'Get currently active weekly events that offer bonus multipliers',
    inputSchema: z.object({}),
    outputSchema: z.array(WeeklyEventSchema),
  },
  async () => {
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
  },
);

export const getChallengeParticipants = ai.defineTool(
  {
    name: 'getChallengeParticipants',
    description:
      'Get the list of user IDs who have joined a specific challenge',
    inputSchema: z.object({
      challengeId: z.string().describe('The challenge document ID'),
    }),
    outputSchema: z.object({
      challengeId: z.string(),
      participantIds: z.array(z.string()),
      count: z.number(),
    }),
  },
  async (input) => {
    const doc = await db.collection('challenges').doc(input.challengeId).get();
    const joined: string[] = doc.data()?.joined_people ?? [];
    return {
      challengeId: input.challengeId,
      participantIds: joined,
      count: joined.length,
    };
  },
);

export const searchChallengesByArea = ai.defineTool(
  {
    name: 'searchChallengesByArea',
    description:
      'Search for challenges near a given GPS coordinate within a radius (in meters)',
    inputSchema: z.object({
      latitude: z.number().describe('Center latitude'),
      longitude: z.number().describe('Center longitude'),
      radiusMeters: z
        .number()
        .optional()
        .describe('Search radius in meters, defaults to 3000'),
    }),
    outputSchema: z.array(
      ChallengeSchema.extend({ distanceMeters: z.number() }),
    ),
  },
  async (input) => {
    const radius = input.radiusMeters ?? 3000;
    const snap = await db.collection('challenges').get();
    const results: any[] = [];

    for (const doc of snap.docs) {
      const d = doc.data();
      const coords = extractCoords(d);
      const dist = haversineDistance(
        input.latitude,
        input.longitude,
        coords.latitude,
        coords.longitude,
      );
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
  },
);

export const joinChallenge = ai.defineTool(
  {
    name: 'joinChallenge',
    description:
      'Join a challenge for a user — adds the user to the challenge participant list and the challenge to the user joined list',
    inputSchema: z.object({
      userId: z.string().describe('The user document ID'),
      challengeId: z.string().describe('The challenge document ID'),
    }),
    outputSchema: z.object({
      success: z.boolean(),
      message: z.string(),
    }),
  },
  async (input) => {
    try {
      const batch = db.batch();
      const chlgRef = db.collection('challenges').doc(input.challengeId);
      const userRef = db.collection('users').doc(input.userId);

      batch.update(chlgRef, {
        joined_people: FieldValue.arrayUnion([input.userId]),
      });
      batch.update(userRef, {
        joined_chlgs: FieldValue.arrayUnion([input.challengeId]),
      });

      await batch.commit();
      return { success: true, message: `Joined challenge ${input.challengeId}` };
    } catch (e: any) {
      return { success: false, message: e.message ?? 'Failed to join challenge' };
    }
  },
);

export const getForumMessages = ai.defineTool(
  {
    name: 'getForumMessages',
    description:
      'Get forum/discussion messages for a specific challenge',
    inputSchema: z.object({
      challengeId: z.string().describe('The challenge document ID'),
      limit: z.number().optional().describe('Max messages to return, default 20'),
    }),
    outputSchema: z.array(
      z.object({
        id: z.string(),
        userId: z.string(),
        userName: z.string(),
        message: z.string(),
        createdAt: z.string(),
      }),
    ),
  },
  async (input) => {
    const snap = await db
      .collection('challenges')
      .doc(input.challengeId)
      .collection('forum')
      .orderBy('created_at', 'desc')
      .limit(input.limit ?? 20)
      .get();

    return snap.docs.map((doc) => {
      const d = doc.data();
      return {
        id: doc.id,
        userId: d.user_id ?? '',
        userName: d.user_name ?? 'Anonymous',
        message: d.message ?? '',
        createdAt: d.created_at?.toDate?.()?.toISOString?.() ?? '',
      };
    });
  },
);

export const postForumMessage = ai.defineTool(
  {
    name: 'postForumMessage',
    description:
      'Post a message to a challenge forum/discussion board',
    inputSchema: z.object({
      challengeId: z.string().describe('The challenge document ID'),
      userId: z.string().describe('The user posting the message'),
      userName: z.string().describe('Display name of the user'),
      message: z.string().describe('The forum message text'),
    }),
    outputSchema: z.object({
      success: z.boolean(),
      messageId: z.string(),
    }),
  },
  async (input) => {
    const ref = await db
      .collection('challenges')
      .doc(input.challengeId)
      .collection('forum')
      .add({
        user_id: input.userId,
        user_name: input.userName,
        message: input.message,
        created_at: FieldValue.serverTimestamp(),
      });
    return { success: true, messageId: ref.id };
  },
);

export const allTools = [
  getChallenges,
  getChallengeById,
  getUserProfile,
  getActiveEvents,
  getChallengeParticipants,
  searchChallengesByArea,
  joinChallenge,
  getForumMessages,
  postForumMessage,
];
