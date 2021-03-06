{ pkgs, lib, config, inputs, ... }:

let
  firefoxFlake = inputs.firefox.packages.${pkgs.system};
  firefoxBin = pkgs.writeShellScriptBin "firefox-bin" ''
    exec ${pkgs.firefox-bin}/bin/firefox -p"''${@}"
  '';
  firefoxNightly = pkgs.writeShellScriptBin "firefox-nightly" ''
    exec ${firefoxFlake.firefox-nightly-bin}/bin/firefox -p"''${@}"
  '';

  torbrowserPkg =
    if pkgs.system == "aarch64-linux"
    then pkgs.tor-browser-bundle-ports-bin
    else pkgs.tor-browser-bundle-bin;
in
{
  imports = [
    ./interactive.nix # includes core.nix (which imports hm)

    ../mixins/alacritty.nix
    ../mixins/chromecast.nix
    ../mixins/fonts.nix
    ../mixins/gtk.nix
    ../mixins/kitty.nix
    ../mixins/mpv.nix
    ../mixins/mako.nix
    ../mixins/pipewire.nix
    ../mixins/qt.nix
    ../mixins/spotify.nix
    ../mixins/termite.nix
  ];
  # TODO: xdg-user-dirs fixup

  config = {
    nixpkgs.config.allowUnfree = true;

    hardware.opengl.enable = true;
    # see pipewire.nix for pulseaudio/pipewire stuffs

    services.pcscd.enable = true;

    home-manager.users.cole = { pkgs, ... }: {
      home.sessionVariables = {
        BROWSER = "firefox";
        TERMINAL = "termite";
        MOZ_USE_XINPUT2 = "1";
      };
      services = {
        udiskie.enable = true;
      };
      home.packages = with pkgs; [
        colePackages.customGuiCommands

        # misc
        evince
        gimp
        qemu
        vscodium
        #vscode
        freerdp
        virt-viewer
        #vlc
        imv

        # misc utils for desktop
        brightnessctl
        pulsemixer

        # terminals
        alacritty
        #cool-retro-term
        kitty

        # matrix clients
        fractal
        #nheko
        quaternion
        spectral
        mirage-im
        element-desktop
        cchat-gtk
        neochat

        rkvm

        gnome3.nautilus
        gnome3.file-roller
        gnome3.gnome-tweaks
        spice-gtk

        # browsers
        ungoogled-chromium
      ]
      ++ lib.optionals (pkgs.system == "x86_64-linux") [
        firefox
        firefoxBin
        firefoxNightly

        ddccontrol i2c-tools
        scrcpy

        # yucky non-free
        discord
        ripcord

        # not supported on aarch64, likely its an appimage or something
        radicle-upstream
      ] ++ lib.optionals (pkgs.system == "aarch64-linux") [
        # use stable on aarch64-linux
        inputs.stable.legacyPackages.${pkgs.system}.firefox
        inputs.stable.legacyPackages.${pkgs.system}.chromium
      ];
    };
  };
}
