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
        netduke32 = final.callPackage ./netduke32.nix { };
      };

      packages = forAllSystems (system:
        let
          pkgs = pkgsFor system;
        in {
          notblood = pkgs.callPackage ./package.nix { };
          netduke32 = pkgs.callPackage ./netduke32.nix { };
          default = self.packages.${system}.notblood;
        }
      );

      apps = forAllSystems (system: {
        notblood = {
          type = "app";
          program = "${self.packages.${system}.notblood}/bin/notblood";
        };
        netduke32 = {
          type = "app";
          program = "${self.packages.${system}.netduke32}/bin/netduke32";
        };
        default = self.apps.${system}.notblood;
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
