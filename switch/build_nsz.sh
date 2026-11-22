#!/usr/bin/env bash
# Builds an installable title (NSP and NSZ, for DBI, Tinfoil, Awoo...) of the Switch port.
#
#   switch/build_nsz.sh [path/to/prod.keys]
#
# Without keys it prepares everything that does not need them (ExeFS, control, RomFS) and packs it into
# dist/SpamtonSubplot-nsp-kit.zip, which can be turned into an NSP/NSZ on a PC (see switch/nsp/README.md).
# With keys it also runs hacbrewpack and nsz and writes the NSP/NSZ files to dist/.
#
# The keys must be dumped from your own console (Lockpick_RCM). They are only read, never copied anywhere.
# Needs devkitPro (like build.sh) and, for the key step, `hacbrewpack` and `nsz` (pip install nsz) in PATH
# or set through the HACBREWPACK / NSZ environment variables.
set -euo pipefail

TITLE_ID="01a57b0758b70000"
APP_NAME="Spamton Subplot"
APP_PUBLISHER="SaRlow (Switch port: Butterscotch)"
APP_VERSION="3.5"
KEYS="${1:-${PROD_KEYS:-}}"
HACBREWPACK="${HACBREWPACK:-hacbrewpack}"
NSZ="${NSZ:-nsz}"

: "${DEVKITPRO:=/opt/devkitpro}"
export DEVKITPRO
TOOLS="$DEVKITPRO/tools/bin"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$ROOT/build/switch"
PKG="$WORK/nsp"
DIST="$ROOT/dist"

# 1. Runner ELF and RomFS (also produces the NRO).
if [ -z "${SKIP_RUNNER_BUILD:-}" ]; then
    bash "$ROOT/switch/build.sh"
fi
[ -f "$WORK/cmake/butterscotch.elf" ] || { echo "error: run switch/build.sh first" >&2; exit 1; }

# 2. ExeFS and control.
rm -rf "$PKG"
mkdir -p "$PKG/exefs" "$PKG/control"
"$TOOLS/elf2nso" "$WORK/cmake/butterscotch.elf" "$PKG/exefs/main"
"$TOOLS/npdmtool" "$ROOT/switch/nsp/npdm.json" "$PKG/exefs/main.npdm" 2>/dev/null
"$TOOLS/nacptool" --create "$APP_NAME" "$APP_PUBLISHER" "$APP_VERSION" "$PKG/control/control.nacp" --titleid="$TITLE_ID"
python3 "$ROOT/switch/nsp/make_control.py" "$PKG/control" "$ROOT/switch/icon.jpg" "$APP_NAME" "$APP_PUBLISHER"
# Startup logo (made by switch/nsp/make_logo.py).
cp -r "$ROOT/switch/nsp/logo" "$PKG/logo"

# RomFS variants: English as shipped, Russian with the translation pack baked in
# (the port reads lang/ from the RomFS when the SD card has none).
rm -rf "$PKG/romfs" "$PKG/romfs_ru"
cp -r "$WORK/romfs" "$PKG/romfs"
cp -r "$WORK/romfs" "$PKG/romfs_ru"
cp -r "$ROOT/russian/lang" "$PKG/romfs_ru/lang"

# 3. Keyless kit for building the NSP/NSZ on a PC.
mkdir -p "$DIST"
KIT="$WORK/nsp-kit/SpamtonSubplot-nsp-kit"
rm -rf "$WORK/nsp-kit"
mkdir -p "$KIT"
cp -r "$PKG/exefs" "$PKG/control" "$PKG/logo" "$PKG/romfs" "$KIT/"
cp -r "$ROOT/russian/lang" "$KIT/russian_lang"
cp "$ROOT/switch/nsp/make_nsz.bat" "$ROOT/switch/nsp/make_nsz_ru.bat" "$ROOT/switch/nsp/README.md" "$KIT/"
rm -f "$DIST/SpamtonSubplot-nsp-kit.zip"
(cd "$WORK/nsp-kit" && python3 -c "import shutil; shutil.make_archive('$DIST/SpamtonSubplot-nsp-kit', 'zip', '.')")
echo "kit: $DIST/SpamtonSubplot-nsp-kit.zip"

if [ -z "$KEYS" ]; then
    echo "No prod.keys given: skipping NSP/NSZ packing. Run again with the path to your prod.keys."
    exit 0
fi
[ -f "$KEYS" ] || { echo "error: keys file $KEYS not found" >&2; exit 1; }

# 4. NSP with hacbrewpack, then NSZ with nsz (both need the keys).
pack() {
    local romfs="$1" suffix="$2"
    local tmp="$WORK/hbp$suffix"
    rm -rf "$tmp"
    mkdir -p "$tmp"
    # hacbrewpack sets LogoHandling to Auto in the NACP, so the program NCA must carry the logo section:
    # without it (--nologo) the system applet manager (am) aborts with 2128-0007 on recent firmware.
    "$HACBREWPACK" -k "$KEYS" --titleid "$TITLE_ID" --keygeneration 1 --logodir "$PKG/logo" \
        --exefsdir "$PKG/exefs" --romfsdir "$romfs" --controldir "$PKG/control" \
        --tempdir "$tmp/temp" --ncadir "$tmp/nca" --backupdir "$tmp/backup" --nspdir "$tmp/nsp"
    local nsp="$DIST/SpamtonSubplot$suffix [$TITLE_ID][v0].nsp"
    local built
    built="$(find "$tmp/nsp" -maxdepth 1 -name '*.nsp' | head -n 1)"
    [ -n "$built" ] || { echo "error: hacbrewpack produced no NSP" >&2; exit 1; }
    mv "$built" "$nsp"
    echo "nsp: $nsp"
}
pack "$PKG/romfs" ""
pack "$PKG/romfs_ru" "_RU"

# nsz looks for the keys in ~/.switch/prod.keys.
mkdir -p "$HOME/.switch"
if [ ! -f "$HOME/.switch/prod.keys" ] || ! cmp -s "$KEYS" "$HOME/.switch/prod.keys"; then
    cp "$KEYS" "$HOME/.switch/prod.keys"
fi
# nsz names its output after the title ID and version, which both variants share,
# so compress each one into its own folder and rename it after the NSP.
for nsp in "$DIST"/SpamtonSubplot*"[$TITLE_ID][v0].nsp"; do
    out="$WORK/nsz-out"
    rm -rf "$out"
    mkdir -p "$out"
    "$NSZ" -C -o "$out" "$nsp"
    built="$(find "$out" -maxdepth 1 -name '*.nsz' | head -n 1)"
    [ -n "$built" ] || { echo "error: nsz produced nothing for $nsp" >&2; exit 1; }
    mv "$built" "${nsp%.nsp}.nsz"
    chmod 644 "${nsp%.nsp}.nsz"
done
ls -la "$DIST"
