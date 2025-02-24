import * as vscode from 'vscode';
import { VersionManagerError } from '../errors';
import { RubyEnvironment } from '../environment';

export interface ActivationResult {
    env: RubyEnvironment;
    version: string;
    gemPath: string[];
    yjit: boolean;
}

/**
 * Abstract base class for Ruby version managers
 */
export abstract class VersionManager {
    protected readonly outputChannel: vscode.OutputChannel;
    protected readonly workspaceFolder: vscode.WorkspaceFolder;
    protected readonly bundleUri: vscode.Uri;

    constructor(
        outputChannel: vscode.OutputChannel,
        workspaceFolder: vscode.WorkspaceFolder,
        bundleUri: vscode.Uri
    ) {
        this.outputChannel = outputChannel;
        this.workspaceFolder = workspaceFolder;
        this.bundleUri = bundleUri;
    }

    /**
     * Activate the Ruby environment for this version manager
     */
    abstract activate(): Promise<ActivationResult>;

    /**
     * Run the environment activation script and parse its output
     */
    protected async runEnvActivationScript(scriptPath: string): Promise<ActivationResult> {
        const { spawn } = require('child_process');
        const childProcess = spawn(scriptPath, [], {
            cwd: this.workspaceFolder.uri.fsPath,
            env: { ...process.env, RUBYOPT: "-E UTF-8:UTF-8" }
        });

        return new Promise((resolve, reject) => {
            let stdout = '';
            let stderr = '';

            childProcess.stdout.on('data', (data: Buffer) => {
                stdout += data.toString();
            });

            childProcess.stderr.on('data', (data: Buffer) => {
                stderr += data.toString();
            });

            childProcess.on('close', (code: number) => {
                if (code !== 0) {
                    reject(new VersionManagerError('Failed to activate Ruby environment', {
                        stderr,
                        code
                    }));
                    return;
                }

                try {
                    const result = this.parseActivationOutput(stdout);
                    resolve(result);
                } catch (error) {
                    reject(error);
                }
            });
        });
    }

    /**
     * Parse the output from the activation script
     */
    protected parseActivationOutput(output: string): ActivationResult {
        const lines = output.trim().split('\n');
        const env: RubyEnvironment = {
            PATH: process.env.PATH || ''
        };
        let version = '';
        let gemPath: string[] = [];
        let yjit = false;

        for (const line of lines) {
            const [key, value] = line.split('=');
            if (!key || !value) continue;

            if (key === 'RUBY_VERSION') {
                version = value;
            } else if (key === 'GEM_PATH') {
                gemPath = value.split(':');
            } else if (key === 'RUBY_YJIT_ENABLE') {
                yjit = value === '1';
            } else {
                env[key] = value;
            }
        }

        if (!version) {
            throw new VersionManagerError('Ruby version not found in activation output', { output });
        }

        return { env, version, gemPath, yjit };
    }

    /**
     * Log a message to the output channel
     */
    protected log(message: string): void {
        this.outputChannel.appendLine(message);
    }
}
