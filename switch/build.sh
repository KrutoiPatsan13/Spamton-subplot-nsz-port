#!/usr/bin/env bash
# Builds SpamtonSubplot.nro (Nintendo Switch homebrew) from the game's data.win
# using the open source Butterscotch GameMaker runner plus this port's patch.
#
# Requires devkitPro with the Switch toolchain (devkitA64, libnx, switch-sdl2, switch-mesa, switch-ffmpeg).
# The easiest way is the official container:
#   docker run --rm -v "$PWD":/work -w /work devkitpro/devkita64:latest bash switch/build.sh
set -euo pipefail

BUTTERSCOTCH_REPO="https://github.com/ButterscotchRunner/Butterscotch"
BUTTERSCOTCH_COMMIT="a487150fd004d47be1f34157e543cec253bd993b"

APP_NAME="Spamton Subplot"
APP_AUTHOR="SaRlow (Switch port: Butterscotch)"
APP_VERSION="3.5"

: "${DEVKITPRO:=/opt/devkitpro}"
export DEVKITPRO
TOOLS="$DEVKITPRO/tools/bin"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$ROOT/build/switch"
SRC="$WORK/butterscotch"
BUILD="$WORK/cmake"
ROMFS="$WORK/romfs"
DIST="$ROOT/dist"

mkdir -p "$WORK" "$DIST"

# 1. Fetch Butterscotch at a pinned commit, so builds are reproducible.
if [ ! -d "$SRC/.git" ]; then
    git init -q "$SRC"
    git -C "$SRC" remote add origin "$BUTTERSCOTCH_REPO"
fi
git -C "$SRC" fetch -q --depth 1 origin "$BUTTERSCOTCH_COMMIT"
git -C "$SRC" checkout -q --force FETCH_HEAD
git -C "$SRC" clean -qfdx

# 2. Port changes: font_add and other missing builtins, native resolution, asset overrides
#    (borders, Switch controls, translations), Switch button layout and save folder.
git -C "$SRC" apply --whitespace=nowarn "$ROOT/switch/patches/butterscotch-port.patch"

# 3. Build the runner ELF.
cmake -S "$SRC" -B "$BUILD" -G Ninja \
    -DPLATFORM=switch \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON
cmake --build "$BUILD"

ELF="$BUILD/butterscotch.elf"
[ -f "$ELF" ] || { echo "error: $ELF was not built" >&2; exit 1; }

# 4. RomFS: everything the game reads at runtime next to data.win, plus the port's own assets.
rm -rf "$ROMFS"
mkdir -p "$ROMFS"
for f in data.win audio_music.dat font.otf keybinds.txt options.ini; do
    cp "$ROOT/$f" "$ROMFS/$f"
done
cp -r "$ROOT/switch/romfs/." "$ROMFS/"

# 5. Package the NRO with name, author, version and icon.
"$TOOLS/nacptool" --create "$APP_NAME" "$APP_AUTHOR" "$APP_VERSION" "$WORK/app.nacp"
"$TOOLS/elf2nro" "$ELF" "$DIST/SpamtonSubplot.nro" \
    --icon="$ROOT/switch/icon.jpg" \
    --nacp="$WORK/app.nacp" \
    --romfsdir="$ROMFS"

ls -la "$DIST/SpamtonSubplot.nro"
