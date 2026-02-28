import { z } from 'genkit';
import { ai } from '../genkit.js';
import { getFirestore, GeoPoint } from 'firebase-admin/firestore';

const db = getFirestore();

/**
 * Import challenges discovered by the browser agent into Firestore.
 * This bridges the browser-agent output (discovered_challenges.json) with
 * the Firebase database that Genkit flows query.
 */
export const importDiscoveredChallengesFlow = ai.defineFlow(
  {
    name: 'importDiscoveredChallenges',
    inputSchema: z.object({
      challenges: z.array(
        z.object({
          title: z.string(),
          description: z.string(),
          difficulty: z.string(),
          location: z.array(z.number()).describe('[longitude, latitude]'),
          type: z.string(),
          duration: z.number().describe('Duration in hours'),
          photo_url: z.string().nullable().optional(),
        }),
      ),
    }),
    outputSchema: z.object({
      imported: z.number(),
      skipped: z.number(),
      challengeIds: z.array(z.string()),
    }),
  },
  async (input) => {
    const imported: string[] = [];
    let skipped = 0;

    for (const challenge of input.challenges) {
      // Check for duplicate by title
      const existing = await db
        .collection('challenges')
        .where('title', '==', challenge.title)
        .limit(1)
        .get();

      if (!existing.empty) {
        skipped++;
        continue;
      }

      // Map browser agent types to app types
      const typeMap: Record<string, string> = {
        hiking: 'hiking',
        dining: 'food',
        sightseeing: 'photo',
        cultural: 'culture',
        adventure: 'activity',
        nightlife: 'nightlife',
        shopping: 'activity',
      };

      const [lon, lat] = challenge.location;
      const hours = challenge.duration;
      const h = Math.floor(hours);
      const m = Math.round((hours - h) * 60);
      const durationStr = `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}:00`;

      const ref = await db.collection('challenges').add({
        title: challenge.title,
        description: challenge.description,
        difficulty: challenge.difficulty,
        type: typeMap[challenge.type] ?? challenge.type,
        location: new GeoPoint(lat, lon),
        expected_duration: durationStr,
        score: challenge.difficulty === 'easy' ? 100 : challenge.difficulty === 'medium' ? 200 : 300,
        chlg_pic_url: challenge.photo_url ?? '',
        joined_people: [],
        created_at: new Date(),
        source: 'browser_agent',
      });

      imported.push(ref.id);
    }

    return {
      imported: imported.length,
      skipped,
      challengeIds: imported,
    };
  },
);
