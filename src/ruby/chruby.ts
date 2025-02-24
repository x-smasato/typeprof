import * as vscode from 'vscode';
import * as path from 'path';
import { existsSync } from 'fs';
import { VersionManager, ActivationResult } from './versionManager';

export class Chruby extends VersionManager {
    async activate(): Promise<ActivationResult> {
        const chrubyPath = await this.findChrubyInstallation();
        if (!chrubyPath) {
            throw new Error('chruby installation not found');
        }

        const scriptPath = path.join(chrubyPath, 'bin', 'chruby-exec');
        return this.runEnvActivationScript(scriptPath);
    }

    private async findChrubyInstallation(): Promise<string | undefined> {
        // Check common chruby installation paths
        const possiblePaths = [
            '/usr/local/share/chruby',
            '/usr/share/chruby',
            path.join(process.env.HOME || '', '.chruby'),
        ];

        for (const possiblePath of possiblePaths) {
            if (possiblePath && existsSync(path.join(possiblePath, 'bin', 'chruby-exec'))) {
                return possiblePath;
            }
        }

        return undefined;
    }
}
