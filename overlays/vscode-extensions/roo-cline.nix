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
    version = "3.26.7";
    sha256 = "sha256-VQHFowIAiKcJ0K21UTC5n3+bz6iytpd+SFqGMgfVeZg=";
    # sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  meta = with lib; {
    description = "AI-powered autonomous coding agent that lives in your editor";
    downloadPage = "https://marketplace.visualstudio.com/items?itemName=RooVeterinaryInc.roo-cline";
    homepage = "https://github.com/RooVetGit/Roo-Code";
    license = licenses.asl20;
    maintainers = with lib.maintainers; [];
  };
}
