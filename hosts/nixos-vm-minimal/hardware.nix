{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  # Boot configuration optimized for UTM
  boot = {
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "virtio_pci"
        "usbhid"
        "usb_storage"
        "sr_mod"
        "virtio_blk"
        # LUKS encryption modules
        "dm_crypt"
        "aes"
        "cryptd"
        # Network modules for remote unlocking
        "virtio_net"
      ];
      kernelModules = [];

      # Enable network in initrd for remote LUKS unlocking
      network = {
        enable = true;

        # Enable DHCP client explicitly
        udhcpc.enable = true;

        # Explicit network initialization and debugging
        postCommands = ''
          echo "=== initrd Network Setup Debug ==="

          # Wait for network modules to load
          sleep 2

          # Force network interface up and DHCP with retries
          echo "Initializing network..."
          network_configured=false

          for iface in enp0s1 eth0 ens3 enp1s0; do
            if ip link show "$iface" 2>/dev/null; then
              echo "Found network interface: $iface"

              # Bring interface up
              ip link set "$iface" up
              sleep 1

              # Try DHCP multiple times
              for attempt in 1 2 3; do
                echo "DHCP attempt $attempt on $iface..."
                if udhcpc -i "$iface" -t 10 -T 3 -A 1; then
                  echo "DHCP successful on attempt $attempt"
                  network_configured=true
                  break
                fi
                sleep 2
              done

              # Check if we got an IP
              if ip addr show "$iface" | grep "inet "; then
                echo "Network configured successfully:"
                ip addr show "$iface"
                ip route show
                echo "Testing connectivity..."
                ping -c 1 8.8.8.8 || echo "No internet connectivity"
                network_configured=true
                break
              fi
            fi
          done

          if [ "$network_configured" = "false" ]; then
            echo "WARNING: Network configuration failed!"
            echo "Available interfaces:"
            ip link show
          fi

          echo "Available LUKS devices:"
          ls -la /dev/disk/by-partlabel/ 2>/dev/null || echo "No by-partlabel directory"
          echo "Available block devices:"
          ls -la /dev/vd* /dev/sd* 2>/dev/null || echo "No block devices found"

          echo "Checking if LUKS device is already unlocked:"
          ls -la /dev/mapper/ 2>/dev/null || echo "No /dev/mapper directory"

          # Verify cryptsetup-askpass is available
          echo "cryptsetup-askpass location:"
          which cryptsetup-askpass || echo "cryptsetup-askpass not found"
          ls -la /bin/cryptsetup-askpass || echo "/bin/cryptsetup-askpass not found"
        '';

        # SSH server in initrd - enable after key generation
        ssh = {
          enable = true; # Enable SSH for testing
          port = 2222; # Use different port to avoid conflicts

          # Use cryptsetup-askpass as shell for automatic LUKS prompting
          shell = "/bin/cryptsetup-askpass";

          # SSH host keys for initrd (generate with scripts/generate-initrd-keys.sh)
          hostKeys = [
            "/etc/secrets/initrd/ssh_host_rsa_key"
            "/etc/secrets/initrd/ssh_host_ed25519_key"
          ];

          # Authorized keys for root user in initrd
          authorizedKeys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEWvGgnlCq6l+ObGMVLLs34CP0vEX+Edf7sx6/3BvDpQ dan"
          ];
        };
      };
    };

    kernelModules = [];

    # Enable virtio modules for better VM performance
    kernelParams = [
      "console=ttyS0,115200n8"
      "console=tty0"
    ];

    extraModulePackages = [];

    # UEFI boot configuration for VM
    loader = {
      grub.enable = false; # Explicitly disable GRUB
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  # Filesystem configuration is handled by disko.nix
  # No swap for VM
  swapDevices = [];

  # Network interfaces
  networking.useDHCP = lib.mkDefault true;

  # Hardware platform
  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

  # VM-specific optimizations
  services = {
    # Enable SPICE agent for better integration
    spice-vdagentd.enable = true;

    # QEMU guest agent for VM management
    qemuGuest.enable = true;
  };

  # Video drivers for UTM
  services.xserver = {
    enable = false; # We'll start minimal without X11
    videoDrivers = ["qxl"];
  };

  # Power management for VMs
  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";

  # Memory and CPU optimizations for virtualization
  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
    "vm.dirty_ratio" = 15;
    "vm.dirty_background_ratio" = 5;
  };
}
