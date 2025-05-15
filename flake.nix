{
  description = "Playground Tools";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.bashInteractive

            pkgs.pre-commit
            pkgs.gitleaks

            pkgs.kubeseal
            pkgs.kustomize
            pkgs.argocd
            pkgs.kubernetes-helm
            pkgs.stern
            pkgs.yamllint
          ];
        };
      });
}
