#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const os = require('os');

const CONTEXT_LIMIT = 200000;
const AUTO_COMPACT_LIMIT = Math.floor(CONTEXT_LIMIT * 0.8);
const COLOR_THRESHOLDS = { WARNING: 50, DANGER: 70 };

const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  red: '\x1b[31m',
  cyan: '\x1b[36m',
  dim: '\x1b[2m'
};

const encodeProjectPath = projectPath => '-' + projectPath.replace(/^\//, '').replace(/[/.]/g, '-');

const getSessionTranscriptPath = () => {
  const claudeDir = path.join(os.homedir(), '.config', 'claude');
  const currentProject = encodeProjectPath(process.cwd());
  const projectDir = path.join(claudeDir, 'projects', currentProject);

  try {
    const files = fs.readdirSync(projectDir);
    const transcriptFiles = files.filter(f => f.endsWith('.jsonl'));

    if (transcriptFiles.length === 0) return null;

    const latestFile = transcriptFiles
      .map(f => {
        const fullPath = path.join(projectDir, f);
        return {
          name: f,
          path: fullPath,
          mtime: fs.statSync(fullPath).mtime
        };
      })
      .sort((a, b) => b.mtime - a.mtime)[0];

    return latestFile.path;
  } catch {
    return null;
  }
};

const calculateTokens = text => Math.floor(text.length / 4);

const parseJsonlFile = (filePath, processor) => {
  try {
    return processor(fs.readFileSync(filePath, 'utf8').trim().split('\n').filter(line => line.trim()));
  } catch {
    return null;
  }
};

const getSessionInfo = filePath =>
  parseJsonlFile(filePath, (lines) => {
    const parseJsonLine = line => { try { return JSON.parse(line); } catch { return null; } };
    const extractContent = content =>
      typeof content === 'string' ? content :
        Array.isArray(content) ? content.map(item => (item.text ?? '') + (item.thinking ?? '')).join('') : '';

    const parsed = lines.map(parseJsonLine).filter(Boolean);
    const modelName = [...parsed].reverse().find(json => json.type === 'assistant')?.message?.model;
    const totalText = parsed.map(json => extractContent(json.message?.content)).join('');

    return {
      totalTokens: calculateTokens(totalText),
      modelName
    };
  }) || { totalTokens: 0, modelName: null };

const getUsageColor = p => [
  [p < COLOR_THRESHOLDS.WARNING, colors.green],
  [p < COLOR_THRESHOLDS.DANGER, colors.yellow],
  [true, colors.red]
].find(([condition]) => condition)[1];
const formatModelName = modelName => modelName?.match(/^claude-([^-]+-\d+)/)?.[1] ?? modelName ?? 'claude';
const formatTokenCount = count => count >= 1000 ? `${(count / 1000).toFixed(1)}K` : count.toString();

const main = () => {
  try {
    const transcriptPath = getSessionTranscriptPath();

    if (!transcriptPath || !fs.existsSync(transcriptPath)) {
      console.log(`${colors.dim}No active session${colors.reset}`);
      return;
    }

    const sessionInfo = getSessionInfo(transcriptPath);
    const percentage = Math.min((sessionInfo.totalTokens / AUTO_COMPACT_LIMIT) * 100, 100);
    const usageColor = getUsageColor(percentage);

    console.log([
      `${colors.cyan}${formatModelName(sessionInfo.modelName)}${colors.reset}`,
      `📁 ${colors.dim}${path.basename(process.cwd())}${colors.reset}`,
      `🔥 ${usageColor}${formatTokenCount(sessionInfo.totalTokens)}/${formatTokenCount(AUTO_COMPACT_LIMIT)} (${usageColor}${percentage.toFixed(1)}%)${colors.reset}`,
      ``
    ].join(' │ '));

  } catch (error) {
    console.log(`${colors.red}Error: ${error.message}${colors.reset}`);
  }
};

main();
