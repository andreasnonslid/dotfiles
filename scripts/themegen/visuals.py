"""Generated imagery: the wallpaper, the lock/login art, and the boot splash."""
import math
import os
import random
import shutil
import struct
import tempfile
import zlib
from .core import GEN, ROOT, WALLPAPER, mix, rgb


def png(path, w, h, rows):
    def chunk(tag, data):
        b = struct.pack(">I", len(data)) + tag + data
        return b + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    raw = b"".join(b"\x00" + bytes(r) for r in rows)
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(dir=path.parent, delete=False) as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0)))
        f.write(chunk(b"IDAT", zlib.compress(raw, 6)))
        f.write(chunk(b"IEND", b""))
    os.replace(f.name, path)


def wallpaper(c, kind, w=1280, h=720):
    """kind: flat | glow (two soft glows + ring) | rings (concentric rings)."""
    bg, a1, a2 = rgb(c["bg"]), rgb(c["accent"]), rgb(c["accent2"])
    lo = tuple(int(v * 0.55) for v in bg)
    hi = tuple(min(255, int(v * 1.25) + 6) for v in bg)
    glows = [((0.15, 0.9), 0.65, a1, 0.34), ((0.88, 0.12), 0.55, a2, 0.28)]
    asp = w / h
    rows = []
    for y in range(h):
        row = bytearray()
        fy = y / h
        for x in range(w):
            fx = x / w
            if kind == "flat":
                px = list(bg)
            else:
                u = fx * 0.5 + fy * 0.5
                px = [hi[i] + (lo[i] - hi[i]) * u for i in range(3)]
            if kind == "glow":
                for (cx, cy), r, col, st in glows:
                    d = math.hypot((fx - cx) * asp, fy - cy) / r
                    if d < 1:
                        k = (1 - d) ** 2 * st
                        for i in range(3):
                            px[i] += (col[i] - px[i]) * k
                d = math.hypot((fx - 0.15) * asp, fy - 0.9)
                ring = max(0.0, 1 - abs(d - 0.45) / 0.004) * 0.10
                for i in range(3):
                    px[i] += (a1[i] - px[i]) * ring
            elif kind == "rings":
                d = math.hypot((fx - 0.5) * asp, fy - 0.5)
                for n in range(1, 9):
                    ring = max(0.0, 1 - abs(d - n * 0.12) / 0.004) * (0.22 - n * 0.02)
                    col = a1 if n % 2 else a2
                    for i in range(3):
                        px[i] += (col[i] - px[i]) * ring
            row += bytes(int(min(255, max(0, v))) for v in px)
        rows.append(row)
    png(WALLPAPER, w, h, rows)


def make_splash_bg(c, w=1920, h=1080):
    """Calm 'horizon' art in the palette: sky, a big soft moon, layered ridges low down.
    The upper middle is left clear on purpose: the login splash puts its quote there."""
    import cairo
    import hashlib

    rnd = random.Random(int(hashlib.sha256((c["bg"] + c["accent"]).encode()).hexdigest()[:12], 16))
    col = lambda hexc, a=1.0: tuple(v / 255 for v in rgb(hexc)) + (a,)
    surf = cairo.ImageSurface(cairo.FORMAT_ARGB32, w, h)
    cr = cairo.Context(surf)

    sky = cairo.LinearGradient(0, 0, 0, h)
    sky.add_color_stop_rgba(0.00, *col(mix(c["bg"], "#000000", 0.30)))
    sky.add_color_stop_rgba(0.55, *col(c["bg"]))
    sky.add_color_stop_rgba(0.78, *col(mix(c["bg"], c["accent"], 0.38)))
    sky.add_color_stop_rgba(1.00, *col(mix(c["bg"], c["accent2"], 0.30)))
    cr.set_source(sky)
    cr.paint()

    # sparse stars, kept away from the quote area
    for _ in range(140):
        x, y = rnd.random() * w, rnd.random() * h * 0.5
        if w * 0.18 < x < w * 0.82 and h * 0.16 < y < h * 0.5:
            continue
        cr.set_source_rgba(*col(c["fg"], 0.15 + rnd.random() * 0.35))
        cr.arc(x, y, 0.6 + rnd.random() * 1.1, 0, 2 * math.pi)
        cr.fill()

    # moon with a wide glow, low on the right so the centre stays free
    mx, my, mr = w * 0.76, h * 0.60, h * 0.085
    glow = cairo.RadialGradient(mx, my, mr * 0.4, mx, my, mr * 6)
    glow.add_color_stop_rgba(0, *col(c["accent2"], 0.40))
    glow.add_color_stop_rgba(1, *col(c["accent2"], 0.0))
    cr.set_source(glow)
    cr.paint()
    cr.set_source_rgba(*col(mix(c["fg"], c["accent2"], 0.25), 0.95))
    cr.arc(mx, my, mr, 0, 2 * math.pi)
    cr.fill()

    # ridgelines: back to front, darker toward the viewer
    layers = 5
    for i in range(layers):
        f = i / (layers - 1)
        base = h * (0.62 + 0.07 * i)
        amp = h * (0.075 - 0.008 * i)
        phase = [rnd.random() * 6.28 for _ in range(4)]
        freq = [1.1 + i * 0.25, 2.3 + i * 0.4, 4.7, 9.0]
        cr.move_to(0, h)
        for px in range(0, w + 8, 8):
            x = px / w
            y = base - amp * (
                0.55 * math.sin(freq[0] * 6.28 * x + phase[0])
                + 0.28 * math.sin(freq[1] * 6.28 * x + phase[1])
                + 0.12 * math.sin(freq[2] * 6.28 * x + phase[2])
                + 0.05 * math.sin(freq[3] * 6.28 * x + phase[3]))
            cr.line_to(px, y)
        cr.line_to(w, h)
        cr.close_path()
        cr.set_source_rgba(*col(mix(mix(c["bg"], c["accent"], 0.30 - 0.22 * f), "#000000", 0.10 + 0.55 * f)))
        cr.fill()

    out = WALLPAPER.parent / "splash-bg.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    surf.write_to_png(str(out))


def make_plymouth(c):
    """Boot splash into linux/plymouth/dotfiles: the lock screen's horizon art and one thin progress
    line, so boot -> lock is a single continuous scene (installed by linux/install-plymouth.sh)."""
    import cairo
    out = ROOT / "linux/plymouth/dotfiles"
    out.mkdir(parents=True, exist_ok=True)
    art = WALLPAPER.parent / "splash-bg.png"
    shutil.copyfile(art, out / "bg.png")
    col = lambda h, a=1.0: tuple(v / 255 for v in rgb(h)) + (a,)
    for name, color in (("track", col(c["fg"], 0.18)), ("fill", col(c["accent"], 0.95))):
        sf = cairo.ImageSurface(cairo.FORMAT_ARGB32, 8, 3)
        cr = cairo.Context(sf)
        cr.set_source_rgba(*color)
        cr.paint()
        sf.write_to_png(str(out / f"{name}.png"))
    for stale in ("logo.png", "seg_on.png", "seg_off.png", "label.png"):
        (out / stale).unlink(missing_ok=True)

    bg = rgb(c["bg"])
    (out / "dotfiles.plymouth").write_text(
        "[Plymouth Theme]\nName=dotfiles\nDescription=Palette-driven boot splash (scripts/theme.py)\n"
        "ModuleName=script\n\n[script]\nImageDir=/usr/share/plymouth/themes/dotfiles\n"
        "ScriptFile=/usr/share/plymouth/themes/dotfiles/dotfiles.script\n")
    (out / "dotfiles.script").write_text(f"""// {GEN}
Window.SetBackgroundTopColor({bg[0] / 255:.4f}, {bg[1] / 255:.4f}, {bg[2] / 255:.4f});
Window.SetBackgroundBottomColor({bg[0] / 255:.4f}, {bg[1] / 255:.4f}, {bg[2] / 255:.4f});

sw = Window.GetWidth();
sh = Window.GetHeight();

art = Image("bg.png");
art_sprite = Sprite(art.Scale(sw, sh));
art_sprite.SetZ(-100);

bar_w = Math.Int(sw * 0.22);
bar_h = Math.Max(2, Math.Int(sh * 0.0028));
bar_x = Math.Int((sw - bar_w) / 2);
bar_y = Math.Int(sh * 0.93);

track_src = Image("track.png");
track = Sprite(track_src.Scale(bar_w, bar_h));
track.SetPosition(bar_x, bar_y, 1);

fill_src = Image("fill.png");
fill = Sprite();
fill.SetPosition(bar_x, bar_y, 2);

target = 0;
shown = 0;

fun on_progress(duration, progress) {{
    target = progress;
}}
Plymouth.SetBootProgressFunction(on_progress);

fun on_refresh() {{
    shown = shown + (target - shown) * 0.12;
    w = Math.Int(bar_w * shown);
    if (w > 0)
        fill.SetImage(fill_src.Scale(w, bar_h));
}}
Plymouth.SetRefreshFunction(on_refresh);
""")
