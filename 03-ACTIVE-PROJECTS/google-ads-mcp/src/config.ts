import { config } from 'dotenv';
import { z } from 'zod';

// Only load .env in development, not when run as MCP server
if (!process.env.GOOGLE_ADS_CLIENT_ID) {
  // Suppress dotenv console output
  const originalLog = console.log;
  console.log = () => {};
  config();
  console.log = originalLog;
}

const configSchema = z.object({
  clientId: z.string().min(1, 'GOOGLE_ADS_CLIENT_ID is required'),
  clientSecret: z.string().min(1, 'GOOGLE_ADS_CLIENT_SECRET is required'),
  developerToken: z.string().min(1, 'GOOGLE_ADS_DEVELOPER_TOKEN is required'),
  refreshToken: z.string().min(1, 'GOOGLE_ADS_REFRESH_TOKEN is required'),
  customerId: z.string().min(1, 'GOOGLE_ADS_CUSTOMER_ID is required'),
  loginCustomerId: z.string().optional(),
});

// Lazy config: only validate when actually needed (not at import time)
// This allows the MCP server to start and list tools without credentials
let _config: z.infer<typeof configSchema> | null = null;

export function getGoogleAdsConfig() {
  if (!_config) {
    _config = configSchema.parse({
      clientId: process.env.GOOGLE_ADS_CLIENT_ID,
      clientSecret: process.env.GOOGLE_ADS_CLIENT_SECRET,
      developerToken: process.env.GOOGLE_ADS_DEVELOPER_TOKEN,
      refreshToken: process.env.GOOGLE_ADS_REFRESH_TOKEN,
      customerId: process.env.GOOGLE_ADS_CUSTOMER_ID,
      loginCustomerId: process.env.GOOGLE_ADS_LOGIN_CUSTOMER_ID,
    });
  }
  return _config;
}

// Keep backward compat: eager access still works if env vars are set
export const googleAdsConfig = new Proxy({} as z.infer<typeof configSchema>, {
  get(_target, prop: string) {
    return getGoogleAdsConfig()[prop as keyof z.infer<typeof configSchema>];
  },
});
