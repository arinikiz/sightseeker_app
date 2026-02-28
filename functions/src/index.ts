import { initializeApp } from 'firebase-admin/app';
import { onCallGenkit } from 'firebase-functions/https';
import { defineSecret } from 'firebase-functions/params';

import { chatWithGuideFlow } from './flows/chatFlow.js';
import { verifyPhotoFlow } from './flows/photoVerificationFlow.js';
import { generateRouteFlow } from './flows/routeGenerationFlow.js';
import { browseLocationsFlow } from './flows/browseLocationsFlow.js';

initializeApp();

const openaiApiKey = defineSecret('OPENAI_API_KEY');

export const chatWithGuide = onCallGenkit(
  { secrets: [openaiApiKey] },
  chatWithGuideFlow,
);

export const verifyPhoto = onCallGenkit(
  { secrets: [openaiApiKey] },
  verifyPhotoFlow,
);

export const generateRoute = onCallGenkit(
  { secrets: [openaiApiKey] },
  generateRouteFlow,
);

export const browseLocations = onCallGenkit(
  { secrets: [openaiApiKey] },
  browseLocationsFlow,
);
