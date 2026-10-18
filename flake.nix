{
  description = "Nix package for NotBlood (Blood source port)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      pkgsFor = system: import nixpkgs { inherit system; };
    in
    {
      overlays.default = final: prev: {
        notblood = final.callPackage ./package.nix { };
      };

      packages = forAllSystems (system:
        let
          pkgs = pkgsFor system;
        in {
          notblood = pkgs.callPackage ./package.nix { };
          default = self.packages.${system}.notblood;
        }
      );

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/notblood";
        };
      });

      devShells = forAllSystems (system:
        let
          pkgs = pkgsFor system;
        in {
          default = pkgs.mkShell {
            inputsFrom = [ self.packages.${system}.default ];
          };
        }
      );
    };
}
