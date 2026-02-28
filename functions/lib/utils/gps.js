"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.GPS_THRESHOLD_METERS = void 0;
exports.haversineDistance = haversineDistance;
const EARTH_RADIUS_METERS = 6_371_000;
/** Haversine distance in meters between two lat/lng points. */
function haversineDistance(lat1, lng1, lat2, lng2) {
    const toRad = (deg) => (deg * Math.PI) / 180;
    const dLat = toRad(lat2 - lat1);
    const dLng = toRad(lng2 - lng1);
    const a = Math.sin(dLat / 2) ** 2 +
        Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
    return EARTH_RADIUS_METERS * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}
/** Default GPS proximity threshold for challenge verification (meters). */
exports.GPS_THRESHOLD_METERS = 500;
//# sourceMappingURL=gps.js.map