#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const os = require('os');

const CONTEXT_LIMIT = 200000;
const AUTO_COMPACT_RATIO = 0.8;
const COLOR_THRESHOLDS = { WARNING: 50, DANGER: 70 };

const loadPricing = () => {
  try {
    const pricingPath = path.join(__dirname, 'pricing.json');
    if (fs.existsSync(pricingPath)) {
      const pricingData = JSON.parse(fs.readFileSync(pricingPath, 'utf8'));
      return pricingData.models;
    }
  } catch {
  }
  return null;
};

const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  red: '\x1b[31m',
  cyan: '\x1b[36m',
  dim: '\x1b[2m'
};

const shouldDisplayColors = process.stdout.isTTY && !process.env.NO_COLOR;
if (!shouldDisplayColors) {
  Object.keys(colors).forEach(k => { colors[k] = ''; });
}

const convertProjectPathToDirectoryName = projectPath => '-' + projectPath.replace(/^\//, '').replace(/[/.]/g, '-');

const getSessionTranscriptPath = () => {
  const claudeDir = path.join(os.homedir(), '.config', 'claude');
  const currentProject = convertProjectPathToDirectoryName(process.cwd());
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

const normalizeModelKey = (name) => name
  ? name.replace(/-\d{8}$/, '').replace(/-latest$/, '')
  : name;

const calculateCostFromUsage = (totalUsage, modelName) => {
  const pricing = loadPricing();
  if (!pricing) return 0;

  const normalized = normalizeModelKey(modelName);
  const modelPricing = pricing[modelName] || pricing[normalized];
  if (!modelPricing) return 0;

  const cost = (
    (totalUsage.input || 0) * modelPricing.input +
    (totalUsage.output || 0) * modelPricing.output +
    (totalUsage.cacheCreate || 0) * modelPricing.cacheCreate +
    (totalUsage.cacheRead || 0) * modelPricing.cacheRead
  );

  return cost;
};

const parseJsonlFile = (filePath, processor) => {
  try {
    return processor(fs.readFileSync(filePath, 'utf8').trim().split('\n').filter(line => line.trim()));
  } catch {
    return null;
  }
};

const parseSessionMessages = (lines) => {
  const parseJsonLine = line => { try { return JSON.parse(line); } catch { return null; } };
  const parsed = lines.map(parseJsonLine).filter(Boolean);
  return parsed.filter(json => json.type === 'assistant');
};

const getSessionInfo = filePath =>
  parseJsonlFile(filePath, (lines) => {
    const assistantMessages = parseSessionMessages(lines);

    const latestAssistant = assistantMessages[assistantMessages.length - 1];
    const modelName = latestAssistant?.message?.model;

    const recentInputTokens = latestAssistant?.message?.usage?.input_tokens || 0;

    const totalUsage = assistantMessages.reduce((usage, message) => {
      const messageUsage = message.message?.usage;
      if (messageUsage) {
        usage.input += messageUsage.input_tokens || 0;
        usage.output += messageUsage.output_tokens || 0;
        usage.cacheCreate += messageUsage.cache_creation_input_tokens || 0;
        usage.cacheRead += messageUsage.cache_read_input_tokens || 0;
      }
      return usage;
    }, { input: 0, output: 0, cacheCreate: 0, cacheRead: 0 });

    const sessionCost = calculateCostFromUsage(totalUsage, modelName);

    return {
      recentInputTokens,
      modelName,
      sessionCost
    };
  }) || { recentInputTokens: 0, modelName: null, sessionCost: 0 };

const getPercentageColor = percentage => [
  [percentage < COLOR_THRESHOLDS.WARNING, colors.green],
  [percentage < COLOR_THRESHOLDS.DANGER, colors.yellow],
  [true, colors.red]
].find(([condition]) => condition)[1];
const formatModelName = modelName => modelName?.match(/^claude-([^-]+-\d+)/)?.[1] ?? modelName ?? 'claude';
const formatTokenCount = count => count >= 1000 ? `${(count / 1000).toFixed(1)}K` : count.toString();

const MODEL_CONTEXT_LIMITS = {
  'claude-3-5-sonnet': 200000,
  'claude-sonnet-4': 200000,
  'claude-opus-4': 200000
};

const main = () => {
  try {
    const transcriptPath = getSessionTranscriptPath();

    if (!transcriptPath || !fs.existsSync(transcriptPath)) {
      console.log(`${colors.dim}No active session${colors.reset}`);
      return;
    }

    const sessionInfo = getSessionInfo(transcriptPath);
    const recentTokens = sessionInfo.recentInputTokens;

    const normalizedModel = normalizeModelKey(sessionInfo.modelName);
    const contextLimit = MODEL_CONTEXT_LIMITS[normalizedModel] ?? CONTEXT_LIMIT;
    const autoCompactLimit = Math.floor(contextLimit * AUTO_COMPACT_RATIO);

    const percentage = Math.min((recentTokens / autoCompactLimit) * 100, 100);
    const usageColor = getPercentageColor(percentage);
    const remainingTokens = Math.max(autoCompactLimit - recentTokens, 0);

    const displayParts = [];

    if (sessionInfo.modelName) {
      displayParts.push(`🤖 ${formatModelName(sessionInfo.modelName)}`);
    }

    if (sessionInfo.sessionCost > 0) {
      displayParts.push(`💰 $${sessionInfo.sessionCost.toFixed(2)} session`);
    }

    displayParts.push(`🧠 recent: ${usageColor}${formatTokenCount(recentTokens)}/${formatTokenCount(autoCompactLimit)} (${percentage.toFixed(1)}%)${colors.reset}`);

    const warningColor = getPercentageColor(percentage);
    displayParts.push(`⚠️  AUTO-COMPACT in ${warningColor}${formatTokenCount(remainingTokens)} tokens${colors.reset}`);

    console.log(displayParts.join(' | '));

  } catch (error) {
    console.log(`${colors.red}Error: ${error.message}${colors.reset}`);
  }
};

main();
