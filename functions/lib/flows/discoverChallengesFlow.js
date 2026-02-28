"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.discoverChallengesFlow = void 0;
require("../firebase-init.js");
const genkit_1 = require("genkit");
const genkit_js_1 = require("../genkit.js");
const firestore_1 = require("firebase-admin/firestore");
const db = (0, firestore_1.getFirestore)();
// HK Government Tourism Commission & official recommendation sites
const HK_TOURISM_URLS = [
    'https://www.tourism.gov.hk/',
    'https://www.tourism.gov.hk/tourism-projects.php',
    'https://www.discoverhongkong.com/eng/explore/attractions.html',
];
const ChallengeOutputSchema = genkit_1.z.object({
    challenges: genkit_1.z.array(genkit_1.z.object({
        title: genkit_1.z.string(),
        description: genkit_1.z.string(),
        difficulty: genkit_1.z.enum(['easy', 'medium', 'hard']),
        type: genkit_1.z.enum(['hiking', 'dining', 'sightseeing', 'cultural', 'adventure', 'nightlife', 'shopping']),
        duration: genkit_1.z.number().describe('Hours to complete'),
        latitude: genkit_1.z.number(),
        longitude: genkit_1.z.number(),
        photo_url: genkit_1.z.string().nullable().optional(),
    })),
});
function genChlgId() {
    return `chlg_${crypto.randomUUID().replace(/-/g, '').slice(0, 12)}`;
}
exports.discoverChallengesFlow = genkit_js_1.ai.defineFlow({
    name: 'discoverChallengesFromWeb',
    inputSchema: genkit_1.z.object({
        sourceUrl: genkit_1.z.string().optional().describe('Specific URL to scrape; if omitted, uses HK gov tourism sites'),
    }),
    outputSchema: genkit_1.z.object({
        success: genkit_1.z.boolean(),
        message: genkit_1.z.string(),
        challengeIds: genkit_1.z.array(genkit_1.z.string()),
        count: genkit_1.z.number(),
    }),
}, async (input) => {
    const urlsToFetch = input.sourceUrl ? [input.sourceUrl] : HK_TOURISM_URLS;
    const fetchedContents = [];
    for (const url of urlsToFetch) {
        try {
            const res = await fetch(url, {
                headers: { 'User-Agent': 'SightSeeker/1.0 (HK Tourism Challenge Discovery)' },
            });
            if (!res.ok)
                continue;
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
        }
        catch {
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
    const { text } = await genkit_js_1.ai.generate({
        model: genkit_js_1.openAI.model('gpt-4o'),
        prompt,
        output: { schema: ChallengeOutputSchema },
    });
    let parsed;
    try {
        const json = JSON.parse(text);
        parsed = ChallengeOutputSchema.parse(json);
    }
    catch {
        return {
            success: false,
            message: 'AI response could not be parsed as valid challenges.',
            challengeIds: [],
            count: 0,
        };
    }
    const challengeIds = [];
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
            location: new firestore_1.GeoPoint(c.latitude, c.longitude),
            created_at: firestore_1.FieldValue.serverTimestamp(),
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
});
//# sourceMappingURL=discoverChallengesFlow.js.map