# OpenClaw Onboarding Skill

Expert AI agent skill for deploying OpenClaw Gateway with comprehensive setup guidance.

## Installation

This skill is already installed in `.claude/skills/openclaw-onboarding/`.

## What It Does

The OpenClaw Onboarding Expert provides:

1. **Critical Disk Space Validation**
   - Checks available disk space before EVERY phase
   - Prevents the #1 deployment failure mode (running out of space mid-install)
   - Tracks disk usage delta after each phase
   - Warns if space drops below safety buffer

2. **Deployment Path Selection**
   - Guides users between VM-isolated vs Native macOS deployments
   - Decision tree based on environment, security needs, and disk availability
   - Clear comparison of tradeoffs

3. **Phased Implementation Expertise**
   - Deep knowledge of all phase prompts in `SETUP GUIDES/`
   - Pre-flight checks before each phase
   - Integration with `/phased-build` skill
   - Rollback and recovery guidance

4. **Moltbook Integration**
   - Streamlined agent management setup
   - Claim link generation and verification
   - Troubleshooting common issues

5. **Production Hardening**
   - Security checklist validation
   - Monitoring and backup verification
   - Production readiness scoring

## Usage

### Invoke Directly

```bash
# From terminal
/openclaw-onboarding
```

### Trigger Automatically

The skill activates when you ask:
- "set up openclaw"
- "deploy openclaw gateway"
- "which openclaw setup should I use"
- "vm or native openclaw"
- "help me with openclaw"
- "moltbook integration"

### Use with Phased Build

```bash
# Navigate to a setup guide
cd "SETUP GUIDES/openclaw-vm-setup"

# Run phased build (skill auto-activates as domain expert)
/phased-build
```

The skill will:
1. Run disk space checks before each phase
2. Validate prerequisites
3. Track disk usage
4. Provide troubleshooting if phases fail
5. Guide Moltbook integration (Phase 8 for VM)

## Key Features

### Disk Space Vigilance

**Before Every Phase**:
```bash
# Automatic check
df -h /
AVAILABLE_GB=$(df -g / | awk 'NR==2 {print $4}')

# VM setup requires 70GB
# Native setup requires 10GB
# Fails fast if insufficient
```

**After Every Phase**:
```markdown
## Disk Usage Timeline
Before Phase: 150GB
After Phase: 80GB
Delta: 70GB (VM image created)
```

### Deployment Decision Tree

Asks the right questions:
1. Production or development?
2. Security requirements?
3. Available disk space?
4. Time budget?

Recommends optimal path based on answers.

### Comprehensive Troubleshooting

Solutions for common issues:
- Disk space runs out mid-deployment
- VM won't start after creation
- SSH connection refused
- Gateway not accessible
- Moltbook claim link not generated

## Setup Guides Supported

### VM Setup (openclaw-vm-setup)
- **Phases**: 0-8 (9 total phases)
- **Time**: 30-45 minutes
- **Disk**: 70GB required
- **Best For**: Production, maximum isolation

### Native Setup (openclaw-native-setup)
- **Phases**: 0-6 (7 total phases)
- **Time**: 10-15 minutes
- **Disk**: 10GB required
- **Best For**: Development, fast performance

## Integration Points

### With /phased-build
- Provides domain expertise during phase execution
- Adds disk space checks to standard workflow
- Enhances safety and reliability

### With SETUP GUIDES/
- Deep knowledge of all implementation phases
- Understands helper scripts
- Knows configuration options

### With Moltbook
- Knows integration workflow
- Can troubleshoot claim link issues
- Guides dashboard configuration

## Example Workflows

### New Deployment
1. User: "I want to set up OpenClaw"
2. Skill runs environment diagnostics
3. Skill recommends VM vs Native
4. Skill validates disk space
5. Skill guides through phases with checks
6. Skill offers Moltbook integration

### Troubleshooting
1. User: "My OpenClaw setup failed"
2. Skill checks current disk space
3. Skill finds last completed phase
4. Skill provides cleanup recommendations
5. Skill offers resume or rollback options

### Production Readiness
1. User: "Is my OpenClaw ready for production?"
2. Skill reviews hardening guide
3. Skill checks completed phases
4. Skill validates security configuration
5. Skill provides readiness score
6. Skill lists remaining tasks

## Dependencies

- `SETUP GUIDES/openclaw-vm-setup/`
- `SETUP GUIDES/openclaw-native-setup/`
- Standard Unix tools: `df`, `du`, `ls`, `cat`
- Optional: Moltbook account

## Version History

### 1.0.0 (2026-01-31)
- Initial release
- Disk space validation for all phases
- VM vs Native decision tree
- Comprehensive troubleshooting
- Moltbook integration guidance
- Production hardening checklist

## License

Part of the Clawdbot Ready project.
