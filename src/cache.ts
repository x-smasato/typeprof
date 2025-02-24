import { RubyEnvironment, loadRubyEnvironment } from './environment';
import { RubyEnvironmentError } from './errors';

export class EnvironmentCache {
    private static instance: EnvironmentCache;
    private cache: Map<string, RubyEnvironment> = new Map();
    private lastUpdate: Map<string, number> = new Map();
    private readonly cacheTimeout = 5 * 60 * 1000; // 5 minutes
    
    private constructor() {}
    
    static getInstance(): EnvironmentCache {
        if (!EnvironmentCache.instance) {
            EnvironmentCache.instance = new EnvironmentCache();
        }
        return EnvironmentCache.instance;
    }
    
    get(cwd: string): RubyEnvironment {
        try {
            const now = Date.now();
            const lastUpdate = this.lastUpdate.get(cwd) || 0;

            // Check if cache is expired
            if (!this.cache.has(cwd) || (now - lastUpdate) > this.cacheTimeout) {
                const env = loadRubyEnvironment(cwd);
                this.cache.set(cwd, env);
                this.lastUpdate.set(cwd, now);
            }

            const cachedEnv = this.cache.get(cwd);
            if (!cachedEnv) {
                throw new RubyEnvironmentError('Failed to retrieve environment from cache');
            }

            return cachedEnv;
        } catch (error) {
            if (error instanceof RubyEnvironmentError) {
                throw error;
            }
            throw new RubyEnvironmentError('Cache operation failed', { cause: error });
        }
    }
    
    clear(cwd: string): void {
        this.cache.delete(cwd);
        this.lastUpdate.delete(cwd);
    }

    clearAll(): void {
        this.cache.clear();
        this.lastUpdate.clear();
    }
}

export const environmentCache = EnvironmentCache.getInstance();
