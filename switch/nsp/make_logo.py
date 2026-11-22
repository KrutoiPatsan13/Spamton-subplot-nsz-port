"""Generates the startup logo of the installable title (switch/nsp/logo/).

usage: python3 make_logo.py <font.otf> <output dir>

The Switch shows the program NCA's logo section while the game starts: NintendoLogo.png in the top left corner
and StartupMovie.gif in the bottom right one. The NACP says the system handles the logo ("Auto"), so the title
must ship both files: a package without them fails to start on recent firmware.
NintendoLogo.png is left black (nothing in the corner); StartupMovie.gif types "SPAMTON SUBPLOT" in the game's font.
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFont

font_path, out_dir = sys.argv[1:3]
os.makedirs(out_dir, exist_ok=True)

# Same size and format as the logos that NTON packs into forwarders known to start on firmware 21 and newer.
Image.new("RGB", (256, 128), (0, 0, 0)).save(os.path.join(out_dir, "NintendoLogo.png"), optimize=True)

W, H = 256, 80
TEXT = ["SPAMTON", "SUBPLOT"]
font = ImageFont.truetype(font_path, 32)
small = ImageFont.truetype(font_path, 16)

# Palette: index 0 is the transparent black background, 1..255 a ramp up to Spamton's yellow on the last glyph.
palette = [0, 0, 0]
for i in range(1, 256):
    v = i / 255
    palette += [round(255 * v), round(255 * v), round(255 * v)]
YELLOW = 255
palette[YELLOW * 3:YELLOW * 3 + 3] = [255, 236, 0]
WHITE = 254
palette[WHITE * 3:WHITE * 3 + 3] = [255, 255, 255]


def frame(chars_shown, cursor_on, tag_alpha):
    im = Image.new("L", (W, H), 0)
    d = ImageDraw.Draw(im)
    d.fontmode = "1"  # pixel font: no anti-aliasing
    y = 4
    remaining = chars_shown
    last = None
    for line in TEXT:
        shown = line[:max(0, remaining)]
        remaining -= len(line)
        left, _, right, _ = d.textbbox((0, 0), line, font=font)
        x = W - 8 - right
        d.text((x, y), shown, font=font, fill=WHITE)
        if shown and len(shown) < len(line) or (remaining <= 0 and last is None and shown):
            last = (x + d.textlength(shown, font=font), y)
        y += 34
    if cursor_on and last is not None:
        cx, cy = last
        d.rectangle([cx + 2, cy + 24, cx + 14, cy + 27], fill=YELLOW)
    if tag_alpha:
        d.text((6, H - 18), "[[BIG SHOT]]", font=small, fill=YELLOW)
    out = Image.frombytes("P", (W, H), im.tobytes())
    out.putpalette(palette)
    return out


total = sum(len(t) for t in TEXT)
frames, durations = [], []
frames.append(frame(0, True, False))
durations.append(300)
for n in range(1, total + 1):
    frames.append(frame(n, True, False))
    durations.append(60)
for i in range(6):
    frames.append(frame(total, i % 2 == 0, True))
    durations.append(250)

frames[0].save(
    os.path.join(out_dir, "StartupMovie.gif"), save_all=True, append_images=frames[1:], duration=durations,
    loop=0, transparency=0, disposal=2, optimize=False,
)
print("logo ready:", out_dir)
