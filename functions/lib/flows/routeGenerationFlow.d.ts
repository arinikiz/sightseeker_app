import { z } from 'genkit';
export declare const generateRouteFlow: import("genkit").Action<z.ZodObject<{
    userId: z.ZodString;
    interests: z.ZodArray<z.ZodString, "many">;
    availableHours: z.ZodNumber;
    fitnessLevel: z.ZodOptional<z.ZodEnum<["low", "medium", "high"]>>;
    groupSize: z.ZodOptional<z.ZodNumber>;
}, "strip", z.ZodTypeAny, {
    userId: string;
    interests: string[];
    availableHours: number;
    fitnessLevel?: "low" | "medium" | "high" | undefined;
    groupSize?: number | undefined;
}, {
    userId: string;
    interests: string[];
    availableHours: number;
    fitnessLevel?: "low" | "medium" | "high" | undefined;
    groupSize?: number | undefined;
}>, z.ZodObject<{
    route: z.ZodArray<z.ZodObject<{
        challengeId: z.ZodString;
        title: z.ZodString;
        reason: z.ZodString;
        estimatedMinutes: z.ZodNumber;
        order: z.ZodNumber;
    }, "strip", z.ZodTypeAny, {
        title: string;
        challengeId: string;
        reason: string;
        estimatedMinutes: number;
        order: number;
    }, {
        title: string;
        challengeId: string;
        reason: string;
        estimatedMinutes: number;
        order: number;
    }>, "many">;
    summary: z.ZodString;
    totalEstimatedMinutes: z.ZodNumber;
}, "strip", z.ZodTypeAny, {
    route: {
        title: string;
        challengeId: string;
        reason: string;
        estimatedMinutes: number;
        order: number;
    }[];
    summary: string;
    totalEstimatedMinutes: number;
}, {
    route: {
        title: string;
        challengeId: string;
        reason: string;
        estimatedMinutes: number;
        order: number;
    }[];
    summary: string;
    totalEstimatedMinutes: number;
}>, z.ZodTypeAny>;
