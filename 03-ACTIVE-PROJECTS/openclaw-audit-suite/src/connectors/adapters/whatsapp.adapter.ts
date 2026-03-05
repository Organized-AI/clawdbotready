import { BasePlatformAdapter } from './base.js';
import type { PlatformType, ConnectionResult } from '../../shared/types.js';
import { createChildLogger } from '../../shared/logger.js';
import { PlatformConnectionError } from '../../shared/errors.js';

const log = createChildLogger('whatsapp-adapter');

export interface WhatsAppConfig {
  phoneNumberId: string;
  accessToken: string;
  businessAccountId: string;
}

export interface WhatsAppData {
  templates: WATemplate[];
  conversationMetrics: WAConversationMetrics;
  automationRules: WAAutomationRule[];
}

export interface WATemplate {
  id: string;
  name: string;
  status: string;
  category: string;
  language: string;
  sentCount: number;
  deliveredCount: number;
  readCount: number;
}

export interface WAConversationMetrics {
  totalConversations: number;
  avgResponseTimeMinutes: number;
  automatedResponses: number;
  humanResponses: number;
  responseRate: number;
}

export interface WAAutomationRule {
  id: string;
  name: string;
  trigger: string;
  isActive: boolean;
  triggerCount: number;
}

export class WhatsAppAdapter extends BasePlatformAdapter<WhatsAppConfig, WhatsAppData> {
  readonly platform: PlatformType = 'whatsapp_business';
  private config?: WhatsAppConfig;

  async connect(config: WhatsAppConfig): Promise<ConnectionResult> {
    log.info({ phoneNumberId: config.phoneNumberId }, 'Connecting to WhatsApp Business');
    this.config = config;
    try {
      await this.ping();
      return { success: true, platformId: config.phoneNumberId };
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Unknown error';
      return { success: false, platformId: config.phoneNumberId, error: message };
    }
  }

  async pullData(_connectionId: string): Promise<WhatsAppData> {
    if (!this.config) throw new PlatformConnectionError('whatsapp_business', 'Not connected');
    log.info('Pulling WhatsApp Business data');

    const [templates, conversationMetrics, automationRules] = await Promise.all([
      this.fetchTemplates(),
      this.fetchConversationMetrics(),
      this.fetchAutomationRules(),
    ]);

    return { templates, conversationMetrics, automationRules };
  }

  async disconnect(_connectionId: string): Promise<void> {
    this.config = undefined;
  }

  protected async ping(): Promise<void> {
    if (!this.config) throw new PlatformConnectionError('whatsapp_business', 'Not connected');
  }

  private async fetchTemplates(): Promise<WATemplate[]> { return []; }
  private async fetchConversationMetrics(): Promise<WAConversationMetrics> {
    return { totalConversations: 0, avgResponseTimeMinutes: 0, automatedResponses: 0, humanResponses: 0, responseRate: 0 };
  }
  private async fetchAutomationRules(): Promise<WAAutomationRule[]> { return []; }
}
