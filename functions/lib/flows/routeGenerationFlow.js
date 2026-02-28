"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.generateRouteFlow = void 0;
const genkit_1 = require("genkit");
const genkit_js_1 = require("../genkit.js");
const firestoreTools_js_1 = require("../tools/firestoreTools.js");
exports.generateRouteFlow = genkit_js_1.ai.defineFlow({
    name: 'generateRoute',
    inputSchema: genkit_1.z.object({
        userId: genkit_1.z.string().describe('User ID to check completed/joined challenges'),
        interests: genkit_1.z
            .array(genkit_1.z.string())
            .describe('User interests: food, hiking, photography, culture, nightlife'),
        availableHours: genkit_1.z.number().describe('How many hours the user has available'),
        fitnessLevel: genkit_1.z
            .enum(['low', 'medium', 'high'])
            .optional()
            .describe('User fitness level'),
        groupSize: genkit_1.z.number().optional().describe('Number of people in group'),
    }),
    outputSchema: genkit_1.z.object({
        route: genkit_1.z.array(genkit_1.z.object({
            challengeId: genkit_1.z.string(),
            title: genkit_1.z.string(),
            reason: genkit_1.z.string().describe('Why this stop is recommended'),
            estimatedMinutes: genkit_1.z.number(),
            order: genkit_1.z.number(),
        })),
        summary: genkit_1.z.string().describe('Overall route summary from the AI'),
        totalEstimatedMinutes: genkit_1.z.number(),
    }),
}, async (input) => {
    const prompt = `You are a route planning AI for HK Explorer, a Hong Kong tourism app.

The user wants a personalized challenge route with these preferences:
- Interests: ${input.interests.join(', ')}
- Available time: ${input.availableHours} hours
- Fitness level: ${input.fitnessLevel ?? 'medium'}
- Group size: ${input.groupSize ?? 1}

Use the tools to:
1. Fetch the user's profile to see which challenges they've already completed
2. Fetch all available challenges
3. Check for active weekly events that might give bonus points

Then create an optimized route that:
- Skips challenges the user already completed
- Matches their interests
- Fits within their available time
- Considers geographic proximity (don't zigzag across Hong Kong)
- Mixes challenge types for variety
- Prioritizes challenges that align with active weekly events for bonus points

Return a JSON object with:
- "route": array of objects with challengeId, title, reason, estimatedMinutes, order
- "summary": a brief friendly summary of the route
- "totalEstimatedMinutes": total estimated time in minutes`;
    const { text } = await genkit_js_1.ai.generate({
        prompt,
        tools: [firestoreTools_js_1.getChallenges, firestoreTools_js_1.getUserProfile, firestoreTools_js_1.getActiveEvents],
        output: {
            schema: genkit_1.z.object({
                route: genkit_1.z.array(genkit_1.z.object({
                    challengeId: genkit_1.z.string(),
                    title: genkit_1.z.string(),
                    reason: genkit_1.z.string(),
                    estimatedMinutes: genkit_1.z.number(),
                    order: genkit_1.z.number(),
                })),
                summary: genkit_1.z.string(),
                totalEstimatedMinutes: genkit_1.z.number(),
            }),
        },
    });
    try {
        return JSON.parse(text);
    }
    catch {
        return { route: [], summary: 'Could not generate a route.', totalEstimatedMinutes: 0 };
    }
});
//# sourceMappingURL=routeGenerationFlow.js.map