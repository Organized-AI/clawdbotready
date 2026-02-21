import { GoogleAdsApi } from 'google-ads-api';
import { googleAdsConfig } from './config.js';

/**
 * Create a Google Ads customer client.
 * @param customerId — optional override; falls back to GOOGLE_ADS_CUSTOMER_ID env var.
 */
export function createGoogleAdsClient(customerId?: string) {
  const client = new GoogleAdsApi({
    client_id: googleAdsConfig.clientId,
    client_secret: googleAdsConfig.clientSecret,
    developer_token: googleAdsConfig.developerToken,
  });

  const customer = client.Customer({
    customer_id: customerId || googleAdsConfig.customerId,
    login_customer_id: googleAdsConfig.loginCustomerId,
    refresh_token: googleAdsConfig.refreshToken,
  });

  return customer;
}

/** Expose the raw GoogleAdsApi instance (for service-level calls like listAccessibleCustomers). */
export function createGoogleAdsApi() {
  return new GoogleAdsApi({
    client_id: googleAdsConfig.clientId,
    client_secret: googleAdsConfig.clientSecret,
    developer_token: googleAdsConfig.developerToken,
  });
}
