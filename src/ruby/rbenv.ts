import * as vscode from 'vscode';
import * as path from 'path';
import { existsSync } from 'fs';
import { VersionManager, ActivationResult } from './versionManager';

export class Rbenv extends VersionManager {
    async activate(): Promise<ActivationResult> {
        const rbenvPath = await this.findRbenvInstallation();
        if (!rbenvPath) {
            throw new Error('rbenv installation not found');
        }

        const scriptPath = path.join(rbenvPath, 'bin', 'rbenv');
        return this.runEnvActivationScript(scriptPath);
    }

    private async findRbenvInstallation(): Promise<string | undefined> {
        // Check common rbenv installation paths
        const possiblePaths = [
            process.env.RBENV_ROOT,
            path.join(process.env.HOME || '', '.rbenv'),
            '/usr/local/rbenv',
            '/opt/rbenv',
        ];

        for (const possiblePath of possiblePaths) {
            if (possiblePath && existsSync(path.join(possiblePath, 'bin', 'rbenv'))) {
                return possiblePath;
            }
        }

        // Try to find rbenv in PATH
        const pathDirs = (process.env.PATH || '').split(path.delimiter);
        for (const dir of pathDirs) {
            const rbenvPath = path.join(dir, 'rbenv');
            if (existsSync(rbenvPath)) {
                return path.dirname(path.dirname(rbenvPath));
            }
        }

        return undefined;
    }
}
