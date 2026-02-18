#!/usr/bin/env node
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
  ErrorCode,
  McpError
} from '@modelcontextprotocol/sdk/types.js';

// Campaigns
import { campaignTools, listCampaigns, listCampaignsSchema, getCampaign, getCampaignSchema, createCampaign, createCampaignSchema, updateCampaign, updateCampaignSchema } from './tools/campaigns.js';

// Ad Groups
import { adGroupTools, listAdGroups, listAdGroupsSchema, createAdGroup, createAdGroupSchema, updateAdGroup, updateAdGroupSchema, getAdGroup, getAdGroupSchema } from './tools/ad-groups.js';

// Ads
import { adTools, listAds, listAdsSchema, createResponsiveSearchAd, createResponsiveSearchAdSchema, updateAd, updateAdSchema, getAdPerformance, getAdPerformanceSchema } from './tools/ads.js';

// Keywords
import { keywordTools, listKeywords, listKeywordsSchema, addKeywords, addKeywordsSchema, addNegativeKeywords, addNegativeKeywordsSchema, updateKeyword, updateKeywordSchema, getKeywordPerformance, getKeywordPerformanceSchema } from './tools/keywords.js';

// Performance & Reports
import { performanceTools, getAccountPerformance, getAccountPerformanceSchema, getCampaignPerformance, getCampaignPerformanceSchema, getAdGroupPerformance, getAdGroupPerformanceSchema, getSearchTermsReport, getSearchTermsReportSchema } from './tools/performance.js';

// Accounts
import { accountTools, listAccessibleCustomers, listAccessibleCustomersSchema, getAccountHierarchy, getAccountHierarchySchema, getAccountInfo, getAccountInfoSchema, listManagerAccounts, listManagerAccountsSchema } from './tools/accounts.js';

// Analytics
import { analyticsTools, getTopBottomKeywords, getTopBottomKeywordsSchema, getKeywordOpportunities, getKeywordOpportunitiesSchema, getCampaignComparison, getCampaignComparisonSchema } from './tools/analytics.js';

// Conversions
import { conversionTools, listConversionActions, listConversionActionsSchema, createConversionAction, createConversionActionSchema, updateConversionAction, updateConversionActionSchema, getConversionStats, getConversionStatsSchema } from './tools/conversions.js';

// Shopping
import { shoppingTools, getProductPerformance, getProductPerformanceSchema, getProductPartitionPerformance, getProductPartitionPerformanceSchema, getTopBottomProducts, getTopBottomProductsSchema } from './tools/shopping.js';

const server = new Server(
  {
    name: 'google-ads-mcp',
    version: '2.0.0',
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// All tools from every module
const allTools = [
  ...campaignTools,
  ...adGroupTools,
  ...adTools,
  ...keywordTools,
  ...performanceTools,
  ...accountTools,
  ...analyticsTools,
  ...conversionTools,
  ...shoppingTools,
];

server.setRequestHandler(ListToolsRequestSchema, async () => {
  return { tools: allTools };
});

// Tool name → { schema, handler } map for clean dispatch
const toolHandlers: Record<string, { schema: any; handler: (args: any) => Promise<any> }> = {
  // Campaigns
  list_campaigns: { schema: listCampaignsSchema, handler: listCampaigns },
  get_campaign: { schema: getCampaignSchema, handler: getCampaign },
  create_campaign: { schema: createCampaignSchema, handler: createCampaign },
  update_campaign: { schema: updateCampaignSchema, handler: updateCampaign },

  // Ad Groups
  list_ad_groups: { schema: listAdGroupsSchema, handler: listAdGroups },
  create_ad_group: { schema: createAdGroupSchema, handler: createAdGroup },
  update_ad_group: { schema: updateAdGroupSchema, handler: updateAdGroup },
  get_ad_group: { schema: getAdGroupSchema, handler: getAdGroup },

  // Ads
  list_ads: { schema: listAdsSchema, handler: listAds },
  create_responsive_search_ad: { schema: createResponsiveSearchAdSchema, handler: createResponsiveSearchAd },
  update_ad: { schema: updateAdSchema, handler: updateAd },
  get_ad_performance: { schema: getAdPerformanceSchema, handler: getAdPerformance },

  // Keywords
  list_keywords: { schema: listKeywordsSchema, handler: listKeywords },
  add_keywords: { schema: addKeywordsSchema, handler: addKeywords },
  add_negative_keywords: { schema: addNegativeKeywordsSchema, handler: addNegativeKeywords },
  update_keyword: { schema: updateKeywordSchema, handler: updateKeyword },
  get_keyword_performance: { schema: getKeywordPerformanceSchema, handler: getKeywordPerformance },

  // Performance & Reports
  get_account_performance: { schema: getAccountPerformanceSchema, handler: getAccountPerformance },
  get_campaign_performance: { schema: getCampaignPerformanceSchema, handler: getCampaignPerformance },
  get_ad_group_performance: { schema: getAdGroupPerformanceSchema, handler: getAdGroupPerformance },
  get_search_terms_report: { schema: getSearchTermsReportSchema, handler: getSearchTermsReport },

  // Accounts
  list_accessible_customers: { schema: listAccessibleCustomersSchema, handler: listAccessibleCustomers },
  get_account_hierarchy: { schema: getAccountHierarchySchema, handler: getAccountHierarchy },
  get_account_info: { schema: getAccountInfoSchema, handler: getAccountInfo },
  list_manager_accounts: { schema: listManagerAccountsSchema, handler: listManagerAccounts },

  // Analytics
  get_top_bottom_keywords: { schema: getTopBottomKeywordsSchema, handler: getTopBottomKeywords },
  get_keyword_opportunities: { schema: getKeywordOpportunitiesSchema, handler: getKeywordOpportunities },
  get_campaign_comparison: { schema: getCampaignComparisonSchema, handler: getCampaignComparison },

  // Conversions
  list_conversion_actions: { schema: listConversionActionsSchema, handler: listConversionActions },
  create_conversion_action: { schema: createConversionActionSchema, handler: createConversionAction },
  update_conversion_action: { schema: updateConversionActionSchema, handler: updateConversionAction },
  get_conversion_stats: { schema: getConversionStatsSchema, handler: getConversionStats },

  // Shopping
  get_product_performance: { schema: getProductPerformanceSchema, handler: getProductPerformance },
  get_product_partition_performance: { schema: getProductPartitionPerformanceSchema, handler: getProductPartitionPerformance },
  get_top_bottom_products: { schema: getTopBottomProductsSchema, handler: getTopBottomProducts },
};

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  const tool = toolHandlers[name];
  if (!tool) {
    throw new McpError(ErrorCode.MethodNotFound, `Unknown tool: ${name}`);
  }

  try {
    const parsedArgs = tool.schema.parse(args);
    const result = await tool.handler(parsedArgs);
    return { content: [{ type: 'text', text: JSON.stringify(result, null, 2) }] };
  } catch (error: any) {
    if (error instanceof McpError) {
      throw error;
    }
    // Google Ads API errors have .errors array with detailed info
    let errorMessage = 'Unknown error occurred';
    if (error?.errors?.length > 0) {
      errorMessage = error.errors.map((e: any) => {
        const code = e.error_code ? JSON.stringify(e.error_code) : '';
        const path = e.location?.field_path_elements?.map((p: any) => p.field_name).join('.') || '';
        return `${e.message}${code ? ` (${code})` : ''}${path ? ` at ${path}` : ''}`;
      }).join('; ');
    } else if (error instanceof Error) {
      errorMessage = error.message;
    } else if (typeof error === 'string') {
      errorMessage = error;
    }
    throw new McpError(ErrorCode.InternalError, `Tool execution failed: ${errorMessage}`);
  }
});

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
}

main().catch((error) => {
  console.error('Fatal error:', error);
  process.exit(1);
});
