"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.environmentCache = exports.EnvironmentCache = void 0;
const environment_1 = require("./environment");
const errors_1 = require("./errors");
class EnvironmentCache {
    constructor() {
        this.cache = new Map();
        this.lastUpdate = new Map();
        this.cacheTimeout = 5 * 60 * 1000; // 5 minutes
    }
    static getInstance() {
        if (!EnvironmentCache.instance) {
            EnvironmentCache.instance = new EnvironmentCache();
        }
        return EnvironmentCache.instance;
    }
    get(cwd) {
        try {
            const now = Date.now();
            const lastUpdate = this.lastUpdate.get(cwd) || 0;
            // Check if cache is expired
            if (!this.cache.has(cwd) || (now - lastUpdate) > this.cacheTimeout) {
                const env = (0, environment_1.loadRubyEnvironment)(cwd);
                this.cache.set(cwd, env);
                this.lastUpdate.set(cwd, now);
            }
            const cachedEnv = this.cache.get(cwd);
            if (!cachedEnv) {
                throw new errors_1.RubyEnvironmentError('Failed to retrieve environment from cache');
            }
            return cachedEnv;
        }
        catch (error) {
            if (error instanceof errors_1.RubyEnvironmentError) {
                throw error;
            }
            throw new errors_1.RubyEnvironmentError('Cache operation failed', { cause: error });
        }
    }
    clear(cwd) {
        this.cache.delete(cwd);
        this.lastUpdate.delete(cwd);
    }
    clearAll() {
        this.cache.clear();
        this.lastUpdate.clear();
    }
}
exports.EnvironmentCache = EnvironmentCache;
exports.environmentCache = EnvironmentCache.getInstance();
//# sourceMappingURL=cache.js.map