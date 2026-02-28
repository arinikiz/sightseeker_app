import './firebase-init.js';
import { onCallGenkit } from 'firebase-functions/https';
import { defineSecret } from 'firebase-functions/params';

import { chatWithGuideFlow } from './flows/chatFlow.js';
import { verifyPhotoFlow } from './flows/photoVerificationFlow.js';
import { generateRouteFlow } from './flows/routeGenerationFlow.js';
import { browseLocationsFlow } from './flows/browseLocationsFlow.js';
import { discoverChallengesFlow } from './flows/discoverChallengesFlow.js';

const openaiApiKey = defineSecret('OPENAI_API_KEY');

export const chatWithGuide = onCallGenkit(
  { secrets: [openaiApiKey], cors: true },
  chatWithGuideFlow,
);

export const verifyPhoto = onCallGenkit(
  { secrets: [openaiApiKey], cors: true },
  verifyPhotoFlow,
);

export const generateRoute = onCallGenkit(
  { secrets: [openaiApiKey], cors: true },
  generateRouteFlow,
);

export const browseLocations = onCallGenkit(
  { secrets: [openaiApiKey], cors: true },
  browseLocationsFlow,
);

export const discoverChallengesFromWeb = onCallGenkit(
  {
    secrets: [openaiApiKey],
    cors: true,
    timeoutSeconds: 120, // Fetch + AI extraction can take 60–90s
  },
  discoverChallengesFlow,
);
