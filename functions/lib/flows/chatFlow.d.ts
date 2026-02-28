import { z } from 'genkit';
export declare const chatWithGuideFlow: import("genkit").Action<z.ZodObject<{
    message: z.ZodString;
    userId: z.ZodOptional<z.ZodString>;
    history: z.ZodOptional<z.ZodArray<z.ZodObject<{
        role: z.ZodEnum<["user", "model"]>;
        content: z.ZodString;
    }, "strip", z.ZodTypeAny, {
        content: string;
        role: "user" | "model";
    }, {
        content: string;
        role: "user" | "model";
    }>, "many">>;
}, "strip", z.ZodTypeAny, {
    message: string;
    userId?: string | undefined;
    history?: {
        content: string;
        role: "user" | "model";
    }[] | undefined;
}, {
    message: string;
    userId?: string | undefined;
    history?: {
        content: string;
        role: "user" | "model";
    }[] | undefined;
}>, z.ZodObject<{
    response: z.ZodString;
}, "strip", z.ZodTypeAny, {
    response: string;
}, {
    response: string;
}>, z.ZodTypeAny>;
