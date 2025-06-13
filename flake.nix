{
  description = "Unbuch";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Pin nixpkgs to a commit where pandoc 2.14 was available (July 2021)
    oldPkgs.url = "github:NixOS/nixpkgs/4c3c80df545ec5cb26b5480979c3e3f93518cbe5";

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, oldPkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        old = import oldPkgs { inherit system; };

        pythonEnv = pkgs.python312.withPackages (ps: with ps; [ 
          pip
          pandocfilters
        ]);
        app = pkgs.lib.fileset.toSource {
          root = ./.;
          fileset = ./.;
        };
      in {
        packages = {
          default = pkgs.mkShell {
            name = "pandoc-python-env";
            buildInputs = [
              old.pandoc
              pythonEnv
            ];
          };

          docker = pkgs.dockerTools.buildLayeredImage {
            #docker = pkgs.dockerTools.buildImage {
            name = "unbuch";
            tag = "latest";
            created = "now";

            contents = [
              (pkgs.runCommand "app-dir" { } ''
                mkdir -p $out/app
                cp -r ${app}/* $out/app
                '')
              pkgs.bashInteractive
              pkgs.gnumake
              pkgs.coreutils
              pkgs.gnugrep
              pkgs.which
              old.pandoc
              pythonEnv
            ];

            config = {
              Env = [
                "PATH=${pythonEnv}/bin:/bin/:/usr/local/bin"
              ];
              Cmd = [
                "/bin/bash"
              ];
              WorkingDir = "/app";
            };
          };
        };

        devShells.default = pkgs.mkShell {
          name = "pandoc-python-shell";
          buildInputs = [
            old.pandoc
            pythonEnv
          ];
        };
      });
}
