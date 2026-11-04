// Rule-table driver for Maki's secret-access guard.
//
// Usage: bun tests/unit/maki-secret-guard.mjs <path to secret-guard.lua>
//
// The guard is a Lua plugin that would export `M.rules`, a plain data table it
// hands to `maki.api.register_permission_rule`. That API is the contract that
// matters, but it only exists inside a running Maki, so this driver does not
// run the plugin: it reads the declared rules straight out of the Lua source
// and asserts their shape. A non-zero exit means a rule was added, dropped or
// re-aimed — that is what the flake check reports.
//
// Two properties are load-bearing and easy to lose in a later edit:
//
//   1. `read` and `grep` rules are absent on purpose. Maki's own read and grep
//      handlers dispatch as session-owned Lua tools (`lua:read`), and a rule
//      registered from the repository against them registers successfully and
//      then never fires. A rule that cannot fire is worse than no rule, so the
//      guard omits it and this driver fails if one is ever added back. The
//      residue is recorded as R-036 in docs/arc42/11-risks-and-technical-debt.md.
//   2. No rule of effect `allow` may appear. An allow here would hand a plugin
//      the authority to pre-approve work the user never approved.

import { readFileSync } from "node:fs";

const guardPath = process.argv[2];
if (!guardPath) {
  console.error("usage: maki-secret-guard.mjs <path to secret-guard.lua>");
  process.exit(2);
}

const source = readFileSync(guardPath, "utf8");

/** Every `{ tool = "...", scope = "...", effect = "..." }` table in the file. */
function declaredRules(text) {
  const rules = [];
  const pattern =
    /\{\s*tool\s*=\s*"([^"]+)"\s*,\s*scope\s*=\s*"([^"]+)"\s*,\s*effect\s*=\s*"([^"]+)"\s*\}/g;
  for (const m of text.matchAll(pattern)) {
    rules.push({ tool: m[1], scope: m[2], effect: m[3] });
  }
  return rules;
}

// A rule written across several lines is invisible to the parser, which would
// make a required rule look absent and let an added one go unseen. Refuse the
// file rather than report a verdict about a table it did not read.
const openBraces = (source.match(/\{\s*tool\s*=/g) || []).length;
if (openBraces !== declaredRules(source).length) {
  console.error(`${openBraces} rules declared but only ${declaredRules(source).length} parsed: write each rule on one line`);
  process.exit(1);
}

const rules = declaredRules(source);
const byTool = (tool) => rules.filter((r) => r.tool === tool).map((r) => r.scope);
const bash = byTool("bash");
const write = byTool("write");
const edit = byTool("edit");

// Commands that decrypt or read protected material, and the rule that must
// cover each. A scope matches when it appears in the pattern's glob form; the
// check is deliberately literal so a rewording shows up as a change here.
const requiredBash = [
  ["sops -d secrets.yaml", "sops *"],
  ["cd /tmp && sops -d f", "sops *"],
  ["ssh-to-age -i key.txt", "ssh-to-age *"],
  ["age -d -i key secrets.yaml", "age -d*"],
  ["age --decrypt -i key secrets.yaml", "age --decrypt*"],
];

const protectedTrees = ["/run/secrets", "sops-nix/secrets", "var/lib/sops-nix", "sops/age"];

let failed = 0;
function check(ok, message) {
  if (!ok) failed += 1;
  console.log(`${ok ? "ok  " : "FAIL"} ${message}`);
}

for (const [example, scope] of requiredBash) {
  check(bash.includes(scope), `bash deny ${scope} covers ${example}`);
}

for (const tool of ["write", "edit"]) {
  const scopes = byTool(tool);
  for (const tree of protectedTrees) {
    check(
      scopes.some((s) => s.includes(tree) && s.endsWith("/**")),
      `${tool} deny covers the ${tree} subtree`,
    );
  }
}

check(write.length > 0 && edit.length === write.length, "write and edit cover the same, non-empty set of trees");

const leadingWildcards = bash.filter((s) => s.startsWith("*"));
check(
  leadingWildcards.length === 0,
  `no bash scope starts with a wildcard, which Maki accepts then never matches (found ${leadingWildcards.join(", ")})`,
);

check(byTool("read").length === 0, "no read rule: Maki does not enforce a repository read scope (R-036)");
check(byTool("grep").length === 0, "no grep rule: Maki does not enforce a repository grep scope (R-036)");

// The exact table, so a dropped rule is as visible as a rewording. Update this
// list only together with the decision it encodes.
const expected = [
  "bash sops *",
  "bash ssh-to-age *",
  "bash age -d*",
  "bash age --decrypt*",
  "write /run/secrets/**",
  "edit /run/secrets/**",
  "write /home/dan/.config/sops-nix/secrets/**",
  "edit /home/dan/.config/sops-nix/secrets/**",
  "write /var/lib/sops-nix/**",
  "edit /var/lib/sops-nix/**",
  "write /home/dan/.config/sops/age/**",
  "edit /home/dan/.config/sops/age/**",
];
const actual = rules.map((r) => `${r.tool} ${r.scope}`);
const added = actual.filter((r) => !expected.includes(r));
const removed = expected.filter((r) => !actual.includes(r));
check(added.length === 0, `no rule beyond the decided set (added: ${added.join(", ") || "none"})`);
check(removed.length === 0, `no decided rule is missing (removed: ${removed.join(", ") || "none"})`);

const allows = rules.filter((r) => r.effect === "allow");
check(allows.length === 0, `no allow rule (found ${allows.length})`);

const denies = rules.filter((r) => r.effect === "deny");
check(denies.length === rules.length, "every rule denies");

const wideDenies = rules.filter((r) => ["*", "**", "/*", "/**"].includes(r.scope));
check(wideDenies.length === 0, "no rule denies everything, which would stop all repository work");

console.log(`${rules.length} rules, ${failed} failed checks`);
process.exit(failed === 0 ? 0 : 1);
