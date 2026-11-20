#!/usr/bin/env bash
# Builds SpamtonSubplot.nro (Nintendo Switch homebrew) from the game's data.win
# using the open source Butterscotch GameMaker runner.
#
# Requires devkitPro with the Switch toolchain (devkitA64 + libnx + switch-sdl2 + switch-mesa).
# The easiest way is the official container:
#   docker run --rm -v "$PWD":/work -w /work devkitpro/devkita64:latest bash switch/build.sh
set -euo pipefail

BUTTERSCOTCH_REPO="https://github.com/ButterscotchRunner/Butterscotch"
BUTTERSCOTCH_COMMIT="a487150fd004d47be1f34157e543cec253bd993b"

APP_NAME="Spamton Subplot"
APP_AUTHOR="Spamton Subplot fan game (Butterscotch port)"
APP_VERSION="2.0.0"
SAVE_DIR="sdmc:/switch/spamton_subplot"

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

# 2. Port-specific changes: keep saves in our own folder instead of the generic one.
MAIN_C="$SRC/src/switch/main.c"
grep -q 'args.saveFolder = "sdmc:/switch/butterscotch";' "$MAIN_C" \
    || { echo "error: save folder line not found in $MAIN_C, update the patch" >&2; exit 1; }
sed -i "s|args.saveFolder = \"sdmc:/switch/butterscotch\";|args.saveFolder = \"$SAVE_DIR\";|" "$MAIN_C"
sed -i "s|\"sdmc:/switch/butterscotch/data.win\"|\"$SAVE_DIR/data.win\"|" "$MAIN_C"

# 3. Build the runner ELF.
cmake -S "$SRC" -B "$BUILD" -G Ninja \
    -DPLATFORM=switch \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON
cmake --build "$BUILD"

ELF="$(find "$BUILD" -maxdepth 1 -name 'butterscotch*.elf' | head -n 1)"
[ -n "$ELF" ] || { echo "error: butterscotch ELF not found in $BUILD" >&2; exit 1; }

# 4. RomFS: everything the game reads at runtime, next to data.win.
rm -rf "$ROMFS"
mkdir -p "$ROMFS"
for f in data.win audio_music.dat font.otf keybinds.txt options.ini; do
    cp "$ROOT/$f" "$ROMFS/$f"
done

# 5. Package the NRO with our name, author, version and icon.
"$TOOLS/nacptool" --create "$APP_NAME" "$APP_AUTHOR" "$APP_VERSION" "$WORK/app.nacp"
"$TOOLS/elf2nro" "$ELF" "$DIST/SpamtonSubplot.nro" \
    --icon="$ROOT/switch/icon.jpg" \
    --nacp="$WORK/app.nacp" \
    --romfsdir="$ROMFS"

ls -la "$DIST/SpamtonSubplot.nro"
