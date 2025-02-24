import spawn from 'cross-spawn';
import { workspace } from 'vscode';
import { existsSync } from 'fs';
import { RubyEnvironmentError, ShellExecutionError } from './errors';

// 環境変数のホワイトリスト
const RUBY_ENVIRONMENT_VARIABLES = [
    'PATH',
    'GEM_PATH',
    'GEM_HOME',
    'RUBY_VERSION',
    'RBENV_VERSION',
    'RBENV_ROOT',
    'CHRUBY_VERSION',
    'CHRUBY_ROOT',
    'RVM_PATH',
    'RVM_ROOT',
    'BUNDLE_PATH',
    'BUNDLE_GEMFILE',
    'RUBYOPT'
];

/**
 * Type-safe interface for Ruby environment variables
 */
export interface RubyEnvironment {
    // Required base type for indexing
    [key: string]: string | undefined;

    // Required environment variables
    PATH: string;

    // Ruby core environment variables
    RUBY_VERSION?: string;
    RUBY_ENGINE?: string;
    RUBY_ENGINE_VERSION?: string;
    RUBY_YJIT_ENABLE?: string;
    RUBYOPT?: string;
    RUBYLIB?: string;

    // Gem environment variables
    GEM_HOME?: string;
    GEM_PATH?: string;
    GEM_ROOT?: string;
    BUNDLE_PATH?: string;
    BUNDLE_GEMFILE?: string;
    BUNDLE_BIN?: string;

    // rbenv specific variables
    RBENV_VERSION?: string;
    RBENV_ROOT?: string;
    RBENV_DIR?: string;
    RBENV_HOOK_PATH?: string;

    // RVM specific variables
    RVM_PATH?: string;
    RVM_ROOT?: string;
    RVM_VERSION?: string;
    RVM_RUBY_STRING?: string;
    RVM_GEM_SET_NAME?: string;

    // chruby specific variables
    CHRUBY_VERSION?: string;
    CHRUBY_ROOT?: string;
    RUBY_ROOT?: string;
    RUBY_HOME?: string;

    // Additional environment variables
    LANG?: string;
    LC_ALL?: string;
    SHELL?: string;
}

/**
 * Platform-specific shell configuration
 */
export interface ShellConfig {
    shell: string;
    args: string[];
}

/**
 * Get shell configuration based on platform and VSCode settings
 */
export function getShellConfig(): ShellConfig {
    // Determine platform
    const os = process.platform === 'win32' ? 'windows' : 
               process.platform === 'darwin' ? 'osx' : 'linux';
    
    // Get VSCode terminal configuration
    const config = workspace.getConfiguration('terminal.integrated');
    
    // Try to get shell from VSCode settings
    let shell = config.get<string>(`automationShell.${os}`) ||
                config.get<string>('automationShell') ||
                process.env.SHELL;
    
    // Platform-specific fallbacks
    if (!shell) {
        if (os === 'windows') {
            shell = process.env.COMSPEC || 'cmd.exe';
        } else {
            // Try common Unix shells in order
            const commonShells = ['/bin/bash', '/usr/bin/bash', '/bin/sh'];
            shell = commonShells.find(s => existsSync(s)) || '/bin/sh';
        }
    }
    
    // Get shell arguments
    const args = config.get<string[]>(`automationShellArgs.${os}`) ||
                config.get<string[]>('automationShellArgs') ||
                [];
    
    // Add default arguments for specific shells
    if (shell.endsWith('bash')) {
        args.push('--noprofile', '--norc');
    } else if (shell.endsWith('zsh')) {
        args.push('--no-rcs', '--no-globalrcs');
    }
    
    return { shell, args };
}

// 環境変数の処理
import { sanitizeEnvironment } from './common';

function processEnvironment(env: { [key: string]: string }): RubyEnvironment {
    // First sanitize the environment
    const sanitizedEnv = sanitizeEnvironment(env);
    
    // Then filter for Ruby-specific variables
    return Object.entries(sanitizedEnv)
        .filter(([key]) => RUBY_ENVIRONMENT_VARIABLES.includes(key))
        .reduce<RubyEnvironment>((acc, [key, value]) => {
            if (typeof value === 'string') {
                acc[key] = value;
            }
            return acc;
        }, { PATH: sanitizedEnv.PATH });
}

// 環境の読み込み
export function loadRubyEnvironment(cwd: string): RubyEnvironment {
    try {
        const { shell, args } = getShellConfig();
        const result = spawn.sync(shell, [...args, '-c', 'env'], { cwd });
        
        if (result.error) {
            throw new ShellExecutionError('Failed to execute shell command', {
                error: result.error,
                shell,
                args
            });
        }

        if (result.status !== 0) {
            throw new ShellExecutionError('Shell command failed', {
                status: result.status,
                stderr: result.stderr?.toString(),
                shell,
                args
            });
        }

        if (!result.stdout) {
            throw new RubyEnvironmentError('No environment variables found');
        }

        const env = Object.fromEntries(
            result.stdout.toString()
                .split('\n')
                .filter(Boolean)
                .map((line: string) => line.split('=', 2))
        );

        return processEnvironment(env);
    } catch (error) {
        if (error instanceof RubyEnvironmentError) {
            throw error;
        }
        throw new RubyEnvironmentError('Failed to load Ruby environment', { cause: error });
    }
}
