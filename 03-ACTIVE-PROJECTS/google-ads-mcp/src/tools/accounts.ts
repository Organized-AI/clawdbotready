import { z } from 'zod';
import { createGoogleAdsClient, createGoogleAdsApi } from '../google-ads-client.js';
import { googleAdsConfig } from '../config.js';
import { Tool } from '@modelcontextprotocol/sdk/types.js';

export const listAccessibleCustomersSchema = z.object({});

export const getAccountHierarchySchema = z.object({
  customerId: z.string().optional().describe('Manager account customer ID to query hierarchy from. Uses default if omitted.'),
});

export const getAccountInfoSchema = z.object({
  customerId: z.string().describe('Google Ads customer ID to get info for.'),
});

export const listManagerAccountsSchema = z.object({
  customerId: z.string().optional().describe('Google Ads customer ID. Uses default account if omitted.'),
});

/**
 * List ALL accessible customer accounts under the MCC.
 * Equivalent to meta-ads-cli `accounts` command.
 * Queries customer_client from the manager account to discover all child accounts.
 */
export async function listAccessibleCustomers(_args: z.infer<typeof listAccessibleCustomersSchema>) {
  // Use the MCC (login_customer_id) to discover all child accounts
  const mccId = googleAdsConfig.loginCustomerId || googleAdsConfig.customerId;
  const client = createGoogleAdsClient(mccId);

  try {
    const query = `
      SELECT
        customer_client.id,
        customer_client.descriptive_name,
        customer_client.currency_code,
        customer_client.time_zone,
        customer_client.manager,
        customer_client.status,
        customer_client.level
      FROM customer_client
      WHERE customer_client.level <= 1
      ORDER BY customer_client.descriptive_name
    `;

    const response = await client.query(query);

    return {
      mccId,
      customers: response.map(row => ({
        id: String(row.customer_client?.id),
        name: row.customer_client?.descriptive_name,
        currencyCode: row.customer_client?.currency_code,
        timeZone: row.customer_client?.time_zone,
        isManager: row.customer_client?.manager,
        status: row.customer_client?.status,
        level: row.customer_client?.level,
      }))
    };
  } catch (error) {
    // Fallback: if MCC query fails, try the basic single-account approach
    try {
      const fallbackClient = createGoogleAdsClient();
      const query = `
        SELECT
          customer.id,
          customer.descriptive_name,
          customer.currency_code,
          customer.time_zone
        FROM customer
        LIMIT 1
      `;
      const response = await fallbackClient.query(query);
      return {
        mccId: null,
        note: 'MCC query failed; showing only the configured default account.',
        customers: response.map(row => ({
          id: String(row.customer?.id),
          name: row.customer?.descriptive_name,
          currencyCode: row.customer?.currency_code,
          timeZone: row.customer?.time_zone,
          isManager: false,
          status: 'ENABLED',
          level: 0,
        }))
      };
    } catch (fallbackError) {
      throw new Error(`Failed to list accessible customers: ${error.message}`);
    }
  }
}

export async function getAccountHierarchy(args: z.infer<typeof getAccountHierarchySchema>) {
  const client = createGoogleAdsClient(args.customerId);

  try {
    const query = `
      SELECT
        customer_client.client_customer,
        customer_client.level,
        customer_client.manager,
        customer_client.descriptive_name,
        customer_client.currency_code,
        customer_client.time_zone,
        customer_client.id
      FROM customer_client
      WHERE customer_client.level <= 2
    `;

    const response = await client.query(query);

    return response.map(row => ({
      id: row.customer_client?.id,
      descriptiveName: row.customer_client?.descriptive_name,
      currencyCode: row.customer_client?.currency_code,
      timeZone: row.customer_client?.time_zone,
      level: row.customer_client?.level,
      isManager: row.customer_client?.manager,
      clientCustomer: row.customer_client?.client_customer
    }));
  } catch (error) {
    throw new Error(`Failed to get account hierarchy: ${error.message}`);
  }
}

export async function getAccountInfo(args: z.infer<typeof getAccountInfoSchema>) {
  const client = createGoogleAdsClient(args.customerId);

  try {
    const query = `
      SELECT
        customer.id,
        customer.descriptive_name,
        customer.currency_code,
        customer.time_zone,
        customer.auto_tagging_enabled,
        customer.tracking_url_template,
        customer.optimization_score,
        customer.pay_per_conversion_eligibility_failure_reasons
      FROM customer
    `;

    const response = await client.query(query);

    if (response.length === 0) {
      throw new Error('Customer not found');
    }

    const customer = response[0].customer;

    return {
      id: customer?.id,
      descriptiveName: customer?.descriptive_name,
      currencyCode: customer?.currency_code,
      timeZone: customer?.time_zone,
      autoTaggingEnabled: customer?.auto_tagging_enabled,
      trackingUrlTemplate: customer?.tracking_url_template,
      optimizationScore: customer?.optimization_score,
      payPerConversionEligibilityFailureReasons: customer?.pay_per_conversion_eligibility_failure_reasons || []
    };
  } catch (error) {
    throw new Error(`Failed to get account info: ${error.message}`);
  }
}

export async function listManagerAccounts(args: z.infer<typeof listManagerAccountsSchema>) {
  const client = createGoogleAdsClient(args.customerId);

  try {
    const query = `
      SELECT
        customer_manager_link.manager_customer,
        customer_manager_link.client_customer,
        customer_manager_link.status
      FROM customer_manager_link
      WHERE customer_manager_link.status = 'ACTIVE'
    `;

    const response = await client.query(query);

    return response.map(row => ({
      managerCustomer: row.customer_manager_link?.manager_customer,
      clientCustomer: (row.customer_manager_link as any)?.client_customer,
      status: row.customer_manager_link?.status
    }));
  } catch (error) {
    throw new Error(`Failed to list manager accounts: ${error.message}`);
  }
}

const customerIdProp = {
  customerId: {
    type: 'string' as const,
    description: 'Google Ads customer ID to target. If omitted, uses the default account.',
  },
};

export const accountTools: Tool[] = [
  {
    name: 'list_accessible_customers',
    description: 'List ALL Google Ads accounts accessible under the MCC (Manager account). Use this first to discover available account IDs, then pass customerId to other tools.',
    inputSchema: {
      type: 'object',
      properties: {},
    },
  },
  {
    name: 'get_account_hierarchy',
    description: 'Get the account hierarchy showing manager and client relationships',
    inputSchema: {
      type: 'object',
      properties: {
        ...customerIdProp,
      },
    },
  },
  {
    name: 'get_account_info',
    description: 'Get detailed information about a specific Google Ads account',
    inputSchema: {
      type: 'object',
      properties: {
        customerId: {
          type: 'string',
          description: 'Customer ID to get info for',
        },
      },
      required: ['customerId'],
    },
  },
  {
    name: 'list_manager_accounts',
    description: 'List manager account relationships',
    inputSchema: {
      type: 'object',
      properties: {
        ...customerIdProp,
      },
    },
  },
];
