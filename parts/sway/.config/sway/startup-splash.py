#!/usr/bin/env python3
"""Login splash: a calm background image, one quote, and a quiet line showing the desktop coming up.

The quote is picked at random, seeded from the date and time (so it differs every login).
Progress reads milestone files that startup-reveal.sh creates in $XDG_RUNTIME_DIR/startup/:
  waybar terminal zed firefox -> a dot lights per piece;  done -> finish and exit.
Exits by itself after 9 s or on any key press, so it can never trap the session.
"""
import math
import os
import random
import re
import time
from pathlib import Path

import gi
gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
gi.require_version("Pango", "1.0")
gi.require_version("PangoCairo", "1.0")
from gi.repository import GLib, Gdk, GdkPixbuf, Gtk, Pango, PangoCairo  # noqa: E402

GLib.set_prgname("startup-splash")  # the Wayland app_id the sway rule matches

HERE = Path(__file__).resolve().parent
HOME = Path.home()
RUN = Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp")) / "startup"
STEPS = [("waybar", "bar"), ("terminal", "terminal"), ("zed", "editor"), ("firefox", "browser")]
SERIF = "Liberation Serif"
MONO = "IosevkaTerm Nerd Font"


def colors():
    c = {"bg": "#1e1e2e", "fg": "#cdd6f4", "dim": "#6c7086", "accent": "#cba6f7", "accent2": "#89b4fa"}
    try:
        for line in (HOME / ".config/sway/colors.conf").read_text().splitlines():
            m = re.match(r"set \$(\w+)\s+(#[0-9a-fA-F]{6})", line)
            if m and m[1] in c:
                c[m[1]] = m[2]
    except OSError:
        pass
    return {k: tuple(int(v[i:i + 2], 16) / 255 for i in (1, 3, 5)) for k, v in c.items()}


QUOTE_FILE = HOME / ".local/share/palette/login-quote.txt"
FRAME_FILE = HOME / ".local/share/palette/login-frame.png"


def _rows():
    rows = []
    try:
        for line in (HERE / "quotes.txt").read_text().splitlines():
            if "|" in line and not line.startswith("#"):
                q, a = line.split("|", 1)
                rows.append((q.strip(), a.strip()))
    except OSError:
        pass
    return rows


def pick_quote(now=None):
    """Seeded from the date and time, as the user asked: YYYYMMDDHHMMSS."""
    seed = int(time.strftime("%Y%m%d%H%M%S", now or time.localtime()))
    rows = _rows()
    return random.Random(seed).choice(rows) if rows else ("Good things take a moment.", "")


def load_quote(new=False):
    """The quote the prepared login frame shows (so the splash continues it unchanged).
    new=True picks a fresh one from the current date and time and remembers it for the next login."""
    if not new:
        try:
            q, a = QUOTE_FILE.read_text().split("|", 1)
            return q.strip(), a.strip()
        except (OSError, ValueError):
            pass
    quote = pick_quote()
    try:
        previous = QUOTE_FILE.read_text().split("|", 1)[0].strip()
    except OSError:
        previous = ""
    if quote[0] == previous:
        # still seeded by the date and time, just never the same quote twice in a row
        seed = int(time.strftime("%Y%m%d%H%M%S")) + 1
        rows = [r for r in _rows() if r[0] != previous]
        quote = random.Random(seed).choice(rows) if rows else quote
    try:
        QUOTE_FILE.parent.mkdir(parents=True, exist_ok=True)
        QUOTE_FILE.write_text(f"{quote[0]}|{quote[1]}\n")
    except OSError:
        pass
    return quote


def paint(cr, w, h, c, bg, quote, shown, ready):
    """Draw one frame. `shown` is the eased progress 0..1, `ready` a list of bools per step."""
    cr.set_source_rgb(*c["bg"])
    cr.paint()
    if bg is not None:
        sc = max(w / bg.get_width(), h / bg.get_height())
        cr.save()
        cr.scale(sc, sc)
        Gdk.cairo_set_source_pixbuf(cr, bg, (w / sc - bg.get_width()) / 2, (h / sc - bg.get_height()) / 2)
        cr.paint()
        cr.restore()

    # the quote, centred in the calm upper-middle area
    text, author = quote
    box = w * 0.56
    lay = PangoCairo.create_layout(cr)
    lay.set_width(int(box * Pango.SCALE))
    lay.set_alignment(Pango.Alignment.CENTER)
    lay.set_font_description(Pango.FontDescription(f"{SERIF} Italic {max(22, int(h * 0.043))}"))
    lay.set_text("“" + text + "”", -1)
    tw, th = lay.get_pixel_size()
    top = h * 0.30 - th / 2
    cr.set_source_rgba(*c["fg"], 0.96)
    cr.move_to((w - box) / 2, top)
    PangoCairo.show_layout(cr, lay)

    if author:
        al = PangoCairo.create_layout(cr)
        al.set_font_description(Pango.FontDescription(f"{MONO} {max(12, int(h * 0.02))}"))
        al.set_text("—  " + author, -1)
        aw, ah = al.get_pixel_size()
        cr.set_source_rgba(*c["accent"], 0.95)
        cr.move_to((w - aw) / 2, top + th + h * 0.025)
        PangoCairo.show_layout(cr, al)

    # a quiet progress line near the bottom and four dots under it
    lw, lh = w * 0.22, max(2.0, h * 0.0028)
    x, y = (w - lw) / 2, h * 0.93
    cr.set_source_rgba(*c["fg"], 0.18)
    cr.rectangle(x, y, lw, lh)
    cr.fill()
    cr.set_source_rgba(*c["accent"], 0.95)
    cr.rectangle(x, y, lw * shown, lh)
    cr.fill()
    gap = lw / (len(STEPS) - 1)
    for i, ok in enumerate(ready):
        cr.set_source_rgba(*(c["accent2"] if ok else c["fg"]), 0.9 if ok else 0.25)
        cr.arc(x + i * gap, y + h * 0.020, h * 0.003, 0, 2 * math.pi)
        cr.fill()


class Splash(Gtk.Window):
    def __init__(self):
        super().__init__(title="startup-splash")
        self.c = colors()
        self.quote = load_quote()
        self.start = time.time()
        self.shown = 0.0
        self.finish_at = None
        try:
            self.bg = GdkPixbuf.Pixbuf.new_from_file(str(HOME / ".local/share/palette/splash-bg.png"))
        except GLib.Error:
            self.bg = None
        self.set_decorated(False)
        self.fullscreen()
        self.connect("destroy", Gtk.main_quit)
        self.connect("key-press-event", lambda *_: Gtk.main_quit())
        self.area = Gtk.DrawingArea()
        self.area.connect("draw", lambda wd, cr: paint(
            cr, wd.get_allocated_width(), wd.get_allocated_height(), self.c, self.bg, self.quote,
            self.shown, self.milestones()))
        self.add(self.area)
        GLib.timeout_add(33, self.tick)
        self.show_all()

    def milestones(self):
        return [(RUN / name).exists() for name, _ in STEPS]

    def tick(self):
        done = (RUN / "done").exists()
        target = 1.0 if done else sum(self.milestones()) / len(STEPS) * 0.92
        self.shown += (target - self.shown) * (0.6 if done else 0.14)
        if done and self.finish_at is None:
            self.finish_at = time.time() + 0.10   # ~3 frames: just enough to see the bar complete
        if (self.finish_at and time.time() >= self.finish_at) or time.time() - self.start > 9:
            Gtk.main_quit()
            return False
        self.area.queue_draw()
        return True


def render(out, new):
    """Write the login frame (art + quote + empty progress) to a PNG without opening a window."""
    import cairo
    c = colors()
    try:
        bg = GdkPixbuf.Pixbuf.new_from_file(str(HOME / ".local/share/palette/splash-bg.png"))
    except GLib.Error:
        bg = None
    w, h = (bg.get_width(), bg.get_height()) if bg else (1920, 1080)
    surf = cairo.ImageSurface(cairo.FORMAT_ARGB32, w, h)
    paint(cairo.Context(surf), w, h, c, bg, load_quote(new), 0.0, [False] * len(STEPS))
    tmp = Path(str(out) + ".tmp")
    surf.write_to_png(str(tmp))
    os.replace(tmp, out)


if __name__ == "__main__":
    import sys
    if "--render" in sys.argv:
        render(Path(sys.argv[sys.argv.index("--render") + 1]), "--new" in sys.argv)
        raise SystemExit(0)
    splash = Splash()  # keep a reference: an unreferenced window is garbage-collected at once
    Gtk.main()
