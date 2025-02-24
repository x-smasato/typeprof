/**
 * Custom error class for Ruby environment related errors
 */
export class RubyEnvironmentError extends Error {
    constructor(message: string, public readonly details?: any) {
        super(message);
        this.name = 'RubyEnvironmentError';
    }
}

/**
 * Custom error class for version manager related errors
 */
export class VersionManagerError extends RubyEnvironmentError {
    constructor(message: string, details?: any) {
        super(message, details);
        this.name = 'VersionManagerError';
    }
}

/**
 * Custom error class for shell execution related errors
 */
export class ShellExecutionError extends RubyEnvironmentError {
    constructor(message: string, details?: any) {
        super(message, details);
        this.name = 'ShellExecutionError';
    }
}
