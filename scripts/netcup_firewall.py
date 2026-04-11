#!/usr/bin/env python3
"""netcup-firewall — CLI tool to manage netcup vServer firewall rules.

Subcommands:
  backup    Save current firewall rules to a JSON file.
  lockdown  Apply a deny-all inbound policy (kill-switch).
  restore   Restore firewall rules from a previously saved JSON file.
  apply     Apply a named policy template (bootstrap or production).
"""

import argparse
import sys


def parse_args(argv=None):
    """Parse command-line arguments.

    Args:
        argv: List of argument strings. When None, sys.argv[1:] is used.

    Returns:
        argparse.Namespace with parsed arguments.
    """
    parser = argparse.ArgumentParser(
        prog="netcup-firewall",
        description="Manage netcup vServer firewall rules declaratively.",
    )

    subparsers = parser.add_subparsers(dest="command")
    subparsers.required = True  # ensure missing subcommand raises SystemExit

    # --- backup ---
    backup_parser = subparsers.add_parser("backup", help="Save current firewall rules.")
    backup_parser.add_argument(
        "--server",
        required=True,
        help="Target server name.",
    )
    backup_parser.set_defaults(command="backup")

    # --- lockdown ---
    lockdown_parser = subparsers.add_parser(
        "lockdown", help="Apply deny-all inbound policy."
    )
    lockdown_parser.add_argument(
        "--server",
        required=True,
        help="Target server name.",
    )
    lockdown_parser.add_argument(
        "--yes",
        action="store_true",
        default=False,
        help="Skip confirmation prompt.",
    )
    lockdown_parser.set_defaults(command="lockdown")

    # --- restore ---
    restore_parser = subparsers.add_parser(
        "restore", help="Restore firewall rules from a backup file."
    )
    restore_parser.add_argument(
        "--server",
        required=True,
        help="Target server name.",
    )
    restore_parser.add_argument(
        "--file",
        required=True,
        help="Path to the JSON backup file.",
    )
    restore_parser.set_defaults(command="restore")

    # --- apply ---
    apply_parser = subparsers.add_parser(
        "apply", help="Apply a named policy template."
    )
    apply_parser.add_argument(
        "--server",
        required=True,
        help="Target server name.",
    )
    apply_parser.add_argument(
        "--policy",
        required=True,
        choices=["bootstrap", "production"],
        help="Policy template to apply.",
    )
    apply_parser.set_defaults(command="apply")

    return parser.parse_args(argv)


# ---------------------------------------------------------------------------
# Command handlers
# ---------------------------------------------------------------------------


def cmd_backup(args):
    """Handle the backup subcommand."""
    print("Not implemented")
    sys.exit(1)


def cmd_lockdown(args):
    """Handle the lockdown subcommand."""
    print("Not implemented")
    sys.exit(1)


def cmd_restore(args):
    """Handle the restore subcommand."""
    print("Not implemented")
    sys.exit(1)


def cmd_apply(args):
    """Handle the apply subcommand."""
    print("Not implemented — see Epic 15")
    sys.exit(1)


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

_DISPATCH = {
    "backup": cmd_backup,
    "lockdown": cmd_lockdown,
    "restore": cmd_restore,
    "apply": cmd_apply,
}


def main():
    """Parse arguments and dispatch to the appropriate command handler."""
    args = parse_args()
    handler = _DISPATCH.get(args.command)
    if handler is None:
        # Should not happen because subparsers.required = True, but be safe.
        parse_args(["--help"])
        sys.exit(1)
    handler(args)


if __name__ == "__main__":
    main()
