import { genkit } from 'genkit';
import { openAI } from '@genkit-ai/compat-oai/openai';

export { openAI };

export const ai = genkit({
  plugins: [openAI()],
  model: openAI.model('gpt-4o'),
});
