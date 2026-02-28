"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.browseLocationsFlow = void 0;
const genkit_1 = require("genkit");
const genkit_js_1 = require("../genkit.js");
const firestoreTools_js_1 = require("../tools/firestoreTools.js");
exports.browseLocationsFlow = genkit_js_1.ai.defineFlow({
    name: 'browseLocations',
    inputSchema: genkit_1.z.object({
        query: genkit_1.z.string().optional().describe('Free-text search query like "best food spots" or "easy photo challenges"'),
        category: genkit_1.z.string().optional().describe('Category filter: photo, food, activity, hiking'),
        userLatitude: genkit_1.z.number().optional().describe('User latitude for nearby search'),
        userLongitude: genkit_1.z.number().optional().describe('User longitude for nearby search'),
        radiusMeters: genkit_1.z.number().optional().describe('Search radius in meters'),
    }),
    outputSchema: genkit_1.z.object({
        results: genkit_1.z.array(genkit_1.z.object({
            challengeId: genkit_1.z.string(),
            title: genkit_1.z.string(),
            description: genkit_1.z.string(),
            type: genkit_1.z.string(),
            difficulty: genkit_1.z.string(),
            aiTip: genkit_1.z.string().describe('AI-generated insider tip about this location'),
            participantCount: genkit_1.z.number(),
            distanceMeters: genkit_1.z.number().optional(),
        })),
        summary: genkit_1.z.string().describe('AI summary of the search results'),
    }),
}, async (input) => {
    const searchContext = [
        input.query ? `User is searching for: "${input.query}"` : '',
        input.category ? `Category filter: ${input.category}` : '',
        input.userLatitude
            ? `User is near: ${input.userLatitude}, ${input.userLongitude}`
            : '',
    ]
        .filter(Boolean)
        .join('\n');
    const prompt = `You are a location discovery AI for HK Explorer, a Hong Kong tourism app.

${searchContext}

Use the available tools to:
1. Search for challenges matching the user's query or category
2. If the user provided their location, find nearby challenges using searchChallengesByArea
3. Check participant counts for popular challenges
4. Check for active weekly events

For each result, generate a helpful insider tip about the location (best time to visit, what to look out for, local recommendations).

Return a JSON object with:
- "results": array of objects with challengeId, title, description, type, difficulty, aiTip, participantCount, distanceMeters (if location was provided)
- "summary": a brief friendly summary of what you found`;
    const { text } = await genkit_js_1.ai.generate({
        prompt,
        tools: [
            firestoreTools_js_1.getChallenges,
            firestoreTools_js_1.getChallengeParticipants,
            firestoreTools_js_1.searchChallengesByArea,
            firestoreTools_js_1.getActiveEvents,
        ],
        output: {
            schema: genkit_1.z.object({
                results: genkit_1.z.array(genkit_1.z.object({
                    challengeId: genkit_1.z.string(),
                    title: genkit_1.z.string(),
                    description: genkit_1.z.string(),
                    type: genkit_1.z.string(),
                    difficulty: genkit_1.z.string(),
                    aiTip: genkit_1.z.string(),
                    participantCount: genkit_1.z.number(),
                    distanceMeters: genkit_1.z.number().optional(),
                })),
                summary: genkit_1.z.string(),
            }),
        },
    });
    try {
        return JSON.parse(text);
    }
    catch {
        return { results: [], summary: 'Could not process location search.' };
    }
});
//# sourceMappingURL=browseLocationsFlow.js.map