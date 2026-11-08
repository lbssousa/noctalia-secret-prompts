{
  description = "lbssousa/secret-prompts Noctalia plugin and its noctalia-secret-prompts helper";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAll = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      overlays.default = final: _: { noctalia-secret-prompts = final.callPackage ./nix/package.nix { }; };

      packages = forAll (pkgs: rec {
        noctalia-secret-prompts = pkgs.callPackage ./nix/package.nix { };
        default = noctalia-secret-prompts;
      });

      checks = forAll (pkgs: {
        inherit (self.packages.${pkgs.stdenv.hostPlatform.system}) noctalia-secret-prompts;
      });

      formatter = forAll (pkgs: pkgs.nixfmt);
    };
}
