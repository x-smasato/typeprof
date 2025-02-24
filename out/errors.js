"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ShellExecutionError = exports.VersionManagerError = exports.RubyEnvironmentError = void 0;
/**
 * Custom error class for Ruby environment related errors
 */
class RubyEnvironmentError extends Error {
    constructor(message, details) {
        super(message);
        this.details = details;
        this.name = 'RubyEnvironmentError';
    }
}
exports.RubyEnvironmentError = RubyEnvironmentError;
/**
 * Custom error class for version manager related errors
 */
class VersionManagerError extends RubyEnvironmentError {
    constructor(message, details) {
        super(message, details);
        this.name = 'VersionManagerError';
    }
}
exports.VersionManagerError = VersionManagerError;
/**
 * Custom error class for shell execution related errors
 */
class ShellExecutionError extends RubyEnvironmentError {
    constructor(message, details) {
        super(message, details);
        this.name = 'ShellExecutionError';
    }
}
exports.ShellExecutionError = ShellExecutionError;
//# sourceMappingURL=errors.js.map