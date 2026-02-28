"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.chatWithGuideFlow = void 0;
const genkit_1 = require("genkit");
const genkit_js_1 = require("../genkit.js");
const firestoreTools_js_1 = require("../tools/firestoreTools.js");
const SYSTEM_PROMPT = `You are HK Explorer Guide, an enthusiastic and knowledgeable AI travel companion for Hong Kong. You help tourists discover the best of Hong Kong through fun challenges and activities.

Your personality: Friendly, energetic, like a local friend showing someone around. Use casual language. Occasionally drop in Cantonese phrases with translations (e.g., "That's 好正 (ho jeng) — really awesome!").

Your capabilities:
1. Ask users about their interests (food, hiking, photography, culture, nightlife), available time, fitness level, and group size
2. Recommend personalized challenge routes from the available challenges — always use the getChallenges or searchChallengesByArea tool to fetch real data
3. Provide insider tips about each location (best times to visit, what to avoid, hidden gems nearby)
4. Suggest meetups with other travelers heading to the same spots — use getChallengeParticipants to check who else is going
5. Adapt recommendations based on weather and time of day
6. Check active weekly events for bonus multipliers using getActiveEvents

When recommending a route:
- Consider geographic proximity (don't send someone from Lantau to Sham Shui Po to Lantau again)
- Factor in difficulty and time requirements
- Mix challenge types for variety
- Always explain WHY you're recommending each stop

Response format: Keep responses concise and mobile-friendly. Use short paragraphs. When listing a route, number the stops clearly.`;
exports.chatWithGuideFlow = genkit_js_1.ai.defineFlow({
    name: 'chatWithGuide',
    inputSchema: genkit_1.z.object({
        message: genkit_1.z.string().describe('The user message'),
        userId: genkit_1.z.string().optional().describe('Current user ID for personalization'),
        history: genkit_1.z
            .array(genkit_1.z.object({
            role: genkit_1.z.enum(['user', 'model']),
            content: genkit_1.z.string(),
        }))
            .optional()
            .describe('Previous conversation turns'),
    }),
    outputSchema: genkit_1.z.object({
        response: genkit_1.z.string(),
    }),
}, async (input) => {
    const historyMessages = input.history?.map((h) => ({
        role: h.role,
        content: [{ text: h.content }],
    })) ?? [];
    const { text } = await genkit_js_1.ai.generate({
        system: SYSTEM_PROMPT,
        messages: [
            ...historyMessages,
            { role: 'user', content: [{ text: input.message }] },
        ],
        tools: [
            firestoreTools_js_1.getChallenges,
            firestoreTools_js_1.getChallengeById,
            firestoreTools_js_1.getUserProfile,
            firestoreTools_js_1.getActiveEvents,
            firestoreTools_js_1.getChallengeParticipants,
            firestoreTools_js_1.searchChallengesByArea,
        ],
    });
    return { response: text };
});
//# sourceMappingURL=chatFlow.js.map