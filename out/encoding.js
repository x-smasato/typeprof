"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.sanitizeEnvironment = sanitizeEnvironment;
exports.isValidUtf8 = isValidUtf8;
/**
 * Sanitizes environment variables by ensuring UTF-8 encoding and proper typing
 */
function sanitizeEnvironment(env) {
    const sanitized = Object.entries(env).reduce((acc, [key, value]) => {
        // Skip if value is undefined
        if (value === undefined) {
            return acc;
        }
        try {
            // Verify UTF-8 encoding
            const buffer = Buffer.from(value);
            const decoded = buffer.toString('utf8');
            // Only include if the value is valid UTF-8
            if (decoded === value) {
                acc[key] = value;
            }
        }
        catch (error) {
            // Skip invalid encodings
            console.warn(`Skipping invalid encoding for ${key}`);
        }
        return acc;
    }, {});
    // Ensure PATH is always present
    sanitized.PATH = sanitized.PATH || process.env.PATH || '';
    return sanitized;
}
/**
 * Checks if a string is valid UTF-8
 */
function isValidUtf8(str) {
    try {
        const buffer = Buffer.from(str);
        return buffer.toString('utf8') === str;
    }
    catch (_a) {
        return false;
    }
}
//# sourceMappingURL=encoding.js.map