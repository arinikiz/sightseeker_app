import '../firebase-init.js';
import { z } from 'genkit';
export declare const verifyPhotoFlow: import("genkit").Action<z.ZodObject<{
    challengeId: z.ZodString;
    imageBase64: z.ZodString;
    userLatitude: z.ZodNumber;
    userLongitude: z.ZodNumber;
    userId: z.ZodString;
}, "strip", z.ZodTypeAny, {
    challengeId: string;
    userId: string;
    imageBase64: string;
    userLatitude: number;
    userLongitude: number;
}, {
    challengeId: string;
    userId: string;
    imageBase64: string;
    userLatitude: number;
    userLongitude: number;
}>, z.ZodObject<{
    verified: z.ZodBoolean;
    confidence: z.ZodNumber;
    reason: z.ZodString;
    funFact: z.ZodString;
    gpsVerified: z.ZodBoolean;
    gpsDistanceMeters: z.ZodNumber;
}, "strip", z.ZodTypeAny, {
    verified: boolean;
    confidence: number;
    reason: string;
    funFact: string;
    gpsVerified: boolean;
    gpsDistanceMeters: number;
}, {
    verified: boolean;
    confidence: number;
    reason: string;
    funFact: string;
    gpsVerified: boolean;
    gpsDistanceMeters: number;
}>, z.ZodTypeAny>;
