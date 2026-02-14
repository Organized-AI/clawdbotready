#!/usr/bin/env npx tsx
/**
 * Gateway Usage Intelligence Analyzer
 *
 * Parses OpenClaw session JSONL files, categorizes user intents,
 * tracks tool usage/failures, and generates actionable reports
 * with skill/agent/CLI tool suggestions.
 *
 * Usage: npx tsx scripts/analyze-gateway-usage.ts [--raw-dir path]
 */

import { readFileSync, readdirSync, writeFileSync, mkdirSync, existsSync, realpathSync } from "fs";
import { join, resolve } from "path";

// ─── Types ───────────────────────────────────────────────────────────────────

interface SessionEntry {
  type: string;
  id?: string;
  timestamp?: string;
  version?: number;
  cwd?: string;
  provider?: string;
  modelId?: string;
  content?: MessageContent;
  // message-type entries embed content differently
  [key: string]: unknown;
}

interface MessageContent {
  role: string;
  content: ContentBlock[];
  timestamp?: number;
}

interface ContentBlock {
  type: string;
  text?: string;
  id?: string;
  name?: string;
  arguments?: Record<string, unknown>;
}

interface UserMessage {
  timestamp: Date;
  rawText: string;
  cleanText: string;
  sender: string;
  senderId: string;
  source: string; // "telegram" | "webchat" | "unknown"
  sessionId: string;
}

interface ToolCall {
  timestamp: Date;
  name: string;
  arguments: Record<string, unknown>;
  sessionId: string;
}

interface ToolResult {
  timestamp: Date;
  toolName: string;
  toolCallId: string;
  success: boolean;
  errorMessage: string | null;
  sessionId: string;
}

interface AssistantResponse {
  timestamp: Date;
  text: string;
  toolCalls: ToolCall[];
  sessionId: string;
}

interface IntentCategory {
  name: string;
  keywords: string[];
  patterns: RegExp[];
}

interface DetectedIntent {
  category: string;
  message: UserMessage;
  confidence: number;
}

interface PainPoint {
  type: string;
  description: string;
  count: number;
  examples: string[];
  severity: "high" | "medium" | "low";
}

interface AutomationSuggestion {
  type: "skill" | "agent" | "cli-tool";
  name: string;
  description: string;
  triggers: string[];
  reason: string;
  priority: "high" | "medium" | "low";
}

interface AnalysisResult {
  period: { start: Date; end: Date };
  sessionCount: number;
  messageCount: number;
  userMessages: UserMessage[];
  assistantResponses: AssistantResponse[];
  toolCalls: ToolCall[];
  toolResults: ToolResult[];
  intents: DetectedIntent[];
  painPoints: PainPoint[];
  suggestions: AutomationSuggestion[];
}

// ─── Intent Categories ───────────────────────────────────────────────────────

const INTENT_CATEGORIES: IntentCategory[] = [
  {
    name: "google-ads-performance",
    keywords: ["cpa", "cpc", "ctr", "impression", "conversion", "spend", "cost", "performance", "doing", "metrics", "results"],
    patterns: [/how.*(campaign|ad).*(doing|perform)/i, /campaign.*performance/i, /check.*(cpa|campaign|ads)/i, /what.*cpa/i],
  },
  {
    name: "google-ads-campaigns",
    keywords: ["campaign", "pmax", "search", "brand", "active", "enabled", "paused", "list"],
    patterns: [/what.*(campaign|pmax).*active/i, /list.*campaign/i, /show.*campaign/i, /active.*campaign/i],
  },
  {
    name: "google-ads-management",
    keywords: ["pause", "enable", "budget", "bid", "change", "update", "set", "adjust"],
    patterns: [/pause.*(campaign|ad)/i, /enable.*(campaign|ad)/i, /(change|set|adjust).*budget/i],
  },
  {
    name: "bot-status",
    keywords: ["working", "online", "alive", "running", "status", "available"],
    patterns: [/are you (working|online|there|alive)/i, /you working/i, /is.*bot.*(working|running)/i],
  },
  {
    name: "reporting",
    keywords: ["report", "summary", "today", "yesterday", "last 7 days", "weekly", "daily", "overview"],
    patterns: [/daily.*report/i, /today.*only/i, /last.*\d+.*day/i, /weekly.*report/i],
  },
  {
    name: "troubleshooting",
    keywords: ["error", "fix", "broken", "not working", "wrong", "issue", "problem", "weird"],
    patterns: [/not.*(working|responding)/i, /something.*wrong/i, /(fix|help).*error/i],
  },
  {
    name: "setup-config",
    keywords: ["setup", "install", "configure", "set up", "skill", "tool", "believe you have"],
    patterns: [/set.*up/i, /was set up/i, /believe.*have.*tool/i, /check.*skill/i],
  },
  {
    name: "general-question",
    keywords: [],
    patterns: [/.*/],
  },
];

// ─── Parsing ─────────────────────────────────────────────────────────────────

function parseSessionFile(filepath: string): SessionEntry[] {
  const content = readFileSync(filepath, "utf-8");
  const entries: SessionEntry[] = [];
  for (const line of content.split("\n")) {
    if (!line.trim()) continue;
    try {
      entries.push(JSON.parse(line));
    } catch {
      // Skip malformed lines
    }
  }
  return entries;
}

function extractSessionId(filepath: string): string {
  const filename = filepath.split("/").pop() || "";
  return filename.replace(".jsonl", "");
}

const TELEGRAM_PREFIX = /^\[Telegram\s+(.+?)\s+\((@\w+)\)\s+id:(\d+)\s+[^\]]+\]\s*/;
const TIMESTAMP_PREFIX = /^\[\w+ \d{4}-\d{2}-\d{2} \d{2}:\d{2} \w+\]\s*/;
const MESSAGE_ID_SUFFIX = /\n?\[message_id:\s*[^\]]+\]\s*$/;

function extractUserMessages(entries: SessionEntry[], sessionId: string): UserMessage[] {
  const messages: UserMessage[] = [];

  for (const entry of entries) {
    if (entry.type !== "message") continue;

    // OpenClaw stores message data in "message" field, not "content"
    const msg = (entry as any).message as MessageContent | undefined;
    if (!msg || msg.role !== "user") continue;

    const blocks = msg.content;
    if (!Array.isArray(blocks)) continue;

    for (const block of blocks) {
      if (block.type !== "text" || !block.text) continue;

      let rawText = block.text;
      let sender = "unknown";
      let senderId = "unknown";
      let source = "unknown";

      // Extract Telegram metadata
      const tgMatch = rawText.match(TELEGRAM_PREFIX);
      if (tgMatch) {
        sender = tgMatch[1];
        senderId = tgMatch[3];
        source = "telegram";
      }

      // Strip metadata prefixes and message ID suffix
      let cleanText = rawText
        .replace(TELEGRAM_PREFIX, "")
        .replace(TIMESTAMP_PREFIX, "")
        .replace(MESSAGE_ID_SUFFIX, "")
        .trim();

      const ts = entry.timestamp
        ? new Date(entry.timestamp)
        : msg.timestamp
          ? new Date(msg.timestamp)
          : new Date();

      messages.push({
        timestamp: ts,
        rawText,
        cleanText,
        sender,
        senderId,
        source,
        sessionId,
      });
    }
  }

  return messages;
}

function extractAssistantData(
  entries: SessionEntry[],
  sessionId: string
): { responses: AssistantResponse[]; toolCalls: ToolCall[]; toolResults: ToolResult[] } {
  const responses: AssistantResponse[] = [];
  const toolCalls: ToolCall[] = [];
  const toolResults: ToolResult[] = [];

  for (const entry of entries) {
    if (entry.type !== "message") continue;

    // OpenClaw stores message data in "message" field
    const msg = (entry as any).message as MessageContent | undefined;
    if (!msg) continue;

    const ts = entry.timestamp
      ? new Date(entry.timestamp)
      : msg.timestamp
        ? new Date(msg.timestamp)
        : new Date();

    if (msg.role === "assistant") {
      const blocks = msg.content;
      if (!Array.isArray(blocks)) continue;

      const textParts: string[] = [];
      const calls: ToolCall[] = [];

      for (const block of blocks) {
        if (block.type === "text" && block.text) {
          textParts.push(block.text);
        } else if (block.type === "toolCall" && block.name) {
          const tc: ToolCall = {
            timestamp: ts,
            name: block.name,
            arguments: (block.arguments as Record<string, unknown>) || {},
            sessionId,
          };
          calls.push(tc);
          toolCalls.push(tc);
        }
      }

      responses.push({
        timestamp: ts,
        text: textParts.join("\n"),
        toolCalls: calls,
        sessionId,
      });
    }

    if (msg.role === "toolResult") {
      const resultContent = msg.content;
      let success = true;
      let errorMessage: string | null = null;

      if (Array.isArray(resultContent)) {
        for (const block of resultContent) {
          const text = block.text || "";
          if (
            text.includes('"status": "error"') ||
            text.includes("error") ||
            text.includes("failed") ||
            text.includes("ENOENT") ||
            text.includes("401") ||
            text.includes("command not found") ||
            text.includes("exit code")
          ) {
            success = false;
            // Extract a concise error
            const errMatch = text.match(/"error":\s*"([^"]+)"/);
            errorMessage = errMatch ? errMatch[1] : text.substring(0, 200);
          }
        }
      }

      toolResults.push({
        timestamp: ts,
        toolName: (msg as any)?.toolName || "unknown",
        toolCallId: (msg as any)?.toolCallId || "unknown",
        success,
        errorMessage,
        sessionId,
      });
    }
  }

  return { responses, toolCalls, toolResults };
}

// ─── Intent Detection ────────────────────────────────────────────────────────

function classifyIntent(msg: UserMessage): DetectedIntent {
  let bestCategory = "general-question";
  let bestScore = 0;

  const text = msg.cleanText.toLowerCase();

  for (const cat of INTENT_CATEGORIES) {
    if (cat.name === "general-question") continue;

    let score = 0;

    // Keyword scoring
    for (const kw of cat.keywords) {
      if (text.includes(kw.toLowerCase())) {
        score += 2;
      }
    }

    // Pattern scoring
    for (const pat of cat.patterns) {
      if (pat.test(text)) {
        score += 3;
      }
    }

    if (score > bestScore) {
      bestScore = score;
      bestCategory = cat.name;
    }
  }

  return {
    category: bestCategory,
    message: msg,
    confidence: Math.min(bestScore / 10, 1),
  };
}

// ─── Pain Point Detection ────────────────────────────────────────────────────

function detectPainPoints(
  toolResults: ToolResult[],
  assistantResponses: AssistantResponse[],
  userMessages: UserMessage[]
): PainPoint[] {
  const painPoints: PainPoint[] = [];

  // 1. Tool failures
  const failuresByTool = new Map<string, { count: number; errors: string[] }>();
  for (const tr of toolResults) {
    if (!tr.success) {
      const existing = failuresByTool.get(tr.toolName) || { count: 0, errors: [] };
      existing.count++;
      if (tr.errorMessage && existing.errors.length < 3) {
        existing.errors.push(tr.errorMessage.substring(0, 150));
      }
      failuresByTool.set(tr.toolName, existing);
    }
  }

  for (const [tool, data] of failuresByTool) {
    painPoints.push({
      type: "tool-failure",
      description: `${tool} failed ${data.count} time(s)`,
      count: data.count,
      examples: data.errors,
      severity: data.count >= 3 ? "high" : data.count >= 2 ? "medium" : "low",
    });
  }

  // 2. "I don't have access" / capability gaps
  const capGaps: string[] = [];
  for (const resp of assistantResponses) {
    if (
      resp.text.match(/don't (currently )?have access/i) ||
      resp.text.match(/unable to find/i) ||
      resp.text.match(/not.*available/i) ||
      resp.text.match(/I'm unable/i) ||
      resp.text.match(/skill.*not found/i)
    ) {
      capGaps.push(resp.text.substring(0, 150));
    }
  }
  if (capGaps.length > 0) {
    painPoints.push({
      type: "capability-gap",
      description: `Agent reported missing capabilities ${capGaps.length} time(s)`,
      count: capGaps.length,
      examples: capGaps.slice(0, 3),
      severity: capGaps.length >= 3 ? "high" : "medium",
    });
  }

  // 3. Repeated similar questions (user asking same thing multiple ways)
  const intentCounts = new Map<string, number>();
  for (const msg of userMessages) {
    const intent = classifyIntent(msg);
    intentCounts.set(intent.category, (intentCounts.get(intent.category) || 0) + 1);
  }

  for (const [intent, count] of intentCounts) {
    if (count >= 3 && intent !== "general-question") {
      painPoints.push({
        type: "repeated-intent",
        description: `"${intent}" asked ${count} times — candidate for automation`,
        count,
        examples: [],
        severity: count >= 5 ? "high" : "medium",
      });
    }
  }

  return painPoints.sort((a, b) => {
    const sevOrder = { high: 0, medium: 1, low: 2 };
    return sevOrder[a.severity] - sevOrder[b.severity] || b.count - a.count;
  });
}

// ─── Suggestion Generation ───────────────────────────────────────────────────

function generateSuggestions(
  intents: DetectedIntent[],
  painPoints: PainPoint[],
  toolCalls: ToolCall[]
): AutomationSuggestion[] {
  const suggestions: AutomationSuggestion[] = [];

  // Group intents by category
  const intentGroups = new Map<string, DetectedIntent[]>();
  for (const i of intents) {
    const group = intentGroups.get(i.category) || [];
    group.push(i);
    intentGroups.set(i.category, group);
  }

  // Suggest skills for repeated domain-specific patterns
  for (const [category, group] of intentGroups) {
    if (category === "general-question" || group.length < 2) continue;

    const examples = group.slice(0, 3).map((g) => g.message.cleanText);

    if (category.startsWith("google-ads")) {
      if (category === "google-ads-performance") {
        suggestions.push({
          type: "skill",
          name: "blade-daily-report",
          description: "Auto-generate daily Blade campaign performance summary with CPA, spend, and conversion metrics",
          triggers: examples,
          reason: `"${category}" intent appeared ${group.length} times`,
          priority: group.length >= 4 ? "high" : "medium",
        });
      }
      if (category === "google-ads-campaigns") {
        suggestions.push({
          type: "cli-tool",
          name: "campaign-status",
          description: "Quick one-liner to list active campaigns with budget and status",
          triggers: examples,
          reason: `"${category}" intent appeared ${group.length} times`,
          priority: "medium",
        });
      }
      if (category === "google-ads-management") {
        suggestions.push({
          type: "agent",
          name: "campaign-manager",
          description: "Multi-step agent for safe campaign modifications (pause/enable/budget) with confirmation",
          triggers: examples,
          reason: `"${category}" intent appeared ${group.length} times`,
          priority: "medium",
        });
      }
    }

    if (category === "reporting") {
      suggestions.push({
        type: "skill",
        name: "scheduled-reports",
        description: "Automated daily/weekly performance summaries sent proactively via Telegram",
        triggers: examples,
        reason: `"${category}" intent appeared ${group.length} times`,
        priority: group.length >= 3 ? "high" : "medium",
      });
    }
  }

  // Suggest fixes for pain points
  for (const pp of painPoints) {
    if (pp.type === "tool-failure" && pp.description.includes("memory_search")) {
      suggestions.push({
        type: "cli-tool",
        name: "fix-memory-search",
        description: "Diagnose and fix OpenAI API key for memory_search embeddings",
        triggers: ["memory search broken", "embeddings 401"],
        reason: pp.description,
        priority: "high",
      });
    }
    if (pp.type === "capability-gap") {
      suggestions.push({
        type: "skill",
        name: "capability-router",
        description: "Smart routing skill that redirects unsupported queries to appropriate tools or suggests alternatives",
        triggers: ["I don't have access", "unable to find"],
        reason: pp.description,
        priority: "medium",
      });
    }
  }

  // Deduplicate by name
  const seen = new Set<string>();
  return suggestions.filter((s) => {
    if (seen.has(s.name)) return false;
    seen.add(s.name);
    return true;
  });
}

// ─── Report Generation ───────────────────────────────────────────────────────

function generateReport(result: AnalysisResult): string {
  const { period, sessionCount, messageCount, userMessages, toolCalls, toolResults, intents, painPoints, suggestions } =
    result;

  const fmtDate = (d: Date) => d.toISOString().split("T")[0];

  // Intent summary
  const intentCounts = new Map<string, { count: number; examples: string[]; successRate: number }>();
  for (const i of intents) {
    const existing = intentCounts.get(i.category) || { count: 0, examples: [], successRate: 0 };
    existing.count++;
    if (existing.examples.length < 2) {
      existing.examples.push(i.message.cleanText.substring(0, 80));
    }
    intentCounts.set(i.category, existing);
  }

  // Tool summary
  const toolSummary = new Map<string, { calls: number; success: number; failure: number; topError: string }>();
  for (const tc of toolCalls) {
    const existing = toolSummary.get(tc.name) || { calls: 0, success: 0, failure: 0, topError: "" };
    existing.calls++;
    toolSummary.set(tc.name, existing);
  }
  for (const tr of toolResults) {
    const existing = toolSummary.get(tr.toolName) || { calls: 0, success: 0, failure: 0, topError: "" };
    if (tr.success) {
      existing.success++;
    } else {
      existing.failure++;
      if (!existing.topError && tr.errorMessage) {
        existing.topError = tr.errorMessage.substring(0, 80);
      }
    }
    toolSummary.set(tr.toolName, existing);
  }

  // Unique senders
  const senders = new Set(userMessages.filter((m) => m.sender !== "unknown").map((m) => m.sender));

  let report = `# Gateway Usage Intelligence Report\n\n`;
  report += `**Period**: ${fmtDate(period.start)} to ${fmtDate(period.end)}\n`;
  report += `**Sessions**: ${sessionCount} | **User Messages**: ${messageCount} | **Tool Calls**: ${toolCalls.length}\n`;
  if (senders.size > 0) {
    report += `**Users**: ${[...senders].join(", ")}\n`;
  }
  report += `\n---\n\n`;

  // Top User Intents
  report += `## Top User Intents\n\n`;
  report += `| Intent | Count | Example | Confidence |\n`;
  report += `|--------|-------|---------|------------|\n`;

  const sortedIntents = [...intentCounts.entries()].sort((a, b) => b[1].count - a[1].count);
  for (const [category, data] of sortedIntents) {
    if (category === "general-question" && data.count < 2) continue;
    const example = data.examples[0] || "-";
    report += `| ${category} | ${data.count} | "${example}" | - |\n`;
  }
  report += `\n`;

  // Tool Usage
  if (toolSummary.size > 0) {
    report += `## Tool Usage\n\n`;
    report += `| Tool | Calls | Success | Failure | Top Error |\n`;
    report += `|------|-------|---------|---------|----------|\n`;

    const sortedTools = [...toolSummary.entries()].sort((a, b) => b[1].calls - a[1].calls);
    for (const [tool, data] of sortedTools) {
      report += `| ${tool} | ${data.calls} | ${data.success} | ${data.failure} | ${data.topError || "-"} |\n`;
    }
    report += `\n`;
  }

  // Pain Points
  if (painPoints.length > 0) {
    report += `## Pain Points\n\n`;
    for (let i = 0; i < painPoints.length; i++) {
      const pp = painPoints[i];
      const badge = pp.severity === "high" ? "**HIGH**" : pp.severity === "medium" ? "MEDIUM" : "low";
      report += `${i + 1}. [${badge}] **${pp.description}**\n`;
      for (const ex of pp.examples) {
        report += `   - \`${ex.substring(0, 120)}\`\n`;
      }
    }
    report += `\n`;
  }

  // Suggested Automations
  if (suggestions.length > 0) {
    report += `## Suggested Automations\n\n`;
    for (const s of suggestions) {
      const typeLabel = s.type === "skill" ? "Skill" : s.type === "agent" ? "Agent" : "CLI Tool";
      const priority = s.priority === "high" ? " **[HIGH PRIORITY]**" : "";
      report += `### ${typeLabel}: \`${s.name}\`${priority}\n`;
      report += `${s.description}\n\n`;
      report += `**Reason**: ${s.reason}\n`;
      report += `**Triggers**: ${s.triggers.map((t) => `"${t}"`).join(", ")}\n\n`;
    }
  }

  // User Message Timeline
  report += `## User Message Timeline\n\n`;
  report += `| Time | Sender | Message | Intent |\n`;
  report += `|------|--------|---------|--------|\n`;
  for (const msg of userMessages) {
    const intent = classifyIntent(msg);
    const time = msg.timestamp.toISOString().substring(0, 16).replace("T", " ");
    const sender = msg.sender !== "unknown" ? msg.sender : msg.source;
    const text = msg.cleanText.substring(0, 60).replace(/\|/g, "\\|");
    report += `| ${time} | ${sender} | ${text} | ${intent.category} |\n`;
  }
  report += `\n`;

  report += `---\n`;
  report += `*Generated ${new Date().toISOString()} by analyze-gateway-usage.ts*\n`;

  return report;
}

// ─── Main ────────────────────────────────────────────────────────────────────

function main() {
  const projectDir = resolve(join(import.meta.dirname || __dirname, ".."));
  const rawDir = process.argv.includes("--raw-dir")
    ? process.argv[process.argv.indexOf("--raw-dir") + 1]
    : join(projectDir, ".analysis", "raw", "latest");
  const reportsDir = join(projectDir, ".analysis", "reports");

  // Resolve symlink (e.g., .analysis/raw/latest -> 2026-02-09)
  const resolvedRawDir = realpathSync(rawDir);
  const sessionsDir = join(resolvedRawDir, "sessions");

  if (!existsSync(sessionsDir)) {
    console.error(`Sessions directory not found: ${sessionsDir}`);
    console.error(`Run: just log-pull`);
    process.exit(1);
  }

  mkdirSync(reportsDir, { recursive: true });

  console.log(`\n[analyze] Parsing sessions from ${sessionsDir}`);

  // Parse all session JSONL files
  const allUserMessages: UserMessage[] = [];
  const allAssistantResponses: AssistantResponse[] = [];
  const allToolCalls: ToolCall[] = [];
  const allToolResults: ToolResult[] = [];
  let sessionCount = 0;

  const files = readdirSync(sessionsDir).filter((f) => f.endsWith(".jsonl"));

  for (const file of files) {
    const filepath = join(sessionsDir, file);
    const sessionId = extractSessionId(filepath);

    console.log(`[analyze]   ${file}`);
    const entries = parseSessionFile(filepath);

    const userMsgs = extractUserMessages(entries, sessionId);
    const { responses, toolCalls, toolResults } = extractAssistantData(entries, sessionId);

    allUserMessages.push(...userMsgs);
    allAssistantResponses.push(...responses);
    allToolCalls.push(...toolCalls);
    allToolResults.push(...toolResults);

    if (userMsgs.length > 0) sessionCount++;
  }

  console.log(`[analyze] Found ${allUserMessages.length} user messages across ${sessionCount} sessions`);
  console.log(`[analyze] Found ${allToolCalls.length} tool calls, ${allToolResults.length} tool results`);

  // Sort by timestamp
  allUserMessages.sort((a, b) => a.timestamp.getTime() - b.timestamp.getTime());

  // Classify intents
  const intents = allUserMessages.map(classifyIntent);

  // Detect pain points
  const painPoints = detectPainPoints(allToolResults, allAssistantResponses, allUserMessages);

  // Generate suggestions
  const suggestions = generateSuggestions(intents, painPoints, allToolCalls);

  // Determine period
  const timestamps = allUserMessages.map((m) => m.timestamp.getTime()).filter((t) => !isNaN(t));
  const periodStart = timestamps.length > 0 ? new Date(Math.min(...timestamps)) : new Date();
  const periodEnd = timestamps.length > 0 ? new Date(Math.max(...timestamps)) : new Date();

  const result: AnalysisResult = {
    period: { start: periodStart, end: periodEnd },
    sessionCount,
    messageCount: allUserMessages.length,
    userMessages: allUserMessages,
    assistantResponses: allAssistantResponses,
    toolCalls: allToolCalls,
    toolResults: allToolResults,
    intents,
    painPoints,
    suggestions,
  };

  // Generate report
  const report = generateReport(result);
  const dateStamp = new Date().toISOString().split("T")[0];
  const reportPath = join(reportsDir, `report-${dateStamp}.md`);
  const latestPath = join(reportsDir, `latest-report.md`);

  writeFileSync(reportPath, report);
  writeFileSync(latestPath, report);

  // Write patterns.json for programmatic consumption
  const patternsPath = join(reportsDir, `patterns.json`);
  const patterns = {
    generated: new Date().toISOString(),
    period: { start: periodStart.toISOString(), end: periodEnd.toISOString() },
    sessionCount,
    messageCount: allUserMessages.length,
    intentSummary: Object.fromEntries(
      intents.reduce((acc, i) => {
        acc.set(i.category, (acc.get(i.category) || 0) + 1);
        return acc;
      }, new Map<string, number>())
    ),
    toolSummary: {
      totalCalls: allToolCalls.length,
      uniqueTools: [...new Set(allToolCalls.map((tc) => tc.name))],
      failureRate:
        allToolResults.length > 0
          ? allToolResults.filter((tr) => !tr.success).length / allToolResults.length
          : 0,
    },
    painPoints: painPoints.map((pp) => ({ type: pp.type, description: pp.description, severity: pp.severity, count: pp.count })),
    suggestions: suggestions.map((s) => ({ type: s.type, name: s.name, description: s.description, priority: s.priority })),
  };
  writeFileSync(patternsPath, JSON.stringify(patterns, null, 2));

  console.log(`\n[analyze] Report written to:`);
  console.log(`[analyze]   ${reportPath}`);
  console.log(`[analyze]   ${latestPath}`);
  console.log(`[analyze]   ${patternsPath}`);
  console.log(`\n[analyze] View: just log-view\n`);
}

main();
