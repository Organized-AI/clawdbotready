import { createServer, type IncomingMessage, type ServerResponse } from "node:http";
import { readFileSync, writeFileSync, mkdirSync, existsSync } from "node:fs";
import { join } from "node:path";
import { homedir } from "node:os";

const CONFIG_DIR = join(homedir(), ".meta-ads-cli");
const CONFIG_FILE = join(CONFIG_DIR, "config.json");
const TOKEN_CACHE = join(CONFIG_DIR, "token_cache.json");
const CALLBACK_PORT = 8888;
const OAUTH_SCOPE = "ads_management,ads_read,business_management,pages_show_list,pages_read_engagement";

export interface Config {
  app_id?: string;
  app_secret?: string;
}

export interface TokenCache {
  access_token: string;
  expires_at?: string;
  token_type?: string;
}

function ensureConfigDir(): void {
  if (!existsSync(CONFIG_DIR)) {
    mkdirSync(CONFIG_DIR, { recursive: true });
  }
}

export function loadConfig(): Config {
  ensureConfigDir();
  if (!existsSync(CONFIG_FILE)) return {};
  try {
    return JSON.parse(readFileSync(CONFIG_FILE, "utf-8")) as Config;
  } catch {
    return {};
  }
}

export function saveConfig(config: Config): void {
  ensureConfigDir();
  writeFileSync(CONFIG_FILE, JSON.stringify(config, null, 2), { mode: 0o600 });
}

export function loadTokenCache(): TokenCache | null {
  if (!existsSync(TOKEN_CACHE)) return null;
  try {
    const cache = JSON.parse(readFileSync(TOKEN_CACHE, "utf-8")) as TokenCache;
    if (cache.expires_at) {
      const expires = new Date(cache.expires_at);
      if (expires <= new Date()) {
        return null; // expired
      }
    }
    return cache;
  } catch {
    return null;
  }
}

export function saveTokenCache(cache: TokenCache): void {
  ensureConfigDir();
  writeFileSync(TOKEN_CACHE, JSON.stringify(cache, null, 2), { mode: 0o600 });
}

export function getAccessToken(): string {
  // Priority 1: env var
  const envToken = process.env.META_ACCESS_TOKEN;
  if (envToken) return envToken;

  // Priority 2: cached token
  const cached = loadTokenCache();
  if (cached?.access_token) return cached.access_token;

  throw new Error(
    "No Meta access token found.\n" +
    "Options:\n" +
    "  1. Run: meta-ads-cli login\n" +
    "  2. Set META_ACCESS_TOKEN environment variable\n" +
    "  3. Add token to ~/.meta-ads-cli/token_cache.json"
  );
}

export function getTokenStatus(): { hasToken: boolean; source: string; expiresAt?: string } {
  const envToken = process.env.META_ACCESS_TOKEN;
  if (envToken) {
    return { hasToken: true, source: "META_ACCESS_TOKEN env var" };
  }
  const cached = loadTokenCache();
  if (cached?.access_token) {
    return {
      hasToken: true,
      source: "~/.meta-ads-cli/token_cache.json",
      expiresAt: cached.expires_at,
    };
  }
  return { hasToken: false, source: "none" };
}

export async function exchangeForLongLived(
  shortToken: string,
  appId: string,
  appSecret: string
): Promise<{ access_token: string; expires_in?: number }> {
  const url = new URL("https://graph.facebook.com/v22.0/oauth/access_token");
  url.searchParams.set("grant_type", "fb_exchange_token");
  url.searchParams.set("client_id", appId);
  url.searchParams.set("client_secret", appSecret);
  url.searchParams.set("fb_exchange_token", shortToken);

  const res = await fetch(url.toString());
  const json = (await res.json()) as Record<string, unknown>;
  if (json.error) {
    const err = json.error as { message: string };
    throw new Error(`Token exchange failed: ${err.message}`);
  }
  return json as { access_token: string; expires_in?: number };
}

export async function runOAuthFlow(appId: string, appSecret?: string): Promise<string> {
  return new Promise((resolve, reject) => {
    const server = createServer(async (req: IncomingMessage, res: ServerResponse) => {
      const url = new URL(req.url ?? "/", `http://localhost:${CALLBACK_PORT}`);

      if (url.pathname === "/callback") {
        const code = url.searchParams.get("code");
        const error = url.searchParams.get("error");

        if (error) {
          res.writeHead(400, { "Content-Type": "text/html" });
          res.end(`<h1>Auth Failed</h1><p>${url.searchParams.get("error_description") ?? error}</p>`);
          server.close();
          reject(new Error(`OAuth error: ${error}`));
          return;
        }

        if (!code) {
          res.writeHead(400, { "Content-Type": "text/html" });
          res.end("<h1>No authorization code received</h1>");
          server.close();
          reject(new Error("No authorization code in callback"));
          return;
        }

        try {
          // Exchange code for access token
          const tokenUrl = new URL("https://graph.facebook.com/v22.0/oauth/access_token");
          tokenUrl.searchParams.set("client_id", appId);
          if (appSecret) tokenUrl.searchParams.set("client_secret", appSecret);
          tokenUrl.searchParams.set("redirect_uri", `http://localhost:${CALLBACK_PORT}/callback`);
          tokenUrl.searchParams.set("code", code);

          const tokenRes = await fetch(tokenUrl.toString());
          const tokenJson = (await tokenRes.json()) as Record<string, unknown>;

          if (tokenJson.error) {
            const err = tokenJson.error as { message: string };
            throw new Error(err.message);
          }

          let accessToken = tokenJson.access_token as string;
          let expiresIn = tokenJson.expires_in as number | undefined;

          // Exchange for long-lived token if we have app_secret
          if (appSecret) {
            try {
              const longLived = await exchangeForLongLived(accessToken, appId, appSecret);
              accessToken = longLived.access_token;
              expiresIn = longLived.expires_in;
            } catch {
              // Fall back to short-lived token
            }
          }

          // Cache the token
          const expiresAt = expiresIn
            ? new Date(Date.now() + expiresIn * 1000).toISOString()
            : undefined;

          saveTokenCache({
            access_token: accessToken,
            expires_at: expiresAt,
            token_type: appSecret ? "long-lived" : "short-lived",
          });

          res.writeHead(200, { "Content-Type": "text/html" });
          res.end(
            "<h1>Authenticated!</h1>" +
            `<p>Token type: ${appSecret ? "long-lived (60 days)" : "short-lived (1 hour)"}</p>` +
            "<p>You can close this window and return to your terminal.</p>"
          );
          server.close();
          resolve(accessToken);
        } catch (err) {
          res.writeHead(500, { "Content-Type": "text/html" });
          res.end(`<h1>Error</h1><p>${err instanceof Error ? err.message : String(err)}</p>`);
          server.close();
          reject(err);
        }
      } else {
        res.writeHead(404);
        res.end("Not found");
      }
    });

    server.listen(CALLBACK_PORT, () => {
      const authUrl = new URL("https://www.facebook.com/v22.0/dialog/oauth");
      authUrl.searchParams.set("client_id", appId);
      authUrl.searchParams.set("redirect_uri", `http://localhost:${CALLBACK_PORT}/callback`);
      authUrl.searchParams.set("scope", OAUTH_SCOPE);
      authUrl.searchParams.set("response_type", "code");

      console.log("\nOpen this URL in your browser to authenticate:\n");
      console.log(authUrl.toString());
      console.log("\nWaiting for callback...\n");
    });

    server.on("error", (err) => {
      if ((err as NodeJS.ErrnoException).code === "EADDRINUSE") {
        reject(new Error(`Port ${CALLBACK_PORT} is in use. Close any existing auth flows and retry.`));
      } else {
        reject(err);
      }
    });
  });
}
