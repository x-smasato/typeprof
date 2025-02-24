import * as vscode from 'vscode';
import * as child_process from 'child_process';
import { existsSync } from 'fs';
import { getShellConfig, RubyEnvironment } from './environment';
import { EnvironmentCache } from './cache';

const environmentCache = EnvironmentCache.getInstance();

// 型定義の追加
declare module 'child_process' {
    interface SpawnOptions {
        env?: NodeJS.ProcessEnv | RubyEnvironment;
    }
}

const CONFIGURATION_ROOT_SECTION = 'typeprof';

function executeTypeProf(folder: vscode.WorkspaceFolder, arg: string): child_process.ChildProcessWithoutNullStreams {
    const configuration = vscode.workspace.getConfiguration(CONFIGURATION_ROOT_SECTION);
    const customServerPath = configuration.get<string | null>('server.path');
    const cwd = folder.uri.fsPath;
    
    // コマンドの構築
    let cmd: string;
    if (existsSync(`${cwd}/bin/typeprof`)) {
        cmd = './bin/typeprof';
    } else if (customServerPath) {
        cmd = customServerPath;
    } else if (existsSync(`${cwd}/Gemfile`)) {
        cmd = 'bundle exec typeprof';
    } else {
        cmd = 'typeprof';
    }
    cmd = cmd + ' ' + arg;

    // シェル設定とRuby環境の取得
    const { shell, args: shellArgs } = getShellConfig();
    const env = environmentCache.get(cwd);
    
    // TypeProfの実行
    return child_process.spawn(shell, [...shellArgs, '-c', cmd], { 
        cwd,
        env: { ...process.env, ...env }
    });
}

let typeProfProcess: child_process.ChildProcessWithoutNullStreams | undefined;

export function activate(context: vscode.ExtensionContext) {
    const disposable = vscode.commands.registerCommand('typeprof.run', async () => {
        const editor = vscode.window.activeTextEditor;
        if (!editor) {
            vscode.window.showErrorMessage('No active editor found');
            return;
        }

        const document = editor.document;
        if (document.languageId !== 'ruby') {
            vscode.window.showErrorMessage('Not a Ruby file');
            return;
        }

        const workspaceFolder = vscode.workspace.getWorkspaceFolder(document.uri);
        if (!workspaceFolder) {
            vscode.window.showErrorMessage('File not in workspace');
            return;
        }

        // 既存のプロセスを終了
        if (typeProfProcess) {
            typeProfProcess.kill();
        }

        // 新しいプロセスを開始
        typeProfProcess = executeTypeProf(workspaceFolder, document.fileName);

        typeProfProcess.stdout.on('data', (data) => {
            console.log(`TypeProf output: ${data}`);
        });

        typeProfProcess.stderr.on('data', (data) => {
            console.error(`TypeProf error: ${data}`);
        });

        typeProfProcess.on('close', (code) => {
            if (code !== 0) {
                vscode.window.showErrorMessage(`TypeProf process exited with code ${code}`);
            }
            typeProfProcess = undefined;
        });
    });

    context.subscriptions.push(disposable);
}

export function deactivate() {
    if (typeProfProcess) {
        typeProfProcess.kill();
        typeProfProcess = undefined;
    }
}
