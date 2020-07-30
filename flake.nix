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
    master = { url = "github:nixos/nixpkgs/master"; };
    stable = { url = "github:nixos/nixpkgs/nixos-20.03"; };
    unstable = { url = "github:nixos/nixpkgs/nixos-unstable"; };
    cmpkgs = { url = "github:colemickens/nixpkgs/cmpkgs"; };
    pipkgs = { url = "github:colemickens/nixpkgs/pipkgs"; };

    nix.url = "github:nixos/nix/flakes";
    nix.inputs.nixpkgs.follows = "master";

    home.url = "github:colemickens/home-manager/cmhm";
    home.inputs.nixpkgs.follows = "cmpkgs";

    construct.url = "github:matrix-construct/construct";
    construct.inputs.nixpkgs.follows = "cmpkgs";

    firenight  = { url = "github:colemickens/flake-firefox-nightly"; };
    firenight.inputs.nixpkgs.follows = "cmpkgs";

    wayland  = { url = "github:colemickens/nixpkgs-wayland"; };
    # these are kind of weird, they don't really apply
    # to me if I'm using just  `wayland#overlay`, afaict?
    wayland.inputs.nixpkgs.follows = "cmpkgs";
    wayland.inputs.master.follows = "master";

    hardware = { url = "github:nixos/nixos-hardware"; };
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
          modules = [(./. + "/machines/${hostname}/configuration.nix")];
          specialArgs.inputs = inputs;
        };
    in rec {
      devShell = forAllSystems (system:
        (pkgsFor inputs.unstable system).mkShell {
          nativeBuildInputs = with (pkgsFor inputs.unstable system); [
            #(pkgsFor inputs.master system).nixFlakes
            (pkgsFor inputs.unstable system).nixFlakes
            #inputs.nix.packages."${system}".nix  # ?????????????
            (pkgsFor inputs.stable system).cachix
            bash cacert curl git jq mercurial
            nettools openssh ripgrep rsync
            nix-build-uncached nix-prefetch-git
          ];
        }
      );

      nixosConfigurations = {
        azdev     = mkSystem "x86_64-linux" inputs.unstable "azdev";
        raspberry = mkSystem "aarch64-linux" inputs.pipkgs "raspberry";
        #fastraz   = mkSystem "aarch64-linux" inputs.cmpkgs "raspberry";
        xeep      = mkSystem "x86_64-linux"  inputs.cmpkgs "xeep";
      };

      machines = {
        azdev = inputs.self.nixosConfigurations.azdev.config.system.build.azureImage;
        xeep = inputs.self.nixosConfigurations.xeep.config.system.build.toplevel;
        raspberry = inputs.self.nixosConfigurations.raspberry.config.system.build.toplevel;
      };

      defaultPackage = [
        inputs.self.nixosConfigurations.xeep.config.system.build.toplevel
        inputs.self.nixosConfigurations.raspberry.config.system.build.toplevel
      ];
    };
}