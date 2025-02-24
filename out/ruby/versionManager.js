"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.VersionManager = void 0;
const errors_1 = require("../errors");
/**
 * Abstract base class for Ruby version managers
 */
class VersionManager {
    constructor(outputChannel, workspaceFolder, bundleUri) {
        this.outputChannel = outputChannel;
        this.workspaceFolder = workspaceFolder;
        this.bundleUri = bundleUri;
    }
    /**
     * Run the environment activation script and parse its output
     */
    runEnvActivationScript(scriptPath) {
        return __awaiter(this, void 0, void 0, function* () {
            const { spawn } = require('child_process');
            const childProcess = spawn(scriptPath, [], {
                cwd: this.workspaceFolder.uri.fsPath,
                env: Object.assign(Object.assign({}, process.env), { RUBYOPT: "-E UTF-8:UTF-8" })
            });
            return new Promise((resolve, reject) => {
                let stdout = '';
                let stderr = '';
                childProcess.stdout.on('data', (data) => {
                    stdout += data.toString();
                });
                childProcess.stderr.on('data', (data) => {
                    stderr += data.toString();
                });
                childProcess.on('close', (code) => {
                    if (code !== 0) {
                        reject(new errors_1.VersionManagerError('Failed to activate Ruby environment', {
                            stderr,
                            code
                        }));
                        return;
                    }
                    try {
                        const result = this.parseActivationOutput(stdout);
                        resolve(result);
                    }
                    catch (error) {
                        reject(error);
                    }
                });
            });
        });
    }
    /**
     * Parse the output from the activation script
     */
    parseActivationOutput(output) {
        const lines = output.trim().split('\n');
        const env = {
            PATH: process.env.PATH || ''
        };
        let version = '';
        let gemPath = [];
        let yjit = false;
        for (const line of lines) {
            const [key, value] = line.split('=');
            if (!key || !value)
                continue;
            if (key === 'RUBY_VERSION') {
                version = value;
            }
            else if (key === 'GEM_PATH') {
                gemPath = value.split(':');
            }
            else if (key === 'RUBY_YJIT_ENABLE') {
                yjit = value === '1';
            }
            else {
                env[key] = value;
            }
        }
        if (!version) {
            throw new errors_1.VersionManagerError('Ruby version not found in activation output', { output });
        }
        return { env, version, gemPath, yjit };
    }
    /**
     * Log a message to the output channel
     */
    log(message) {
        this.outputChannel.appendLine(message);
    }
}
exports.VersionManager = VersionManager;
//# sourceMappingURL=versionManager.js.map