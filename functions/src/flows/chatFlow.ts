import { z } from 'genkit';
import { ai } from '../genkit.js';
import {
  getChallenges,
  getChallengeById,
  getUserProfile,
  getActiveEvents,
  getChallengeParticipants,
  searchChallengesByArea,
  joinChallenge,
  getForumMessages,
  postForumMessage,
} from '../tools/firestoreTools.js';

// ── Planner system prompt (from Bedrock agent planner.j2) ──
const PLANNER_PROMPT = `You are a Travel Planner Agent for Hong Kong.
Your ONLY job is to extract structured travel preferences from the user's message.

Respond with ONLY valid JSON, absolutely no other text:
{
    "available_time_hours": <number of hours, default 4>,
    "interests": <list from: "food", "photo", "culture", "hiking", "nightlife", "activity">,
    "difficulty_preference": <"easy" or "medium" or "hard" or "any", default "any">,
    "group_size": <number, default 1>,
    "special_requests": <string, anything else like "first time", "with kids", "rainy day">
}`;

// ── Guide system prompt (merged Bedrock guide + Genkit original) ──
const GUIDE_SYSTEM_PROMPT = `You are HK Explorer Guide, an enthusiastic and knowledgeable AI travel companion for Hong Kong. You help tourists discover the best of Hong Kong through fun challenges and activities.

Your personality: Friendly, energetic, like a local friend showing someone around. Use casual language. Occasionally drop in Cantonese phrases with translations.

Your capabilities:
1. Ask users about their interests (food, hiking, photography, culture, nightlife), available time, fitness level, and group size
2. Recommend personalized challenge routes from the available challenges — always use the getChallenges or searchChallengesByArea tool to fetch real data
3. Provide insider tips about each location (best times to visit, what to avoid, hidden gems nearby)
4. Suggest meetups with other travelers heading to the same spots — use getChallengeParticipants to check who else is going
5. Adapt recommendations based on weather and time of day
6. Check active weekly events for bonus multipliers using getActiveEvents
7. Help users join challenges using the joinChallenge tool
8. Show forum discussions for challenges using getForumMessages

When recommending a route:
- Consider geographic proximity (don't send someone from Lantau to Sham Shui Po to Lantau again)
- Factor in difficulty and time requirements
- Mix challenge types for variety
- Always explain WHY you're recommending each stop
- Mention how many other travelers have joined each challenge (social proof)

Response format: Keep responses concise and mobile-friendly. Use short paragraphs. When listing a route, number the stops clearly.`;

export const chatWithGuideFlow = ai.defineFlow(
  {
    name: 'chatWithGuide',
    inputSchema: z.object({
      message: z.string().describe('The user message'),
      userId: z.string().optional().describe('Current user ID for personalization'),
      history: z
        .array(
          z.object({
            role: z.enum(['user', 'model']),
            content: z.string(),
          }),
        )
        .optional()
        .describe('Previous conversation turns'),
      mode: z.enum(['guide', 'bedrock']).optional().describe('Chat mode: guide (Genkit AI) or bedrock (multi-agent workflow)'),
    }),
    outputSchema: z.object({
      response: z.string(),
      route: z
        .array(
          z.object({
            challengeId: z.string(),
            title: z.string(),
            reason: z.string(),
            estimatedMinutes: z.number().optional(),
          }),
        )
        .optional(),
    }),
  },
  async (input) => {
    const mode = input.mode ?? 'guide';

    if (mode === 'bedrock') {
      return await runBedrockStyleWorkflow(input);
    }

    // ── Standard Genkit guide flow ──
    const historyMessages =
      input.history?.map((h) => ({
        role: h.role as 'user' | 'model',
        content: [{ text: h.content }],
      })) ?? [];

    const { text } = await ai.generate({
      system: GUIDE_SYSTEM_PROMPT,
      messages: [
        ...historyMessages,
        { role: 'user', content: [{ text: input.message }] },
      ],
      tools: [
        getChallenges,
        getChallengeById,
        getUserProfile,
        getActiveEvents,
        getChallengeParticipants,
        searchChallengesByArea,
        joinChallenge,
        getForumMessages,
        postForumMessage,
      ],
    });

    return { response: text };
  },
);

// ── Bedrock-style multi-agent workflow (Planner → Research → Guide) ──
async function runBedrockStyleWorkflow(input: {
  message: string;
  userId?: string;
  history?: Array<{ role: 'user' | 'model'; content: string }>;
}): Promise<{
  response: string;
  route?: Array<{ challengeId: string; title: string; reason: string; estimatedMinutes?: number }>;
}> {
  const greetings = new Set(['hi', 'hey', 'hello', 'yo', 'sup', 'hola', 'hii', 'heya']);
  if (greetings.has(input.message.trim().toLowerCase())) {
    const { text } = await ai.generate({
      system: GUIDE_SYSTEM_PROMPT,
      prompt: `The user just said '${input.message}'. Give a short warm greeting and ask what they want to do in Hong Kong. 2-3 sentences max.`,
    });
    return { response: text };
  }

  // Step 1: Planner — extract travel preferences
  const { text: plannerText } = await ai.generate({
    system: PLANNER_PROMPT,
    prompt: `Extract travel preferences from this message: '${input.message}'`,
  });

  let preferences: {
    available_time_hours?: number;
    interests?: string[];
    difficulty_preference?: string;
    group_size?: number;
    special_requests?: string;
  };
  try {
    preferences = JSON.parse(plannerText);
  } catch {
    preferences = { available_time_hours: 4, interests: ['food', 'photo', 'culture'] };
  }

  // Step 2: Research — fetch challenges from Firestore and select best matches
  const { text: researchText } = await ai.generate({
    system: `You are a Research Agent. Given travel preferences and a list of challenges, select the best matches and create an optimized route.
Respond with ONLY a JSON object:
{
  "selected_challenges": [{ "challengeId": "...", "title": "...", "type": "...", "reason": "...", "estimatedMinutes": 60 }],
  "route_summary": "brief summary"
}`,
    prompt: `Preferences: ${JSON.stringify(preferences)}

Use the tools to fetch all challenges, then select 3-6 that best match the user's preferences. Consider:
- Interests: ${(preferences.interests ?? []).join(', ')}
- Available time: ${preferences.available_time_hours ?? 4} hours
- Difficulty: ${preferences.difficulty_preference ?? 'any'}
- Group size: ${preferences.group_size ?? 1}`,
    tools: [getChallenges, searchChallengesByArea, getActiveEvents, getChallengeParticipants],
    output: {
      schema: z.object({
        selected_challenges: z.array(
          z.object({
            challengeId: z.string(),
            title: z.string(),
            type: z.string(),
            reason: z.string(),
            estimatedMinutes: z.number().optional(),
          }),
        ),
        route_summary: z.string(),
      }),
    },
  });

  let researchResult: {
    selected_challenges: Array<{
      challengeId: string;
      title: string;
      type: string;
      reason: string;
      estimatedMinutes?: number;
    }>;
    route_summary: string;
  };
  try {
    researchResult = JSON.parse(researchText);
  } catch {
    researchResult = { selected_challenges: [], route_summary: 'Could not find matching challenges.' };
  }

  // Step 3: Guide — generate friendly response with route
  const historyStr =
    input.history
      ?.slice(-6)
      .map((h) => `${h.role}: ${h.content}`)
      .join('\n') ?? 'Start of conversation.';

  const socialInfo = researchResult.selected_challenges
    .map((c) => `- ${c.title}: recommended because ${c.reason}`)
    .join('\n');

  const { text: guideText } = await ai.generate({
    system: GUIDE_SYSTEM_PROMPT,
    prompt: `Recent conversation:
${historyStr}

User's latest message: "${input.message}"

I've researched and found these challenges for them:
${socialInfo}

Route summary: ${researchResult.route_summary}

Now write a friendly, engaging response presenting this route. Include insider tips, mention social aspects (other travelers), and make it sound exciting. Number the stops clearly.`,
  });

  return {
    response: guideText,
    route: researchResult.selected_challenges.map((c) => ({
      challengeId: c.challengeId,
      title: c.title,
      reason: c.reason,
      estimatedMinutes: c.estimatedMinutes,
    })),
  };
}
