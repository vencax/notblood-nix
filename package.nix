{
  lib,
  stdenv,
  fetchFromGitHub,
  pkg-config,
  makeWrapper,
  makeDesktopItem,
  copyDesktopItems,
  SDL2,
  libGL,
  alsa-lib,
  flac,
  libvorbis,
  libvpx,
  gtk2,
  zenity,
  curl,
  p7zip,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "notblood";
  version = "0-unstable-2024-09-16";

  src = fetchFromGitHub {
    owner = "clipmove";
    repo = "NotBlood";
    rev = "4aa93cb12194a8864ff467a139cc2ca38595a1ff";
    hash = "sha256-JWvCFmQRYncOlfYHd16vSyinwJJdwlKIZRndPPiTqZU=";
  };

  nativeBuildInputs = [
    pkg-config
    makeWrapper
    copyDesktopItems
  ];

  buildInputs = [
    SDL2
    libGL
    alsa-lib
    flac
    libvorbis
    libvpx
    gtk2
  ];

  enableParallelBuilding = true;

  postPatch = ''
    substituteInPlace source/imgui/src/imgui_impl_sdl2.cpp \
      --replace-fail '#include <SDL.h>' '#include <SDL2/SDL.h>' \
      --replace-fail '#include <SDL_syswm.h>' '#include <SDL2/SDL_syswm.h>' \
      --replace-fail '#include <SDL_vulkan.h>' '#include <SDL2/SDL_vulkan.h>'

    cat << 'EOF' > EDUKE32_REVISION.mak
VC_REV := latest
VC_HASH := 4aa93cb
VC_BRANCH := master
EOF
  '';

  makeFlags = [
    "SDLCONFIG=${SDL2}/bin/sdl2-config"
    "HAVE_GTK2=1"
    "PACKAGE_REPOSITORY=1"
    "LTO=0"
  ];

  buildFlags = [
    "blood"
    "tools"
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/games/notblood $out/share/icons/hicolor/256x256/apps

    # Install binaries
    install -Dm755 notblood $out/bin/.notblood-wrapped
    for t in arttool bsuite cacheinfo generateicon givedepth ivfrate kextract kgroup kmd2tool map2stl; do
      if [ -f "$t" ]; then
        install -Dm755 "$t" "$out/bin/$t"
      fi
    done

    # Engine data file (required by NotBlood)
    install -Dm644 notblood.pk3 $out/share/games/notblood/notblood.pk3

    # Application icon
    if [ -f .github/workflows/logo.png ]; then
      install -Dm644 .github/workflows/logo.png $out/share/icons/hicolor/256x256/apps/notblood.png
    fi

    # Wrapper ensuring engine assets are always mounted via -j
    makeWrapper $out/bin/.notblood-wrapped $out/bin/notblood \
      --prefix PATH : "${lib.makeBinPath [ zenity ]}" \
      --add-flags "-j=$out/share/games/notblood"

    # Helper script to download Blood assets into ~/.config/notblood
    cat << 'EOF' > $out/bin/notblood-download-shareware
#!/usr/bin/env bash
set -euo pipefail

if [[ "''${1:-}" =~ ^(-h|--help)$ ]]; then
  echo "Usage: notblood-download-shareware [DEST_DIR]"
  echo "Downloads Blood game data files (One Unit Whole Blood) into DEST_DIR"
  echo "Default DEST_DIR: \''${XDG_CONFIG_HOME:-\$HOME/.config}/notblood"
  exit 0
fi

DEST_DIR="''${1:-''${XDG_CONFIG_HOME:-$HOME/.config}/notblood}"
mkdir -p "$DEST_DIR"

echo "==> Downloading Blood game assets..."
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

URL="https://archive.org/download/nblood-blood-ouwb/nblood-win64-20240419-r14014.7z"
echo "Downloading archive (~185MB) from Internet Archive..."
${curl}/bin/curl -fL --progress-bar "$URL" -o "$TMP_DIR/blood.7z"

echo "Extracting game assets into $DEST_DIR..."
${p7zip}/bin/7z x "$TMP_DIR/blood.7z" -o"$TMP_DIR/extracted" -y > /dev/null

EXTRACT_SRC="$(find "$TMP_DIR/extracted" -type f -iname 'blood.rff' | head -n 1)"
if [ -n "$EXTRACT_SRC" ]; then
  SRC_DIR="$(dirname "$EXTRACT_SRC")"
  cp -rf "$SRC_DIR"/* "$DEST_DIR/"
else
  ${p7zip}/bin/7z e "$TMP_DIR/blood.7z" -o"$DEST_DIR" -y > /dev/null
fi

echo "==> Success! Blood assets are installed in: $DEST_DIR"
echo "Launch the game by running: notblood"
EOF
    chmod +x $out/bin/notblood-download-shareware

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "notblood";
      icon = "notblood";
      exec = "notblood";
      comment = "Enhanced source port of Blood";
      desktopName = "NotBlood";
      genericName = "Blood Source Port";
      categories = [ "Game" ];
    })
  ];

  meta = {
    description = "Gameplay mod and source port of Blood based on NBlood and EDuke32";
    homepage = "https://github.com/clipmove/NotBlood";
    license = lib.licenses.gpl2Plus;
    platforms = [ "x86_64-linux" ];
    mainProgram = "notblood";
  };
})
