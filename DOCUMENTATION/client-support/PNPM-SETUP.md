# Getting Started with pnpm

This project uses **pnpm** (Performant npm) as its package manager. pnpm is faster, more efficient, and safer than npm.

## Why pnpm?

- ⚡ **Faster installs** - 2-3x faster than npm
- 💾 **Saves disk space** - Packages stored once globally, not duplicated per project
- 🔒 **Safer** - Strict dependency isolation prevents phantom dependencies
- 🎯 **Deterministic** - Consistent installs across all machines

## Quick Start

### 1. Install pnpm (One-Time Setup)

**Option A: Using npm (if you have Node.js installed)**
```bash
npm install -g pnpm
```

**Option B: Using Homebrew (macOS/Linux)**
```bash
brew install pnpm
```

**Option C: Using standalone script (No Node.js required)**
```bash
curl -fsSL https://get.pnpm.io/install.sh | sh -
```

**Option D: Windows (PowerShell)**
```powershell
iwr https://get.pnpm.io/install.ps1 -useb | iex
```

### 2. Verify Installation

```bash
pnpm --version
```

You should see something like `10.28.2` or higher.

### 3. Setup This Project

For first-time setup (installs dependencies + ensures Just is installed):

```bash
pnpm run setup
```

For regular dependency updates:

```bash
pnpm install
```

That's it! 🎉

## Common Commands

| Task | Command |
|------|---------|
| **First-time setup** | `pnpm run setup` |
| Install dependencies | `pnpm install` or `pnpm i` |
| Run a script | `pnpm <script-name>` (e.g., `pnpm dev`) |
| Add a package | `pnpm add <package>` |
| Add dev dependency | `pnpm add -D <package>` |
| Remove a package | `pnpm remove <package>` |
| Run a package binary | `pnpm dlx <command>` (like npx) |
| Update dependencies | `pnpm update` |
| List dependencies | `pnpm list` |

## Important: `pnpm setup` vs `pnpm run setup`

⚠️ **Don't confuse these two commands:**

- **`pnpm setup`** - Global pnpm configuration (adds pnpm to your PATH)
  - Run this ONCE on your system after installing pnpm
  - Not related to this project

- **`pnpm run setup`** - This project's setup script
  - Installs Node.js dependencies
  - Checks for Just command runner
  - Run this for first-time project setup

## Migrating from npm/yarn?

### If you used npm:
```bash
# Remove old files
rm -rf node_modules package-lock.json

# Install with pnpm
pnpm install
```

### If you used yarn:
```bash
# Remove old files
rm -rf node_modules yarn.lock

# Install with pnpm
pnpm install
```

## Key Differences from npm

| npm | pnpm |
|-----|------|
| `npm install` | `pnpm install` |
| `npm run build` | `pnpm build` (no "run" needed!) |
| `npm run dev` | `pnpm dev` |
| `npx some-tool` | `pnpm dlx some-tool` |
| `npm install -g tool` | `pnpm add -g tool` |

## Troubleshooting

### "pnpm: command not found"

1. Close and reopen your terminal
2. If still not working, run the global setup:
   ```bash
   pnpm setup
   source ~/.zshrc  # or source ~/.bashrc
   ```

### "Module not found" errors

This might happen if you try to import a package that isn't in `package.json`. This is actually a **feature** - pnpm prevents phantom dependencies!

**Solution**: Add the package explicitly:
```bash
pnpm add <missing-package>
```

### "Just not found" errors

Run the project setup script:
```bash
pnpm run setup
```

This will prompt you to install Just if it's missing.

### Symlink issues on Windows

Run your terminal as Administrator or enable Developer Mode in Windows Settings.

## Additional Resources

- [pnpm Official Docs](https://pnpm.io)
- [pnpm vs npm Benchmark](https://pnpm.io/benchmarks)
- [GitHub: pnpm/pnpm](https://github.com/pnpm/pnpm)
- [Just Command Runner](https://just.systems/man/en/)

## Need Help?

If you run into issues:
1. Check that you have Node.js installed: `node --version` (v18+ recommended)
2. Try removing `node_modules` and `pnpm-lock.yaml`, then run `pnpm install` again
3. Check the [pnpm troubleshooting guide](https://pnpm.io/faq)
4. Ask the team in your project's communication channel

---

**First time using pnpm?** Just run these commands:
```bash
npm install -g pnpm
pnpm run setup
```
You're ready to go! 🚀
