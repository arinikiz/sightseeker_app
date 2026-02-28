import '../firebase-init.js';
import { z } from 'genkit';
export declare const getChallenges: import("genkit").ToolAction<z.ZodObject<{
    type: z.ZodOptional<z.ZodString>;
    difficulty: z.ZodOptional<z.ZodString>;
}, "strip", z.ZodTypeAny, {
    type?: string | undefined;
    difficulty?: string | undefined;
}, {
    type?: string | undefined;
    difficulty?: string | undefined;
}>, z.ZodArray<z.ZodObject<{
    id: z.ZodString;
    title: z.ZodString;
    description: z.ZodString;
    type: z.ZodString;
    difficulty: z.ZodString;
    score: z.ZodOptional<z.ZodNumber>;
    expected_duration: z.ZodOptional<z.ZodString>;
    latitude: z.ZodNumber;
    longitude: z.ZodNumber;
    joined_people: z.ZodOptional<z.ZodArray<z.ZodString, "many">>;
    chlg_pic_url: z.ZodOptional<z.ZodString>;
    sponsor: z.ZodOptional<z.ZodNullable<z.ZodObject<{
        name: z.ZodString;
        type: z.ZodString;
    }, "strip", z.ZodTypeAny, {
        type: string;
        name: string;
    }, {
        type: string;
        name: string;
    }>>>;
}, "strip", z.ZodTypeAny, {
    type: string;
    id: string;
    title: string;
    description: string;
    difficulty: string;
    latitude: number;
    longitude: number;
    score?: number | undefined;
    expected_duration?: string | undefined;
    joined_people?: string[] | undefined;
    chlg_pic_url?: string | undefined;
    sponsor?: {
        type: string;
        name: string;
    } | null | undefined;
}, {
    type: string;
    id: string;
    title: string;
    description: string;
    difficulty: string;
    latitude: number;
    longitude: number;
    score?: number | undefined;
    expected_duration?: string | undefined;
    joined_people?: string[] | undefined;
    chlg_pic_url?: string | undefined;
    sponsor?: {
        type: string;
        name: string;
    } | null | undefined;
}>, "many">>;
export declare const getChallengeById: import("genkit").ToolAction<z.ZodObject<{
    challengeId: z.ZodString;
}, "strip", z.ZodTypeAny, {
    challengeId: string;
}, {
    challengeId: string;
}>, z.ZodNullable<z.ZodObject<{
    id: z.ZodString;
    title: z.ZodString;
    description: z.ZodString;
    type: z.ZodString;
    difficulty: z.ZodString;
    score: z.ZodOptional<z.ZodNumber>;
    expected_duration: z.ZodOptional<z.ZodString>;
    latitude: z.ZodNumber;
    longitude: z.ZodNumber;
    joined_people: z.ZodOptional<z.ZodArray<z.ZodString, "many">>;
    chlg_pic_url: z.ZodOptional<z.ZodString>;
    sponsor: z.ZodOptional<z.ZodNullable<z.ZodObject<{
        name: z.ZodString;
        type: z.ZodString;
    }, "strip", z.ZodTypeAny, {
        type: string;
        name: string;
    }, {
        type: string;
        name: string;
    }>>>;
}, "strip", z.ZodTypeAny, {
    type: string;
    id: string;
    title: string;
    description: string;
    difficulty: string;
    latitude: number;
    longitude: number;
    score?: number | undefined;
    expected_duration?: string | undefined;
    joined_people?: string[] | undefined;
    chlg_pic_url?: string | undefined;
    sponsor?: {
        type: string;
        name: string;
    } | null | undefined;
}, {
    type: string;
    id: string;
    title: string;
    description: string;
    difficulty: string;
    latitude: number;
    longitude: number;
    score?: number | undefined;
    expected_duration?: string | undefined;
    joined_people?: string[] | undefined;
    chlg_pic_url?: string | undefined;
    sponsor?: {
        type: string;
        name: string;
    } | null | undefined;
}>>>;
export declare const getUserProfile: import("genkit").ToolAction<z.ZodObject<{
    userId: z.ZodString;
}, "strip", z.ZodTypeAny, {
    userId: string;
}, {
    userId: string;
}>, z.ZodNullable<z.ZodObject<{
    uid: z.ZodString;
    name_surname: z.ZodString;
    email: z.ZodOptional<z.ZodString>;
    cum_points: z.ZodNumber;
    joined_chlgs: z.ZodArray<z.ZodString, "many">;
    completed_chlg: z.ZodArray<z.ZodString, "many">;
    user_pic_url: z.ZodOptional<z.ZodString>;
}, "strip", z.ZodTypeAny, {
    uid: string;
    name_surname: string;
    cum_points: number;
    joined_chlgs: string[];
    completed_chlg: string[];
    email?: string | undefined;
    user_pic_url?: string | undefined;
}, {
    uid: string;
    name_surname: string;
    cum_points: number;
    joined_chlgs: string[];
    completed_chlg: string[];
    email?: string | undefined;
    user_pic_url?: string | undefined;
}>>>;
export declare const getActiveEvents: import("genkit").ToolAction<z.ZodObject<{}, "strip", z.ZodTypeAny, {}, {}>, z.ZodArray<z.ZodObject<{
    id: z.ZodString;
    description: z.ZodString;
    multiplier: z.ZodNumber;
    target_category: z.ZodString;
    start_date: z.ZodString;
    end_date: z.ZodString;
}, "strip", z.ZodTypeAny, {
    id: string;
    description: string;
    multiplier: number;
    target_category: string;
    start_date: string;
    end_date: string;
}, {
    id: string;
    description: string;
    multiplier: number;
    target_category: string;
    start_date: string;
    end_date: string;
}>, "many">>;
export declare const getChallengeParticipants: import("genkit").ToolAction<z.ZodObject<{
    challengeId: z.ZodString;
}, "strip", z.ZodTypeAny, {
    challengeId: string;
}, {
    challengeId: string;
}>, z.ZodObject<{
    challengeId: z.ZodString;
    participantIds: z.ZodArray<z.ZodString, "many">;
    count: z.ZodNumber;
}, "strip", z.ZodTypeAny, {
    count: number;
    challengeId: string;
    participantIds: string[];
}, {
    count: number;
    challengeId: string;
    participantIds: string[];
}>>;
export declare const searchChallengesByArea: import("genkit").ToolAction<z.ZodObject<{
    latitude: z.ZodNumber;
    longitude: z.ZodNumber;
    radiusMeters: z.ZodOptional<z.ZodNumber>;
}, "strip", z.ZodTypeAny, {
    latitude: number;
    longitude: number;
    radiusMeters?: number | undefined;
}, {
    latitude: number;
    longitude: number;
    radiusMeters?: number | undefined;
}>, z.ZodArray<z.ZodObject<{
    id: z.ZodString;
    title: z.ZodString;
    description: z.ZodString;
    type: z.ZodString;
    difficulty: z.ZodString;
    score: z.ZodOptional<z.ZodNumber>;
    expected_duration: z.ZodOptional<z.ZodString>;
    latitude: z.ZodNumber;
    longitude: z.ZodNumber;
    joined_people: z.ZodOptional<z.ZodArray<z.ZodString, "many">>;
    chlg_pic_url: z.ZodOptional<z.ZodString>;
    sponsor: z.ZodOptional<z.ZodNullable<z.ZodObject<{
        name: z.ZodString;
        type: z.ZodString;
    }, "strip", z.ZodTypeAny, {
        type: string;
        name: string;
    }, {
        type: string;
        name: string;
    }>>>;
} & {
    distanceMeters: z.ZodNumber;
}, "strip", z.ZodTypeAny, {
    type: string;
    id: string;
    title: string;
    description: string;
    difficulty: string;
    latitude: number;
    longitude: number;
    distanceMeters: number;
    score?: number | undefined;
    expected_duration?: string | undefined;
    joined_people?: string[] | undefined;
    chlg_pic_url?: string | undefined;
    sponsor?: {
        type: string;
        name: string;
    } | null | undefined;
}, {
    type: string;
    id: string;
    title: string;
    description: string;
    difficulty: string;
    latitude: number;
    longitude: number;
    distanceMeters: number;
    score?: number | undefined;
    expected_duration?: string | undefined;
    joined_people?: string[] | undefined;
    chlg_pic_url?: string | undefined;
    sponsor?: {
        type: string;
        name: string;
    } | null | undefined;
}>, "many">>;
export declare const allTools: (import("genkit").ToolAction<z.ZodObject<{
    type: z.ZodOptional<z.ZodString>;
    difficulty: z.ZodOptional<z.ZodString>;
}, "strip", z.ZodTypeAny, {
    type?: string | undefined;
    difficulty?: string | undefined;
}, {
    type?: string | undefined;
    difficulty?: string | undefined;
}>, z.ZodArray<z.ZodObject<{
    id: z.ZodString;
    title: z.ZodString;
    description: z.ZodString;
    type: z.ZodString;
    difficulty: z.ZodString;
    score: z.ZodOptional<z.ZodNumber>;
    expected_duration: z.ZodOptional<z.ZodString>;
    latitude: z.ZodNumber;
    longitude: z.ZodNumber;
    joined_people: z.ZodOptional<z.ZodArray<z.ZodString, "many">>;
    chlg_pic_url: z.ZodOptional<z.ZodString>;
    sponsor: z.ZodOptional<z.ZodNullable<z.ZodObject<{
        name: z.ZodString;
        type: z.ZodString;
    }, "strip", z.ZodTypeAny, {
        type: string;
        name: string;
    }, {
        type: string;
        name: string;
    }>>>;
}, "strip", z.ZodTypeAny, {
    type: string;
    id: string;
    title: string;
    description: string;
    difficulty: string;
    latitude: number;
    longitude: number;
    score?: number | undefined;
    expected_duration?: string | undefined;
    joined_people?: string[] | undefined;
    chlg_pic_url?: string | undefined;
    sponsor?: {
        type: string;
        name: string;
    } | null | undefined;
}, {
    type: string;
    id: string;
    title: string;
    description: string;
    difficulty: string;
    latitude: number;
    longitude: number;
    score?: number | undefined;
    expected_duration?: string | undefined;
    joined_people?: string[] | undefined;
    chlg_pic_url?: string | undefined;
    sponsor?: {
        type: string;
        name: string;
    } | null | undefined;
}>, "many">> | import("genkit").ToolAction<z.ZodObject<{
    challengeId: z.ZodString;
}, "strip", z.ZodTypeAny, {
    challengeId: string;
}, {
    challengeId: string;
}>, z.ZodNullable<z.ZodObject<{
    id: z.ZodString;
    title: z.ZodString;
    description: z.ZodString;
    type: z.ZodString;
    difficulty: z.ZodString;
    score: z.ZodOptional<z.ZodNumber>;
    expected_duration: z.ZodOptional<z.ZodString>;
    latitude: z.ZodNumber;
    longitude: z.ZodNumber;
    joined_people: z.ZodOptional<z.ZodArray<z.ZodString, "many">>;
    chlg_pic_url: z.ZodOptional<z.ZodString>;
    sponsor: z.ZodOptional<z.ZodNullable<z.ZodObject<{
        name: z.ZodString;
        type: z.ZodString;
    }, "strip", z.ZodTypeAny, {
        type: string;
        name: string;
    }, {
        type: string;
        name: string;
    }>>>;
}, "strip", z.ZodTypeAny, {
    type: string;
    id: string;
    title: string;
    description: string;
    difficulty: string;
    latitude: number;
    longitude: number;
    score?: number | undefined;
    expected_duration?: string | undefined;
    joined_people?: string[] | undefined;
    chlg_pic_url?: string | undefined;
    sponsor?: {
        type: string;
        name: string;
    } | null | undefined;
}, {
    type: string;
    id: string;
    title: string;
    description: string;
    difficulty: string;
    latitude: number;
    longitude: number;
    score?: number | undefined;
    expected_duration?: string | undefined;
    joined_people?: string[] | undefined;
    chlg_pic_url?: string | undefined;
    sponsor?: {
        type: string;
        name: string;
    } | null | undefined;
}>>> | import("genkit").ToolAction<z.ZodObject<{
    userId: z.ZodString;
}, "strip", z.ZodTypeAny, {
    userId: string;
}, {
    userId: string;
}>, z.ZodNullable<z.ZodObject<{
    uid: z.ZodString;
    name_surname: z.ZodString;
    email: z.ZodOptional<z.ZodString>;
    cum_points: z.ZodNumber;
    joined_chlgs: z.ZodArray<z.ZodString, "many">;
    completed_chlg: z.ZodArray<z.ZodString, "many">;
    user_pic_url: z.ZodOptional<z.ZodString>;
}, "strip", z.ZodTypeAny, {
    uid: string;
    name_surname: string;
    cum_points: number;
    joined_chlgs: string[];
    completed_chlg: string[];
    email?: string | undefined;
    user_pic_url?: string | undefined;
}, {
    uid: string;
    name_surname: string;
    cum_points: number;
    joined_chlgs: string[];
    completed_chlg: string[];
    email?: string | undefined;
    user_pic_url?: string | undefined;
}>>> | import("genkit").ToolAction<z.ZodObject<{}, "strip", z.ZodTypeAny, {}, {}>, z.ZodArray<z.ZodObject<{
    id: z.ZodString;
    description: z.ZodString;
    multiplier: z.ZodNumber;
    target_category: z.ZodString;
    start_date: z.ZodString;
    end_date: z.ZodString;
}, "strip", z.ZodTypeAny, {
    id: string;
    description: string;
    multiplier: number;
    target_category: string;
    start_date: string;
    end_date: string;
}, {
    id: string;
    description: string;
    multiplier: number;
    target_category: string;
    start_date: string;
    end_date: string;
}>, "many">> | import("genkit").ToolAction<z.ZodObject<{
    challengeId: z.ZodString;
}, "strip", z.ZodTypeAny, {
    challengeId: string;
}, {
    challengeId: string;
}>, z.ZodObject<{
    challengeId: z.ZodString;
    participantIds: z.ZodArray<z.ZodString, "many">;
    count: z.ZodNumber;
}, "strip", z.ZodTypeAny, {
    count: number;
    challengeId: string;
    participantIds: string[];
}, {
    count: number;
    challengeId: string;
    participantIds: string[];
}>> | import("genkit").ToolAction<z.ZodObject<{
    latitude: z.ZodNumber;
    longitude: z.ZodNumber;
    radiusMeters: z.ZodOptional<z.ZodNumber>;
}, "strip", z.ZodTypeAny, {
    latitude: number;
    longitude: number;
    radiusMeters?: number | undefined;
}, {
    latitude: number;
    longitude: number;
    radiusMeters?: number | undefined;
}>, z.ZodArray<z.ZodObject<{
    id: z.ZodString;
    title: z.ZodString;
    description: z.ZodString;
    type: z.ZodString;
    difficulty: z.ZodString;
    score: z.ZodOptional<z.ZodNumber>;
    expected_duration: z.ZodOptional<z.ZodString>;
    latitude: z.ZodNumber;
    longitude: z.ZodNumber;
    joined_people: z.ZodOptional<z.ZodArray<z.ZodString, "many">>;
    chlg_pic_url: z.ZodOptional<z.ZodString>;
    sponsor: z.ZodOptional<z.ZodNullable<z.ZodObject<{
        name: z.ZodString;
        type: z.ZodString;
    }, "strip", z.ZodTypeAny, {
        type: string;
        name: string;
    }, {
        type: string;
        name: string;
    }>>>;
} & {
    distanceMeters: z.ZodNumber;
}, "strip", z.ZodTypeAny, {
    type: string;
    id: string;
    title: string;
    description: string;
    difficulty: string;
    latitude: number;
    longitude: number;
    distanceMeters: number;
    score?: number | undefined;
    expected_duration?: string | undefined;
    joined_people?: string[] | undefined;
    chlg_pic_url?: string | undefined;
    sponsor?: {
        type: string;
        name: string;
    } | null | undefined;
}, {
    type: string;
    id: string;
    title: string;
    description: string;
    difficulty: string;
    latitude: number;
    longitude: number;
    distanceMeters: number;
    score?: number | undefined;
    expected_duration?: string | undefined;
    joined_people?: string[] | undefined;
    chlg_pic_url?: string | undefined;
    sponsor?: {
        type: string;
        name: string;
    } | null | undefined;
}>, "many">>)[];
