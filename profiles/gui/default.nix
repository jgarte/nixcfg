{ config, lib, pkgs, ... }:

with lib;

let
  spkgs = (import /etc/nixpkgs-sway/default.nix {
    config = config.nixpkgs.config;
  }).pkgs;
in
{
  imports = [
    ../../users/cole
    ../common
  ];

  config = { 
    nixpkgs.overlays = [
      (import (builtins.fetchTarball 
        "https://github.com/mozilla/nixpkgs-mozilla/archive/c72ff151a3e25f14182569679ed4cd22ef352328.tar.gz"))
    ];
    environment.variables.MOZ_USE_XINPUT2 = "1";
    hardware.pulseaudio.enable = true;
    nixpkgs.config.pulseaudio = true;

    programs = {
      light.enable = true;
      sway = {
        enable = true;
        package = spkgs.sway;
      };
    };

    services = {
      flatpak.enable = true;
    };

    fonts = {
      #enableFontDir = true;
      #enableGhostscriptFonts = true;
      fonts = with pkgs; [
        corefonts inconsolata awesome
        fira-code fira-code-symbols fira-mono
        source-code-pro
        noto-fonts noto-fonts-emoji
      ];
    };

    environment.systemPackages = with pkgs; [
      # firefox-nightly-bin from the mozilla-nixpkgs overlay
      latest.firefox-nightly-bin
      # apperance
      arc-theme numix-icon-theme numix-icon-theme-circle
      # browsers
      chromium google-chrome
      # misc desktop
      freerdpUnstable
      # images
      gimp graphviz inkscape # TODO: add basic image viewer? todo: whats a good one?
      # video
      vlc mpv
      # audio
      pavucontrol # TODO: phase out in favor of pulsemixer
      # misc internet
      spotify transmission
      # virtualization # only if libvirtd is enabled though.... (which it isn't anywhere right now)
      # TODO: put in my own sort of module?
      # virtmanager virtviewer
      # editors
      vscode kate gnome3.gedit
      # communication
      slack signal-desktop zoom-us

      # TODO: put these behind an option
      # KDE
      ark
      # GNOME
      gnome3.gnome-tweaks # TODO: enabled to cfg gtk w/ sway :( TODO: figure better solution

      libinput libinput-gestures
      pulsemixer
      epiphany # TODO: remove when firefox/wayland work well

      # tiling wm specific
      i3status-rust
      termite
      dmenu
      xwayland
      pulsemixer

      # sway is provided by the program module
      spkgs.wlroots
      spkgs.redshift-wayland
      spkgs.slurp
      spkgs.grim
      #spkgs.waybar
    ];
  };
}

