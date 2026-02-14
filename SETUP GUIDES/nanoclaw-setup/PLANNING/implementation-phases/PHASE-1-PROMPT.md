# Phase 1: Clone & Install Dependencies

## Objective
Clone the NanoClaw repository and install all Node.js dependencies.

## Steps

1. **Clone the repository**
   ```bash
   cd ~
   git clone https://github.com/qwibitai/nanoclaw.git
   cd nanoclaw
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Verify installation**
   ```bash
   # Check that key dependencies are present
   node -e "require('@whiskeysockets/baileys'); console.log('baileys OK')"
   node -e "require('better-sqlite3'); console.log('sqlite OK')"
   node -e "require('zod'); console.log('zod OK')"
   ```

4. **Verify TypeScript compiles**
   ```bash
   npx tsc --noEmit
   ```

5. **Create required directories**
   ```bash
   mkdir -p logs data groups store
   ```

## Success Criteria
- [ ] Repository cloned to `~/nanoclaw`
- [ ] `npm install` completed without errors
- [ ] TypeScript type-check passes
- [ ] `logs/`, `data/`, `groups/`, `store/` directories exist

## Troubleshooting
- **npm install fails on better-sqlite3**: This is a native module. Ensure Xcode command line tools are installed: `xcode-select --install`
- **Permission errors**: Don't use sudo with npm. If needed, fix npm permissions: `npm config set prefix ~/.npm-global`
