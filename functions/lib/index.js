"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.discoverChallengesFromWeb = exports.browseLocations = exports.generateRoute = exports.verifyPhoto = exports.chatWithGuide = void 0;
require("./firebase-init.js");
const https_1 = require("firebase-functions/https");
const params_1 = require("firebase-functions/params");
const chatFlow_js_1 = require("./flows/chatFlow.js");
const photoVerificationFlow_js_1 = require("./flows/photoVerificationFlow.js");
const routeGenerationFlow_js_1 = require("./flows/routeGenerationFlow.js");
const browseLocationsFlow_js_1 = require("./flows/browseLocationsFlow.js");
const discoverChallengesFlow_js_1 = require("./flows/discoverChallengesFlow.js");
const openaiApiKey = (0, params_1.defineSecret)('OPENAI_API_KEY');
exports.chatWithGuide = (0, https_1.onCallGenkit)({ secrets: [openaiApiKey] }, chatFlow_js_1.chatWithGuideFlow);
exports.verifyPhoto = (0, https_1.onCallGenkit)({ secrets: [openaiApiKey] }, photoVerificationFlow_js_1.verifyPhotoFlow);
exports.generateRoute = (0, https_1.onCallGenkit)({ secrets: [openaiApiKey] }, routeGenerationFlow_js_1.generateRouteFlow);
exports.browseLocations = (0, https_1.onCallGenkit)({ secrets: [openaiApiKey] }, browseLocationsFlow_js_1.browseLocationsFlow);
exports.discoverChallengesFromWeb = (0, https_1.onCallGenkit)({
    secrets: [openaiApiKey],
    timeoutSeconds: 120, // Fetch + AI extraction can take 60–90s
}, discoverChallengesFlow_js_1.discoverChallengesFlow);
//# sourceMappingURL=index.js.map