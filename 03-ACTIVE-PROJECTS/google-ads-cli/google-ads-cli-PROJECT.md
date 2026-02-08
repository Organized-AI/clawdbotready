# Google Ads CLI Rebuild

## Vision
Replace the bloated Python-based google-ads-pro skill (15,923 files causing EMFILE errors) with a lightweight Node.js/TypeScript CLI tool that provides the same Google Ads API functionality while maintaining OpenClaw Gateway stability.

## Primary User
OpenClaw Gateway running on M1 Mac Mini, providing Telegram bot interface for Google Ads management.

## Success Criteria
- [x] Prerequisites validated (SSH access, credentials extracted, gateway stable)
- [ ] CLI tool built and installed globally
- [ ] File count in skills/ directory: 15,923 → 1 file
- [ ] File descriptors remain stable at ~56 (no spike to 10,267)
- [ ] Telegram bot functional with full Google Ads features (CPA metrics, budgets, campaigns, reporting)
- [ ] Zero EMFILE errors in gateway logs
- [ ] 24-hour stability test passed

## Non-Goals
- Not rebuilding the entire OpenClaw Gateway
- Not migrating to cloud-based deployment
- Not adding features beyond original Python skill parity
- Not changing Google Ads API authentication method
