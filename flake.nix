{
  description = "A very basic devshell";

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.devshell.url = "github:numtide/devshell";
  inputs.poetry2nix-src.url = "github:nix-community/poetry2nix";

  outputs = { self, nixpkgs, flake-utils, poetry2nix-src, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlay = final: prev: {
          poetryEnv = prev.poetry2nix.mkPoetryEnv {
            projectDir = ./.;
            python = prev.python39;
          };
        };
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ poetry2nix-src.overlay overlay inputs.devshell.overlay ];
        };
        devShell = pkgs.devshell.mkShell {
          imports = [ (pkgs.devshell.importTOML ./devshell.toml) ];
        };
      in { inherit devShell; });
}
