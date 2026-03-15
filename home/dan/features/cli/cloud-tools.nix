{pkgs, ...}: {
  # Cloud development and infrastructure tools
  home.packages = with pkgs; [
    # Google Cloud Platform
    google-cloud-sdk # Complete Google Cloud CLI toolset (gcloud, gsutil, bq)

    # Infrastructure as Code
    tenv # Version manager for OpenTofu, Terraform, Terragrunt, and Atmos
    # terraform        # Managed by tenv; do not install directly

    # Other cloud tools (uncomment as needed)
    # awscli2          # AWS CLI v2
    # azure-cli        # Azure CLI
    # kubectl          # Kubernetes CLI
    # helm             # Kubernetes package manager
    # doctl            # DigitalOcean CLI
  ];

  # Configure gcloud completion for fish
  programs.fish.interactiveShellInit = ''
    # Google Cloud SDK completion
    if test -f "${pkgs.google-cloud-sdk}/google-cloud-sdk/completion.fish.inc"
      source "${pkgs.google-cloud-sdk}/google-cloud-sdk/completion.fish.inc"
    end
  '';

  # Useful aliases for gcloud
  programs.fish.shellAliases = {
    # gcloud shortcuts
    gcp = "gcloud config list project --format='value(core.project)'";
    gcs = "gcloud config set project";
    gcl = "gcloud config list";

    # Common gcloud commands
    gce = "gcloud compute instances list";
    gck = "gcloud container clusters list";
    gcr = "gcloud run services list";

    # gsutil shortcuts
    gsls = "gsutil ls";
    gscp = "gsutil cp";
    gsrm = "gsutil rm";
  };
}
