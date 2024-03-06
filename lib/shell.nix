{pkgs, ...}: let
  inherit (pkgs) stdenv;
  inherit (pkgs.lib) strings;

  isNixOS = let
    issue =
      if builtins.pathExists "/etc/issue"
      then builtins.readFile "/etc/issue"
      else "";
  in
    stdenv.isLinux && (strings.hasInfix "NixOS" issue);

  hostShell = builtins.getEnv "SHELL";

  shell =
    if hostShell != ""
    then hostShell
    else "${pkgs.bashInteractive}/bin/bash";

  mkShell = {
    bubblewrap ? false,
    environmentVariables ? {},
    packages ? _: [],
    ...
  } @ attrs: let
    cleanAttrs = builtins.removeAttrs attrs ["bubblewrap" "environmentVariables" "packages"];

    initBash = pkgs.writeText "init-bash" ''
      export SHELL="${shell}"

      ${builtins.concatStringsSep "\n" (
        builtins.attrValues (
          builtins.mapAttrs (name: value: "export ${name}=${value}") environmentVariables
        )
      )}

      exec ${shell}
    '';

    mkBubblewrapShell =
      (pkgs.buildFHSEnvBubblewrap (cleanAttrs
        // {
          runScript = "bash --init-file ${initBash}";

          multiPkgs = _: [];
          targetPkgs = pkgs: (packages pkgs);
          extraOutputsToInstall = ["dev"];
        }))
      .env;

    mkStandardShell = pkgs.mkShell (cleanAttrs
      // {
        packages = (packages pkgs) ++ [pkgs.bashInteractive];
        shellHook = ". ${initBash}";
      });
  in
    if (bubblewrap && isNixOS)
    then mkBubblewrapShell
    else mkStandardShell;
in {inherit mkShell;}
