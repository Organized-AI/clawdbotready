const API_VERSION = "v22.0";
const API_BASE = `https://graph.facebook.com/${API_VERSION}`;

export interface ApiError {
  message: string;
  type: string;
  code: number;
  error_subcode?: number;
  fbtrace_id?: string;
}

export interface ApiResponse {
  data?: unknown[];
  paging?: {
    cursors?: { before?: string; after?: string };
    next?: string;
  };
  error?: ApiError;
  [key: string]: unknown;
}

export function ensureActPrefix(accountId: string): string {
  return accountId.startsWith("act_") ? accountId : `act_${accountId}`;
}

export function stripActPrefix(accountId: string): string {
  return accountId.startsWith("act_") ? accountId.slice(4) : accountId;
}

export async function makeApiRequest(
  endpoint: string,
  accessToken: string,
  params: Record<string, unknown> = {},
  method: "GET" | "POST" = "GET"
): Promise<ApiResponse> {
  const url = new URL(`${API_BASE}/${endpoint}`);

  if (method === "GET") {
    url.searchParams.set("access_token", accessToken);
    for (const [key, value] of Object.entries(params)) {
      if (value === undefined || value === null || value === "") continue;
      const str =
        typeof value === "object" ? JSON.stringify(value) : String(value);
      url.searchParams.set(key, str);
    }

    const res = await fetch(url.toString());
    const json = (await res.json()) as ApiResponse;
    if (json.error) {
      throw new MetaApiError(json.error, res.status);
    }
    return json;
  }

  // POST: form-encoded body
  url.searchParams.set("access_token", accessToken);
  const body = new URLSearchParams();
  for (const [key, value] of Object.entries(params)) {
    if (value === undefined || value === null) continue;
    const str =
      typeof value === "object" ? JSON.stringify(value) : String(value);
    body.set(key, str);
  }

  const res = await fetch(url.toString(), {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: body.toString(),
  });
  const json = (await res.json()) as ApiResponse;
  if (json.error) {
    throw new MetaApiError(json.error, res.status);
  }
  return json;
}

export async function uploadFile(
  endpoint: string,
  accessToken: string,
  filePath: string,
  fieldName: string,
  extraParams: Record<string, string> = {}
): Promise<ApiResponse> {
  const fs = await import("node:fs");
  const path = await import("node:path");

  const fileBuffer = fs.readFileSync(filePath);
  const fileName = path.basename(filePath);

  const boundary = `----MetaAdsCLI${Date.now()}`;
  const parts: Buffer[] = [];

  // Access token
  parts.push(
    Buffer.from(
      `--${boundary}\r\nContent-Disposition: form-data; name="access_token"\r\n\r\n${accessToken}\r\n`
    )
  );

  // Extra params
  for (const [key, value] of Object.entries(extraParams)) {
    parts.push(
      Buffer.from(
        `--${boundary}\r\nContent-Disposition: form-data; name="${key}"\r\n\r\n${value}\r\n`
      )
    );
  }

  // File
  parts.push(
    Buffer.from(
      `--${boundary}\r\nContent-Disposition: form-data; name="${fieldName}"; filename="${fileName}"\r\nContent-Type: application/octet-stream\r\n\r\n`
    )
  );
  parts.push(fileBuffer);
  parts.push(Buffer.from(`\r\n--${boundary}--\r\n`));

  const body = Buffer.concat(parts);
  const url = `${API_BASE}/${endpoint}`;

  const res = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": `multipart/form-data; boundary=${boundary}` },
    body,
  });
  const json = (await res.json()) as ApiResponse;
  if (json.error) {
    throw new MetaApiError(json.error, res.status);
  }
  return json;
}

export class MetaApiError extends Error {
  code: number;
  type: string;
  httpStatus: number;
  subcode?: number;
  fbtraceId?: string;

  constructor(error: ApiError, httpStatus: number) {
    super(error.message);
    this.name = "MetaApiError";
    this.code = error.code;
    this.type = error.type;
    this.httpStatus = httpStatus;
    this.subcode = error.error_subcode;
    this.fbtraceId = error.fbtrace_id;
  }

  toUserMessage(): string {
    if (this.code === 190) return "Access token expired or invalid. Run: meta-ads-cli login";
    if (this.code === 4) return "API rate limit reached. Wait a few minutes and try again.";
    if (this.code === 200) return "Insufficient permissions. Check your app's API scope.";
    if (this.code === 100) return `Invalid parameter: ${this.message}`;
    return `Meta API error (${this.code}): ${this.message}`;
  }
}
