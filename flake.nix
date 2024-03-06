{
  description = "My personal NixOS utils library";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    nixpkgs,
    flake-utils,
    ...
  }: let
    overlays = import ./overlays;

    forEachSystem = flake-utils.lib.eachSystem (with flake-utils.lib.system; [
      aarch64-darwin
      x86_64-darwin
      x86_64-linux
    ]);

    systemsFlakes = forEachSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [overlays];
      };

      packages = builtins.listToAttrs (builtins.map (pkg: {
        name = pkg;
        value = pkgs.${pkg};
      }) (builtins.attrNames (overlays pkgs pkgs)));
    in rec {
      inherit packages;

      checks = {
        overlays-check = pkgs.symlinkJoin {
          name = "overlays";
          paths = builtins.attrValues packages;
        };
      };

      lib = import ./lib {inherit pkgs;};

      devShells.default = lib.mkShell {
        name = "utility";
        bubblewrap = true;
      };
    });
  in
    systemsFlakes
    // {
      lib = systemsFlakes.lib // {inherit forEachSystem;};
      overlays.default = overlays;
    };
}
