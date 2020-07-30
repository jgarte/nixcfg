{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    boot = {
      tmpOnTmpfs = true;
      cleanTmpDir = true;
      kernel.sysctl = {
        "fs.file-max" = 100000;
        "fs.inotify.max_user_instances" = 256;
        "fs.inotify.max_user_watches" = 500000;
      };
    };

    # TODO: root ssh config to get nix daemon to use user's gpg-agent for ssh (closer to gpg conf hopefully)

    nix = {
      buildCores = 0;
      binaryCachePublicKeys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "colemickens.cachix.org-1:bNrJ6FfMREB4bd4BOjEN85Niu8VcPdQe4F4KxVsb/I4="
        "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
      ];
      binaryCaches = [
        "https://cache.nixos.org"
        "https://colemickens.cachix.org"
        "https://nixpkgs-wayland.cachix.org"
      ];
      trustedUsers = [ "@wheel" "root" ];
    };

    users.users."root".hashedPassword = "$6$k.vT0coFt3$BbZN9jqp6Yw75v9H/wgFs9MZfd5Ycsfthzt3Jdw8G93YhaiFjkmpY5vCvJ.HYtw0PZOye6N9tBjNS698tM3i/1";

    nixpkgs.overlays = [
      (import ../packages)
    ];

    i18n.defaultLocale = "en_US.UTF-8";

    security.sudo.wheelNeedsPassword = false;
    users.mutableUsers = false;
  };
}
