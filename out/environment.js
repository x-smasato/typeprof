"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.getShellConfig = getShellConfig;
exports.loadRubyEnvironment = loadRubyEnvironment;
const cross_spawn_1 = __importDefault(require("cross-spawn"));
const vscode_1 = require("vscode");
const fs_1 = require("fs");
const errors_1 = require("./errors");
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
 * Get shell configuration based on platform and VSCode settings
 */
function getShellConfig() {
    // Determine platform
    const os = process.platform === 'win32' ? 'windows' :
        process.platform === 'darwin' ? 'osx' : 'linux';
    // Get VSCode terminal configuration
    const config = vscode_1.workspace.getConfiguration('terminal.integrated');
    // Try to get shell from VSCode settings
    let shell = config.get(`automationShell.${os}`) ||
        config.get('automationShell') ||
        process.env.SHELL;
    // Platform-specific fallbacks
    if (!shell) {
        if (os === 'windows') {
            shell = process.env.COMSPEC || 'cmd.exe';
        }
        else {
            // Try common Unix shells in order
            const commonShells = ['/bin/bash', '/usr/bin/bash', '/bin/sh'];
            shell = commonShells.find(s => (0, fs_1.existsSync)(s)) || '/bin/sh';
        }
    }
    // Get shell arguments
    const args = config.get(`automationShellArgs.${os}`) ||
        config.get('automationShellArgs') ||
        [];
    // Add default arguments for specific shells
    if (shell.endsWith('bash')) {
        args.push('--noprofile', '--norc');
    }
    else if (shell.endsWith('zsh')) {
        args.push('--no-rcs', '--no-globalrcs');
    }
    return { shell, args };
}
// 環境変数の処理
const encoding_1 = require("./encoding");
function processEnvironment(env) {
    // First sanitize the environment
    const sanitizedEnv = (0, encoding_1.sanitizeEnvironment)(env);
    // Then filter for Ruby-specific variables
    return Object.entries(sanitizedEnv)
        .filter(([key]) => RUBY_ENVIRONMENT_VARIABLES.includes(key))
        .reduce((acc, [key, value]) => {
        if (typeof value === 'string') {
            acc[key] = value;
        }
        return acc;
    }, { PATH: sanitizedEnv.PATH });
}
// 環境の読み込み
function loadRubyEnvironment(cwd) {
    var _a;
    try {
        const { shell, args } = getShellConfig();
        const result = cross_spawn_1.default.sync(shell, [...args, '-c', 'env'], { cwd });
        if (result.error) {
            throw new errors_1.ShellExecutionError('Failed to execute shell command', {
                error: result.error,
                shell,
                args
            });
        }
        if (result.status !== 0) {
            throw new errors_1.ShellExecutionError('Shell command failed', {
                status: result.status,
                stderr: (_a = result.stderr) === null || _a === void 0 ? void 0 : _a.toString(),
                shell,
                args
            });
        }
        if (!result.stdout) {
            throw new errors_1.RubyEnvironmentError('No environment variables found');
        }
        const env = Object.fromEntries(result.stdout.toString()
            .split('\n')
            .filter(Boolean)
            .map((line) => line.split('=', 2)));
        return processEnvironment(env);
    }
    catch (error) {
        if (error instanceof errors_1.RubyEnvironmentError) {
            throw error;
        }
        throw new errors_1.RubyEnvironmentError('Failed to load Ruby environment', { cause: error });
    }
}
//# sourceMappingURL=environment.js.map