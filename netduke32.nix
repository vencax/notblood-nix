{ lib
, stdenv
, fetchgit
, pkg-config
, makeWrapper
, copyDesktopItems
, makeDesktopItem
, sdl2-compat
, libglvnd
, alsa-lib
, flac
, libvorbis
, libvpx
, gtk2
, zenity
, curl
, unzip
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "netduke32";
  version = "1.2.1";

  src = fetchgit {
    url = "https://voidpoint.io/StrikerTheHedgefox/eduke32-csrefactor.git";
    rev = "f919616e0792a7af1f8006af5e606f0e26927673";
    hash = "sha256-kH9B602IOev+OEWHoeHurI7UUkuiCTFlaavS+6qtJNY=";
  };

  nativeBuildInputs = [
    pkg-config
    makeWrapper
    copyDesktopItems
  ];

  buildInputs = [
    sdl2-compat
    libglvnd
    alsa-lib
    flac
    libvorbis
    libvpx
    gtk2
  ];

  postPatch = ''
    substituteInPlace source/imgui/src/imgui_impl_sdl.cpp \
      --replace-fail '#include <SDL.h>' '#include <SDL2/SDL.h>' \
      --replace-fail '#include <SDL_syswm.h>' '#include <SDL2/SDL_syswm.h>' \
      --replace-fail '#include <SDL_vulkan.h>' '#include <SDL2/SDL_vulkan.h>'

    substituteInPlace source/build/include/libdivide.h \
      --replace-fail 'return div.denom.magic == other.denom.magic && div.denom.more == other.denom.more;' \
                     'return div.denom.magic == other.div.denom.magic && div.denom.more == other.div.denom.more;'

    cat << 'EOF' > EDUKE32_REVISION.mak
VC_REV := 1.2.1
VC_HASH := f919616
VC_BRANCH := master
EOF
  '';

  buildFlags = [ "netduke32" ];

  makeFlags = [
    "SDLCONFIG=${sdl2-compat}/bin/sdl2-config"
    "HAVE_GTK2=1"
    "PACKAGE_REPOSITORY=1"
    "LTO=0"
  ];

  enableParallelBuilding = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/games/netduke32 $out/share/icons/hicolor/256x256/apps

    # Install binary
    install -Dm755 netduke32 $out/bin/.netduke32-wrapped

    # Engine data file (required by EDuke32/NetDuke32)
    if [ -f eduke32.dat ]; then
      install -Dm644 eduke32.dat $out/share/games/netduke32/eduke32.dat
    fi

    # Application icon
    if [ -f source/netduke32/rsrc/game_icon.png ]; then
      install -Dm644 source/netduke32/rsrc/game_icon.png $out/share/icons/hicolor/256x256/apps/netduke32.png
    fi

    # Wrapper ensuring engine assets are always mounted via -j
    makeWrapper $out/bin/.netduke32-wrapped $out/bin/netduke32 \
      --prefix PATH : "${lib.makeBinPath [ zenity ]}" \
      --add-flags "-j=$out/share/games/netduke32"

    # Helper script to download Duke Nukem 3D Shareware assets into ~/.config/netduke32
    cat << 'EOF' > $out/bin/netduke32-download-shareware
#!/usr/bin/env bash
set -euo pipefail

if [[ "''${1:-}" =~ ^(-h|--help)$ ]]; then
  echo "Usage: netduke32-download-shareware [DEST_DIR]"
  echo "Downloads Duke Nukem 3D Shareware game assets (DUKE3D.GRP, CON files) into DEST_DIR"
  echo "Default DEST_DIR: \''${XDG_CONFIG_HOME:-\$HOME/.config}/netduke32"
  exit 0
fi

DEST_DIR="''${1:-''${XDG_CONFIG_HOME:-$HOME/.config}/netduke32}"
mkdir -p "$DEST_DIR"

echo "==> Downloading Duke Nukem 3D Shareware game assets..."
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

URL="https://archive.org/download/duke-3-d/DUKE3D.zip"
echo "Downloading archive (~16MB) from Internet Archive..."
${curl}/bin/curl -fL --progress-bar "$URL" -o "$TMP_DIR/duke3d.zip"

echo "Extracting game assets into $DEST_DIR..."
${unzip}/bin/unzip -qo "$TMP_DIR/duke3d.zip" -d "$TMP_DIR/extracted"

EXTRACT_SRC="$(find "$TMP_DIR/extracted" -type f -iname 'duke3d.grp' | head -n 1)"
if [ -n "$EXTRACT_SRC" ]; then
  SRC_DIR="$(dirname "$EXTRACT_SRC")"
  cp -rf "$SRC_DIR"/* "$DEST_DIR/"
else
  ${unzip}/bin/unzip -qo "$TMP_DIR/duke3d.zip" -d "$DEST_DIR/"
fi

echo "==> Success! Duke Nukem 3D Shareware assets are installed in: $DEST_DIR"
echo "Launch the game by running: netduke32"
EOF
    chmod +x $out/bin/netduke32-download-shareware

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "netduke32";
      icon = "netduke32";
      exec = "netduke32";
      comment = "Advanced Duke Nukem 3D source port with improved multiplayer functionality";
      desktopName = "NetDuke32";
      genericName = "Duke Nukem 3D Source Port";
      categories = [ "Game" ];
    })
  ];

  meta = {
    description = "Advanced Duke Nukem 3D source port with improved multiplayer functionality";
    homepage = "https://voidpoint.io/StrikerTheHedgefox/eduke32-csrefactor";
    license = lib.licenses.gpl2Plus;
    platforms = [ "x86_64-linux" ];
    mainProgram = "netduke32";
  };
})
