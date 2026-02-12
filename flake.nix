{
  description = "MCP Agent Mail - Inter-agent messaging and coordination";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    crane.url = "github:ipetkov/crane";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, crane, fenix, flake-utils, ... }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        fenixPkgs = fenix.packages.${system};
        rustToolchain = fenixPkgs.combine [
          fenixPkgs.latest.cargo
          fenixPkgs.latest.rustc
        ];
        craneLib = (crane.mkLib pkgs).overrideToolchain rustToolchain;

        commonArgs = {
          src = craneLib.cleanCargoSource ./.;
          pname = "mcp-agent-mail";
          version = "0.1.0";
          strictDeps = true;
          nativeBuildInputs = with pkgs; [ pkg-config cmake ];
          buildInputs = with pkgs; [ openssl zlib libssh2 libgit2 ];
          OPENSSL_NO_VENDOR = "1";
          LIBGIT2_NO_VENDOR = "1";
          LIBSSH2_SYS_USE_PKG_CONFIG = "1";
        };

        cargoArtifacts = craneLib.buildDepsOnly commonArgs;
      in {
        packages.default = craneLib.buildPackage (commonArgs // {
          inherit cargoArtifacts;
          doCheck = false;
        });
      });
}
