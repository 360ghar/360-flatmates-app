#!/usr/bin/env python3
"""Frames raw app screenshots into store images.

Input : raw PNGs (390x844 logical at 3x, safe-area insets applied) from
        test/store_screenshots, a paper-cut background per shot, a caption per
        shot and locale.
Output: iPhone 6.9" and 6.5", Play phone and Play feature graphic.

  STORE_SHOTS_OUT=/abs/raw python3 tool/store_screenshots/compose.py tool/store_screenshots/config.json

Raw PNGs come from: STORE_SHOTS_OUT=/abs/raw STORE_PHOTOS_DIR=/abs/photos flutter test test/store_screenshots
(run one --plain-name per shot: the image cache breaks after the first test in a process).
"""
import json, os, sys
from PIL import Image, ImageDraw, ImageFilter, ImageFont

CREAM = (248, 243, 234)
INK = (35, 32, 28)


def font(spec, size):
    return ImageFont.truetype(spec["path"], size, index=spec.get("index", 0))


def cover(img, w, h, anchor=(0.5, 0.5)):
    s = max(w / img.width, h / img.height)
    img = img.resize((round(img.width * s), round(img.height * s)), Image.LANCZOS)
    x = round((img.width - w) * anchor[0])
    y = round((img.height - h) * anchor[1])
    return img.crop((x, y, x + w, y + h))


def status_bar(w, h, scale, ink=INK):
    """Time, signal, wifi, battery on a transparent strip (dark ink)."""
    bar = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(bar)
    f = ImageFont.truetype("/System/Library/Fonts/SFNS.ttf", round(17 * 3 * scale))
    cy = round(h * 0.52)
    d.text((round(w * 0.085), cy), "9:41", font=f, fill=ink, anchor="lm")
    u = 3 * scale
    x = w - round(w * 0.075)
    # battery
    bw, bh = 25 * u, 12 * u
    d.rounded_rectangle((x - bw, cy - bh / 2, x, cy + bh / 2), radius=3.5 * u, outline=ink, width=max(2, round(1.2 * u)))
    d.rounded_rectangle((x - bw + 2.2 * u, cy - bh / 2 + 2.2 * u, x - 2.2 * u - bw * 0.12, cy + bh / 2 - 2.2 * u), radius=1.5 * u, fill=ink)
    x -= bw + 8 * u
    # wifi: three arcs and a dot
    wcx, wcy = x - 8 * u, cy + 5 * u
    for r in (14, 9.5, 5):
        d.arc((wcx - r * u, wcy - r * u, wcx + r * u, wcy + r * u), 225, 315, fill=ink, width=max(2, round(2.2 * u)))
    d.ellipse((wcx - 1.8 * u, wcy - 1.8 * u, wcx + 1.8 * u, wcy + 1.8 * u), fill=ink)
    x -= 25 * u
    # signal: four bars
    for i in range(4):
        bh_ = (4 + i * 2.6) * u
        bx = x - (4 - i) * 5 * u
        d.rounded_rectangle((bx, cy + 6 * u - bh_, bx + 3.2 * u, cy + 6 * u), radius=1 * u, fill=ink)
    return bar


def phone(raw_path, width, ink=INK):
    """Returns an RGBA phone: bezel, screen, island. Height follows the screen."""
    bez = round(width * 0.026)
    sw = width - 2 * bez
    scr = Image.open(raw_path).convert("RGB")
    scale = sw / scr.width
    scr = scr.resize((sw, round(scr.height * scale)), Image.LANCZOS)
    scr = scr.convert("RGBA")
    scr.alpha_composite(status_bar(sw, round(141 * scale), scale, ink))
    h = scr.height + 2 * bez
    rad = round(width * 0.14)
    body = Image.new("RGBA", (width, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(body)
    d.rounded_rectangle((0, 0, width - 1, h - 1), radius=rad, fill=(24, 22, 20, 255))
    mask = Image.new("L", (sw, scr.height), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, sw - 1, scr.height - 1), radius=rad - bez, fill=255)
    body.paste(scr, (bez, bez), mask)
    d = ImageDraw.Draw(body)
    iw, ih = round(sw * 0.31), round(sw * 0.088)
    ix = (width - iw) // 2
    iy = bez + round(sw * 0.03)
    d.rounded_rectangle((ix, iy, ix + iw, iy + ih), radius=ih // 2, fill=(10, 10, 10, 255))
    return body


def drop(canvas, layer, xy):
    """Tight directional shadow (down-right, small blur), then the layer."""
    sh = Image.new("RGBA", layer.size, (0, 0, 0, 0))
    sh.putalpha(layer.getchannel("A").point(lambda a: int(a * 0.38)))
    pad = 40
    big = Image.new("RGBA", (layer.width + 2 * pad, layer.height + 2 * pad), (0, 0, 0, 0))
    big.paste(sh, (pad, pad))
    big = big.filter(ImageFilter.GaussianBlur(10))
    s = max(6, layer.width // 90)
    canvas.alpha_composite(big, (xy[0] - pad + s, xy[1] - pad + s * 2))
    canvas.alpha_composite(layer, xy)


def wrap(draw, text, f, maxw):
    words, lines, cur = text.split(" "), [], ""
    for w in words:
        t = (cur + " " + w).strip()
        if draw.textlength(t, font=f) <= maxw:
            cur = t
        else:
            lines.append(cur)
            cur = w
    lines.append(cur)
    return lines


def shot(cfg, base, bg_name, raw, caption, size, lang, out, ink=INK):
    W, H = size
    canvas = cover(Image.open(os.path.join(base, cfg["backgrounds"][bg_name])), W, H, (0.5, 0.0)).convert("RGBA")
    d = ImageDraw.Draw(canvas)
    f = font(cfg["fonts"][lang], round(W * (0.092 if lang == "en" else 0.072)))
    lines = wrap(d, caption, f, W * (0.84 if lang == "en" else 0.92))
    lh = round(f.size * (1.12 if lang == "en" else 1.3))
    y = round(H * 0.058)
    for ln in lines:
        d.text((W / 2, y), ln, font=f, fill=CREAM, anchor="ma")
        y += lh
    pw = round(W * 0.80)
    ph = phone(raw, pw, ink)
    top = max(y + round(H * 0.035), round(H * 0.235))
    drop(canvas, ph, ((W - pw) // 2, top))
    canvas.convert("RGB").save(out, quality=92)


def feature(cfg, base, raws, out, lang):
    W, H = 1024, 500
    canvas = cover(Image.open(os.path.join(base, cfg["backgrounds"]["wide"])), W, H, (0.5, 0.2)).convert("RGBA")
    d = ImageDraw.Draw(canvas)
    f1 = font(cfg["fonts"]["en"], 86)
    d.text((W / 2, 62), cfg["brand"], font=f1, fill=CREAM, anchor="ma")
    f2 = font(cfg["fonts"][lang], 34 if lang == "en" else 32)
    d.text((W / 2, 168), cfg["feature_tagline"][lang], font=f2, fill=CREAM, anchor="ma")
    pw = 210
    for i, (r, dx) in enumerate(zip(raws, (-130, 130))):
        ph = phone(r, pw)
        drop(canvas, ph, (W // 2 - pw // 2 + dx, 262))
    canvas.convert("RGB").save(out, quality=92)


def main(cfg_path):
    cfg = json.load(open(cfg_path))
    base = os.path.dirname(os.path.abspath(cfg_path))
    root = os.path.abspath(os.path.join(base, cfg["repo_root"]))
    for spec in cfg["fonts"].values():
        spec["path"] = os.path.join(base, spec["path"])
    raw = lambda n, lang: os.path.join(os.environ.get("STORE_SHOTS_OUT", cfg["raw_dir"]), f"{n}_{lang}.png")
    for lang, loc in cfg["locales"].items():
        for i, s in enumerate(cfg["shots"], 1):
            cap = s["caption"][lang]
            for key, size in cfg["ios_sizes"].items():
                p = os.path.join(root, "fastlane/screenshots", loc["ios"])
                os.makedirs(p, exist_ok=True)
                shot(cfg, base, s["bg"], raw(s["raw"], lang), cap, size, lang, os.path.join(p, f"{key}_{s['raw']}.jpg"), CREAM if s.get("light_status") else INK)
            p = os.path.join(root, "fastlane/metadata/android", loc["android"], "images", "phoneScreenshots")
            os.makedirs(p, exist_ok=True)
            shot(cfg, base, s["bg"], raw(s["raw"], lang), cap, tuple(cfg["play_size"]), lang, os.path.join(p, f"{s['raw']}.jpg"), CREAM if s.get("light_status") else INK)
        p = os.path.join(root, "fastlane/metadata/android", loc["android"], "images")
        feature(cfg, base, [raw(n, lang) for n in cfg["feature_shots"]], os.path.join(p, "featureGraphic.jpg"), lang)


if __name__ == "__main__":
    main(sys.argv[1])
