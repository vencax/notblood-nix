# notblood-nix

Nix flake packaging for:
- [NotBlood](https://github.com/clipmove/NotBlood): Enhanced gameplay mod and source port of **Blood** based on NBlood and EDuke32 engine technology.
- [NetDuke32](https://voidpoint.io/StrikerTheHedgefox/eduke32-csrefactor): Advanced **Duke Nukem 3D** source port with overhauled client/server multiplayer netcode based on EDuke32.

## Features
- Native Linux build with SDL2 and Wayland support.
- Pre-packaged mod resources (`notblood.pk3` for NotBlood, `eduke32.dat` for NetDuke32).
- Desktop launcher integration and application icons.
- Includes engine tools (`kextract`, `kgroup`, `bsuite`, `arttool`, etc.).
- Includes download helpers: `notblood-download-shareware` and `netduke32-download-shareware` to quickly set up game assets.

---

## Quick Run

Run directly with Nix Flakes:

```bash
# Run NotBlood
nix run github:vencax/notblood-nix#notblood

# Run NetDuke32
nix run github:vencax/notblood-nix#netduke32
```

---

## Integration into NixOS

In your `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    notblood-nix = {
      url = "github:vencax/notblood-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, notblood-nix, ... }: {
    nixosConfigurations.yourhost = nixpkgs.lib.nixosSystem {
      modules = [
        {
          nixpkgs.overlays = [
            notblood-nix.overlays.default
          ];
          environment.systemPackages = [
            pkgs.notblood
          ];
        }
      ];
    };
  };
}
```

---

## Game Assets

NotBlood is a game engine source port and requires the original game files from **Blood (v1.21)** (e.g. from GOG, Steam, original CD, or Shareware).

### Option 1: Automatic Download (Helper script)
Run:
```bash
notblood-download-shareware
```
This automatically downloads and sets up the Blood shareware data into `~/.config/notblood/`.

### Option 2: Full Game (GOG / Steam / CD)
Copy the following files into `~/.config/notblood/`:
- `BLOOD.INI`
- `BLOOD.RFF`
- `GUI.RFF`
- `SOUNDS.RFF`
- `SURFACE.DAT`
- `TILES000.ART` ... `TILES017.ART`
- `VOXEL.DAT`
- Optional: `movie/` directory for cutscenes, `*.OGG` / `*.FLAC` for CD audio.

---

## Duke Nukem 3D Assets (NetDuke32)

NetDuke32 requires the original Duke Nukem 3D data files (`DUKE3D.GRP`, `*.CON`).

### Option 1: Automatic Download (Helper script)
Run:
```bash
netduke32-download-shareware
```
This automatically downloads and extracts the official Duke Nukem 3D Shareware data into `~/.config/netduke32/`.

### Option 2: Full Game (Atomic Edition / Steam / GOG)
Copy `DUKE3D.GRP` (and optionally `GAME.CON`, `DEFS.CON`, `USER.CON`) into `~/.config/netduke32/`.

