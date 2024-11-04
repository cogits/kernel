{
  description = "Building linux kernel and drivers.";
  inputs.nixpkgs.url = "flake:nixpkgs";

  outputs = {self, nixpkgs}: let
    inherit (nixpkgs) lib;

    eachSystem = systems: fn:
      lib.foldl' (acc: sys:
          lib.recursiveUpdate
          acc
          (lib.mapAttrs (_: value: {${sys} = value;}) (fn sys))
      ) {}
      systems;

    supportedSystems = [ "x86_64-linux" "i686-linux" "aarch64-linux" "riscv64-linux" ];

  in eachSystem supportedSystems (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        pkgs' = pkgs.pkgsCross.riscv64;
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs;
            [
              # kernel
              flex bison perl bc
              # mount
              util-linux e2fsprogs
              # qemu
              meson ninja python3 glib libslirp libtasn1
              # https://github.com/NixOS/nixpkgs/issues/334195#issuecomment-2428458882
              pkg-config
              # tools
              git rsync apk-tools
            ] ++ [
              # busybox
              pkgs'.stdenv.cc.libc.static
            ] ++ (with pkgs'.buildPackages; [
              gcc gdb
            ]);

          env = {
            APK_STATIC = "apk";
            CROSS_COMPILE = "riscv64-unknown-linux-gnu-";
          };

          hardeningDisable = ["all"];
        };
      }
    );
}
