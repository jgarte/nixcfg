{
  # overlay will load an overlay, either from:
  #  ../overlays/{name}
  #  ./pkgs/{name}
  overlay = name:
    let
      localimportpath = ../overlays + "/${name}";
      importpath = ./imports + "/${name}";
    in
      if builtins.pathExists localimportpath then
        (import "${localimportpath}")
      else if builtins.pathExists importpath then
        (import (import "${importpath}"))
      else (abort "you must vendor overlay imports");

  # TODO: see if there's way to simplify this, (note: nixpkgs.nixos does not eval overlays)
  mkSystem = { nixpkgs, system ? "x86_64-linux", rev ? "git", extraModules ? [], ... }:
    let
      pkgs = import (nixpkgs) {
        inherit (machine.config.nixpkgs) config overlays;
      };
      machine = import "${nixpkgs}/nixos/lib/eval-config.nix" {
        inherit system;
        modules = [
          #({config, ...}: {
          #  system.nixos.revision = rev;
          #  system.nixos.versionSuffix = ".git.${rev}";
          #})
        ] ++ extraModules;
      };
    in
      machine;

  findNixpkgs = branchName:
    let
      localimportpath = ../nixpkgs- + "${branchName}";
    in
      if builtins.pathExists localimportpath then
        localimportpath
      else
        builtins.fetchTarball { url = "https://foo"; };
}
