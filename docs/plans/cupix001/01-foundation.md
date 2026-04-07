← [Back to Index](00-index.md)

## Epic 1: Foundation

**Goal**: Register `cupix001` in the flake, create skeleton host, declare the `networking.cupix001` option set, set up `private.nix` pattern, update `.gitignore` and `.sops.yaml`. End state: `nix flake check` passes with an empty-but-valid host.

### Story 1.1: Flake Registration

#### Step 1.1.1: Red — Assert cupix001 hostname is not empty

- **Test type**: assertion
- **File**: `tests/assertions/cupix001-invariants.nix`
- **What to test**: `config.networking.hostName == "cupix001"` — wrapped in `lib.mkIf (config.networking.hostName == "cupix001") { assertions = [...]; }` following the pattern in `tests/assertions/thiniel-invariants.nix`. **CRITICAL**: every assertion in this file MUST be inside this `lib.mkIf` guard to avoid firing on thiniel, nixos-vm-minimal, or any other host that imports `tests/assertions/default.nix`.
- **Also**: Create `tests/assertions/cupix001-invariants.nix` with the hostname assertion, add `./cupix001-invariants.nix` import to `tests/assertions/default.nix`
- **Verify**: `nix flake check` — will fail because no `nixosConfigurations.cupix001` exists yet
- **Expected**: FAIL (cupix001 host not registered in flake)

#### Step 1.1.2: Green — Add nixosConfigurations.cupix001 skeleton to flake.nix

- **File**: `flake.nix`
- **What to implement**: Add `nixosConfigurations.cupix001` block following the existing `thiniel` pattern exactly:
  - `system = "x86_64-linux"`
  - `specialArgs = { inherit inputs outputs; pkgs-unstable = (import ./lib/helpers.nix).mkPkgsUnstable { inherit nixpkgs-unstable; system = "x86_64-linux"; }; }`
  - `modules`: overlay inline block, `./hosts/cupix001`, `disko.nixosModules.disko`, `home-manager.nixosModules.home-manager`, HM inline block with `useGlobalPkgs/useUserPackages`, `users.dan = import ./home/dan/cupix001.nix`, `extraSpecialArgs`
  - **Note**: `sops-nix.nixosModules.sops` and `impermanence.nixosModules.impermanence` are imported inside `hosts/cupix001/default.nix` (matching `thiniel` convention), NOT in the flake modules list
- **Also create**:
  - `hosts/cupix001/default.nix` — skeleton with imports: `../common/global`, `../common/users/dan.nix`, `./hardware.nix`, `./options.nix`, `./private.nix`, `../../tests/assertions`, `inputs.sops-nix.nixosModules.sops`, `inputs.impermanence.nixosModules.impermanence`; set `networking.hostName = "cupix001"`, `system.stateVersion = "25.11"`, `nixpkgs.hostPlatform = "x86_64-linux"`, `networking.networkmanager.enable = lib.mkForce false`
  - `home/dan/cupix001.nix` — minimal HM profile importing `./global/default.nix`, setting `home.username = "dan"`, `home.homeDirectory = "/home/dan"`
- **Verify**: `nix flake check`
- **Expected**: PASS (skeleton evaluates; hostname assertion fires and passes)

#### Step 1.1.3: Green — Create hardware.nix stub

- **File**: `hosts/cupix001/hardware.nix`
- **What to implement**: KVM hardware stub — `boot.initrd.availableKernelModules = ["virtio_pci" "virtio_scsi" "virtio_blk" "virtio_net"]`, `boot.loader.grub.enable = true` (BIOS placeholder; will be updated to systemd-boot if UEFI confirmed in prerequisites). Add comment: `# Boot mode determined in prerequisites step 2; update to systemd-boot if UEFI`.
- **Verify**: `nix flake check`
- **Expected**: PASS

#### Step 1.1.4: Green — Create options.nix and private.nix stubs

- **File**: `hosts/cupix001/options.nix` — declares `networking.cupix001` option set (see Story 1.2 for full spec)
- **File**: `hosts/cupix001/private.nix` — placeholder values matching `private.nix.example` (not committed to repo after real values added)
- **File**: `hosts/cupix001/private.nix.example` — template with placeholder values and gathering instructions
- **Verify**: `nix flake check`
- **Expected**: PASS

### Story 1.2: Options Module (networking.cupix001)

#### Step 1.2.1: Red — Assert networking.cupix001 required options fail without values

- **Test type**: assertion (eval-time via NixOS module system — NOT `lib.debug.runTests`, which cannot evaluate a full NixOS module stack)
- **File**: `tests/assertions/cupix001-invariants.nix`
- **What to test**: Add assertion that `config.networking.cupix001.publicIPv4 != ""` — this will fire at eval time if the option has no default and is not set, producing a clear error. Testing `lib.mkOption` type enforcement requires `lib.evalModules`, which is unwieldy; use eval-time assertion guards instead.
- **Verify**: `nix flake check`
- **Expected**: FAIL (options.nix and private.nix don't exist yet, eval fails with undefined option)

#### Step 1.2.2: Green — Implement options.nix

- **File**: `hosts/cupix001/options.nix`
- **What to implement**: Declare `networking.cupix001` with `lib.mkOption` for: `publicIPv4` (types.str, no default), `publicIPv6` (types.str, default ""), `prefixLengthV4` (types.int), `prefixLengthV6` (types.int, default 64), `gateway4` (types.str), `gateway6` (types.str, default ""), `dns` (types.listOf types.str), `wgListenPort` (types.port, default 51820), `wgTunnelIPv4` (types.str), `wgPeerTunnelIPv4` (types.str), `enablePublicSSH` (types.bool, default true), `sshBootstrapPort` (types.port, default 55809), `interfaceName` (types.str, default "ens3")
- **Note**: No unit test file needed — option type enforcement is exercised by `nix flake check` evaluating the cupix001 nixosConfiguration with values from private.nix
- **Verify**: `nix flake check`
- **Expected**: PASS

### Story 1.3: Private File Infrastructure

#### Step 1.3.1: Red — Assert .gitignore contains private.nix entry

- **Test type**: shell check (not a Nix assertion — detecting a `.gitignore` entry cannot be done at Nix eval time)
- **File**: `.gitignore`
- **What to test**: Run `git check-ignore -v hosts/cupix001/private.nix` — exits non-zero if the file is not gitignored
- **Verify**: `git check-ignore -v hosts/cupix001/private.nix` → exits 1 (FAIL — entry not yet added)
- **Expected**: FAIL

**Note on placeholder detection**: Do NOT add a Nix assertion that checks `publicIPv4 != "203.0.113.42"`. Such an assertion would permanently break `nix flake check` for every developer who clones the repo and has not yet replaced placeholder values in `private.nix`. Instead, use the deployment checklist in `docs/cupix001-deployment.md` and the `private.nix.example` template as operational controls.

#### Step 1.3.2: Green — Add .gitignore entry and create private.nix.example

- **File**: `.gitignore`
- **What to implement**: Add line `hosts/cupix001/private.nix`
- **File**: `hosts/cupix001/private.nix.example`
- **What to implement**: Template with all `networking.cupix001` fields, placeholder values (use RFC 5737 documentation IPs like `203.0.113.42`), and gathering instructions as comments for each field
- **Verify**: `git check-ignore -v hosts/cupix001/private.nix` → exits 0 (PASS); `nix flake check` still passes
- **Expected**: PASS

#### Step 1.3.3: Green — Update README.md with private.nix setup instructions

- **File**: `README.md`
- **What to implement**: Add a "Host setup — cupix001" section documenting: (1) copy `hosts/cupix001/private.nix.example` to `hosts/cupix001/private.nix`, (2) fill in real values using the gathering commands, (3) `private.nix` is gitignored and must exist on the build machine before `nix build` or `nix flake check` succeeds for cupix001
- **Verify**: File exists and section is present
- **Expected**: PASS (documentation-only — no `nix flake check` required per project rules)

### Story 1.4: SOPS Configuration

#### Step 1.4.1: Red — Assert sops config references cupix001 secrets file

- **Test type**: assertion
- **File**: `tests/assertions/cupix001-invariants.nix`
- **What to test**: `config.sops.defaultSopsFile` is set (non-null) when hostname is cupix001
- **Verify**: `nix flake check`
- **Expected**: FAIL (sops not configured in cupix001 default.nix yet)

#### Step 1.4.2: Green — Configure SOPS in default.nix and .sops.yaml

- **File**: `hosts/cupix001/default.nix`
- **What to implement**: Add sops configuration. **Age key strategy** (choose one and document rationale in a comment):
  - **Option A (recommended)**: `sops.age.sshKeyPaths = ["/persist/etc/ssh/ssh_host_ed25519_key"];` — derives the age identity from the SSH host key. Requires `/persist/etc/ssh` to be in impermanence persistent paths (covered in Epic 3). No separate age key file to provision.
  - **Option B**: `sops.age.keyFile = "/persist/sops-age-key";` — dedicated age key file. Requires the file to be added to the impermanence persistent files list (`environment.persistence."/persist/system".files`) and provisioned via `--extra-files` in nixos-anywhere.
  - **Note**: Whichever option is chosen, the age key path MUST be on `/persist` — if outside `/persist`, impermanence will wipe it on every reboot and sops-nix will fail to decrypt secrets after the first reboot.
  - Add `sops.defaultSopsFile = ./secrets.yaml; sops.defaultSopsFormat = "yaml";`
- **File**: `.sops.yaml`
- **What to implement**: Add `&cupix001` anchor with host age key placeholder, add `creation_rules` entry for `hosts/cupix001/secrets.yaml` referencing both the cupix001 host key and the `*dan` admin key
- **File**: `hosts/cupix001/secrets.yaml`
- **What to implement**: Create empty sops-encrypted secrets file (or placeholder structure with `sops` metadata)
- **Verify**: `nix flake check`
- **Expected**: PASS

### Story 1.5: Home Manager Minimal Profile

#### Step 1.5.1: Red — Assert HM profile sets correct username

- **Test type**: assertion (eval-time via HM module check)
- **File**: `tests/assertions/cupix001-invariants.nix`
- **What to test**: Verify the cupix001 configuration evaluates successfully with home-manager (implicitly tested by `nix flake check` evaluating all configurations)
- **Verify**: `nix flake check`
- **Expected**: PASS (already done in 1.1.2 — this is a validation checkpoint)

**Note**: This step is a checkpoint, not a new Red-Green cycle.
