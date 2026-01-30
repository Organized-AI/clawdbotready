#!/usr/bin/env node

/**
 * Welcome & Onboarding Script
 *
 * Shows Organized AI branded onboarding matching create-organized-codebase
 */

const fs = require('fs');
const path = require('path');
const readline = require('readline');

// ANSI color codes
const colors = {
  reset: '\x1b[0m',
  bold: '\x1b[1m',
  dim: '\x1b[2m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  cyan: '\x1b[36m',
  gray: '\x1b[90m',
  // Golden yellow matching Organized AI brand (#FFD54F)
  brandYellow: '\x1b[38;2;255;213;79m',
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

function prompt(question) {
  return new Promise((resolve) => {
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout,
    });

    rl.question(`${question} `, (answer) => {
      rl.close();
      resolve(answer.trim());
    });
  });
}

function hasRunBefore() {
  const flagFile = path.join(process.cwd(), '.organized-setup-complete');
  return fs.existsSync(flagFile);
}

function markAsComplete() {
  const flagFile = path.join(process.cwd(), '.organized-setup-complete');
  fs.writeFileSync(flagFile, new Date().toISOString());
}

function detectProjectType() {
  const cwd = process.cwd();
  const projectName = path.basename(cwd);
  const hasClaude = fs.existsSync(path.join(cwd, '.claude'));
  const hasJustfile = fs.existsSync(path.join(cwd, 'justfile'));
  const hasPackageJson = fs.existsSync(path.join(cwd, 'package.json'));
  const isGitRepo = fs.existsSync(path.join(cwd, '.git'));

  return { projectName, hasClaude, hasJustfile, hasPackageJson, isGitRepo };
}

function showBanner() {
  const y = colors.brandYellow;

  console.log('');
  console.log(`   ${y}█▀█ █▀▀█ █▀▀█ █▀▀█ █▀▀▄ ▀█▀ ▀▀█ █▀▀ █▀▀▄   █▀▀█ ▀█▀${colors.reset}`);
  console.log(`   ${y}█ █ █▄▄▀ █ ▄▄ █▄▄█ █  █  █  ▄▀  █▀▀ █  █   █▄▄█  █ ${colors.reset}`);
  console.log(`   ${y}▀▀▀ ▀ ▀▀ ▀▀▀▀ ▀  ▀ ▀  ▀ ▀▀▀ ▀▀▀ ▀▀▀ ▀▀▀    ▀  ▀ ▀▀▀${colors.reset}`);
  console.log('');
  log(`${colors.bold}${colors.brandYellow}Organized AI${colors.reset} ${colors.gray}v1.0.0${colors.reset}`);
  log('Context engineering for Claude Code.', 'dim');
  console.log('');
}

function showProjectDetection(info) {
  const parts = [];

  if (info.hasPackageJson) {
    parts.push('Node.js');
  }
  if (info.isGitRepo) {
    parts.push('Git repository');
  }
  if (info.hasClaude) {
    parts.push(colors.yellow + 'Existing .claude/' + colors.reset);
  }

  if (parts.length > 0) {
    log(`${colors.dim}Detected: ${colors.reset}${parts.join(' • ')}`);
    console.log('');
  }
}

function showProgress(message, status = 'done') {
  const icons = {
    pending: colors.gray + '○' + colors.reset,
    done: colors.green + '✓' + colors.reset,
    skip: colors.yellow + '○' + colors.reset,
  };
  const text = status === 'done' ? message : colors.gray + message + colors.reset;
  console.log(`${icons[status]} ${text}`);
}

function showInstallationStatus(info) {
  console.log('');
  log('Installation Status:', 'bold');
  log('─'.repeat(40), 'dim');
  console.log('');

  showProgress('.claude/ commands', info.hasClaude ? 'done' : 'skip');
  showProgress('justfile recipes', info.hasJustfile ? 'done' : 'skip');
  showProgress('pnpm package manager', 'done');
  showProgress('scripts/ automation', 'done');

  console.log('');
}

function showQuickStart(info) {
  log('Quick Start:', 'bold');
  console.log('');

  log('  pnpm install', 'cyan');
  log('    Install/update dependencies', 'dim');
  console.log('');

  if (info.hasClaude) {
    log('  /status', 'cyan');
    log('    Check project health (Boris methodology)', 'dim');
    console.log('');

    log('  /verify', 'cyan');
    log('    Run verification checks before committing', 'dim');
    console.log('');
  }

  log('  pnpm dev', 'cyan');
  log('    Start development (customize in package.json)', 'dim');
  console.log('');

  if (info.hasJustfile) {
    log('  just --list', 'cyan');
    log('    See available automation recipes', 'dim');
    console.log('');
  }
}

function showNextSteps(info) {
  log('Next Steps:', 'bold');
  console.log('');

  let stepNum = 1;

  if (!info.hasClaude) {
    log(`${stepNum}. Add Claude Code configuration`, 'yellow');
    log(`   Run: ${colors.cyan}npx create-organized-codebase --local${colors.reset}`, 'dim');
    console.log('');
    stepNum++;
  }

  log(`${stepNum}. Customize package.json scripts`, 'yellow');
  log('   Replace placeholder commands with your actual build/test commands', 'dim');
  console.log('');
  stepNum++;

  if (!info.hasJustfile) {
    log(`${stepNum}. (Optional) Create a justfile`, 'yellow');
    log(`   See: ${colors.cyan}https://just.systems/man/en/${colors.reset}`, 'dim');
    console.log('');
    stepNum++;
  }

  log(`${stepNum}. Start building! 🚀`, 'yellow');
  log('   Your development environment is ready', 'dim');
  console.log('');
}

function showBorisMethodology() {
  log('Boris Methodology:', 'bold');
  log('  Plan → Build → Verify → Commit → Review', 'dim');
  console.log('');
  log('  Always give Claude a way to verify its work.', 'dim');
  console.log('');
}

async function main() {
  // Skip if already run
  if (hasRunBefore()) {
    return;
  }

  // Detect project info
  const info = detectProjectType();

  // Show Organized AI branded banner
  showBanner();

  // Show detection
  showProjectDetection(info);

  // Show what's installed
  showInstallationStatus(info);

  // Show quick start commands
  showQuickStart(info);

  // Show next steps
  showNextSteps(info);

  // Show Boris methodology if .claude/ exists
  if (info.hasClaude) {
    showBorisMethodology();
  }

  // Footer separator
  log('─'.repeat(60), 'dim');
  console.log('');

  // Ask if they want to skip
  const answer = await prompt('Would you like to skip this message in the future? (Y/n)');

  if (answer.toLowerCase() !== 'n' && answer.toLowerCase() !== 'no') {
    markAsComplete();
    console.log('');
    log('✓ You can always re-run this with: node scripts/welcome.js', 'green');
  } else {
    console.log('');
    log('✓ This message will show on every pnpm run setup', 'green');
  }

  console.log('');
  log('Happy coding! 🎉', 'bold');
  console.log('');
}

main().catch((error) => {
  console.error('');
  log(`Error: ${error.message}`, 'yellow');
  console.error('');
  process.exit(1);
});
