# 8. Cross-cutting Concepts

<!-- Concepts, principles, and patterns that are relevant across multiple parts
     of the architecture: error handling, security, persistence, UI, logging,
     configuration, testability, etc. -->

<!-- Repeat for each cross-cutting concept: -->

## Per-host identity declaration

A device presents only the identity material it holds, and it states that
material in one place: the host user module declares the private key of its
personal identity (`myHome.ssh.personalIdentityFile`) and the manually
maintained `ssh_config` files it keeps (`myHome.ssh.includedConfigs`).

Shared feature modules render from that declaration: the SSH feature renders the
personal connection entry and the workspace identity configuration from the
declared key path, and renders a work identity entry only where the host
declares that identity's secret material. Device and platform differences are
therefore declared per host, never branched on the platform inside a shared
feature, and no device inherits another device's identity surface.

Rationale: two devices that belong to the same owner do not hold the same keys
or the same work relationships. A shared feature module that hardcodes one
device's key paths fails closed on the other device — access is denied with no
usable key — while hiding which key the device was supposed to present.

Constraint: an identity file path is a declaration, not a guarantee. Nothing in
the configuration checks that the file exists; the declaration is proven on the
device (`ssh -G <connection>`) after activation, and its failure mode is
fail-closed (no key presented).
