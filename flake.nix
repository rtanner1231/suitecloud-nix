{
  description = "A Nix flake for NetSuite's SuiteCloud CLI";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        lib = pkgs.lib;

        suitecloud-cli = pkgs.buildNpmPackage rec {
          pname = "@oracle/suitecloud-cli";
          version = "3.1.0";

          src = pkgs.fetchurl {
            url = "https://registry.npmjs.org/@oracle/suitecloud-cli/-/suitecloud-cli-${version}.tgz";
            sha256 = "sha256-mkcRPMK2f2d0R04x/s0YWB6dFSJAktWOfW2/8DokgKU=";
          };

          npmDepsHash = "sha256-w4QPjPdK3Ia1UcIFQpBWihr+nVuVYhk5qesuzJxZKfg=";

          makeCacheWritable = true;
          npmFlags = [ "--ignore-scripts" ];

          # The postinstall script, which downloads the JAR, is incompatible with Nix.
          # We patch it out of package.json and place the JAR file manually.
          postPatch = ''
            cp ${./package-lock.json} ./package-lock.json

            sed -i.bak '/,$/{ N;
            /"postinstall": "node postinstall.js"/s/,\n.*//; }' ./package.json
          '';

          nativeBuildInputs = [
            pkgs.nodejs_22
            pkgs.openjdk
            pkgs.jq
          ];

          dontNpmBuild = true;

          meta = with lib; {
            description = "Command-line interface for developing on the SuiteCloud platform";
            homepage = "https://www.npmjs.com/package/@oracle/suitecloud-cli";
            license = licenses.unfree;
            maintainers = [ ];
            platforms = platforms.linux ++ platforms.darwin;
          };
        };

        # Fetch the SuiteCloud CLI JAR file
        sdfFileName = "cli-2025.2.0.jar";
        basePath = "https://system.netsuite.com/download/suitecloud-sdk/25.2";

        suiteCloudCliJar = pkgs.fetchurl {
          url = "${basePath}/${sdfFileName}";
          sha256 = "sha256-JTPMmz7qqAUd0R0Im9r/aTCl7cCGOTVQTZG4tWLRwnM=";
        };

      in
      {
        # Default package is the CLI wrapper
        packages = {
          suitecloud-cli = suitecloud-cli;
          default = self.packages.${system}.suitecloud-cli;
        };

        # Home Manager module for a complete installation
        homeManagerModules.default = {
          # Install the suitecloud-cli NPM wrapper
          home.packages = [ self.packages.${system}.suitecloud-cli ];

          # The CLI wrapper expects the JAR file to be in this specific location.
          # This module links the fetched JAR to the correct path in the user's home directory.
          home.file.".suitecloud-sdk/cli/${sdfFileName}" = {
            source = suiteCloudCliJar;
          };
        };

        devShells.default = pkgs.mkShell {
          name = "suitecloud-shell";
          packages = [ self.packages.${system}.suitecloud-cli ];
          shellHook = ''
            # Create the required directory and symlink the JAR for this dev shell session
            if [ ! -f "$HOME/.suitecloud-sdk/cli/${sdfFileName}" ]; then
              echo "Setting up SuiteCloud CLI JAR for this shell session... ⚙️"
              mkdir -p "$HOME/.suitecloud-sdk/cli"
              ln -sf "${suiteCloudCliJar}" "$HOME/.suitecloud-sdk/cli/${sdfFileName}"
            fi
            echo "SuiteCloud CLI is ready to use. ✅"
          '';
        };
      }
    );
}
