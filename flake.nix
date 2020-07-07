{
  description = "colemickens-nixcfg";

  # flakes feedback
  # - i wish inputs were optional so that I could do my current logic
  # ---- they're CLI overrideable?
  # - i hate the git url syntax

  # cached failure isn't actually showing me the ... error?
  # how to use local paths when I want to?

  # credits: bqv, balsoft
  inputs = {
    master = { url = "github:nixos/nixpkgs/master"; };
    stable = { url = "github:nixos/nixpkgs/nixos-20.03"; };
    cmpkgs = { url = "github:colemickens/nixpkgs/cmpkgs"; };
    pipkgs = { url = "github:colemickens/nixpkgs/pipkgs"; };

    nix.url = "github:nixos/nix/flakes";
    nix.inputs.nixpkgs.follows = "master";

    home.url = "github:colemickens/home-manager/cmhm";
    home.inputs.nixpkgs.follows = "cmpkgs";

    construct.url = "github:matrix-construct/construct";
    construct.inputs.nixpkgs.follows = "cmpkgs";

    # <pull_requests>    
    # this stuff is in-flight but I want to dogfood it
    # until I adopt something like git-assembler, I'll use flakes
    # to pull it in

    # git assembler would be nicer because then I can just have cmpkgs
    # and not need to update my config to pull from the pr-flake
    # in fact, I quite don't like this but I'm tired of rebasing stuff
    vimpluginsPkgs = { type = "path"; path = "/home/cole/code/nixpkgs/pulls/vimplugins"; };
    # </pull_requests>

    hardware = { url = "github:nixos/nixos-hardware";        flake = false; };
    mozilla  = { url = "github:mozilla/nixpkgs-mozilla";     flake = false; };
    wayland  = { url = "github:colemickens/nixpkgs-wayland"; flake = false; };
  };
  
  outputs = inputs:
    let
      uniformVersionSuffix = true; # clamp versionSuffix to ".git" to get identical build to non-flakes
      
      nameValuePair = name: value: { inherit name value; };
      genAttrs = names: f: builtins.listToAttrs (map (n: nameValuePair n (f n)) names);
      forAllSystems = genAttrs [ "x86_64-linux" "i686-linux" "aarch64-linux" ];

      pkgsFor = pkgs: system:
        import pkgs { inherit system; config = { allowUnfree = true; }; };

      mkSystem = system: pkgs_: hostname:
        pkgs_.lib.nixosSystem {
          inherit system;
          modules = [ (./. + "/machines/${hostname}/configuration.nix")]
            ++ (if uniformVersionSuffix then
                [({config, lib, ...}: {
                  system.nixos.revision = lib.mkForce "git";
                  system.nixos.versionSuffix = lib.mkForce ".git";
                })]
                else []);
          specialArgs = {
            inherit inputs;
          };
        };
    in rec {
      defaultPackage.x86_64-linux =
        nixosConfigurations.xeep.config.system.build;

      devShell = forAllSystems (system:
        import ./shell.nix {
          pkgs       = pkgsFor inputs.cmpkgs system;
          masterPkgs = pkgsFor inputs.master system;
          cachixPkgs = pkgsFor inputs.stable system;
        }
      );

      nixosConfigurations = {
        raspberry = mkSystem "aarch64-linux" inputs.pipkgs "raspberry";
        xeep      = mkSystem "x86_64-linux"  inputs.cmpkgs "xeep";
      };
    };
}
