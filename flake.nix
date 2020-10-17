{
  description = "colemickens-nixcfg";

  # flakes feedback
  # - i wish inputs were optional so that I could do my current logic
  # ---- they're CLI overrideable?
  # - i hate the git url syntax

  # cached failure isn't actually showing me the ... error?
  # how to use local paths when I want to?

  # nix build is UNRELIABLE because /soemtimes/ it checks for updates, I hate this
  # unpredictable, moves underneath me

  # credits: bqv, balsoft
  inputs = {
    nixpkgs = { url = "github:colemickens/nixpkgs/cmpkgs"; }; # for my regular nixpkgs
    pipkgs = { url = "github:colemickens/nixpkgs/pipkgs"; }; # for experimenting with rpi4
    master = { url = "github:nixos/nixpkgs/master"; }; # for nixFlakes
    stable = { url = "github:nixos/nixpkgs/nixos-20.03"; }; # for cachix

    home-manager.url = "github:colemickens/home-manager/cmhm";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    construct.url = "github:matrix-construct/construct";
    construct.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix/master";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    firefox  = { url = "github:colemickens/flake-firefox-nightly"; };
    firefox.inputs.nixpkgs.follows = "nixpkgs";

    chromium  = { url = "github:colemickens/flake-chromium"; };
    chromium.inputs.nixpkgs.follows = "nixpkgs";

    nixos-veloren = { url = "github:colemickens/nixos-veloren"; };
    nixos-veloren.inputs.nixpkgs.follows = "nixpkgs";

    mobile-nixos = { url = "github:colemickens/mobile-nixos/mobile-nixos-blueline"; };
    mobile-nixos.inputs.nixpkgs.follows = "nixpkgs";

    nix-ipfs = { url = "github:obsidiansystems/nix"; };

    nixos-azure = { url = "github:colemickens/nixos-azure/dev"; };
    nixos-azure.inputs.nixpkgs.follows = "nixpkgs";

    wip-pinebook-pro = { url = "github:colemickens/wip-pinebook-pro"; };
    wip-pinebook-pro.inputs.nixpkgs.follows = "nixpkgs";

    nixpkgs-wayland  = { url = "github:colemickens/nixpkgs-wayland"; };
    # these are kind of weird, they don't really apply
    # to me if I'm using just  `wayland#overlay`, afaict?
    nixpkgs-wayland.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs-wayland.inputs.master.follows = "master";

    hardware = { url = "github:nixos/nixos-hardware"; };

    wfvm = { type = "git"; url = "https://git.m-labs.hk/M-Labs/wfvm"; flake = false;};
  };

  outputs = inputs:
    let
      nameValuePair = name: value: { inherit name value; };
      genAttrs = names: f: builtins.listToAttrs (map (n: nameValuePair n (f n)) names);
      forAllSystems = genAttrs [ "x86_64-linux" "i686-linux" "aarch64-linux" ];

      pkgsFor = pkgs: sys:
        import pkgs {
          system = sys;
          config = { allowUnfree = true; };
        };

      mkSystem = sys: pkgs_: hostname:
        pkgs_.lib.nixosSystem {
          system = sys;
          modules = [(./. + "/hosts/${hostname}/configuration.nix")];
          specialArgs = { inherit inputs; };
        };
    in rec {
      devShell = forAllSystems (system:
        (pkgsFor inputs.nixpkgs system).mkShell {
          nativeBuildInputs = with (pkgsFor inputs.nixpkgs system); [
            (pkgsFor inputs.master system).nixFlakes
            (pkgsFor inputs.stable system).cachix
            bash cacert curl git jq mercurial
            nettools openssh ripgrep rsync
            nix-build-uncached nix-prefetch-git
            packet-cli
            sops
          ];
        }
      );

      packages = forAllSystems (sys:
        let pkgs = import inputs.nixpkgs {
          system = sys;
            config = { allowUnfree = true; };
            overlays = [ inputs.self.overlay ];
          };
        in pkgs.colePackages
      );

      pkgs = forAllSystems (sys:
        let pkgs = import inputs.nixpkgs {
          system = sys;
            config = { allowUnfree = true; };
            overlays = [ inputs.self.overlay ];
          };
        in pkgs
      );

      overlay = self: pkgs:
        let p = {
          customCommands = pkgs.callPackages ./pkgs/commands.nix {};
          customGuiCommands = pkgs.callPackages ./pkgs/commands-gui.nix {};

          alps = pkgs.callPackage ./pkgs/alps {};
          mirage-im = pkgs.libsForQt5.callPackage ./pkgs/mirage-im {};
          neovim-unwrapped = pkgs.callPackage ./pkgs/neovim {
            neovim-unwrapped = pkgs.neovim-unwrapped;
          };
          passrs = pkgs.callPackage ./pkgs/passrs {};
          
          mesa-git = pkgs.callPackage ./pkgs/mesa-git {};

          raspberrypi-eeprom = pkgs.callPackage ./pkgs/raspberrypi-eeprom {};
          rpi4-uefi = pkgs.callPackage ./pkgs/rpi4-uefi {};

          cchat-gtk = pkgs.callPackage ./pkgs/cchat-gtk {
            libhandy = pkgs.callPackage ./pkgs/libhandy {};
          };
          obs-v4l2sink = pkgs.libsForQt5.callPackage ./pkgs/obs-v4l2sink {};

          drm-howto = pkgs.callPackage ./pkgs/drm-howto {};
        }; in p // { colePackages = p; };

      nixosConfigurations = {
        azdev      = mkSystem "x86_64-linux"  inputs.nixpkgs "azdev";
        rpione     = mkSystem "aarch64-linux" inputs.nixpkgs "rpione";
        rpitwo     = mkSystem "aarch64-linux" inputs.pipkgs "rpitwo";
        slynux     = mkSystem "x86_64-linux"  inputs.nixpkgs "slynux";
        xeep       = mkSystem "x86_64-linux"  inputs.nixpkgs "xeep";
        pinebook   = mkSystem "aarch64-linux" inputs.nixpkgs "pinebook";
        testipfsvm = mkSystem "x86_64-linux"  inputs.nixpkgs "testipfsvm";
        bluephone  = mkSystem "aarch64-linux" inputs.nixpkgs "bluephone";
      };

      hosts = rec {
        ## Regular x86_64 hosts
        azdev = inputs.self.nixosConfigurations.azdev.config.system.build.azureImage;
        xeep = inputs.self.nixosConfigurations.xeep.config.system.build.toplevel;
        slynux = inputs.self.nixosConfigurations.slynux.config.system.build.toplevel;

        ## Raspberry Pi 4 systems
        rpione = inputs.self.nixosConfigurations.rpione.config.system.build.toplevel;
        rpitwo = inputs.self.nixosConfigurations.rpitwo.config.system.build.toplevel;
        rpitwo_sd = inputs.self.nixosConfigurations.rpitwo.config.system.build.sdImage;

        ## Pine64 Pinebook Pro Laptop
        pinebook = (pkgsFor inputs.nixpkgs "aarch64-linux").runCommandNoCC "pinebook-bundle" {} ''
          mkdir $out
          ln -s "${inputs.self.nixosConfigurations.pinebook.config.system.build.toplevel}" $out/toplevel
          ln -s "${inputs.wip-pinebook-pro.packages.aarch64-linux.uBootPinebookPro}" $out/uboot
          ln -s "${inputs.wip-pinebook-pro.packages.aarch64-linux.pinebookpro-keyboard-updater}" $out/kbfw
        '';

        ## Demo NixOS VMs
        testipfsvm = inputs.self.nixosConfigurations.testipfsvm.config.system.build.vm;

        ## Windows VMs (automatically built with Nix)
        winvm = import ./hosts/winvm {
          pkgs = pkgsFor inputs.nixpkgs "x86_64-linux";
          inherit inputs;
        };

        ## Mobile-NixOS: Pine64 Pinephone
        pinephone = let
          dev = mkSystem "aarch64-linux" inputs.nixpkgs "pinephone";
        in
          (pkgsFor inputs.nixpkgs "aarch64-linux").runCommandNoCC "pinephone-bundle" {} ''
          mkdir $out
          ln -s "${dev.config.system.build.disk-image}" $out/disk-image;
          ln -s "${dev.config.system.build.toplevel}" $out/toplevel;
          ln -s "${dev.config.system.build.u-boot}" $out/uboot;
          ln -s "${dev.config.system.build.boot-partition}" $out/boot-partition;
        '';

        ## Mobile-NixOS: Pixel 3
        bluephone = let
          dev = inputs.self.nixosConfigurations.bluephone;
        in
          {
            toplevel = dev.config.system.build.toplevel;
            bootimg = dev.config.system.build.android-bootimg;
            kernel = dev.config.mobile.boot.stage-1.kernel.package;
            # device = dev.config.system.build.android-device;
          };
      };
    };
}

