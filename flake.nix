{
  description = "Building linux kernel and drivers.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    # Used for shell.nix
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ...
  } @ inputs:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {inherit system;};
      in {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs;
            [
              meson
              ninja
              flex
              bison
              bc
              rsync
              fuse2fs
              apk-tools
            ]
            ++ (with pkgsCross.riscv64.buildPackages; [
              gcc
            ]);

          hardeningDisable = ["all"];
        };

        # For compatibility with older versions of the `nix` binary
        devShell = self.devShells.${system}.default;
      }
    );
}
