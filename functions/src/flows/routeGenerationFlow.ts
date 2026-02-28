import { z } from 'genkit';
import { ai } from '../genkit.js';
import {
  getChallenges,
  getUserProfile,
  getActiveEvents,
} from '../tools/firestoreTools.js';

export const generateRouteFlow = ai.defineFlow(
  {
    name: 'generateRoute',
    inputSchema: z.object({
      userId: z.string().describe('User ID to check completed/joined challenges'),
      interests: z
        .array(z.string())
        .describe('User interests: food, hiking, photography, culture, nightlife'),
      availableHours: z.number().describe('How many hours the user has available'),
      fitnessLevel: z
        .enum(['low', 'medium', 'high'])
        .optional()
        .describe('User fitness level'),
      groupSize: z.number().optional().describe('Number of people in group'),
    }),
    outputSchema: z.object({
      route: z.array(
        z.object({
          challengeId: z.string(),
          title: z.string(),
          reason: z.string().describe('Why this stop is recommended'),
          estimatedMinutes: z.number(),
          order: z.number(),
        }),
      ),
      summary: z.string().describe('Overall route summary from the AI'),
      totalEstimatedMinutes: z.number(),
    }),
  },
  async (input) => {
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

    const { text } = await ai.generate({
      prompt,
      tools: [getChallenges, getUserProfile, getActiveEvents],
      output: {
        schema: z.object({
          route: z.array(
            z.object({
              challengeId: z.string(),
              title: z.string(),
              reason: z.string(),
              estimatedMinutes: z.number(),
              order: z.number(),
            }),
          ),
          summary: z.string(),
          totalEstimatedMinutes: z.number(),
        }),
      },
    });

    try {
      return JSON.parse(text);
    } catch {
      return { route: [], summary: 'Could not generate a route.', totalEstimatedMinutes: 0 };
    }
  },
);
