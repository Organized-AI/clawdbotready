import { GoogleAdsApi, Customer } from "google-ads-api";
import { readFileSync } from "fs";
import { join } from "path";
import { homedir } from "os";

interface GoogleAdsConfig {
  developer_token: string;
  client_id: string;
  client_secret: string;
  refresh_token: string;
  login_customer_id?: string;
}

export function sanitizeGaqlString(value: string): string {
  return value.replace(/["\\]/g, "").replace(/[^\w\s\-_.]/g, "");
}

export function validateNumericId(value: string, fieldName: string): string {
  const cleaned = value.replace(/\D/g, "");
  if (cleaned.length === 0 || cleaned !== value.trim()) {
    throw new Error(`${fieldName} must be a numeric ID (got: "${value}")`);
  }
  return cleaned;
}

export class GoogleAdsClient {
  private api: GoogleAdsApi;
  private config: GoogleAdsConfig;

  constructor(configPath?: string) {
    const path =
      configPath || join(homedir(), ".google-ads-cli", "config.json");

    try {
      const configData = readFileSync(path, "utf-8");
      this.config = JSON.parse(configData);
    } catch (error) {
      throw new Error(
        `Failed to load config from ${path}: ${error instanceof Error ? error.message : "Unknown error"}`
      );
    }

    this.api = new GoogleAdsApi({
      client_id: this.config.client_id,
      client_secret: this.config.client_secret,
      developer_token: this.config.developer_token,
    });
  }

  getCustomer(customerId: string): Customer {
    return this.api.Customer({
      customer_id: customerId,
      refresh_token: this.config.refresh_token,
      login_customer_id: this.config.login_customer_id,
    });
  }

  getConfig(): GoogleAdsConfig {
    return this.config;
  }
}
