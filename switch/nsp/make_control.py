"""Finishes the control folder of the NSP: patches control.nacp and writes an icon for every language.

usage: python3 make_control.py <control dir> <icon.jpg> <title name> <publisher>
The control dir must already contain control.nacp made by nacptool (with --titleid).
"""
import os
import struct
import sys

LANGUAGES = [
    "AmericanEnglish", "BritishEnglish", "Japanese", "French", "German", "LatinAmericanSpanish", "Spanish",
    "Italian", "Dutch", "CanadianFrench", "Portuguese", "Russian", "Korean", "TraditionalChinese",
    "SimplifiedChinese", "BrazilianPortuguese",
]

control_dir, icon_path, name, publisher = sys.argv[1:5]
nacp_path = os.path.join(control_dir, "control.nacp")
nacp = bytearray(open(nacp_path, "rb").read())
assert len(nacp) == 0x4000, "unexpected NACP size"

# Same name and publisher for all 16 languages, so the HOME menu never shows an empty title.
for i in range(len(LANGUAGES)):
    entry = i * 0x300
    nacp[entry:entry + 0x200] = name.encode("utf-8")[:0x1FF].ljust(0x200, b"\0")
    nacp[entry + 0x200:entry + 0x300] = publisher.encode("utf-8")[:0xFF].ljust(0x100, b"\0")

nacp[0x3025] = 0                                        # StartupUserAccount: none, the game saves to the SD card
struct.pack_into("<I", nacp, 0x302C, (1 << len(LANGUAGES)) - 1)  # SupportedLanguageFlag: all languages
nacp[0x3035] = 2                                        # VideoCapture: enabled
nacp[0x30F1] = 0                                        # LogoHandling: auto, the NCA carries logo/ (make_logo.py)
struct.pack_into("<qq", nacp, 0x3080, 0, 0)             # no user account save data

open(nacp_path, "wb").write(nacp)

icon = open(icon_path, "rb").read()
assert icon[:2] == b"\xff\xd8", "icon must be a JPEG"
for lang in LANGUAGES:
    open(os.path.join(control_dir, f"icon_{lang}.dat"), "wb").write(icon)
print(f"control ready: {name} / {publisher}, {len(LANGUAGES)} languages")
