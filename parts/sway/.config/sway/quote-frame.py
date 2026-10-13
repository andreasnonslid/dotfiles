#!/usr/bin/env python3
"""Render the lock frame: the horizon art with one quote in the calm band at the top.

  quote-frame.py --render OUT [--new]

The quote is chosen from the date and time (YYYYMMDDHHMMSS) and remembered, so the frame sway shows
the instant it starts and the lock screen on top of it carry the same one. --new picks a fresh quote
(never the same as the last) for the next lock. No window is ever opened; this only writes a PNG.
"""

import os
import random
import re
import sys
import time
from pathlib import Path

import cairo
import gi

gi.require_version("Pango", "1.0")
gi.require_version("PangoCairo", "1.0")
from gi.repository import Pango, PangoCairo  # noqa: E402

HERE = Path(__file__).resolve().parent
HOME = Path.home()
PAL = HOME / ".local/share/palette"
QUOTE_FILE = PAL / "login-quote.txt"
SERIF, MONO = "Liberation Serif", "IosevkaTerm Nerd Font"


def colors():
    c = {"fg": "#cdd6f4", "accent": "#cba6f7", "bg": "#1e1e2e"}
    try:
        for line in (HOME / ".config/sway/colors.conf").read_text().splitlines():
            m = re.match(r"set \$(\w+)\s+(#[0-9a-fA-F]{6})", line)
            if m and m[1] in c:
                c[m[1]] = m[2]
    except OSError:
        pass
    return {
        k: tuple(int(v[i : i + 2], 16) / 255 for i in (1, 3, 5)) for k, v in c.items()
    }


def rows():
    out = []
    try:
        for line in (HERE / "quotes.txt").read_text().splitlines():
            if "|" in line and not line.startswith("#"):
                q, a = line.split("|", 1)
                out.append((q.strip(), a.strip()))
    except OSError:
        pass
    return out


def pick(offset=0):
    seed = int(time.strftime("%Y%m%d%H%M%S")) + offset
    r = rows()
    return random.Random(seed).choice(r) if r else ("Good things take a moment.", "")


def load_quote(new=False):
    previous = ""
    try:
        previous = QUOTE_FILE.read_text().split("|", 1)[0].strip()
        if not new:
            q, a = QUOTE_FILE.read_text().split("|", 1)
            return q.strip(), a.strip()
    except (OSError, ValueError):
        pass
    quote = pick()
    if (
        quote[0] == previous
    ):  # still seeded by the date and time, never the same one twice in a row
        r = [x for x in rows() if x[0] != previous]
        quote = (
            random.Random(int(time.strftime("%Y%m%d%H%M%S")) + 1).choice(r)
            if r
            else quote
        )
    try:
        PAL.mkdir(parents=True, exist_ok=True)
        QUOTE_FILE.write_text(f"{quote[0]}|{quote[1]}\n")
    except OSError:
        pass
    return quote


def render(out, new):
    c = colors()
    try:
        art = cairo.ImageSurface.create_from_png(str(PAL / "splash-bg.png"))
        w, h = art.get_width(), art.get_height()
    except (OSError, cairo.Error):
        art, w, h = None, 1920, 1080
    surf = cairo.ImageSurface(cairo.FORMAT_ARGB32, w, h)
    cr = cairo.Context(surf)
    cr.set_source_rgb(*c["bg"])
    cr.paint()
    if art is not None:
        cr.set_source_surface(art, 0, 0)
        cr.paint()

    text, author = load_quote(new)
    box = w * 0.60
    lay = PangoCairo.create_layout(cr)
    lay.set_width(int(box * Pango.SCALE))
    lay.set_alignment(Pango.Alignment.CENTER)
    lay.set_font_description(
        Pango.FontDescription(f"{SERIF} Italic {max(18, int(h * 0.034))}")
    )
    lay.set_text("“" + text + "”", -1)
    tw, th = lay.get_pixel_size()
    top = h * 0.085
    cr.set_source_rgba(*c["fg"], 0.95)
    cr.move_to((w - box) / 2, top)
    PangoCairo.show_layout(cr, lay)
    if author:
        al = PangoCairo.create_layout(cr)
        al.set_font_description(
            Pango.FontDescription(f"{MONO} {max(11, int(h * 0.0175))}")
        )
        al.set_text("—  " + author, -1)
        aw, _ = al.get_pixel_size()
        cr.set_source_rgba(*c["accent"], 0.95)
        cr.move_to((w - aw) / 2, top + th + h * 0.02)
        PangoCairo.show_layout(cr, al)

    tmp = Path(str(out) + ".tmp")
    surf.write_to_png(str(tmp))
    os.replace(tmp, out)


if __name__ == "__main__":
    if "--render" in sys.argv:
        render(Path(sys.argv[sys.argv.index("--render") + 1]), "--new" in sys.argv)
    else:
        sys.exit(__doc__)
