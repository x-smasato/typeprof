"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
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
exports.activate = activate;
exports.deactivate = deactivate;
const vscode = __importStar(require("vscode"));
const child_process = __importStar(require("child_process"));
const fs_1 = require("fs");
const environment_1 = require("./environment");
const cache_1 = require("./cache");
const environmentCache = cache_1.EnvironmentCache.getInstance();
const CONFIGURATION_ROOT_SECTION = 'typeprof';
function executeTypeProf(folder, arg) {
    const configuration = vscode.workspace.getConfiguration(CONFIGURATION_ROOT_SECTION);
    const customServerPath = configuration.get('server.path');
    const cwd = folder.uri.fsPath;
    // コマンドの構築
    let cmd;
    if ((0, fs_1.existsSync)(`${cwd}/bin/typeprof`)) {
        cmd = './bin/typeprof';
    }
    else if (customServerPath) {
        cmd = customServerPath;
    }
    else if ((0, fs_1.existsSync)(`${cwd}/Gemfile`)) {
        cmd = 'bundle exec typeprof';
    }
    else {
        cmd = 'typeprof';
    }
    cmd = cmd + ' ' + arg;
    // シェル設定とRuby環境の取得
    const { shell, args: shellArgs } = (0, environment_1.getShellConfig)();
    const env = environmentCache.get(cwd);
    // TypeProfの実行
    return child_process.spawn(shell, [...shellArgs, '-c', cmd], {
        cwd,
        env: Object.assign(Object.assign({}, process.env), env)
    });
}
let typeProfProcess;
function activate(context) {
    const disposable = vscode.commands.registerCommand('typeprof.run', () => __awaiter(this, void 0, void 0, function* () {
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
    }));
    context.subscriptions.push(disposable);
}
function deactivate() {
    if (typeProfProcess) {
        typeProfProcess.kill();
        typeProfProcess = undefined;
    }
}
//# sourceMappingURL=extension.js.map