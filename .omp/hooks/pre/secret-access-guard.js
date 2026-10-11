// Sops secret-access guard for the omp coding agent.
//
// Mirrors the sops prohibition declared in this repository's `opencode.json`:
// decrypted sops material must never be read, and the tools that decrypt or
// edit it must never be invoked. The declarative half of the rule lives in
// `.omp/config.yml` (`bash.patterns`), which denies the plain command forms.
//
// This hook covers what that declarative layer cannot:
//
//   read, grep  - path rules have no approval-policy equivalent in omp.
//   bash        - `bash.patterns` matches literal command text only, so a
//                 wrapped invocation (`bash -c "sops -d f"`, `env sops -d f`)
//                 and any reader other than `cat` (`head`, `sed`, `python`)
//                 would slip through.
//   eval        - the eval tool shells out on its own; `bash.patterns` does not
//                 apply to it at all (see omp's approval-mode documentation).
//
// Denials here are unconditional: a `tool_call` block wins in every approval
// mode, including yolo.

// Paths holding decrypted sops material. `read`/`grep` match these as globs,
// mirroring the OpenCode resource syntax this rule was ported from; shell and
// eval text matches them as literal substrings, because any mention of them in
// an executable payload targets the same material.
const DENIED_PATH_GLOBS = ["/run/secrets/*", "*sops/age/*", "*/var/lib/sops-nix/*"]
const DENIED_PATH_LITERALS = ["/run/secrets/", "sops/age/", "/var/lib/sops-nix/"]

// Commands that decrypt or edit sops-managed plaintext, and the launchers that
// run a command indirectly. Both are matched only in command position, so
// prose and file names stay allowed: `grep -rn sops docs`, `echo "sops"`,
// `cat .sops.yaml`, and `display("sops")` pass, while `sops -d f`,
// `cd /tmp && sops -d f`, `sudo sops f`, `bash -c "sops -d f"`,
// `subprocess.run(["sops", "-d", "f"])`, and `await Bun.$` + `` `sops -d f` ``
// do not.
const LAUNCHERS = [
  "bash",
  "sh",
  "zsh",
  "dash",
  "ash",
  "ksh",
  "env",
  "sudo",
  "doas",
  "xargs",
  "nohup",
  "command",
  "exec",
  "subprocess\\.\\w+",
  "child_process\\.\\w+",
  "os\\.system",
  "Bun\\.\\$",
  "Deno\\.run",
  "spawn\\w*",
  "exec\\w*",
].join("|")

const INVOCATION = "(?:sops|ssh-to-age)\\b|age\\s+(?:-d|--decrypt)\\b"

const DENIED_COMMANDS = new RegExp(
  // A bare command, at the start of the text or after a shell separator.
  `(?:^|[;&|\\n\`(])\\s*(?:${INVOCATION})` +
    // Or a command reached through a launcher, past its options/assignments
    // and any `(`, `[`, or quote that opens the argument.
    `|\\b(?:${LAUNCHERS})\\b(?:(?:\\s+-\\S+)|(?:\\s+\\w+=\\S+))*\\s*[(["'\`]{0,3}\\s*(?:${INVOCATION})`,
)

const REASON = "sops material is protected by repository policy"

const GLOB_PATTERNS = DENIED_PATH_GLOBS.map(
  (glob) => new RegExp(`^${glob.replace(/[.+?^${}()|[\]\\]/g, "\\$&").replace(/\*/g, ".*")}$`),
)

// `read` expands a leading `file://` before touching the filesystem, so the
// guard has to look through the same prefix.
const normalize = (value) => (value.startsWith("file://") ? value.slice("file://".length) : value)

const targetsSecret = (path) =>
  typeof path === "string" && GLOB_PATTERNS.some((pattern) => pattern.test(normalize(path)))

// `grep` accepts several paths as a semicolon-delimited list.
const anyTargetSecret = (path) =>
  typeof path === "string" &&
  path.split(";").some((entry) => entry !== "" && targetsSecret(entry.trim()))

const textTouchesSecret = (text) =>
  typeof text === "string" &&
  (DENIED_PATH_LITERALS.some((literal) => text.includes(literal)) || DENIED_COMMANDS.test(text))

export default function secretAccessGuard(pi) {
  pi.on("tool_call", (event) => {
    const input = event?.input ?? {}
    let denied
    switch (event?.toolName) {
      case "read":
        denied = targetsSecret(input.path)
        break
      case "grep":
        denied = anyTargetSecret(input.path)
        break
      case "bash":
        denied = textTouchesSecret(input.command)
        break
      case "eval":
        denied = textTouchesSecret(input.code)
        break
      default:
        return
    }
    if (!denied) return
    return { block: true, reason: REASON }
  })
}
