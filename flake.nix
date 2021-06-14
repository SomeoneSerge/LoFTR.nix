{
  description = "A very basic devshell";

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.devshell.url = "github:numtide/devshell";
  inputs.mach-nix = { };
  inputs.poetry2nix-src.url = "github:nix-community/poetry2nix";
  inputs.nixpkgs.follows = "mach-nix/nixpkgs";

  outputs =
    { self, nixpkgs, flake-utils, mach-nix, poetry2nix-src, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlay = final: prev: {
          mach-nix = prev.callPackage "${mach-nix}/default.nix" {
            pypiData = mach-nix.inputs.pypi-deps-db;
            python = "python38";
          };
          pythonEnv = final.mach-nix.mkPython {
            requirements = builtins.readFile ./requirements.txt;
            _.opencensus-context.postInstall = ''
              rm $out/lib/python*/site-packages/opencensus/common/__pycache__/__init__.cpython-*.pyc
              rm $out/lib/python*/site-packages/opencensus/__pycache__/__init__.cpython-*.pyc
            '';
            # overridesPost = [ final.poetry2nix.defaultPoetryOverrides ];
          };
        };
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ overlay inputs.devshell.overlay ];
        };
        devShell = pkgs.devshell.mkShell {
          imports = [ (pkgs.devshell.importTOML ./devshell.toml) ];
        };
      in {
        inherit overlay devShell;
        packages = { inherit (pkgs) pythonEnv; };
      });
}
