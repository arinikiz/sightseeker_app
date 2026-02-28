import { z } from 'genkit';
import { ai } from '../genkit.js';
import {
  getChallenges,
  getChallengeParticipants,
  searchChallengesByArea,
  getActiveEvents,
} from '../tools/firestoreTools.js';

export const browseLocationsFlow = ai.defineFlow(
  {
    name: 'browseLocations',
    inputSchema: z.object({
      query: z.string().optional().describe('Free-text search query like "best food spots" or "easy photo challenges"'),
      category: z.string().optional().describe('Category filter: photo, food, activity, hiking'),
      userLatitude: z.number().optional().describe('User latitude for nearby search'),
      userLongitude: z.number().optional().describe('User longitude for nearby search'),
      radiusMeters: z.number().optional().describe('Search radius in meters'),
    }),
    outputSchema: z.object({
      results: z.array(
        z.object({
          challengeId: z.string(),
          title: z.string(),
          description: z.string(),
          type: z.string(),
          difficulty: z.string(),
          aiTip: z.string().describe('AI-generated insider tip about this location'),
          participantCount: z.number(),
          distanceMeters: z.number().optional(),
        }),
      ),
      summary: z.string().describe('AI summary of the search results'),
    }),
  },
  async (input) => {
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

    const { text } = await ai.generate({
      prompt,
      tools: [
        getChallenges,
        getChallengeParticipants,
        searchChallengesByArea,
        getActiveEvents,
      ],
      output: {
        schema: z.object({
          results: z.array(
            z.object({
              challengeId: z.string(),
              title: z.string(),
              description: z.string(),
              type: z.string(),
              difficulty: z.string(),
              aiTip: z.string(),
              participantCount: z.number(),
              distanceMeters: z.number().optional(),
            }),
          ),
          summary: z.string(),
        }),
      },
    });

    try {
      return JSON.parse(text);
    } catch {
      return { results: [], summary: 'Could not process location search.' };
    }
  },
);
