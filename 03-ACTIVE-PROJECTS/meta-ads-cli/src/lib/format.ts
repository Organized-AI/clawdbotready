export function table(headers: string[], rows: string[][]): string {
  const widths = headers.map((h, i) =>
    Math.max(h.length, ...rows.map((r) => (r[i] ?? "").length))
  );

  const sep = widths.map((w) => "─".repeat(w + 2)).join("┼");
  const headerLine = headers
    .map((h, i) => ` ${h.padEnd(widths[i])} `)
    .join("│");
  const dataLines = rows.map((row) =>
    row.map((cell, i) => ` ${(cell ?? "").padEnd(widths[i])} `).join("│")
  );

  return [headerLine, sep, ...dataLines].join("\n");
}

export function kv(pairs: [string, string][]): string {
  const maxKey = Math.max(...pairs.map(([k]) => k.length));
  return pairs.map(([k, v]) => `  ${k.padEnd(maxKey)}  ${v}`).join("\n");
}

export function divider(char = "═", width = 60): string {
  return char.repeat(width);
}

export function header(title: string, width = 60): string {
  const d = divider("═", width);
  return `${d}\n  ${title}\n${d}`;
}

export function section(title: string, width = 60): string {
  return divider("─", width) + "\n" + title;
}

export function currency(cents: number | string): string {
  const n = typeof cents === "string" ? parseFloat(cents) : cents;
  // Meta API returns values in the account's currency unit (not micros, not cents — actual currency amount as string)
  return `$${n.toFixed(2)}`;
}

export function pct(value: number | string): string {
  const n = typeof value === "string" ? parseFloat(value) : value;
  return `${n.toFixed(2)}%`;
}

export function num(value: number | string): string {
  const n = typeof value === "string" ? parseInt(value, 10) : Math.round(value);
  return n.toLocaleString();
}

export function json(data: unknown): string {
  return JSON.stringify(data, null, 2);
}
