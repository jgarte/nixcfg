{ lib, pkgs, ... }:

let
  c = import ./common.nix { inherit pkgs; };
  mkMount = target: {
    description = "RCloneGoogDrv Mount Thing";
    path = with pkgs; [ fuse bash ];
    serviceConfig = {
      Type = "simple";
      StartLimitInterval = "60s";
      StartLimitBurst = 3;
      ExecStartPre = [
        "-${pkgs.fuse}/bin/fusermount -uz /mnt/${target}"
        "${pkgs.coreutils}/bin/mkdir -p /mnt/${target}"
      ];
      ExecStart = "${c.rclone-lim-mount}/bin/rclone-lim-mount --allow-other ${target}: /mnt/${target}";
      ExecStop = "${pkgs.fuse}/bin/fusermount -uz /mnt/${target}";
      Restart = "on-failure";
    };
    wantedBy = [ "default.target" ];
  };
in {
  systemd.services = {
    rclone_tvshows = mkMount "tvshows";
    rclone_movies  = mkMount "movies";
  };
}
