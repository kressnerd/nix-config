# Roo Cline VSCode Extension
# Fetches the roo-cline VSCode extension from the marketplace
#
# For local development versions, this can be overridden by:
# 1. Using a local .vsix file with vscode-utils.buildVscodeExtension
# 2. Updating the version and sha256 for different marketplace versions
{
  lib,
  vscode-utils,
}:
vscode-utils.buildVscodeMarketplaceExtension {
  mktplcRef = {
    name = "roo-cline";
    publisher = "RooVeterinaryInc";
    version = "3.26.4";
    sha256 = "sha256-oXpiSgnFbaufi7fAkapVJeAC916l0IINEgs57ux6r+k="; # Correct hash for version 3.26.4
  };

  meta = with lib; {
    description = "AI-powered autonomous coding agent that lives in your editor";
    downloadPage = "https://marketplace.visualstudio.com/items?itemName=RooVeterinaryInc.roo-cline";
    homepage = "https://github.com/RooVetGit/Roo-Code";
    license = licenses.asl20;
    maintainers = with lib.maintainers; [];
  };
}
