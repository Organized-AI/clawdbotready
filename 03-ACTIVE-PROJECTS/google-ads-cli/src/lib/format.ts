export function table(headers: string[], rows: string[][]): string {
  const widths = headers.map((h, i) =>
    Math.max(h.length, ...rows.map((r) => (r[i] ?? "").length))
  );

  const sep = widths.map((w) => "━".repeat(w + 2)).join("┼");
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

export function header(title: string, width = 70): string {
  const d = "━".repeat(width);
  return `${d}\n  ${title}\n${d}`;
}

export function json(data: unknown): string {
  return JSON.stringify(data, null, 2);
}

export function currency(micros: number): string {
  return `$${microsToDollars(micros).toFixed(2)}`;
}

export function num(value: number): string {
  return value.toLocaleString();
}

export function pct(value: number): string {
  return `${(value * 100).toFixed(2)}%`;
}

export function dollarsToMicros(dollars: number): number {
  return Math.round(dollars * 1_000_000);
}

export function microsToDollars(micros: number): number {
  return micros / 1_000_000;
}
