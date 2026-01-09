{
  pkgs,
  lib,
  ...
}: {
  # Link LibreWolf NativeMessagingHosts to Mozilla directory
  # This allows LibreWolf to use the same native messaging hosts as Firefox
  home.activation.linkLibreWolfNativeMessaging = lib.hm.dag.entryAfter ["writeBoundary"] ''
    LIBREWOLF_DIR="$HOME/Library/Application Support/LibreWolf"
    MOZILLA_MESSAGING_DIR="$HOME/Library/Application Support/Mozilla/NativeMessagingHosts"
    LIBREWOLF_MESSAGING_DIR="$LIBREWOLF_DIR/NativeMessagingHosts"

    # Create LibreWolf directory if it doesn't exist
    mkdir -p "$LIBREWOLF_DIR"

    # Remove existing NativeMessagingHosts if it's a directory or wrong symlink
    if [ -e "$LIBREWOLF_MESSAGING_DIR" ]; then
      rm -rf "$LIBREWOLF_MESSAGING_DIR"
    fi

    # Create symlink to Mozilla's native messaging directory
    ln -sf "$MOZILLA_MESSAGING_DIR" "$LIBREWOLF_MESSAGING_DIR"
    echo "✓ Linked LibreWolf NativeMessagingHosts to Mozilla directory"
  '';

  home.packages = with pkgs; [
    utm # Virtual machine host for macOS - excellent for running Linux/Windows VMs on Apple Silicon
    slack
  ];
}
