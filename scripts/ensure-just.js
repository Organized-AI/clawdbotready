#!/usr/bin/env node

/**
 * Dependency Setup Script
 *
 * Ensures required system dependencies (Just) are installed.
 * Used by `pnpm setup` command for first-time project setup.
 */

const { execSync } = require('child_process');
const os = require('os');
const readline = require('readline');

// Colors for terminal output
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  cyan: '\x1b[36m',
  dim: '\x1b[2m',
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

/**
 * Check if a command exists in PATH
 */
function commandExists(command) {
  try {
    execSync(`which ${command}`, { stdio: 'ignore' });
    return true;
  } catch {
    return false;
  }
}

/**
 * Get Just version if installed
 */
function getJustVersion() {
  try {
    const version = execSync('just --version', { encoding: 'utf-8' }).trim();
    return version;
  } catch {
    return null;
  }
}

/**
 * Get install command for Just based on OS
 */
function getJustInstallCommand() {
  const platform = os.platform();

  switch (platform) {
    case 'darwin':
      return {
        command: 'brew install just',
        description: 'Homebrew (macOS)',
      };
    case 'linux':
      return {
        command: 'curl --proto "=https" --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to ~/.local/bin',
        description: 'Install script (Linux)',
      };
    case 'win32':
      return {
        command: 'winget install Casey.Just',
        description: 'Winget (Windows)',
      };
    default:
      return {
        command: null,
        description: 'Visit https://just.systems/man/en/ for installation instructions',
      };
  }
}

/**
 * Attempt to install Just automatically
 */
function tryInstallJust() {
  const { command } = getJustInstallCommand();

  if (!command) {
    return false;
  }

  try {
    log(`Running: ${command}`, 'dim');
    execSync(command, { stdio: 'inherit' });
    return commandExists('just');
  } catch {
    return false;
  }
}

/**
 * Prompt user for yes/no
 */
function prompt(question) {
  return new Promise((resolve) => {
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout,
    });

    rl.question(`${question} (y/N): `, (answer) => {
      rl.close();
      resolve(answer.toLowerCase() === 'y' || answer.toLowerCase() === 'yes');
    });
  });
}

/**
 * Main setup function
 */
async function main() {
  console.log('');
  log('='.repeat(60), 'cyan');
  log('  Organized Codebase - Dependency Setup', 'cyan');
  log('='.repeat(60), 'cyan');
  console.log('');

  // Check pnpm
  const pnpmVersion = execSync('pnpm --version', { encoding: 'utf-8' }).trim();
  log(`✓ pnpm ${pnpmVersion} found`, 'green');

  // Check Just
  const justVersion = getJustVersion();

  if (justVersion) {
    log(`✓ Just ${justVersion} found`, 'green');
    console.log('');
    log('All dependencies are installed!', 'green');
    console.log('');
    log('You can now use:', 'dim');
    log('  • pnpm run <script>  - Run package.json scripts', 'dim');
    log('  • just <recipe>      - Run justfile recipes', 'dim');
    console.log('');
    return;
  }

  // Just not found
  console.log('');
  log('⚠ Just command runner not found', 'yellow');
  console.log('');
  log('Just is required to run Organized Codebase recipes (justfile).', 'dim');
  log('Learn more: https://just.systems/man/en/', 'dim');
  console.log('');

  const { command, description } = getJustInstallCommand();

  // Check if we can auto-install
  const platform = os.platform();
  const canAutoInstall = command && (platform === 'darwin' || platform === 'linux');

  if (canAutoInstall) {
    log('Installation method:', 'cyan');
    log(`  ${description}`, 'cyan');
    log(`  ${command}`, 'dim');
    console.log('');

    const shouldInstall = await prompt('Would you like to install Just now?');

    if (shouldInstall) {
      console.log('');
      const success = tryInstallJust();

      if (success) {
        const version = getJustVersion();
        log(`✓ Just ${version} installed successfully!`, 'green');
        console.log('');
        log('Setup complete! 🎉', 'green');
        return;
      } else {
        log('✗ Failed to install Just automatically', 'yellow');
        console.log('');
      }
    }
  }

  // Manual installation instructions
  log('Install Just manually:', 'cyan');
  log(`  ${command || description}`, 'cyan');
  console.log('');
  log('Then run: pnpm setup', 'dim');
  console.log('');

  // Ask if they want to continue anyway
  const continueAnyway = await prompt('Continue without Just? (justfile recipes won\'t work)');

  if (continueAnyway) {
    console.log('');
    log('⚠ Continuing without Just. Install it later to use justfile recipes.', 'yellow');
    console.log('');
  } else {
    console.log('');
    log('Setup cancelled. Install Just and run: pnpm setup', 'dim');
    console.log('');
    process.exit(1);
  }
}

// Run main function
main().catch((error) => {
  console.error('');
  log(`Error: ${error.message}`, 'yellow');
  console.error('');
  process.exit(1);
});
