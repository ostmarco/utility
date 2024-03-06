attrs: let
  shell = import ./shell.nix attrs;
in {
  inherit shell;
  inherit (shell) mkShell;
}
