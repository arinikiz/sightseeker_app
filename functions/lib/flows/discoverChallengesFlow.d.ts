import '../firebase-init.js';
import { z } from 'genkit';
export declare const discoverChallengesFlow: import("genkit").Action<z.ZodObject<{
    sourceUrl: z.ZodOptional<z.ZodString>;
}, "strip", z.ZodTypeAny, {
    sourceUrl?: string | undefined;
}, {
    sourceUrl?: string | undefined;
}>, z.ZodObject<{
    success: z.ZodBoolean;
    message: z.ZodString;
    challengeIds: z.ZodArray<z.ZodString, "many">;
    count: z.ZodNumber;
}, "strip", z.ZodTypeAny, {
    message: string;
    count: number;
    success: boolean;
    challengeIds: string[];
}, {
    message: string;
    count: number;
    success: boolean;
    challengeIds: string[];
}>, z.ZodTypeAny>;
