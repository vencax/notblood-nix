# notblood-nix

Nix flake packaging for [NotBlood](https://github.com/clipmove/NotBlood), an enhanced gameplay mod and source port of **Blood** based on NBlood and EDuke32 engine technology.

## Features
- Native Linux build with SDL2 and Wayland support.
- Pre-packaged mod resources (`notblood.pk3`).
- Desktop launcher integration and application icons.
- Includes engine tools (`kextract`, `kgroup`, `bsuite`, `arttool`, etc.).
- Includes `notblood-download-shareware` helper to quickly set up game assets.

---

## Quick Run

Run directly with Nix Flakes:

```bash
nix run github:vencax/notblood-nix
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
