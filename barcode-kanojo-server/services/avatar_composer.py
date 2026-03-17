"""Server-side kanojo avatar compositor using Pillow.

Composes character part textures from the iOS app's avatar_data directory
into full-body, bust, and icon images served at:
  /profile_images/kanojo/{id}/full.png   (320x480)
  /profile_images/kanojo/{id}/bust.png   (240x300)
  /profile_images/kanojo/{id}/icon.png   (90x90)

The avatar_data directory contains Live2D mesh textures for each body part.
Since we don't have the Live2D SDK, we composite the primary texture from
each part at hardcoded offsets calibrated to produce a recognizable character.

Layer order (back to front):
  HAIR(back) → BODY → EAR → CLOTHES → FACE → NOSE → EYE → BROW → MOUTH
  → FRINGE → HAIR(none - already done) → GLASSES → ACCESSORY → SPOT
"""

import logging
import os
from pathlib import Path
from typing import Optional

from PIL import Image, ImageDraw, ImageFilter

log = logging.getLogger(__name__)

# ─── Paths ───────────────────────────────────────────────────────────────────

from config import settings
_AVATAR_DATA = Path(settings.AVATAR_DATA_DIR)

# Canvas dimensions for the full portrait
CANVAS_W = 320
CANVAS_H = 480

# Background gradient colours (soft pink/lavender, matches the app's placeholder)
BG_TOP = (255, 230, 240)
BG_BOT = (230, 220, 255)

# ─── Part → folder mapping ────────────────────────────────────────────────────

# Maps a Kanojo attribute value (1-based int) to a zero-padded folder name.
# Some parts use 0 to mean "none" (glasses_type=0, accessory_type=0 …).
def _part_folder(category: str, index: int) -> Optional[Path]:
    """Return the path to the variant folder, or None if index==0 (hidden)."""
    if index <= 0:
        return None
    folder_name = f"PARTS_01_{category}_{index:03d}"
    path = _AVATAR_DATA / f"PARTS_01_{category}" / folder_name
    if path.is_dir():
        return path
    # Fall back to _099 (default / placeholder variant)
    fallback = _AVATAR_DATA / f"PARTS_01_{category}" / f"PARTS_01_{category}_099"
    if fallback.is_dir():
        return fallback
    return None


def _load_tex(folder: Optional[Path], tex_index: int = 0) -> Optional[Image.Image]:
    """Load tex_{tex_index}.png from a part folder, return RGBA Image or None."""
    if folder is None:
        return None
    tex = folder / "tex512" / f"tex_{tex_index}.png"
    if not tex.exists():
        return None
    try:
        img = Image.open(tex).convert("RGBA")
        return img
    except Exception as exc:
        log.warning("Cannot load %s: %s", tex, exc)
        return None


def _load_largest_tex(folder: Optional[Path],
                       max_saturation: float = 1.0) -> Optional[Image.Image]:
    """Load the largest (by pixel area) texture from a part folder.

    Optionally filter to textures below a saturation threshold, which is used
    to find skin-toned eyelid arches rather than the coloured iris.
    """
    if folder is None:
        return None
    tex_dir = folder / "tex512"
    if not tex_dir.is_dir():
        return None
    best = None
    best_area = 0
    for tex_path in tex_dir.glob("tex_*.png"):
        try:
            img = Image.open(tex_path).convert("RGBA")
            area = img.width * img.height
            if area > best_area:
                if max_saturation < 1.0:
                    sat = _saturation_score(img)
                    if sat > max_saturation:
                        continue
                best_area = area
                best = img
        except Exception:
            pass
    return best


def _saturation_score(img: Image.Image) -> float:
    """Return average saturation of non-transparent pixels (0-1 scale)."""
    import colorsys
    pixels = list(img.getdata())
    total_sat = 0.0
    count = 0
    for r, g, b, a in pixels:
        if a > 30:  # Only consider visible pixels
            h, l, s = colorsys.rgb_to_hls(r / 255.0, g / 255.0, b / 255.0)
            total_sat += s
            count += 1
    return total_sat / count if count > 0 else 0.0


def _load_iris_pair(folder: Optional[Path]) -> tuple:
    """Find the left and right iris/pupil textures for an eye part folder.

    Returns (left_iris, right_iris) — either may be None.

    Iris textures come in pairs and are identified by:
    - Medium saturation (0.10–0.92) — not pure outlines (sat~1.0) nor eyelid arcs (sat<0.05)
    - Roughly circular: aspect ratio (w/h) between 0.5 and 2.0
    - Not too wide: width ≤ 58px (the wider textures are eyelid sockets, ~64-70px)
    - Minimum area of 400px²
    - NOT tex_0 or tex_1 (those are always eyelid arcs)
    """
    if folder is None:
        return (None, None)
    tex_dir = folder / "tex512"
    if not tex_dir.is_dir():
        return (None, None)

    candidates = []
    for tex_path in sorted(tex_dir.glob("tex_*.png")):
        fname = tex_path.stem  # e.g. "tex_2"
        # Skip tex_0 and tex_1 — always eyelid arcs
        try:
            tex_idx = int(fname.replace("tex_", ""))
        except ValueError:
            continue
        if tex_idx < 2:
            continue
        try:
            img = Image.open(tex_path).convert("RGBA")
            w, h = img.width, img.height
            area = w * h
            if area < 400:
                continue
            aspect = w / h if h > 0 else 99
            if w > 58:
                continue
            if not (0.5 <= aspect <= 2.0):
                continue
            sat = _saturation_score(img)
            if 0.10 <= sat <= 0.92:
                candidates.append((tex_idx, sat, area, img))
        except Exception:
            pass

    if not candidates:
        return (None, None)

    # Sort by saturation (prefer medium), then by area
    candidates.sort(key=lambda x: (x[1], x[2]), reverse=True)

    if len(candidates) >= 2:
        # Find a pair: two candidates with similar saturation (likely left/right)
        best = candidates[0]
        # Look for a partner with similar saturation
        for c in candidates[1:]:
            if abs(c[1] - best[1]) < 0.15:
                # Use tex index to determine left/right (lower index = left)
                if best[0] < c[0]:
                    return (best[3], c[3])
                else:
                    return (c[3], best[3])
        # No good pair, use best and mirror it
        return (best[3], best[3].transpose(Image.FLIP_LEFT_RIGHT))

    # Single candidate — mirror it
    return (candidates[0][3], candidates[0][3].transpose(Image.FLIP_LEFT_RIGHT))


def _paste(canvas: Image.Image, layer: Optional[Image.Image],
           cx: int, cy: int, scale: float = 1.0) -> None:
    """Paste layer centred at (cx, cy) on canvas using alpha compositing."""
    if layer is None:
        return
    if scale != 1.0:
        new_w = max(1, round(layer.width * scale))
        new_h = max(1, round(layer.height * scale))
        layer = layer.resize((new_w, new_h), Image.LANCZOS)
    x = cx - layer.width // 2
    y = cy - layer.height // 2
    # Paste with mask (alpha channel)
    canvas.paste(layer, (x, y), layer)


# ─── Colour tinting ───────────────────────────────────────────────────────────

def _tint(img: Image.Image, hue_shift: int, sat_delta: float, lum_delta: float) -> Image.Image:
    """Apply a simple HSL-based tint to an RGBA image, preserving alpha."""
    import colorsys
    r_img, g_img, b_img, a_img = img.split()
    rgb = Image.merge("RGB", (r_img, g_img, b_img))
    result = Image.new("RGB", rgb.size)
    px_in = list(rgb.getdata())
    px_out = []
    for r, g, b in px_in:
        h, l, s = colorsys.rgb_to_hls(r / 255.0, g / 255.0, b / 255.0)
        # Only tint pixels that aren't very dark (avoids tinting outlines)
        if l > 0.15:
            h = (h + hue_shift / 360.0) % 1.0
            s = max(0.0, min(1.0, s + sat_delta))
            l = max(0.0, min(1.0, l + lum_delta))
            nr, ng, nb = colorsys.hls_to_rgb(h, l, s)
            px_out.append((round(nr * 255), round(ng * 255), round(nb * 255)))
        else:
            px_out.append((r, g, b))
    result.putdata(px_out)
    result.putalpha(a_img)
    return result


# Color convert tables ported from KanojoSetting.java
# Each entry: (hue_shift, sat_delta, lum_delta)
_SKIN_COLORS = [
    (0, 0.0, 0.0), (3, 0.16, 0.16), (0, 0.04, -0.22), (-5, -0.05, -0.55),
    (0, -0.09, -0.91), (-160, -0.07, -0.46), (-5, -0.01, 0.07), (-6, -0.01, 0.2),
    (-9, 0.0, -0.21), (12, -0.01, 0.11), (8, 0.09, 0.0), (0, 0.0, -0.62),
]
_HAIR_COLORS = [
    (1, 0.19, 0.28), (27, 0.3, 0.64), (7, -0.09, 0.52), (7, 0.01, 0.51),
    (21, 0.26, 0.22), (-9, 0.29, 0.71), (-56, 0.01, 0.02), (21, 1.0, 0.91),
    (0, 0.0, 0.0), (12, 0.26, 0.23), (7, 0.0, 0.19), (8, 0.09, 0.24),
    (21, 0.0, 0.0), (180, 0.17, 0.64), (21, 0.51, 0.69), (10, -0.14, 0.96),
    (0, -0.08, -0.35), (4, 0.17, 0.0), (26, -0.12, -0.46), (3, 0.0, -0.31),
    (-25, -0.1, -0.42), (163, 0.1, 0.16), (97, 0.1, 0.55), (-9, 0.11, 0.9),
]
_EYE_COLORS = [
    (0, 0.0, 0.0), (33, -0.06, 0.2), (155, -0.05, 0.0), (5, -0.17, -0.02),
    (12, 0.06, 0.15), (-176, 0.02, 0.09), (-6, -0.26, 0.14), (10, 0.22, 0.01),
    (-143, -0.12, 0.05), (0, -0.33, -0.05), (-12, 0.05, 0.17), (-18, -0.15, 0.19),
]


def _apply_color(img: Optional[Image.Image], table: list, index: int) -> Optional[Image.Image]:
    if img is None:
        return None
    idx = max(0, min(index - 1, len(table) - 1))
    h, s, l = table[idx]
    if h == 0 and s == 0.0 and l == 0.0:
        return img  # No change needed
    return _tint(img, h, s, l)


# ─── Main compositor ──────────────────────────────────────────────────────────

def compose_avatar(kanojo_attrs: dict) -> Image.Image:
    """
    Compose a full-body character image from kanojo attribute values.

    kanojo_attrs keys (all int unless noted):
        body_type, face_type, eye_type, eye_color, brow_type, brow_position (float),
        mouth_type, mouth_position (float), nose_type, ear_type,
        fringe_type, hair_type, hair_color, skin_color,
        clothes_type, glasses_type, accessory_type, spot_type,
        eye_position (float)
    """
    if not _AVATAR_DATA.is_dir():
        log.warning("avatar_data directory not found at %s", _AVATAR_DATA)
        return _placeholder_image(CANVAS_W, CANVAS_H)

    canvas = _gradient_background(CANVAS_W, CANVAS_H)

    # ── Attribute extraction ─────────────────────────────────────────────────
    body_type    = int(kanojo_attrs.get("body_type", 1))
    face_type    = int(kanojo_attrs.get("face_type", 1))
    eye_type     = int(kanojo_attrs.get("eye_type", 1))
    eye_color    = int(kanojo_attrs.get("eye_color", 1))
    eye_pos      = float(kanojo_attrs.get("eye_position", 0.0))
    brow_type    = int(kanojo_attrs.get("brow_type", 1))
    brow_pos     = float(kanojo_attrs.get("brow_position", 0.0))
    mouth_type   = int(kanojo_attrs.get("mouth_type", 1))
    mouth_pos    = float(kanojo_attrs.get("mouth_position", 0.0))
    nose_type    = int(kanojo_attrs.get("nose_type", 1))
    ear_type     = int(kanojo_attrs.get("ear_type", 1))
    fringe_type  = int(kanojo_attrs.get("fringe_type", 1))
    hair_type    = int(kanojo_attrs.get("hair_type", 1))
    hair_color   = int(kanojo_attrs.get("hair_color", 1))
    skin_color   = int(kanojo_attrs.get("skin_color", 1))
    clothes_type = int(kanojo_attrs.get("clothes_type", 1))
    glasses_type = int(kanojo_attrs.get("glasses_type", 0))
    acc_type     = int(kanojo_attrs.get("accessory_type", 0))
    spot_type    = int(kanojo_attrs.get("spot_type", 0))

    # ── Layout constants ─────────────────────────────────────────────────────
    # Reference point: centre of the face oval (horizontally centre of canvas)
    cx = CANVAS_W // 2          # 160
    face_cy = 175               # vertical centre of face
    # Vertical offsets for facial features relative to face_cy
    # eye_pos is in [-1, 1]: shift eyes up/down by up to ±12 px
    eye_shift  = round(eye_pos  * 12)
    brow_shift = round(brow_pos * 10)
    mouth_shift = round(mouth_pos * 8)

    # ── Layer 1: Hair (back) ──────────────────────────────────────────────────
    hair_folder = _part_folder("HAIR", hair_type)
    hair_tex = _apply_color(_load_tex(hair_folder, 0), _HAIR_COLORS, hair_color)
    # Hair is large (~276×310) — scale to fit ~240px wide, place at top
    _paste(canvas, hair_tex, cx, 155, scale=0.87)

    # ── Layer 2: Body (arms/shoulders) ───────────────────────────────────────
    body_folder = _part_folder("BODY", body_type)
    body_tex = _apply_color(_load_tex(body_folder, 1), _SKIN_COLORS, skin_color)  # tex_1 = torso
    if body_tex:
        b_scale = min(0.90, 240 / body_tex.width)
        _paste(canvas, body_tex, cx, 360, scale=b_scale)

    # ── Layer 3: Ears ────────────────────────────────────────────────────────
    ear_folder = _part_folder("EAR", ear_type)
    ear_tex = _apply_color(_load_tex(ear_folder, 0), _SKIN_COLORS, skin_color)
    if ear_tex:
        # Left ear
        _paste(canvas, ear_tex, cx - 88, face_cy + 10)
        # Right ear (mirror)
        ear_flip = ear_tex.transpose(Image.FLIP_LEFT_RIGHT)
        _paste(canvas, ear_flip, cx + 88, face_cy + 10)

    # ── Layer 4: Clothes ─────────────────────────────────────────────────────
    clothes_folder = _part_folder("CLOTHES", clothes_type)
    clothes_tex = _load_largest_tex(clothes_folder)  # largest texture = main garment
    if clothes_tex:
        # Scale so garment is at most 220px wide
        c_scale = min(0.90, 220 / clothes_tex.width)
        _paste(canvas, clothes_tex, cx, 375, scale=c_scale)

    # ── Layer 5: Face ────────────────────────────────────────────────────────
    face_folder = _part_folder("FACE", face_type)
    face_tex = _apply_color(_load_tex(face_folder, 0), _SKIN_COLORS, skin_color)
    _paste(canvas, face_tex, cx, face_cy, scale=1.05)

    # ── Layer 6: Nose ────────────────────────────────────────────────────────
    nose_folder = _part_folder("NOSE", nose_type)
    nose_tex = _apply_color(_load_tex(nose_folder, 0), _SKIN_COLORS, skin_color)
    _paste(canvas, nose_tex, cx, face_cy + 28 + mouth_shift // 2, scale=1.5)

    # ── Layer 7: Eyes ────────────────────────────────────────────────────────
    # Compositing order (back→front):
    #   iris (colored ball) → upper eyelid arch (tex_0 left, tex_1 right)
    # Note: tex_0/tex_1 are the per-eye upper lid arcs that naturally
    # clip the top of the iris and give the eye its half-lidded shape.
    eye_folder = _part_folder("EYE", eye_type)
    eye_y = face_cy - 10 + eye_shift

    # 7a: Iris / pupil pair (left and right, found by saturation + shape heuristics)
    iris_l, iris_r = _load_iris_pair(eye_folder)
    iris_l = _apply_color(iris_l, _EYE_COLORS, eye_color)
    iris_r = _apply_color(iris_r, _EYE_COLORS, eye_color)
    # Draw irises scaled up so they're clearly visible as eyes.
    # Skip eyelid arcs — they're designed for Live2D mesh deformation and
    # produce distracting white blobs when composited flat.
    if iris_l:
        _paste(canvas, iris_l, cx - 42, eye_y, scale=1.6)
    if iris_r:
        _paste(canvas, iris_r, cx + 42, eye_y, scale=1.6)

    # ── Layer 8: Brows ───────────────────────────────────────────────────────
    brow_folder = _part_folder("BROW", brow_type)
    brow_tex = _apply_color(_load_tex(brow_folder, 0), _HAIR_COLORS, hair_color)
    if brow_tex:
        brow_y = face_cy - 40 + brow_shift + eye_shift
        _paste(canvas, brow_tex, cx - 44, brow_y, scale=1.15)
        brow_flip = brow_tex.transpose(Image.FLIP_LEFT_RIGHT)
        _paste(canvas, brow_flip, cx + 44, brow_y, scale=1.15)

    # ── Layer 9: Mouth ───────────────────────────────────────────────────────
    mouth_folder = _part_folder("MOUTH", mouth_type)
    mouth_tex = _load_tex(mouth_folder, 0)
    _paste(canvas, mouth_tex, cx, face_cy + 50 + mouth_shift, scale=1.6)

    # ── Layer 10: Spot (blush/marks) ─────────────────────────────────────────
    spot_folder = _part_folder("SPOT", spot_type)
    spot_tex = _load_tex(spot_folder, 0)
    if spot_tex and spot_tex.width < 50:  # small dot-style spots (blush dots)
        _paste(canvas, spot_tex, cx - 58, face_cy + 18, scale=2.5)
        spot_flip = spot_tex.transpose(Image.FLIP_LEFT_RIGHT)
        _paste(canvas, spot_flip, cx + 58, face_cy + 18, scale=2.5)
    elif spot_tex:
        _paste(canvas, spot_tex, cx, face_cy + 18)

    # ── Layer 11: Fringe (hair bangs) ────────────────────────────────────────
    fringe_folder = _part_folder("FRINGE", fringe_type)
    fringe_tex = _apply_color(_load_tex(fringe_folder, 0), _HAIR_COLORS, hair_color)
    if fringe_tex:
        # Scale fringe to ~210px wide at most (matches canvas width with margins)
        target_w = 210
        fringe_scale = min(1.0, target_w / fringe_tex.width)
        # Position: raised higher so bangs don't cover the eyes
        _paste(canvas, fringe_tex, cx, face_cy - 75, scale=fringe_scale)

    # ── Layer 12: Glasses (above fringe) ─────────────────────────────────────
    if glasses_type > 0:
        glasses_folder = _part_folder("GLASSES", glasses_type)
        glasses_tex = _load_tex(glasses_folder, 0)
        _paste(canvas, glasses_tex, cx, face_cy - 10 + eye_shift, scale=1.4)

    # ── Layer 13: Accessory ──────────────────────────────────────────────────
    if acc_type > 0:
        acc_folder = _part_folder("ACCESSORY", acc_type)
        acc_tex = _load_tex(acc_folder, 0)
        _paste(canvas, acc_tex, cx, face_cy - 92, scale=1.0)

    return canvas


def _gradient_background(w: int, h: int) -> Image.Image:
    img = Image.new("RGBA", (w, h), BG_TOP)
    draw = ImageDraw.Draw(img)
    for y in range(h):
        t = y / (h - 1)
        r = round(BG_TOP[0] + t * (BG_BOT[0] - BG_TOP[0]))
        g = round(BG_TOP[1] + t * (BG_BOT[1] - BG_TOP[1]))
        b = round(BG_TOP[2] + t * (BG_BOT[2] - BG_TOP[2]))
        draw.line([(0, y), (w, y)], fill=(r, g, b, 255))
    return img


def _placeholder_image(w: int, h: int) -> Image.Image:
    img = _gradient_background(w, h)
    draw = ImageDraw.Draw(img)
    draw.ellipse([(w // 2 - 40, h // 3 - 40), (w // 2 + 40, h // 3 + 40)],
                 fill=(200, 180, 210, 200))
    return img


# ─── Public API ──────────────────────────────────────────────────────────────

def generate_and_save(kanojo_id: int, kanojo_attrs: dict, output_dir: Path) -> None:
    """
    Generate full, bust, and icon images for a kanojo and save them.

    output_dir should be:  static/profile_images/kanojo/{kanojo_id}/
    """
    output_dir.mkdir(parents=True, exist_ok=True)

    full_img = compose_avatar(kanojo_attrs)

    # Full portrait (320×480)
    full_rgb = full_img.convert("RGB")
    full_rgb.save(output_dir / "full.png", "PNG", optimize=True)

    # Bust (240×300) — upper half cropped
    bust_box = (0, 0, CANVAS_W, 340)
    bust = full_img.crop(bust_box).resize((240, 300), Image.LANCZOS).convert("RGB")
    bust.save(output_dir / "bust.png", "PNG", optimize=True)

    # Icon (90×90) — face crop centred on face_cy=175
    icon_box = (CANVAS_W // 2 - 100, 80, CANVAS_W // 2 + 100, 280)
    icon = full_img.crop(icon_box).resize((90, 90), Image.LANCZOS).convert("RGB")
    icon.save(output_dir / "icon.png", "PNG", optimize=True)

    log.info("Avatar images saved for kanojo %d at %s", kanojo_id, output_dir)
