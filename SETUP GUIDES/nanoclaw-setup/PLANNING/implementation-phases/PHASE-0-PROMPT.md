# Phase 0: Prerequisites Validation

## Objective
Verify that the target Mac meets all hardware, software, and network requirements for NanoClaw.

## Steps

1. **Verify Apple Silicon**
   ```bash
   uname -m  # Must show: arm64
   ```

2. **Check macOS version**
   ```bash
   sw_vers -productVersion  # Must be 14.0+ (15.0+ preferred for Apple Container)
   ```

3. **Check disk space**
   ```bash
   df -h /  # Need 15GB+ available
   ```

4. **Verify Node.js 20+**
   ```bash
   node --version
   # If not installed: brew install node
   ```

5. **Verify Git**
   ```bash
   git --version
   # If not installed: xcode-select --install
   ```

6. **Verify Claude Code**
   ```bash
   claude --version
   # If not installed: download from claude.ai/download
   ```

7. **Check Apple Container**
   ```bash
   container --version
   # If not installed: brew install container
   ```

8. **Test network connectivity**
   ```bash
   curl -s --connect-timeout 5 https://api.anthropic.com && echo "OK"
   curl -s --connect-timeout 5 https://web.whatsapp.com && echo "OK"
   ```

## Automated Check
```bash
./scripts/check-prerequisites.sh
```

## Success Criteria
- [ ] Apple Silicon Mac confirmed
- [ ] macOS 14.0+ (Sonoma or later)
- [ ] 15GB+ disk space available
- [ ] Node.js 20+ installed
- [ ] Git installed
- [ ] Claude Code installed
- [ ] Apple Container (or Docker) available
- [ ] Network connectivity to Anthropic API and WhatsApp

## If Prerequisites Fail
- **No Apple Silicon**: NanoClaw requires ARM64 for Apple Container. Use Docker on Intel Macs with the `/convert-to-docker` skill.
- **Old Node.js**: `brew install node` or use nvm/fnm to install Node.js 20+.
- **Low disk**: Free space by removing unused applications, Xcode simulators, or Docker images.
- **No Claude Code**: Download from [claude.ai/download](https://claude.ai/download).
