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
            overridesPost = [
              (python-final: python-prev: {
                albumentations = final.mach-nix.buildPythonPackage rec {
                  pname = "albumentations";
                  version = "1.0.0";
                  src = python-prev.fetchPypi {
                    inherit pname version;
                    sha256 =
                      "sha256-i0TPXHMSs0mDd4Fw+z8P2AJ0kjKGQmAtx1ajmpCr1e0=";
                    format = "wheel";
                    python = "py3";
                  };
                  pipInstallFlags = [ "--no-binary=imgaug,albumentations" ];
                  format = "wheel";
                  requirements = ''
                    numpy>=1.11.1
                    scipy
                    scikit-image>=0.16.1
                    PyYAML
                    opencv-python>=4.1.1
                  '';
                };
              })
            ];
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
        packages = {
          inherit (pkgs) pythonEnv;
          inherit (pkgs.mach-nix) mach-nix;
        };
      });
}
