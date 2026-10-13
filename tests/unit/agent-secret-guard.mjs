// Verdict driver for the coding agent's secret-access guard.
//
// Usage: bun tests/unit/agent-secret-guard.mjs <path to secret-access-guard.js>
//
// The hook is an agent plugin: it registers a `tool_call` handler on the
// runtime object the agent passes in. This driver supplies a minimal stand-in
// for that object, captures the handler, and asserts the guard's verdict for
// each recorded tool call. A non-zero exit means a verdict changed — that is
// what the flake check `unit-agent-secret-guard` reports.
//
// The cases below are the guard's contract, not its implementation: a refusal
// for anything that names a decrypted path the guard declares protected
// (`/run/secrets/*`, an age key under a `sops/age/` path, `/var/lib/sops-nix/*`)
// or a decryption command, and no verdict for ordinary repository work. Paths
// outside that declared set — including the user-side sops-nix secret directory
// — are not refused; that property is accepted rather than closed, and is
// recorded as R-021 in docs/arc42/11-risks-and-technical-debt.md.

import { pathToFileURL } from "node:url";

const hookPath = process.argv[2];
if (!hookPath) {
  console.error("usage: agent-secret-guard.mjs <path to secret-access-guard.js>");
  process.exit(2);
}

const runtimeSecrets = "/run/secrets/context7/api-key";
const ageKey = "/home/user/.config/sops/age/keys.txt";
const sopsNix = "/var/lib/sops-nix/key.txt";

/** @type {{tool: string, input: Record<string, string>, refused: boolean, why: string}[]} */
const cases = [
  // Decrypted material may not be read or searched.
  { tool: "read", input: { path: runtimeSecrets }, refused: true, why: "read of a decrypted runtime secret" },
  { tool: "read", input: { path: ageKey }, refused: true, why: "read of an age private key" },
  { tool: "grep", input: { path: sopsNix }, refused: true, why: "grep over a decrypted secret" },
  { tool: "grep", input: { path: `${runtimeSecrets};docs` }, refused: true, why: "grep over a path list naming a secret" },

  // Decryption commands may not be run, in any form.
  { tool: "bash", input: { command: "sops -d hosts/thiniel/secrets.yaml" }, refused: true, why: "a bare decryption command" },
  { tool: "bash", input: { command: "cd /tmp && sops -d f" }, refused: true, why: "a decryption command after a shell separator" },
  { tool: "bash", input: { command: "env sops -d f" }, refused: true, why: "a decryption command behind a launcher" },
  { tool: "bash", input: { command: "ssh-to-age -i /var/lib/sops-nix/key.txt" }, refused: true, why: "the age-key derivation tool" },
  { tool: "bash", input: { command: "age --decrypt -i key.txt secrets.yaml" }, refused: true, why: "age decryption" },
  { tool: "eval", input: { code: "await Bun.$`sops -d f`" }, refused: true, why: "a decryption command inside an eval payload" },

  // Ordinary repository work is not refused.
  { tool: "read", input: { path: "docs/GIVN-VERIFICATION.md" }, refused: false, why: "an ordinary repository file" },
  { tool: "read", input: { path: ".sops.yaml" }, refused: false, why: "the encrypted-recipient file, which holds no plaintext" },
  { tool: "grep", input: { path: "docs;givn" }, refused: false, why: "a path list with no secret" },
  { tool: "bash", input: { command: "grep -rn sops docs" }, refused: false, why: "a search that only mentions the word" },
  { tool: "bash", input: { command: "cat .sops.yaml" }, refused: false, why: "reading the encrypted-recipient file" },
  { tool: "bash", input: { command: "git status --porcelain" }, refused: false, why: "an ordinary command" },
  { tool: "eval", input: { code: "1 + 1" }, refused: false, why: "an ordinary eval payload" },
];

const handlers = new Map();
const agentStandIn = {
  on: (event, handler) => {
    handlers.set(event, handler);
  },
};

const hook = (await import(pathToFileURL(hookPath).href)).default;
hook(agentStandIn);

const toolCall = handlers.get("tool_call");
if (typeof toolCall !== "function") {
  console.error(`the hook registered no tool_call handler (registered: ${[...handlers.keys()].join(", ") || "none"})`);
  process.exit(1);
}

let failed = 0;
for (const testCase of cases) {
  const verdict = toolCall({ toolName: testCase.tool, input: testCase.input });
  const refused = Boolean(verdict && verdict.block);
  const ok = refused === testCase.refused;
  if (!ok) failed += 1;
  const got = refused ? `refused (${verdict.reason})` : "passed";
  console.log(
    `${ok ? "ok  " : "FAIL"} ${testCase.tool} ${JSON.stringify(testCase.input)} -> ${got}` +
      `${ok ? "" : ` [expected ${testCase.refused ? "refusal" : "no verdict"}: ${testCase.why}]`}`,
  );
}

console.log(`${cases.length - failed}/${cases.length} verdicts as expected`);
process.exit(failed === 0 ? 0 : 1);
