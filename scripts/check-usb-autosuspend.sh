#!/usr/bin/env bash
# check-usb-autosuspend.sh — Verify USB HID autosuspend state after nixos-rebuild switch
# Usage: bash scripts/check-usb-autosuspend.sh

set -euo pipefail

echo "=== USB Device Power Management Status ==="
echo ""

fail=0

for dev in /sys/bus/usb/devices/*/; do
  [ -f "$dev/idVendor" ] || continue
  vendor=$(cat "$dev/idVendor" 2>/dev/null || echo "????")
  product=$(cat "$dev/idProduct" 2>/dev/null || echo "????")
  manufacturer=$(cat "$dev/manufacturer" 2>/dev/null || echo "unknown")
  prod_name=$(cat "$dev/product" 2>/dev/null || echo "unknown")
  control=$(cat "$dev/power/control" 2>/dev/null || echo "N/A")
  autosuspend=$(cat "$dev/power/autosuspend" 2>/dev/null || echo "N/A")

  # Check if any interface is HID (bInterfaceClass == 03)
  is_hid="no"
  for iface in "$dev"/*/bInterfaceClass; do
    if [ -f "$iface" ] && [ "$(cat "$iface" 2>/dev/null)" = "03" ]; then
      is_hid="yes"
      break
    fi
  done

  if [ "$is_hid" = "yes" ] && [ "$control" != "on" ]; then
    fail=1
  fi

  if [ "$is_hid" = "yes" ]; then
    marker="[HID] "
  else
    marker="      "
  fi

  printf "%s%s:%s %-20s %-20s control=%-6s autosuspend=%s\n" \
    "$marker" "$vendor" "$product" "$manufacturer" "$prod_name" "$control" "$autosuspend"
done

echo ""
echo "=== Summary ==="
echo "HID devices should show: control=on, autosuspend=-1 (or 0)"
echo "Non-HID devices should show: control=auto (managed by powertop)"

if [ "$fail" -ne 0 ]; then
  echo ""
  echo "FAIL: One or more HID devices have autosuspend enabled"
  exit 1
else
  echo ""
  echo "PASS: All HID devices have autosuspend disabled"
fi
