= Nix Configuration Improvement Todo List
:toc: left
:toclevels: 3
:sectnums:
:icons: font

Based on the comprehensive configuration review, here's a prioritized action plan for enhancing the nix-darwin setup.

== 🚨 High Priority - Fix Anti-patterns

=== Remove imperative package management aliases

* [ ] **Remove imperative package management aliases** from link:../home/dan/features/cli/zsh.nix[`zsh.nix`]
** Remove or comment out `ne = "nix-env"` alias (line 54)
** Add warning comment about avoiding `nix-env -i` for permanent installations
** Update documentation to emphasize declarative alternatives

* [ ] **Add declarative alternatives documentation**
** Create examples showing how to add packages via `home.packages` instead of `nix-env`
** Document how to use `nix shell` for temporary tool access
** Add section on why imperative package management breaks reproducibility

== 🔧 Short-term Enhancements (1-2 weeks)

=== Security Improvements

* [ ] **Implement GPG signing for Git commits**
** Add GPG key management to SOPS secrets
** Configure conditional GPG signing per identity
** Document key generation and management procedures

* [ ] **Document SOPS key backup procedures**
** Create backup strategy for age keys
** Document key rotation procedures
** Add recovery instructions for lost keys

=== Configuration Enhancements

* [ ] **Create package overlays for customizations**
** Add `overlays/` directory structure
** Create example overlay for package modifications
** Document overlay usage patterns

* [ ] **Add user-level service management**
** Identify candidates for Home Manager services
** Implement background services (e.g., backup scripts, sync tools)
** Document service management patterns

=== Development Workflow

* [ ] **Add configuration validation scripts**
** Create pre-commit hooks for `nix flake check`
** Add CI/CD pipeline for testing configurations
** Document testing procedures for new features

== 📊 Medium-term Goals (1-2 months)

=== Multi-host Support

* [ ] **Prepare for additional macOS machines**
** Abstract host-specific configurations
** Create shared module library
** Document host addition procedures

* [ ] **Create reusable module templates**
** Standardize feature module patterns
** Create scaffolding for new features
** Document module development guidelines

=== Enhanced Functionality

* [ ] **Implement custom derivations**
** Identify packages that need customization
** Create `pkgs/` directory for custom packages
** Document package creation workflow

* [ ] **Add development environment automation**
** Create project-specific `shell.nix` templates
** Implement `direnv` integration for automatic environments
** Document development workflow patterns

=== Documentation Expansion

* [ ] **Create troubleshooting guides**
** Common build failures and solutions
** SOPS troubleshooting procedures
** Performance optimization tips

* [ ] **Add migration guides**
** From imperative to declarative package management
** Upgrading between NixOS versions
** Adding new features safely

== 🚀 Long-term Vision (3-6 months)

=== Cross-platform Preparation

* [ ] **Structure for Linux compatibility**
** Abstract platform-specific configurations
** Create shared cross-platform modules
** Plan NixOS integration strategy

* [ ] **Infrastructure as Code integration**
** Evaluate cloud resource management needs
** Plan integration with deployment tools
** Document infrastructure patterns

=== Advanced Features

* [ ] **Custom NixOS modules development**
** Identify reusable system patterns
** Create custom options and modules
** Contribute back to community

* [ ] **Automated backup and sync**
** Implement configuration backup automation
** Create sync strategies for multiple machines
** Document disaster recovery procedures

== 📝 Documentation Tasks

=== Immediate Updates

* [ ] **Update README with anti-pattern warnings**
** Add section on avoiding imperative package management
** Include troubleshooting for common mistakes
** Document best practices clearly

* [ ] **Create feature addition workflow guide**
** Step-by-step module creation process
** Testing and validation procedures
** Integration best practices

=== Content Expansion

* [ ] **Add real-world usage examples**
** Common development scenarios
** Multi-project identity management
** Tool integration patterns

* [ ] **Create video or interactive tutorials**
** Configuration walkthrough
** Feature demonstration
** Troubleshooting sessions

== 🔍 Monitoring and Maintenance

=== Regular Tasks

* [ ] **Set up automated dependency updates**
** Weekly `flake.lock` update checks
** Automated testing of updates
** Rollback procedures for failures

* [ ] **Performance monitoring**
** Build time tracking
** Configuration size monitoring
** System resource usage analysis

=== Quality Assurance

* [ ] **Implement configuration testing**
** Automated build verification
** Feature functionality testing
** Documentation accuracy checks

* [ ] **Code review processes**
** Peer review for significant changes
** Security review for secrets handling
** Performance impact assessment

== 📅 Priority Ranking

[cols="1,3",options="header"]
|===
|Timeframe |Focus Areas

|**Week 1**
|Fix anti-patterns, add GPG signing, create overlays structure

|**Week 2**
|Implement user services, add validation scripts, update documentation

|**Month 1**
|Multi-host preparation, custom derivations, troubleshooting guides

|**Month 2-3**
|Cross-platform preparation, advanced features, automation

|**Ongoing**
|Regular maintenance, monitoring, quality assurance
|===
