import * as vscode from 'vscode';
import * as path from 'path';
import { existsSync } from 'fs';
import { VersionManager, ActivationResult } from './versionManager';

export class Rvm extends VersionManager {
    async activate(): Promise<ActivationResult> {
        const rvmPath = await this.findRvmInstallation();
        if (!rvmPath) {
            throw new Error('RVM installation not found');
        }

        const scriptPath = path.join(rvmPath, 'bin', 'rvm-auto-ruby');
        return this.runEnvActivationScript(scriptPath);
    }

    private async findRvmInstallation(): Promise<string | undefined> {
        // Check common RVM installation paths
        const possiblePaths = [
            process.env.rvm_path,
            path.join(process.env.HOME || '', '.rvm'),
            '/usr/local/rvm',
        ];

        for (const possiblePath of possiblePaths) {
            if (possiblePath && existsSync(path.join(possiblePath, 'bin', 'rvm-auto-ruby'))) {
                return possiblePath;
            }
        }

        return undefined;
    }
}
