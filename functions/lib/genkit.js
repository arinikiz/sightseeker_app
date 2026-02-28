"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ai = exports.openAI = void 0;
const genkit_1 = require("genkit");
const openai_1 = require("@genkit-ai/compat-oai/openai");
Object.defineProperty(exports, "openAI", { enumerable: true, get: function () { return openai_1.openAI; } });
exports.ai = (0, genkit_1.genkit)({
    plugins: [(0, openai_1.openAI)()],
    model: openai_1.openAI.model('gpt-4o'),
});
//# sourceMappingURL=genkit.js.map