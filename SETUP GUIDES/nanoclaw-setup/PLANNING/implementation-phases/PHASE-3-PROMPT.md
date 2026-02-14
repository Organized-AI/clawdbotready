# Phase 3: Container Setup

## Objective
Install the container runtime and build the NanoClaw agent container image.

## Background
NanoClaw agents run inside Linux containers for OS-level isolation. The default runtime is Apple Container (lightweight Linux VMs on macOS). Docker is supported as an alternative via the `/convert-to-docker` skill.

The container image includes: Node.js 22, Chromium (for browser automation), Claude Code CLI, agent-browser, and the NanoClaw agent-runner.

## Steps

1. **Verify Apple Container is installed**
   ```bash
   container --version
   # If not installed:
   brew install container
   ```

2. **Build the agent container image**
   ```bash
   cd ~/nanoclaw
   ./container/build.sh
   ```

   This builds `nanoclaw-agent:latest` using the `container/Dockerfile`.

3. **Verify the image was created**
   ```bash
   container images | grep nanoclaw-agent
   ```

4. **Test the container**
   ```bash
   echo '{"prompt":"What is 2+2?","groupFolder":"test","chatJid":"test@g.us","isMain":false}' | \
     container run -i --rm nanoclaw-agent:latest
   ```

   You should see a JSON response with Claude's answer.

## Build Cache Gotcha

Apple Container's buildkit caches aggressively. If you've made changes and the build seems stale:

```bash
# Nuclear option: purge build cache entirely
container builder stop && container builder rm && container builder start
./container/build.sh
```

Verify after rebuild:
```bash
container run -i --rm --entrypoint wc nanoclaw-agent:latest -l /app/src/index.ts
```

## Alternative: Docker

If Apple Container isn't available (Intel Mac, Linux):

```bash
cd ~/nanoclaw
claude
# Then run the conversion skill:
/convert-to-docker
```

This rewrites `container-runner.ts` to use Docker commands instead.

## Success Criteria
- [ ] Container runtime installed and working
- [ ] `nanoclaw-agent:latest` image built successfully
- [ ] Test container responds to a prompt
- [ ] Container runs as non-root user (uid 1000)

## Troubleshooting
- **Build fails "no space"**: Free disk space, need ~5GB for image layers
- **Apple Container not found**: `brew install container` or install from Xcode
- **Container hangs**: Check if another container builder is running: `container builder ls`
