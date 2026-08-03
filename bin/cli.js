#!/usr/bin/env node

const { spawn } = require('child_process');
const path = require('path');
const os = require('os');

const args = process.argv.slice(2);
const isWindows = os.platform() === 'win32';

const scriptName = isWindows ? 'async_agents.ps1' : 'async_agents.sh';
const scriptPath = path.join(__dirname, '..', scriptName);

let command, cmdArgs;

if (isWindows) {
  command = 'powershell.exe';
  cmdArgs = ['-ExecutionPolicy', 'Bypass', '-File', scriptPath, ...args];
} else {
  command = 'bash';
  cmdArgs = [scriptPath, ...args];
}

const child = spawn(command, cmdArgs, { stdio: 'inherit' });

child.on('exit', (code) => {
  process.exit(code || 0);
});
