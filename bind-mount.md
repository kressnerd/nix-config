When using the **impermanence** module on a NixOS host to run virtual machines or containers, you must persist specific state directories to ensure your VMs, containers, and images survive reboots.

Here are the directories you should generally add to your `persistence` configuration, categorized by the tool you are using.

### 1. Libvirt (KVM/QEMU)
If you are using `libvirtd` (often with `virt-manager`), this is the most critical directory. It contains your VM disk images (`.qcow2`), NVRAM variables (UEFI settings), and network state.

*   **Directory:** `/var/lib/libvirt`

**Why:**
*   `/var/lib/libvirt/images`: Stores the actual VM disk files.
*   `/var/lib/libvirt/qemu`: Stores temporary state and NVRAM.
*   `/var/lib/libvirt/dnsmasq`: Stores DHCP leases for your VM networks (important so VMs keep the same IP).

### 2. Podman & OCI Containers
Podman stores images, container layers, and volumes in the `containers` directory. It also relies on CNI (Container Network Interface) for networking persistence.

*   **Directories:**
    *   `/var/lib/containers`
    *   `/var/lib/cni` (Recommended for network consistency)

### 3. Docker
Docker requires its root data directory to be persisted to keep images and volumes.

*   **Directory:** `/var/lib/docker`

### 4. LXD / LXC
If you are using Linux Containers (LXC) or the LXD daemon.

*   **Directories:**
    *   `/var/lib/lxd` (or `/var/lib/lxc`)
    *   `/var/lib/lxcfs`

### 5. Common System Requirements
While not specific to virtualization tools, these files are critical for stable networking (bridges/interfaces) which virtualization relies heavily on.

*   **Files:**
    *   `/etc/machine-id`: Ensures the host maintains a consistent ID for DHCP leases and network logs. [^1]
    *   `/etc/ssh/ssh_host_*`: If you access your host or move images via SSH.

### Example Configuration
Here is how this might look in your `impermanence` block (usually in `configuration.nix`):

```nix
environment.persistence."/persist" = {
  directories = [
    # Libvirt / KVM
    "/var/lib/libvirt"
    
    # Podman
    "/var/lib/containers"
    "/var/lib/cni"
    
    # Docker (if used)
    # "/var/lib/docker"
  ];
  files = [
    "/etc/machine-id"
  ];
};
```

**Note on Storage:** Virtual machine disk images (inside `/var/lib/libvirt/images`) can be very large. If you are using a filesystem like ZFS or Btrfs, you might prefer creating a dedicated dataset/subvolume for `/var/lib/libvirt` rather than using the impermanence bind-mount mechanism, as bind-mounting large changing files can sometimes have performance overhead or backup complications.

[^1]: [What does impermanence add over built-in functionality?](https://discourse.nixos.org/t/what-does-impermanence-add-over-built-in-functionality/27939) (100%)


To resolve the "bind-mount problem" and avoid "double CoW" (Copy-on-Write) on your LVM+Btrfs setup, you should bypass the `impermanence` module for these specific directories and instead mount a dedicated Btrfs subvolume directly.

Here is the configuration strategy:

### 1. Bypass Impermanence (The "Bind-Mount" Solution)
The `impermanence` module uses bind-mounts to link folders from your persistence storage (e.g., `/persist`) to your root. For high-performance virtualization data, bind-mounts add unnecessary complexity.

Instead of listing these directories in `environment.persistence`, define them as **dedicated filesystems**. This mounts the Btrfs subvolume directly to the target path, skipping the bind-mount logic entirely.

### 2. Disable Copy-on-Write (The "Double CoW" Solution)
You cannot use the `nodatacow` mount option for a single subvolume if your main filesystem is Btrfs (mount options usually apply to the whole partition). Instead, you must apply the `+C` (NoCoW) file attribute to the directory/subvolume.

The best way to automate this in NixOS is using `systemd.tmpfiles.rules`.

### Configuration Example

Assuming you have created a Btrfs subvolume named `@libvirt` on your LVM logical volume (e.g., `/dev/vg0/root`), here is how your `configuration.nix` should look:

```nix
{ config, pkgs, ... }:

{
  # 1. Do NOT include /var/lib/libvirt in your impermanence block.
  # environment.persistence."/persist".directories = [ ... ]; <--- remove libvirt from here

  # 2. Mount the subvolume directly
  fileSystems."/var/lib/libvirt" = {
    device = "/dev/vg0/root";       # Your LVM/Btrfs device
    fsType = "btrfs";
    options = [ "subvol=@libvirt" "noatime" ]; # Note: 'nodatacow' mount option does NOT work here per-subvol
  };

  # 3. Apply NoCoW attribute (+C) automatically
  # The 'h' type sets file attributes. This ensures new files inherit NoCoW.
  systemd.tmpfiles.rules = [
    "h /var/lib/libvirt - - - - +C"
  ];
}
```

### Manual Steps (First Time Setup)
Since attributes like `+C` only apply to **new** files and must be set on an empty directory/subvolume to be fully effective, perform these steps once before deploying the config:

1.  **Create the subvolume:**
    ```bash
    sudo mount /dev/vg0/root /mnt
    sudo btrfs subvolume create /mnt/@libvirt
    ```
2.  **Set the NoCoW attribute on the empty subvolume:**
    ```bash
    sudo chattr +C /mnt/@libvirt
    ```
3.  **Unmount:**
    ```bash
    sudo umount /mnt
    ```
4.  **Rebuild NixOS:** Now apply your new configuration.

### Why this works
*   **No Bind-Mount:** By using `fileSystems`, Linux mounts the storage directly. This isolates the VM I/O from your root filesystem's snapshotting or rollback operations.
*   **No Double CoW:** The `chattr +C` attribute disables Btrfs checksumming and CoW logic for that specific folder. This allows the VM's internal filesystem (e.g., inside a `.qcow2` file) to handle data integrity without the host Btrfs layer interfering, significantly improving performance. [^1][^2]

[^1]: [LUKS BTRFS swap subvolume ignoring mountOptions #493](https://github.com/nix-community/disko/issues/493) (65%)
[^2]: [Should I enable nodatacow for /nix on btrfs for improving ...](https://www.reddit.com/r/NixOS/comments/10ovjso/should_i_enable_nodatacow_for_nix_on_btrfs_for/) (35%)

