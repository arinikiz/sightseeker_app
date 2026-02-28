import '../firebase-init.js';
import { z } from 'genkit';
import { ai, openAI } from '../genkit.js';
import { getFirestore, FieldValue, GeoPoint } from 'firebase-admin/firestore';

const db = getFirestore();

// HK Government Tourism Commission & official recommendation sites
const HK_TOURISM_URLS = [
  'https://www.tourism.gov.hk/',
  'https://www.tourism.gov.hk/tourism-projects.php',
  'https://www.discoverhongkong.com/eng/explore/attractions.html',
];

const ChallengeOutputSchema = z.object({
  challenges: z.array(
    z.object({
      title: z.string(),
      description: z.string(),
      difficulty: z.enum(['easy', 'medium', 'hard']),
      type: z.enum(['hiking', 'dining', 'sightseeing', 'cultural', 'adventure', 'nightlife', 'shopping']),
      duration: z.number().describe('Hours to complete'),
      latitude: z.number(),
      longitude: z.number(),
      photo_url: z.string().nullable().optional(),
    }),
  ),
});

function genChlgId(): string {
  return `chlg_${crypto.randomUUID().replace(/-/g, '').slice(0, 12)}`;
}

export const discoverChallengesFlow = ai.defineFlow(
  {
    name: 'discoverChallengesFromWeb',
    inputSchema: z.object({
      sourceUrl: z.string().optional().describe('Specific URL to scrape; if omitted, uses HK gov tourism sites'),
    }),
    outputSchema: z.object({
      success: z.boolean(),
      message: z.string(),
      challengeIds: z.array(z.string()),
      count: z.number(),
    }),
  },
  async (input) => {
    const urlsToFetch = input.sourceUrl ? [input.sourceUrl] : HK_TOURISM_URLS;
    const fetchedContents: { url: string; text: string }[] = [];

    for (const url of urlsToFetch) {
      try {
        const res = await fetch(url, {
          headers: { 'User-Agent': 'SightSeeker/1.0 (HK Tourism Challenge Discovery)' },
        });
        if (!res.ok) continue;
        const html = await res.text();
        // Strip HTML tags, keep text (rough extraction)
        const text = html
          .replace(/<script[^>]*>[\s\S]*?<\/script>/gi, '')
          .replace(/<style[^>]*>[\s\S]*?<\/style>/gi, '')
          .replace(/<[^>]+>/g, ' ')
          .replace(/\s+/g, ' ')
          .trim()
          .slice(0, 15000);
        if (text.length > 200) {
          fetchedContents.push({ url, text });
        }
      } catch {
        // Skip failed fetches
      }
    }

    if (fetchedContents.length === 0) {
      return {
        success: false,
        message: 'Could not fetch any tourism pages.',
        challengeIds: [],
        count: 0,
      };
    }

    const context = fetchedContents
      .map((c) => `--- From ${c.url} ---\n${c.text}`)
      .join('\n\n');

    const prompt = `You are a challenge discovery agent for SightSeeker, a gamified Hong Kong tourism app.

Extract attractions and activities from this content (from HK Government Tourism Commission and official tourism sites).
Generate 5-10 challenge objects. Each challenge MUST have:
- title: Creative, game-like (e.g. "Peak Conqueror", "Temple of Serenity")
- description: Engaging, ~100 words, frame as a quest
- difficulty: easy | medium | hard
- type: hiking | dining | sightseeing | cultural | adventure | nightlife | shopping
- duration: hours (number, e.g. 2.5)
- latitude, longitude: Real Hong Kong GPS (lat ~22.2-22.4, lng ~113.9-114.3)
- photo_url: null (we don't have images from scrape)

Content:
${context}

Return ONLY a JSON object: {"challenges": [...]}`;

    const { text } = await ai.generate({
      model: openAI.model('gpt-4o'),
      prompt,
      output: { schema: ChallengeOutputSchema },
    });

    let parsed: z.infer<typeof ChallengeOutputSchema>;
    try {
      const json = JSON.parse(text);
      parsed = ChallengeOutputSchema.parse(json);
    } catch {
      return {
        success: false,
        message: 'AI response could not be parsed as valid challenges.',
        challengeIds: [],
        count: 0,
      };
    }

    const challengeIds: string[] = [];
    const batch = db.batch();

    for (const c of parsed.challenges) {
      const id = genChlgId();
      const durationStr = `${String(Math.floor(c.duration)).padStart(2, '0')}:${String(Math.round((c.duration % 1) * 60)).padStart(2, '0')}:00`;
      batch.set(db.collection('challenges').doc(id), {
        title: c.title,
        description: c.description,
        difficulty: c.difficulty,
        type: c.type,
        score: 8.5,
        expected_duration: durationStr,
        location: new GeoPoint(c.latitude, c.longitude),
        created_at: FieldValue.serverTimestamp(),
        joined_people: [],
        chlg_pic_url: c.photo_url ?? '',
      });
      challengeIds.push(id);
    }

    await batch.commit();

    return {
      success: true,
      message: `Discovered ${challengeIds.length} challenges from HK tourism recommendations.`,
      challengeIds,
      count: challengeIds.length,
    };
  },
);
