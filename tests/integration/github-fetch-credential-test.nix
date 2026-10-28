# tests/integration/github-fetch-credential-test.nix
# Integration test: a booted device materialises the GitHub fetch credential its
# configuration declares, at the declared path with the declared owner and mode,
# and presents it to the GitHub host for the owner's account and for root, with
# nothing prepared in the environment; no other local account can read it.
# Run: nix build .#checks.<linux-system>.integration-github-fetch-credential
{
  pkgs,
  sops-nix,
  ...
}:
let
  # The credential value the fixture encrypts. It is a dummy, and the fixture's
  # key pair is generated inside the derivation, so no key is recorded in the
  # repository (the repository's gitleaks rules refuse a recorded
  # `AGE-SECRET-KEY-1…`). See design.md, rejected alternative 7.
  fixtureValue = "ghp-githubfetchcredentialfixture";

  fixture =
    pkgs.runCommand "github-fetch-credential-fixture"
      {
        nativeBuildInputs = [
          pkgs.age
          pkgs.sops
        ];
        inherit fixtureValue;
      }
      ''
        export HOME=$TMPDIR
        mkdir -p $out
        age-keygen -o $out/keys.txt
        recipient=$(age-keygen -y $out/keys.txt)
        printf 'github:\n    access-token: %s\n' "$fixtureValue" > secrets.yaml
        sops --encrypt --age "$recipient" --input-type yaml --output-type yaml secrets.yaml > $out/secrets.yaml
      '';
in
pkgs.testers.runNixOSTest {
  name = "github-fetch-credential";

  nodes.machine = {
    imports = [
      sops-nix.nixosModules.sops
      ../../modules/nixos/github-fetch-credential
    ];

    mySystem.githubFetchCredential = {
      enable = true;
      user = "owner";
    };

    sops = {
      defaultSopsFile = "${fixture}/secrets.yaml";
      defaultSopsFormat = "yaml";
      age.keyFile = "/run/github-fetch-credential-test/age-key.txt";
      # The sops file is a derivation output. A pure evaluation
      # (`nix flake check --no-build`) has not realized it, so sops-nix's
      # eval-time pathExists check cannot run; the VM test build realizes it.
      validateSopsFiles = false;
    };

    # The age key reaches the guest at a runtime path. This boot runs the system
    # activation from the initrd, before the real systemd (and its
    # systemd-tmpfiles-setup) starts, so the rule must be an initrd one to be
    # in place before the render.
    boot.initrd.systemd.tmpfiles.settings."github-fetch-credential" = {
      "/run/github-fetch-credential-test".d = {
        mode = "0700";
        user = "root";
        group = "root";
      };
      "/run/github-fetch-credential-test/age-key.txt".C = {
        mode = "0600";
        user = "root";
        group = "root";
        argument = "${fixture}/keys.txt";
      };
    };

    virtualisation.additionalPaths = [ fixture ];
    boot.initrd.systemd.storePaths = [ fixture ];

    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    users.users.owner.isNormalUser = true;
    users.users.other.isNormalUser = true;

    system.stateVersion = "26.05";
  };

  testScript = ''
    machine.start()
    machine.wait_for_unit("multi-user.target")

    # The fragment exists at the declared path, owned by the declared account
    # with mode 0400.
    assert machine.succeed("stat -c '%a %U' /run/secrets/rendered/nix-github-access-tokens").strip() == "400 owner"

    # The owner's account and root both present the declared credential, with
    # nothing prepared in the environment.
    owner = machine.succeed("sudo -u owner nix config show access-tokens")
    assert "github.com=${fixtureValue}" in owner, owner
    root = machine.succeed("nix config show access-tokens")
    assert "github.com=${fixtureValue}" in root, root

    # No other local account can read the fragment.
    machine.fail("sudo -u other cat /run/secrets/rendered/nix-github-access-tokens")

    # The value is in no configuration file; the machine configuration only
    # names the path (the fixture's own store paths are out of scope).
    conf = machine.succeed("cat /etc/nix/nix.conf")
    assert "!include /run/secrets/rendered/nix-github-access-tokens" in conf, conf
    assert "${fixtureValue}" not in conf, conf
    machine.fail("grep -rl '${fixtureValue}' /etc")
    machine.fail("grep -rl '${fixtureValue}' /home")
  '';
}
