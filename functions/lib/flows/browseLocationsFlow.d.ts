import { z } from 'genkit';
export declare const browseLocationsFlow: import("genkit").Action<z.ZodObject<{
    query: z.ZodOptional<z.ZodString>;
    category: z.ZodOptional<z.ZodString>;
    userLatitude: z.ZodOptional<z.ZodNumber>;
    userLongitude: z.ZodOptional<z.ZodNumber>;
    radiusMeters: z.ZodOptional<z.ZodNumber>;
}, "strip", z.ZodTypeAny, {
    radiusMeters?: number | undefined;
    userLatitude?: number | undefined;
    userLongitude?: number | undefined;
    query?: string | undefined;
    category?: string | undefined;
}, {
    radiusMeters?: number | undefined;
    userLatitude?: number | undefined;
    userLongitude?: number | undefined;
    query?: string | undefined;
    category?: string | undefined;
}>, z.ZodObject<{
    results: z.ZodArray<z.ZodObject<{
        challengeId: z.ZodString;
        title: z.ZodString;
        description: z.ZodString;
        type: z.ZodString;
        difficulty: z.ZodString;
        aiTip: z.ZodString;
        participantCount: z.ZodNumber;
        distanceMeters: z.ZodOptional<z.ZodNumber>;
    }, "strip", z.ZodTypeAny, {
        type: string;
        title: string;
        description: string;
        difficulty: string;
        challengeId: string;
        aiTip: string;
        participantCount: number;
        distanceMeters?: number | undefined;
    }, {
        type: string;
        title: string;
        description: string;
        difficulty: string;
        challengeId: string;
        aiTip: string;
        participantCount: number;
        distanceMeters?: number | undefined;
    }>, "many">;
    summary: z.ZodString;
}, "strip", z.ZodTypeAny, {
    summary: string;
    results: {
        type: string;
        title: string;
        description: string;
        difficulty: string;
        challengeId: string;
        aiTip: string;
        participantCount: number;
        distanceMeters?: number | undefined;
    }[];
}, {
    summary: string;
    results: {
        type: string;
        title: string;
        description: string;
        difficulty: string;
        challengeId: string;
        aiTip: string;
        participantCount: number;
        distanceMeters?: number | undefined;
    }[];
}>, z.ZodTypeAny>;
