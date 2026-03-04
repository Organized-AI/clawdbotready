export class AuditSuiteError extends Error {
  constructor(
    message: string,
    public readonly code: string,
    public readonly statusCode: number = 500,
  ) {
    super(message);
    this.name = 'AuditSuiteError';
  }
}

export class LeadsieApiError extends AuditSuiteError {
  constructor(message: string, statusCode: number = 502) {
    super(message, 'LEADSIE_API_ERROR', statusCode);
    this.name = 'LeadsieApiError';
  }
}

export class WebhookValidationError extends AuditSuiteError {
  constructor(message: string) {
    super(message, 'WEBHOOK_VALIDATION_ERROR', 400);
    this.name = 'WebhookValidationError';
  }
}

export class PlatformConnectionError extends AuditSuiteError {
  constructor(platform: string, message: string) {
    super(`${platform}: ${message}`, 'PLATFORM_CONNECTION_ERROR', 502);
    this.name = 'PlatformConnectionError';
  }
}

export class AuditEngineError extends AuditSuiteError {
  constructor(platform: string, message: string) {
    super(`${platform} audit failed: ${message}`, 'AUDIT_ENGINE_ERROR', 500);
    this.name = 'AuditEngineError';
  }
}
