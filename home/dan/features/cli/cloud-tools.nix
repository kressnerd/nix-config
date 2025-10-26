{pkgs, ...}: {
  # Cloud development and infrastructure tools
  home.packages = with pkgs; [
    # Google Cloud Platform
    google-cloud-sdk # Complete Google Cloud CLI toolset (gcloud, gsutil, bq)

    # Other cloud tools (uncomment as needed)
    # awscli2          # AWS CLI v2
    # azure-cli        # Azure CLI
    # terraform        # Infrastructure as Code
    # kubectl          # Kubernetes CLI
    # helm             # Kubernetes package manager
    # doctl            # DigitalOcean CLI
  ];

  # Configure gcloud completion for zsh
  programs.zsh.initContent = ''
    # Google Cloud SDK completion
    if [ -f "${pkgs.google-cloud-sdk}/google-cloud-sdk/completion.zsh.inc" ]; then
      source "${pkgs.google-cloud-sdk}/google-cloud-sdk/completion.zsh.inc"
    fi
  '';

  # Useful aliases for gcloud
  programs.zsh.shellAliases = {
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
