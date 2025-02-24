import { RubyEnvironment } from './environment';

/**
 * Sanitizes environment variables by ensuring UTF-8 encoding and proper typing
 */
export function sanitizeEnvironment(env: Record<string, string>): RubyEnvironment {
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
        } catch (error) {
            // Skip invalid encodings
            console.warn(`Skipping invalid encoding for ${key}`);
        }
        
        return acc;
    }, {} as RubyEnvironment);

    // Ensure PATH is always present
    sanitized.PATH = sanitized.PATH || process.env.PATH || '';

    return sanitized;
}

/**
 * Checks if a string is valid UTF-8
 */
export function isValidUtf8(str: string): boolean {
    try {
        const buffer = Buffer.from(str);
        return buffer.toString('utf8') === str;
    } catch {
        return false;
    }
}
