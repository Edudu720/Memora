import argparse
import math
import os
import shutil
import tempfile
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ORIG = "apps/.originais"
APPS = "apps"
ASSETS_GUIAS = "app/assets/guias"

FONT_CANDIDATES = [
    r"C:\Windows\Fonts\segoeuib.ttf",
    r"C:\Windows\Fonts\arialbd.ttf",
    r"C:\Windows\Fonts\calibrib.ttf",
]


def load_font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    for p in FONT_CANDIDATES:
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()


def _atomic_save_jpg(
    im: Image.Image,
    dst_path: str,
    quality: int,
    optimize: bool = True,
) -> None:
    parent = os.path.dirname(os.path.abspath(dst_path))
    os.makedirs(parent, exist_ok=True)
    fd, tmp_path = tempfile.mkstemp(prefix=".tmp_", suffix=".jpg", dir=parent)
    os.close(fd)
    try:
        im.convert("RGB").save(tmp_path, "JPEG", quality=quality, optimize=optimize)
        os.replace(tmp_path, dst_path)
    except BaseException:
        if os.path.exists(tmp_path):
            os.unlink(tmp_path)
        raise


def apply_blurs(
    im: Image.Image,
    blur_boxes: list[tuple[int, int, int, int]],
    keep_boxes: list[tuple[int, int, int, int]] | None = None,
    radius: int = 28,
) -> Image.Image:
    """Applies Gaussian Blur strictly to blur_boxes, optionally preserving keep_boxes."""
    if not blur_boxes:
        return im.copy()
    out = im.copy()
    w, h = out.size
    saved = []
    if keep_boxes:
        for kx1, ky1, kx2, ky2 in keep_boxes:
            kb = (max(0, kx1), max(0, ky1), min(w, kx2), min(h, ky2))
            saved.append((kb, im.crop(kb)))
    for x1, y1, x2, y2 in blur_boxes:
        box = (max(0, x1), max(0, y1), min(w, x2), min(h, y2))
        crop = out.crop(box).filter(ImageFilter.GaussianBlur(radius=radius))
        out.paste(crop, box)
    for kb, kimg in saved:
        out.paste(kimg, kb)
    return out


def _anchor_point(
    sx1: int,
    sy1: int,
    sx2: int,
    sy2: int,
    pos: str,
) -> tuple[int, int]:
    cx, cy = (sx1 + sx2) // 2, (sy1 + sy2) // 2
    if pos == "tl":
        return sx1, sy1
    if pos == "tr":
        return sx2, sy1
    if pos == "bl":
        return sx1, sy2
    if pos == "br":
        return sx2, sy2
    if pos == "left":
        return sx1, cy
    if pos == "right":
        return sx2, cy
    if pos == "top":
        return cx, sy1
    return cx, sy2


def draw_annotations(
    im: Image.Image,
    circles: list[tuple[int, int, int, int, int, str, str]],
    top_crop: int,
) -> Image.Image:
    """
    Draws high-contrast transparent-inside rings (ellipse or rounded pill) and
    numbered circular badges (1, 2, ...) at 2x supersampling for crisp edges.
    Each tuple: (x1, y1, x2, y2, num, shape, badge_pos) in ORIGINAL uncropped coords.
    shape: 'ellipse' | 'pill'
    badge_pos: 'tl' | 'tr' | 'bl' | 'br' | 'left' | 'right' | 'top' | 'bottom'
    """
    if not circles:
        return im.copy()
    w, h = im.size
    scale = 2
    # Scale thickness proportionally for high-res portrait images (e.g. 1536x2752)
    # while clamping wide landscape crops (e.g. 1024x441).
    raw_unit = w / 720.0
    unit = max(0.8, min(2.2, raw_unit) if h >= w else min(1.3, raw_unit))
    overlay = Image.new("RGBA", (w * scale, h * scale), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    halo_w = int(round(11 * unit * scale))
    stroke_w = int(round(6 * unit * scale))
    badge_r = int(round(20 * unit * scale))
    font = load_font(int(round(24 * unit * scale)))

    blue = (16, 64, 248, 255)   # #1040F8 MemoraCores.claro.primaria (8.12:1 on white)
    white = (255, 255, 255, 245)

    margin = max(6, int(round(6 * unit)))
    # First pass: draw all rings with white halo then Memora blue stroke
    adj_boxes = []
    for x1, y1, x2, y2, num, shape, badge_pos in circles:
        ax1 = max(margin, x1)
        ay1 = max(margin, y1 - top_crop)
        ax2 = min(w - margin, x2)
        ay2 = min(h - margin, y2 - top_crop)
        sx1, sy1, sx2, sy2 = ax1 * scale, ay1 * scale, ax2 * scale, ay2 * scale
        box = (sx1, sy1, sx2, sy2)
        bw, bh = sx2 - sx1, sy2 - sy1
        rad = min(bw // 2, bh // 2, int(round(46 * unit * scale)))

        if shape == "ellipse":
            draw.ellipse(box, outline=white, width=halo_w)
            draw.ellipse(box, outline=blue, width=stroke_w)
        else:
            draw.rounded_rectangle(box, radius=rad, outline=white, width=halo_w)
            draw.rounded_rectangle(box, radius=rad, outline=blue, width=stroke_w)
        adj_boxes.append((sx1, sy1, sx2, sy2, num, shape, badge_pos))

    # Second pass: place numbered circular badges with collision avoidance
    ow, oh = w * scale, h * scale
    pad = badge_r + int(round(6 * unit * scale))
    min_dist = 2 * badge_r + int(round(12 * unit * scale))
    anchor_order = ["tr", "tl", "br", "bl", "right", "left", "top", "bottom"]
    placed_badges: list[tuple[int, int, int]] = []

    for idx, (sx1, sy1, sx2, sy2, num, shape, badge_pos) in enumerate(adj_boxes):
        ordered_anchors = [badge_pos] + [a for a in anchor_order if a != badge_pos]
        candidates: list[tuple[int, int, int]] = []
        for rank, anc in enumerate(ordered_anchors):
            bx0, by0 = _anchor_point(sx1, sy1, sx2, sy2, anc)
            candidates.append((rank, bx0, by0))
        # Tangential shifts along top/bottom/side edges as fallback
        for shift_idx, mult in enumerate((1.0, -1.0, 1.5, -1.5, 2.0, -2.0), start=len(ordered_anchors)):
            delta = int(round(mult * min_dist))
            bx0, by0 = _anchor_point(sx1, sy1, sx2, sy2, badge_pos)
            candidates.append((shift_idx, bx0 + delta, by0))
            candidates.append((shift_idx, bx0, by0 + delta))

        best_choice: tuple[float, int, float, int, int] | None = None
        for rank, raw_x, raw_y in candidates:
            bx = max(pad, min(ow - pad, raw_x))
            by = max(pad, min(oh - pad, raw_y))
            clamp_dist = math.hypot(bx - raw_x, by - raw_y)
            penalty = 0.0
            for _, px, py in placed_badges:
                d = math.hypot(bx - px, by - py)
                if d < min_dist:
                    penalty += 10000.0 + (min_dist - d) * 100.0
            for j, (ox1, oy1, ox2, oy2, _, _, _) in enumerate(adj_boxes):
                if j == idx:
                    continue
                if (ox1 + 0.5 * badge_r < bx < ox2 - 0.5 * badge_r and
                        oy1 + 0.5 * badge_r < by < oy2 - 0.5 * badge_r):
                    penalty += 2000.0
            score_key = (penalty, rank, clamp_dist, bx, by)
            if best_choice is None or score_key[:3] < best_choice[:3]:
                best_choice = score_key

        assert best_choice is not None
        _, _, _, bx, by = best_choice
        placed_badges.append((num, bx, by))

        outer_pad = int(round(3 * unit * scale))
        outer = (bx - badge_r - outer_pad, by - badge_r - outer_pad,
                 bx + badge_r + outer_pad, by + badge_r + outer_pad)
        inner = (bx - badge_r, by - badge_r, bx + badge_r, by + badge_r)
        draw.ellipse(outer, fill=white)
        draw.ellipse(inner, fill=blue)

        label = str(num)
        tb = draw.textbbox((0, 0), label, font=font)
        tw, th = tb[2] - tb[0], tb[3] - tb[1]
        tx = bx - tw / 2 - tb[0]
        ty = by - th / 2 - tb[1]
        draw.text((tx, ty), label, font=font, fill=(255, 255, 255, 255))

    for i in range(len(placed_badges)):
        for j in range(i + 1, len(placed_badges)):
            n1, x1, y1 = placed_badges[i]
            n2, x2, y2 = placed_badges[j]
            dist = math.hypot(x1 - x2, y1 - y2)
            assert dist >= 2 * badge_r, (
                f"Colisao de badges #{n1} e #{n2}: dist={dist:.1f} < {2 * badge_r}"
            )

    overlay_small = overlay.resize((w, h), Image.Resampling.LANCZOS)
    base = im.convert("RGBA")
    out = Image.alpha_composite(base, overlay_small).convert("RGB")
    return out


def save_asset_jpg(
    im: Image.Image,
    dst_path: str,
    target_width: int = 480,
    quality: int = 80,
) -> None:
    if im.width > target_width:
        ratio = target_width / im.width
        resized = im.resize((target_width, int(im.height * ratio)), Image.Resampling.LANCZOS)
    else:
        resized = im.copy()
    _atomic_save_jpg(resized, dst_path, quality=quality, optimize=True)


def _atomic_save_webp(
    im: Image.Image,
    dst_path: str,
    quality: int = 80,
) -> None:
    parent = os.path.dirname(os.path.abspath(dst_path))
    os.makedirs(parent, exist_ok=True)
    fd, tmp_path = tempfile.mkstemp(prefix=".tmp_", suffix=".webp", dir=parent)
    os.close(fd)
    try:
        im.convert("RGB").save(tmp_path, "WEBP", quality=quality, method=6)
        os.replace(tmp_path, dst_path)
    except BaseException:
        if os.path.exists(tmp_path):
            os.unlink(tmp_path)
        raise


def save_asset_webp(
    im: Image.Image,
    dst_path: str,
    target_width: int = 636,
    quality: int = 80,
) -> None:
    if im.width > target_width:
        ratio = target_width / im.width
        resized = im.resize((target_width, int(im.height * ratio)), Image.Resampling.LANCZOS)
    else:
        resized = im.copy()
    _atomic_save_webp(resized, dst_path, quality=quality)


def _sanitize_instagram_clean(step_idx: int, im: Image.Image) -> Image.Image:
    """Remove termos etaristas nas imagens do Instagram preservando a tipografia."""
    if step_idx == 5:
        out = im.copy()
        d = ImageDraw.Draw(out)
        bg = out.getpixel((150, 220))
        d.rectangle((228, 260, 555, 304), fill=bg)
        f_b = ImageFont.truetype(r"C:\Windows\Fonts\segoeuib.ttf", 30)
        d.text((232, 260), "clube_jardim_e_vida", font=f_b, fill=(242, 244, 248))
        return out
    if step_idx == 8:
        out = im.copy()
        d = ImageDraw.Draw(out)
        bg = out.getpixel((150, 1300))
        d.rectangle((200, 1295, 650, 1345), fill=bg)
        f_r = ImageFont.truetype(r"C:\Windows\Fonts\segoeui.ttf", 34)
        d.text((206, 1294), "saude e bem estar em casa", font=f_r, fill=(242, 244, 248))
        return out
    return im


# Complete validated specification for all 77 screenshots across 6 folders.
# Coordinates are in ORIGINAL (uncropped) image pixels.
SPECS: dict[str, dict] = {
    "whatsapp": {
        "orig_dir": "WhatsApp",
        "steps": [
            # Passo 1: Tela inicial + menu de 3 pontos aberto (720x1600)
            {
                "file": "WhatsApp Image 2026-11-09 at 14.25.21 (4).jpeg",
                "top_crop": 58,
                "blur": [
                    (8, 495, 292, 965),
                    (8, 975, 580, 1365),
                ],
                "circles": [
                    (34, 168, 290, 276, 1, "pill", "tl"),
                    (562, 74, 706, 148, 2, "pill", "bl"),
                    (294, 158, 706, 974, 3, "pill", "tl"),
                    (568, 1192, 704, 1322, 4, "pill", "tl"),
                    (6, 1356, 712, 1494, 5, "pill", "tl"),
                ],
            },
            # Passo 2: Menu de três pontinhos detalhado (634x1363)
            {
                "file": "WhatsApp Image 2026-11-09 at 14.37.40.jpeg",
                "top_crop": 0,
                "blur": [],
                "circles": [
                    (18, 195, 465, 420, 1, "pill", "tr"),
                    (18, 480, 602, 718, 2, "pill", "tr"),
                    (18, 770, 565, 998, 3, "pill", "tr"),
                    (18, 1058, 415, 1295, 4, "pill", "tr"),
                ],
            },
            # Passo 3: Configurações (parte 1) (720x1600)
            {
                "file": "WhatsApp Image 2026-11-09 at 14.25.21 (5).jpeg",
                "top_crop": 58,
                "blur": [(95, 75, 330, 155)],
                "circles": [
                    (440, 76, 706, 154, 1, "pill", "bl"),
                    (20, 195, 600, 454, 2, "pill", "tr"),
                    (20, 486, 686, 610, 3, "pill", "tr"),
                    (20, 640, 686, 990, 4, "pill", "tr"),
                    (20, 1024, 702, 1492, 5, "pill", "tr"),
                ],
            },
            # Passo 4: Configurações (parte 2) (720x1600)
            {
                "file": "WhatsApp Image 2026-11-09 at 14.25.22.jpeg",
                "top_crop": 58,
                "blur": [(95, 75, 330, 155)],
                "circles": [
                    (20, 200, 665, 482, 1, "pill", "tr"),
                    (20, 512, 650, 632, 2, "pill", "tr"),
                    (20, 664, 650, 938, 3, "pill", "tr"),
                    (20, 968, 704, 1420, 4, "pill", "tr"),
                ],
            },
            # Passo 5: Funcionalidades dentro de uma conversa (1536x2752)
            {
                "file": "Gemini_Generated_Image_feko87feko87feko.jfif",
                "top_crop": 100,
                "blur": [(295, 180, 600, 265)],
                "circles": [
                    (18, 134, 1506, 308, 1, "pill", "bl"),
                    (24, 355, 1510, 1650, 2, "pill", "tr"),
                    (24, 1676, 1320, 2328, 3, "pill", "tr"),
                    (16, 2358, 1522, 2562, 4, "pill", "tl"),
                ],
            },
        ],
    },
    "telegram": {
        "orig_dir": "Telegram",
        "steps": [
            # Passo 1: Tela inicial de Chats (720x1600)
            {
                "file": "WhatsApp Image 2026-11-09 at 14.25.20.jpeg",
                "top_crop": 58,
                "blur": [
                    (15, 390, 710, 1135),
                    (15, 1135, 575, 1365),
                    (15, 1500, 705, 1600),
                    (592, 1388, 648, 1442),
                ],
                "circles": [
                    (20, 168, 700, 260, 1, "pill", "tr"),
                    (20, 272, 700, 376, 2, "pill", "tr"),
                    (570, 1134, 706, 1362, 3, "pill", "tl"),
                    (16, 1366, 704, 1496, 4, "pill", "tl"),
                ],
            },
            # Passo 2: Contatos (720x1600)
            {
                "file": "WhatsApp Image 2026-11-09 at 14.25.20 (3).jpeg",
                "top_crop": 58,
                "blur": [(592, 1388, 648, 1442)],
                "circles": [
                    (608, 68, 708, 164, 1, "ellipse", "bl"),
                    (174, 916, 546, 1038, 2, "pill", "tr"),
                    (182, 1370, 348, 1494, 3, "pill", "tl"),
                ],
            },
            # Passo 3: Nova Mensagem (720x1600)
            {
                "file": "WhatsApp Image 2026-11-09 at 14.25.20 (1).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (16, 68, 708, 164, 1, "pill", "bl"),
                    (22, 178, 560, 386, 2, "pill", "tr"),
                    (174, 1146, 546, 1268, 3, "pill", "tr"),
                ],
            },
            # Passo 4: Formulário Novo Contato (720x1600)
            {
                "file": "WhatsApp Image 2026-11-09 at 14.25.20 (2).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (22, 126, 698, 396, 1, "pill", "tr"),
                    (22, 408, 698, 540, 2, "pill", "tr"),
                    (35, 542, 470, 622, 3, "pill", "tr"),
                    (22, 780, 698, 905, 4, "pill", "tr"),
                ],
            },
            # Passo 5: Seu Perfil (720x1600)
            {
                "file": "WhatsApp Image 2026-11-09 at 14.25.21 (3).jpeg",
                "top_crop": 58,
                "blur": [
                    (255, 115, 460, 315),
                    (190, 325, 530, 400),
                    (40, 635, 390, 700),
                    (592, 1388, 648, 1442),
                ],
                "circles": [
                    (16, 68, 708, 164, 1, "pill", "bl"),
                    (18, 466, 702, 610, 2, "pill", "tr"),
                    (18, 626, 702, 760, 3, "pill", "tr"),
                    (164, 1262, 556, 1372, 4, "pill", "tr"),
                ],
            },
            # Passo 6: Configurações (topo) (720x1600)
            {
                "file": "WhatsApp Image 2026-11-09 at 14.25.21.jpeg",
                "top_crop": 58,
                "blur": [
                    (255, 115, 460, 315),
                    (200, 312, 520, 372),
                    (210, 372, 510, 440),
                    (95, 480, 420, 535),
                    (592, 1388, 648, 1442),
                ],
                "keep": [(388, 242, 462, 316)],
                "circles": [
                    (384, 238, 470, 322, 1, "ellipse", "tr"),
                    (38, 704, 682, 826, 2, "pill", "tr"),
                    (22, 868, 688, 1104, 3, "pill", "tr"),
                    (22, 1112, 688, 1348, 4, "pill", "tr"),
                ],
            },
            # Passo 7: Configurações (opções) (720x1600)
            {
                "file": "WhatsApp Image 2026-11-09 at 14.25.21 (1).jpeg",
                "top_crop": 58,
                "blur": [(592, 1388, 648, 1442)],
                "circles": [
                    (16, 66, 708, 144, 1, "pill", "bl"),
                    (22, 150, 698, 504, 2, "pill", "tr"),
                    (22, 516, 698, 746, 3, "pill", "tr"),
                    (22, 758, 698, 1106, 4, "pill", "tr"),
                ],
            },
            # Passo 8: Configurações (recursos e Ajuda) (720x1600)
            {
                "file": "WhatsApp Image 2026-11-09 at 14.25.21 (2).jpeg",
                "top_crop": 58,
                "blur": [(592, 1388, 648, 1442)],
                "circles": [
                    (22, 326, 698, 750, 1, "pill", "tr"),
                    (22, 774, 698, 946, 2, "pill", "tr"),
                    (22, 956, 698, 1252, 3, "pill", "tr"),
                ],
            },
        ],
    },
    "facebook": {
        "orig_dir": "FACE",
        "steps": [
            # Passo 1: Feed Principal (720x1600)
            {
                "file": "WhatsApp Image 2026-11-10 at 14.33.34.jpeg",
                "top_crop": 58,
                "blur": [(18, 808, 355, 902)],
                "circles": [
                    (445, 70, 710, 146, 1, "pill", "bl"),
                    (15, 150, 705, 228, 2, "pill", "tl"),
                    (105, 238, 705, 368, 3, "pill", "tr"),
                    (8, 376, 224, 786, 4, "pill", "tr"),
                ],
            },
            # Passo 2: Vídeos Curtos (Reels) (720x1600)
            {
                "file": "WhatsApp Image 2026-11-10 at 14.33.34 (4).jpeg",
                "top_crop": 58,
                "blur": [(145, 1142, 575, 1245)],
                "circles": [
                    (125, 68, 708, 150, 1, "pill", "bl"),
                    (18, 166, 708, 258, 2, "pill", "tr"),
                    (610, 910, 714, 1446, 3, "pill", "tl"),
                    (14, 1315, 588, 1412, 4, "pill", "tr"),
                ],
            },
            # Passo 3: Marketplace (720x1600)
            {
                "file": "WhatsApp Image 2026-11-10 at 14.33.34 (3).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (525, 156, 708, 232, 1, "pill", "bl"),
                    (12, 236, 708, 320, 2, "pill", "tr"),
                    (12, 330, 708, 768, 3, "pill", "tr"),
                ],
            },
            # Passo 4: Amigos e Solicitações (720x1600)
            {
                "file": "WhatsApp Image 2026-11-10 at 14.33.34 (2).jpeg",
                "top_crop": 58,
                "blur": [
                    (18, 430, 214, 626), (225, 435, 625, 490),
                    (18, 646, 214, 844), (225, 650, 470, 705), (225, 738, 282, 795),
                    (18, 902, 214, 1102), (225, 895, 620, 955), (225, 960, 324, 1052),
                    (18, 1158, 214, 1358), (225, 1150, 520, 1210),
                ],
                "circles": [
                    (240, 70, 348, 146, 1, "ellipse", "bl"),
                    (12, 230, 468, 318, 2, "pill", "tr"),
                    (220, 534, 708, 630, 3, "pill", "tr"),
                ],
            },
            # Passo 5: Notificações (720x1600)
            {
                "file": "WhatsApp Image 2026-11-10 at 14.33.34 (5).jpeg",
                "top_crop": 58,
                "blur": [
                    (18, 335, 162, 474),
                    (18, 495, 162, 635), (170, 485, 625, 615),
                    (18, 655, 162, 795),
                    (18, 815, 162, 955),
                    (18, 974, 162, 1115),
                    (18, 1135, 162, 1275),
                ],
                "circles": [
                    (485, 70, 585, 146, 1, "ellipse", "bl"),
                    (610, 158, 708, 232, 2, "ellipse", "bl"),
                    (12, 320, 628, 476, 3, "pill", "tr"),
                    (632, 330, 708, 408, 4, "ellipse", "bl"),
                ],
            },
            # Passo 6: Menu de Atalhos (720x1600)
            {
                "file": "WhatsApp Image 2026-11-10 at 14.33.34 (1).jpeg",
                "top_crop": 58,
                "blur": [(145, 115, 425, 180), (640, 615, 720, 720)],
                "circles": [
                    (16, 86, 610, 326, 1, "pill", "tr"),
                    (16, 360, 580, 845, 2, "pill", "tr"),
                    (16, 874, 616, 1180, 3, "pill", "tr"),
                ],
            },
            # Passo 7: Configurações e Privacidade (720x1600)
            {
                "file": "WhatsApp Image 2026-11-10 at 14.33.34 (7).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (16, 84, 616, 266, 1, "pill", "tr"),
                    (16, 274, 612, 466, 2, "pill", "tr"),
                    (16, 476, 612, 836, 3, "pill", "tr"),
                    (16, 864, 616, 1296, 4, "pill", "tr"),
                ],
            },
            # Passo 8: Página de Perfil (720x1600)
            {
                "file": "WhatsApp Image 2026-11-10 at 14.33.34 (6).jpeg",
                "top_crop": 58,
                "blur": [(165, 700, 560, 775), (10, 1365, 710, 1500)],
                "circles": [
                    (465, 164, 706, 246, 1, "pill", "bl"),
                    (422, 598, 514, 690, 2, "ellipse", "tr"),
                    (16, 840, 704, 942, 3, "pill", "tr"),
                    (16, 962, 704, 1288, 4, "pill", "tr"),
                ],
            },
            # Passo 9: Editar Perfil (Apresentação e Dados) (720x1600)
            {
                "file": "WhatsApp Image 2026-11-10 at 14.33.34 (8).jpeg",
                "top_crop": 58,
                "blur": [(85, 1020, 470, 1080), (85, 1295, 275, 1350)],
                "circles": [
                    (420, 380, 514, 474, 1, "ellipse", "tr"),
                    (12, 508, 708, 756, 2, "pill", "tr"),
                    (12, 772, 708, 1462, 3, "pill", "tr"),
                ],
            },
            # Passo 10: Editar Perfil (Trabalho, Educação e Interesses) (720x1600)
            {
                "file": "WhatsApp Image 2026-11-10 at 14.33.34 (9).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (12, 130, 708, 476, 1, "pill", "tr"),
                    (12, 490, 708, 1180, 2, "pill", "tr"),
                    (12, 1198, 708, 1446, 3, "pill", "tr"),
                ],
            },
        ],
    },
    "correios": {
        "orig_dir": "Correios",
        "steps": [
            # Passo 1: Home Correios (720x1600)
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.09 (2).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (8, 215, 74, 290, 1, "ellipse", "br"),
                    (525, 208, 712, 288, 2, "pill", "bl"),
                    (24, 965, 702, 1278, 3, "pill", "tl"),
                ],
            },
            # Passo 2: Campo Acompanhe seu Objeto com teclado (720x1600)
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.09 (4).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (178, 546, 594, 673, 1, "pill", "tl"),
                    (600, 560, 686, 656, 2, "ellipse", "tr"),
                    (12, 708, 708, 960, 3, "pill", "tl"),
                ],
            },
            # Passo 3: Formulário Rastreamento com código de imagem (1024x441)
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.09.jpeg",
                "top_crop": 0,
                "blur": [],
                "circles": [
                    (158, 188, 982, 234, 1, "pill", "tr"),
                    (154, 260, 524, 398, 2, "pill", "bl"),
                    (545, 252, 984, 342, 3, "pill", "tr"),
                    (680, 344, 830, 394, 4, "pill", "tl"),
                ],
            },
            # Passo 4: Linha do tempo da entrega (675x863)
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.09 (1).jpeg",
                "top_crop": 0,
                "blur": [(198, 100, 365, 148)],
                "circles": [
                    (48, 56, 520, 198, 1, "pill", "tr"),
                    (56, 206, 650, 324, 2, "pill", "tr"),
                    (56, 332, 650, 846, 3, "pill", "tr"),
                ],
            },
            # Passo 5: Menu aberto (720x1600)
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.09 (3).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (25, 340, 535, 596, 1, "pill", "tr"),
                    (25, 612, 535, 858, 2, "pill", "tr"),
                    (180, 1150, 692, 1272, 3, "pill", "tr"),
                ],
            },
            # Passo 6: Simulador de Preços e Prazos (720x1600)
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.09 (5).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (20, 604, 700, 748, 1, "pill", "tr"),
                    (98, 762, 702, 1025, 2, "pill", "tr"),
                    (125, 1054, 595, 1175, 3, "pill", "tr"),
                ],
            },
            # Passo 7: Menu lateral do Rastreamento (720x1600)
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.09 (6).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (12, 310, 580, 472, 1, "pill", "tr"),
                    (12, 492, 580, 742, 2, "pill", "tr"),
                    (12, 756, 580, 1102, 3, "pill", "tr"),
                ],
            },
            # Passo 8: Login Meu Correios (720x1600)
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.09 (7).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (58, 628, 662, 842, 1, "pill", "tr"),
                    (55, 854, 665, 958, 2, "pill", "tr"),
                    (72, 976, 645, 1148, 3, "pill", "tr"),
                ],
            },
        ],
    },
    "serasa": {
        "orig_dir": "Serasa",
        "steps": [
            # Passo 1: Página inicial pública (inspect 00)
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.36 (1).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (16, 160, 174, 222, 1, "pill", "br"),
                    (526, 160, 704, 222, 2, "pill", "bl"),
                    (54, 1348, 666, 1464, 3, "pill", "tr"),
                ],
            },
            # Passo 2: Feirão e App oficial (inspect 28)
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.36.jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (16, 72, 704, 212, 1, "pill", "bl"),
                    (58, 318, 658, 504, 2, "pill", "tr"),
                    (54, 1348, 666, 1464, 3, "pill", "tr"),
                ],
            },
            # Passo 3: Menu lateral de produtos (inspect 01)
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.36 (2).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (32, 82, 212, 148, 1, "pill", "br"),
                    (56, 178, 698, 275, 2, "pill", "tr"),
                    (20, 292, 695, 765, 3, "pill", "tr"),
                    (20, 795, 685, 1488, 4, "pill", "tr"),
                ],
            },
            # Passo 4: Tela inicial autenticada (inspect 03)
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.36 (4).jpeg",
                "top_crop": 58,
                "blur": [
                    (546, 176, 634, 262),
                    (112, 345, 275, 398),
                ],
                "circles": [
                    (438, 168, 692, 268, 1, "pill", "bl"),
                    (52, 816, 372, 930, 2, "pill", "tr"),
                    (24, 995, 690, 1218, 3, "pill", "tr"),
                    (12, 1278, 708, 1422, 4, "pill", "tl"),
                ],
            },
            # Passo 5: Cartão Serasa Score na home (inspect 07)
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.36 (8).jpeg",
                "top_crop": 58,
                "blur": [(56, 245, 235, 365)],
                "circles": [
                    (45, 185, 675, 435, 1, "pill", "tr"),
                    (45, 470, 675, 762, 2, "pill", "tr"),
                    (35, 778, 685, 956, 3, "pill", "tr"),
                ],
            },
            # Passo 6: Aba Finanças > Seu Serasa Score (inspect 08)
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.36 (9).jpeg",
                "top_crop": 58,
                "blur": [
                    (546, 90, 634, 178),
                    (92, 355, 265, 450),
                ],
                "circles": [
                    (45, 285, 670, 690, 1, "pill", "tr"),
                    (72, 1152, 648, 1250, 2, "pill", "tr"),
                    (132, 1368, 298, 1506, 3, "ellipse", "tl"),
                ],
            },
            # Passo 7: Score rolado - variações e contas conectadas (inspect 09)
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.36 (10).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (24, 608, 696, 912, 1, "pill", "tr"),
                    (35, 938, 685, 1088, 2, "pill", "tr"),
                    (35, 1110, 685, 1265, 3, "pill", "tr"),
                ],
            },
            # Passo 8: Alertas do Score e monitoramento (inspect 17)
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.36 (18).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (45, 445, 675, 795, 1, "pill", "tr"),
                    (55, 815, 665, 1065, 2, "pill", "tr"),
                    (55, 1080, 665, 1315, 3, "pill", "tr"),
                ],
            },
            # Passo 9: Seu nome está limpo (inspect 11)
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.36 (12).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (40, 270, 680, 565, 1, "pill", "tr"),
                    (40, 600, 680, 1102, 2, "pill", "tr"),
                    (434, 1368, 576, 1502, 3, "ellipse", "tl"),
                ],
            },
            # Passo 10: Aba Minhas Dívidas - Ofertas e Acordos (inspect 19)
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.36 (20).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (20, 505, 700, 598, 1, "pill", "tr"),
                    (36, 808, 684, 902, 2, "pill", "tr"),
                    (40, 965, 680, 1300, 3, "pill", "tr"),
                ],
            },
            # Passo 11: Lista de acordos por situação (inspect 20)
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.36 (21).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (65, 110, 650, 635, 1, "pill", "tr"),
                    (65, 765, 620, 1030, 2, "pill", "tr"),
                    (65, 1170, 650, 1505, 3, "pill", "tr"),
                ],
            },
            # Passo 12: Aba Serviços > Dívidas e pendências (inspect 21)
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.36 (22).jpeg",
                "top_crop": 58,
                "blur": [(546, 66, 634, 154)],
                "circles": [
                    (50, 515, 670, 780, 1, "pill", "tr"),
                    (50, 800, 670, 1070, 2, "pill", "tr"),
                    (50, 1090, 670, 1345, 3, "pill", "tr"),
                    (576, 1372, 714, 1504, 4, "pill", "tl"),
                ],
            },
            # Passo 13: Aba Meu CPF topo (inspect 12)
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.36 (13).jpeg",
                "top_crop": 58,
                "blur": [
                    (546, 58, 634, 136),
                    (106, 895, 245, 950),
                ],
                "circles": [
                    (16, 195, 670, 380, 1, "pill", "tr"),
                    (25, 420, 695, 805, 2, "pill", "tr"),
                    (25, 860, 695, 1340, 3, "pill", "tr"),
                    (286, 1368, 434, 1504, 4, "ellipse", "tl"),
                ],
            },
            # Passo 14: Saúde financeira gratuita (inspect 13)
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.36 (14).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (510, 105, 675, 180, 1, "pill", "bl"),
                    (35, 245, 685, 575, 2, "pill", "tr"),
                    (35, 585, 685, 895, 3, "pill", "tr"),
                ],
            },
            # Passo 15: Selo de segurança e Serasa Recomenda (inspect 14)
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.36 (15).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (50, 245, 670, 415, 1, "pill", "tr"),
                    (50, 635, 670, 995, 2, "pill", "tr"),
                ],
            },
            # Passo 16: Dark Web e Extrato Veicular (inspect 15)
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.36 (16).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (46, 74, 674, 405, 1, "pill", "tr"),
                    (46, 428, 674, 772, 2, "pill", "tr"),
                    (46, 795, 674, 1144, 3, "pill", "tr"),
                ],
            },
            # Passo 17: Educação financeira e Consulta Terceiros (inspect 16)
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.36 (17).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (46, 70, 674, 390, 1, "pill", "tr"),
                    (46, 410, 674, 760, 2, "pill", "tr"),
                    (46, 785, 674, 1138, 3, "pill", "tr"),
                ],
            },
            # Passo 18: Crédito e Empréstimos (inspect 06)
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.36 (7).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (14, 64, 698, 958, 1, "pill", "br"),
                    (24, 1078, 404, 1352, 2, "pill", "tr"),
                ],
            },
            # Passo 19: Bloqueio de consultas e Cadastro Positivo (inspect 10)
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.36 (11).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (35, 68, 685, 180, 1, "pill", "tr"),
                    (35, 200, 685, 365, 2, "pill", "br"),
                    (35, 665, 685, 1212, 3, "pill", "tr"),
                ],
            },
            # Passo 20: Extrato Serasa e Bloquear Score (inspect 22)
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.36 (23).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (48, 74, 672, 325, 1, "pill", "tr"),
                    (48, 355, 672, 602, 2, "pill", "tr"),
                    (48, 795, 672, 1060, 3, "pill", "tr"),
                    (48, 1080, 672, 1342, 4, "pill", "tr"),
                ],
            },
            # Passo 21: Proteção de dados e Acompanhar pedidos (inspect 25)
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.36 (26).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (48, 70, 672, 305, 1, "pill", "tr"),
                    (48, 340, 672, 600, 2, "pill", "tr"),
                    (48, 790, 672, 1055, 3, "pill", "tr"),
                    (48, 1075, 672, 1340, 4, "pill", "tr"),
                ],
            },
            # Passo 22: Validador de boleto e Central de Ajuda (inspect 26)
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.36 (27).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (40, 150, 680, 645, 1, "pill", "tr"),
                    (40, 665, 680, 845, 2, "pill", "tr"),
                    (40, 865, 680, 1215, 3, "pill", "tr"),
                ],
            },
        ],
    },
    "gov-br": {
        "orig_dir": "GOV",
        "steps": [
            # Passo 1: Página inicial portal gov.br (inspect 39)
            {
                "file": "WhatsApp Image 2026-11-13 at 10.54.39.jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (110, 148, 471, 237, 1, "pill", "tl"),
                    (473, 148, 698, 237, 2, "pill", "br"),
                    (14, 390, 706, 540, 3, "pill", "tr"),
                    (18, 838, 702, 1498, 4, "pill", "tl"),
                ],
            },
            # Passo 2: Identifique-se com CPF (inspect 34)
            {
                "file": "WhatsApp Image 2026-11-13 at 10.54.39 (35).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (28, 654, 692, 756, 1, "pill", "tr"),
                    (28, 793, 692, 898, 2, "pill", "tr"),
                    (28, 1015, 692, 1362, 3, "pill", "tr"),
                ],
            },
            # Passo 3: Digite sua senha - BLUR CPF REAL (inspect 35)
            {
                "file": "WhatsApp Image 2026-11-13 at 10.54.39 (36).jpeg",
                "top_crop": 58,
                "blur": [(32, 478, 275, 535)],
                "circles": [
                    (28, 620, 692, 725, 1, "pill", "tr"),
                    (28, 767, 692, 868, 2, "pill", "tr"),
                    (28, 875, 692, 1085, 3, "pill", "tr"),
                ],
            },
            # Passo 4: Conta logada - BLUR NOME REAL (inspect 36)
            {
                "file": "WhatsApp Image 2026-11-13 at 10.54.39 (37).jpeg",
                "top_crop": 58,
                "blur": [(155, 488, 565, 548)],
                "circles": [
                    (248, 386, 476, 482, 1, "pill", "tr"),
                    (135, 547, 585, 635, 2, "pill", "tr"),
                    (14, 662, 704, 1270, 3, "pill", "tr"),
                ],
            },
            # Passo 5: Minha área gov.br - BLUR NOME REAL (inspect 38)
            {
                "file": "WhatsApp Image 2026-11-13 at 10.54.39 (39).jpeg",
                "top_crop": 58,
                "blur": [(175, 220, 660, 340)],
                "circles": [
                    (416, 550, 710, 622, 1, "pill", "tl"),
                    (14, 1025, 704, 1208, 2, "pill", "tr"),
                    (14, 1216, 704, 1496, 3, "pill", "tr"),
                ],
            },
            # Passo 6: Painel Olá! e menu lateral (inspect 11)
            {
                "file": "WhatsApp Image 2026-11-13 at 10.54.39 (12).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (6, 185, 128, 750, 1, "pill", "tr"),
                    (165, 498, 618, 760, 2, "pill", "tr"),
                    (160, 772, 614, 1025, 3, "pill", "tr"),
                ],
            },
            # Passo 7: Grade de serviços gov.br rolada (inspect 12)
            {
                "file": "WhatsApp Image 2026-11-13 at 10.54.39 (13).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (138, 158, 598, 415, 1, "pill", "tr"),
                    (138, 430, 598, 732, 2, "pill", "tr"),
                    (138, 742, 605, 1235, 3, "pill", "tl"),
                ],
            },
            # Passo 8: Lista Minha conta (inspect 37)
            {
                "file": "WhatsApp Image 2026-11-13 at 10.54.39 (38).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (14, 70, 704, 526, 1, "pill", "tr"),
                    (14, 534, 704, 808, 2, "pill", "tr"),
                    (14, 978, 704, 1356, 3, "pill", "tr"),
                ],
            },
            # Passo 9: Agenda gov.br (inspect 13)
            {
                "file": "WhatsApp Image 2026-11-13 at 10.54.39 (14).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (142, 280, 706, 360, 1, "pill", "tr"),
                    (136, 442, 692, 720, 2, "pill", "tr"),
                    (265, 1396, 578, 1490, 3, "pill", "tr"),
                ],
            },
            # Passo 10: Certidões - parte 1 (inspect 14)
            {
                "file": "WhatsApp Image 2026-11-13 at 10.54.39 (15).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (142, 240, 616, 545, 1, "pill", "tr"),
                    (142, 558, 616, 860, 2, "pill", "tr"),
                    (142, 876, 622, 1178, 3, "pill", "tr"),
                ],
            },
            # Passo 11: Certidões - parte 2 (inspect 15)
            {
                "file": "WhatsApp Image 2026-11-13 at 10.54.39 (16).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (142, 240, 622, 545, 1, "pill", "tr"),
                    (136, 560, 616, 862, 2, "pill", "tr"),
                    (142, 1196, 385, 1506, 3, "pill", "tr"),
                ],
            },
            # Passo 12: Destaques do portal (inspect 00)
            {
                "file": "WhatsApp Image 2026-11-13 at 10.54.39 (1).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (40, 322, 680, 410, 1, "pill", "tr"),
                    (40, 636, 680, 972, 2, "pill", "tr"),
                    (40, 1005, 680, 1300, 3, "pill", "tr"),
                ],
            },
            # Passo 13: Perfis Agricultor e Turista (inspect 01)
            {
                "file": "WhatsApp Image 2026-11-13 at 10.54.39 (2).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (64, 260, 328, 598, 1, "pill", "tr"),
                    (392, 260, 656, 598, 2, "pill", "tr"),
                    (153, 755, 567, 857, 3, "pill", "tr"),
                ],
            },
            # Passo 14: Perfis Aposentado e Empreendedor (inspect 02)
            {
                "file": "WhatsApp Image 2026-11-13 at 10.54.39 (3).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (84, 260, 348, 598, 1, "pill", "tr"),
                    (386, 260, 702, 598, 2, "pill", "tr"),
                    (153, 755, 567, 857, 3, "pill", "tr"),
                ],
            },
            # Passo 15: Categorias de A até E (inspect 04)
            {
                "file": "WhatsApp Image 2026-11-13 at 10.54.39 (5).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (35, 196, 685, 434, 1, "pill", "tr"),
                    (35, 446, 685, 1012, 2, "pill", "tr"),
                    (35, 1066, 685, 1485, 3, "pill", "tr"),
                ],
            },
            # Passo 16: Categorias de E até T (inspect 05)
            {
                "file": "WhatsApp Image 2026-11-13 at 10.54.39 (6).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (35, 198, 685, 588, 1, "pill", "tr"),
                    (32, 634, 704, 1026, 2, "pill", "tr"),
                    (35, 1072, 685, 1498, 3, "pill", "tr"),
                ],
            },
            # Passo 17: Banner Aplicativos Oficiais (inspect 07)
            {
                "file": "WhatsApp Image 2026-11-13 at 10.54.39 (8).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (55, 375, 665, 692, 1, "pill", "tr"),
                    (95, 718, 620, 1265, 2, "pill", "tr"),
                ],
            },
            # Passo 18: Galeria de Aplicativos (inspect 20)
            {
                "file": "WhatsApp Image 2026-11-13 at 10.54.39 (21).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (108, 240, 702, 336, 1, "pill", "tr"),
                    (25, 775, 700, 858, 2, "pill", "tr"),
                    (125, 896, 595, 1432, 3, "pill", "tl"),
                ],
            },
            # Passo 19: Aplicativos mais acessados (inspect 16)
            {
                "file": "WhatsApp Image 2026-11-13 at 10.54.39 (17).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (155, 220, 620, 452, 1, "pill", "tr"),
                    (155, 496, 620, 740, 2, "pill", "tr"),
                    (144, 792, 610, 1008, 3, "pill", "tl"),
                    (155, 1086, 620, 1492, 4, "pill", "tr"),
                ],
            },
            # Passo 20: Meu INSS e Cadastro Único (inspect 18)
            {
                "file": "WhatsApp Image 2026-11-13 at 10.54.39 (19).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (136, 208, 588, 876, 1, "pill", "tr"),
                    (136, 902, 588, 1506, 2, "pill", "tr"),
                ],
            },
            # Passo 21: MEI e Carteira de Trabalho Digital (inspect 19)
            {
                "file": "WhatsApp Image 2026-11-13 at 10.54.39 (20).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (136, 192, 588, 854, 1, "pill", "tr"),
                    (136, 876, 588, 1506, 2, "pill", "tr"),
                ],
            },
            # Passo 22: Desempenho dos Serviços (inspect 06)
            {
                "file": "WhatsApp Image 2026-11-13 at 10.54.39 (7).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (35, 376, 685, 470, 1, "pill", "tr"),
                    (145, 550, 575, 815, 2, "pill", "tr"),
                    (120, 905, 600, 1508, 3, "pill", "tr"),
                ],
            },
            # Passo 23: Ouvidoria Denúncia e Solicitação (inspect 09)
            {
                "file": "WhatsApp Image 2026-11-13 at 10.54.39 (10).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (40, 596, 678, 1072, 1, "pill", "tr"),
                    (40, 1088, 678, 1502, 2, "pill", "tr"),
                ],
            },
            # Passo 24: Ouvidoria Elogio, Reclamações e Protocolo (inspect 10)
            {
                "file": "WhatsApp Image 2026-11-13 at 10.54.39 (11).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (40, 156, 678, 636, 1, "pill", "tr"),
                    (40, 652, 678, 1134, 2, "pill", "tr"),
                    (160, 1160, 560, 1288, 3, "pill", "tr"),
                ],
            },
        ],
    },
}


# Complete validated specification for the 10 WebP guides (95 screenshots).
# Coordinates are in the clean image's pixel space (top_crop=0).
WEBP_SPECS: dict[str, dict] = {
    "youtube": {
        "orig_dir": "YouTube",
        "steps": [
            {
                "file": "01_inicio_enquete.jpg",
                "circles": [
                    (8, 10, 628, 535, 1, "pill", "br"),
                    (8, 565, 628, 1095, 2, "pill", "tr"),
                    (8, 1185, 628, 1254, 3, "pill", "tl"),
                ],
            },
            {
                "file": "02_inicio_ao_vivo.jpg",
                "circles": [
                    (418, 12, 628, 66, 1, "pill", "bl"),
                    (8, 84, 485, 142, 2, "pill", "br"),
                    (8, 152, 628, 622, 3, "pill", "tr"),
                ],
            },
            {
                "file": "03_shorts.jpg",
                "circles": [
                    (495, 10, 628, 66, 1, "pill", "bl"),
                    (538, 665, 628, 1020, 2, "pill", "tl"),
                    (10, 1035, 385, 1100, 3, "pill", "tr"),
                    (115, 1185, 225, 1254, 4, "pill", "tr"),
                ],
            },
            {
                "file": "04_inscricoes.jpg",
                "circles": [
                    (88, 84, 212, 142, 1, "pill", "br"),
                    (8, 152, 628, 295, 2, "pill", "br"),
                    (8, 308, 628, 1175, 3, "pill", "tr"),
                ],
            },
            {
                "file": "05_voce_historico.jpg",
                "circles": [
                    (8, 88, 628, 255, 1, "pill", "br"),
                    (8, 295, 628, 575, 2, "pill", "tr"),
                    (8, 600, 628, 965, 3, "pill", "tr"),
                    (505, 1185, 615, 1254, 4, "pill", "tl"),
                ],
            },
            {
                "file": "06_canal_perfil.jpg",
                "circles": [
                    (8, 105, 628, 360, 1, "pill", "br"),
                    (8, 548, 485, 606, 2, "pill", "tr"),
                    (8, 616, 628, 1180, 3, "pill", "tr"),
                ],
            },
            {
                "file": "07_menu_mais.jpg",
                "circles": [
                    (415, 84, 495, 142, 1, "pill", "bl"),
                    (8, 152, 420, 560, 2, "pill", "tr"),
                    (8, 590, 420, 825, 3, "pill", "tr"),
                ],
            },
        ],
    },
    "google-fotos": {
        "orig_dir": "GoogleFotos",
        "steps": [
            {
                "file": "01_fotos.jpg",
                "circles": [
                    (10, 14, 624, 92, 1, "pill", "bl"),
                    (12, 110, 624, 472, 2, "pill", "tr"),
                    (6, 495, 630, 1140, 3, "pill", "tr"),
                    (112, 1156, 522, 1236, 4, "pill", "tl"),
                ],
            },
            {
                "file": "02_albuns.jpg",
                "circles": [
                    (12, 108, 624, 710, 1, "pill", "tr"),
                    (12, 745, 624, 1055, 2, "pill", "tr"),
                    (212, 1156, 336, 1236, 3, "pill", "tl"),
                ],
            },
            {
                "file": "03_criar.jpg",
                "circles": [
                    (14, 108, 624, 680, 1, "pill", "tr"),
                    (14, 725, 624, 1055, 2, "pill", "tr"),
                    (328, 1156, 434, 1236, 3, "pill", "tl"),
                ],
            },
            {
                "file": "04_conta.jpg",
                "circles": [
                    (22, 96, 614, 302, 1, "pill", "br"),
                    (22, 415, 614, 618, 2, "pill", "tr"),
                    (22, 635, 614, 735, 3, "pill", "tr"),
                    (22, 922, 614, 1098, 4, "pill", "tr"),
                ],
            },
        ],
    },
    "tiktok": {
        "orig_dir": "TikTok",
        "steps": [
            {
                "file": "01_inicio_para_voce.jpg",
                "circles": [
                    (8, 16, 626, 78, 1, "pill", "bl"),
                    (544, 648, 626, 1175, 2, "pill", "tl"),
                    (12, 1055, 520, 1165, 3, "pill", "tr"),
                    (8, 1184, 628, 1250, 4, "pill", "tl"),
                ],
            },
            {
                "file": "02_amigos.jpg",
                "circles": [
                    (12, 18, 624, 78, 1, "pill", "bl"),
                    (544, 648, 626, 1175, 2, "pill", "tl"),
                    (120, 1184, 240, 1250, 3, "pill", "tr"),
                ],
            },
            {
                "file": "03_criar_camera.jpg",
                "circles": [
                    (16, 48, 626, 200, 1, "pill", "bl"),
                    (40, 945, 455, 1002, 2, "pill", "tl"),
                    (245, 1010, 390, 1148, 3, "ellipse", "tl"),
                ],
            },
            {
                "file": "04_loja.jpg",
                "circles": [
                    (380, 16, 628, 74, 1, "pill", "bl"),
                    (12, 78, 624, 132, 2, "pill", "br"),
                    (8, 650, 628, 1175, 3, "pill", "tr"),
                ],
            },
            {
                "file": "05_mensagens.jpg",
                "circles": [
                    (12, 16, 624, 78, 1, "pill", "bl"),
                    (12, 84, 440, 278, 2, "pill", "br"),
                    (10, 505, 626, 1125, 3, "pill", "tr"),
                    (385, 1184, 512, 1250, 4, "pill", "tl"),
                ],
            },
            {
                "file": "06_perfil.jpg",
                "circles": [
                    (14, 16, 624, 74, 1, "pill", "bl"),
                    (12, 95, 624, 275, 2, "pill", "br"),
                    (20, 302, 616, 360, 3, "pill", "br"),
                    (520, 1184, 628, 1250, 4, "pill", "tl"),
                ],
            },
        ],
    },
    "poupatempo": {
        "orig_dir": "Poupatempo",
        "steps": [
            {
                "file": "01_boas_vindas.jpg",
                "circles": [
                    (36, 480, 600, 668, 1, "pill", "tr"),
                    (38, 725, 598, 810, 2, "pill", "tr"),
                ],
            },
            {
                "file": "02_login_cpf.jpg",
                "circles": [
                    (72, 425, 566, 515, 1, "pill", "tr"),
                    (72, 535, 566, 610, 2, "pill", "tr"),
                    (72, 650, 566, 925, 3, "pill", "tr"),
                ],
            },
            {
                "file": "03_login_senha.jpg",
                "circles": [
                    (72, 400, 566, 495, 1, "pill", "tr"),
                    (72, 515, 566, 650, 2, "pill", "tr"),
                    (200, 680, 440, 730, 3, "pill", "tr"),
                ],
            },
            {
                "file": "04_inicio.jpg",
                "circles": [
                    (12, 435, 624, 650, 1, "pill", "tr"),
                    (12, 690, 624, 980, 2, "pill", "tr"),
                    (8, 1150, 628, 1232, 3, "pill", "tl"),
                ],
            },
            {
                "file": "05_categorias.jpg",
                "circles": [
                    (10, 14, 626, 210, 1, "pill", "br"),
                    (12, 222, 624, 685, 2, "pill", "tr"),
                    (12, 695, 624, 1140, 3, "pill", "tr"),
                ],
            },
            {
                "file": "06_buscar.jpg",
                "circles": [
                    (22, 85, 614, 165, 1, "pill", "br"),
                    (12, 185, 624, 1140, 2, "pill", "tr"),
                    (248, 1150, 388, 1232, 3, "pill", "tl"),
                ],
            },
            {
                "file": "07_agendamento.jpg",
                "circles": [
                    (24, 98, 612, 265, 1, "pill", "tr"),
                    (24, 278, 612, 445, 2, "pill", "tr"),
                    (125, 1150, 250, 1232, 3, "pill", "tl"),
                ],
            },
            {
                "file": "08_agenda_mensal.jpg",
                "circles": [
                    (18, 20, 618, 86, 1, "pill", "br"),
                    (18, 92, 618, 455, 2, "pill", "tr"),
                    (18, 520, 618, 640, 3, "pill", "tr"),
                ],
            },
            {
                "file": "09_servicos_solicitados.jpg",
                "circles": [
                    (8, 82, 628, 302, 1, "pill", "tr"),
                    (8, 308, 628, 635, 2, "pill", "tr"),
                    (8, 642, 628, 1140, 3, "pill", "tr"),
                ],
            },
            {
                "file": "10_carteira_digital.jpg",
                "circles": [
                    (20, 215, 616, 488, 1, "pill", "tr"),
                    (20, 575, 616, 795, 2, "pill", "tr"),
                    (505, 1150, 628, 1232, 3, "pill", "tl"),
                ],
            },
        ],
    },
    "carteira-digital": {
        "orig_dir": "CNH",
        "steps": [
            {
                "file": "01_inicio.jpg",
                "circles": [
                    (8, 8, 628, 82, 1, "pill", "bl"),
                    (12, 105, 624, 282, 2, "pill", "tr"),
                    (12, 298, 624, 650, 3, "pill", "tr"),
                    (12, 662, 624, 835, 4, "pill", "tr"),
                ],
            },
            {
                "file": "02_menu_lateral.jpg",
                "circles": [
                    (12, 18, 415, 190, 1, "pill", "br"),
                    (12, 200, 415, 660, 2, "pill", "tr"),
                    (12, 668, 415, 865, 3, "pill", "tr"),
                ],
            },
            {
                "file": "03_condutor_resumo.jpg",
                "circles": [
                    (18, 105, 618, 560, 1, "pill", "tr"),
                    (18, 595, 618, 775, 2, "pill", "tr"),
                    (18, 790, 618, 975, 3, "pill", "tr"),
                ],
            },
            {
                "file": "04_habilitacao_digital.jpg",
                "circles": [
                    (20, 88, 616, 145, 1, "pill", "br"),
                    (10, 152, 626, 1015, 2, "pill", "tr"),
                    (18, 1020, 618, 1175, 3, "pill", "tl"),
                ],
            },
            {
                "file": "05_condutor_servicos.jpg",
                "circles": [
                    (18, 105, 618, 405, 1, "pill", "tr"),
                    (18, 560, 618, 748, 2, "pill", "tr"),
                    (18, 765, 618, 955, 3, "pill", "tr"),
                ],
            },
            {
                "file": "06_credencial_estacionamento.jpg",
                "circles": [
                    (18, 105, 618, 495, 1, "pill", "tr"),
                    (18, 505, 618, 682, 2, "pill", "tr"),
                    (18, 692, 618, 885, 3, "pill", "tr"),
                ],
            },
            {
                "file": "07_veiculos.jpg",
                "circles": [
                    (12, 8, 520, 86, 1, "pill", "br"),
                    (110, 560, 526, 760, 2, "pill", "tr"),
                ],
            },
            {
                "file": "08_infracoes_menu.jpg",
                "circles": [
                    (18, 240, 618, 368, 1, "pill", "tr"),
                    (18, 385, 618, 515, 2, "pill", "tr"),
                ],
            },
            {
                "file": "09_infracoes_lista.jpg",
                "circles": [
                    (4, 8, 632, 178, 1, "pill", "br"),
                    (6, 182, 630, 316, 2, "pill", "br"),
                    (18, 690, 618, 865, 3, "pill", "tr"),
                ],
            },
            {
                "file": "10_cadastro_positivo.jpg",
                "circles": [
                    (18, 115, 618, 390, 1, "pill", "tr"),
                    (18, 398, 618, 540, 2, "pill", "tr"),
                    (18, 558, 618, 920, 3, "pill", "tr"),
                ],
            },
        ],
    },
    "carteira-de-trabalho": {
        "orig_dir": "CLT",
        "steps": [
            {
                "file": "01_entrar_gov_br.jpg",
                "circles": [
                    (40, 48, 596, 580, 1, "pill", "tr"),
                    (18, 705, 618, 790, 2, "pill", "tr"),
                    (10, 915, 626, 1155, 3, "pill", "tr"),
                ],
            },
            {
                "file": "02_autorizar_compartilhamento.jpg",
                "circles": [
                    (38, 150, 598, 680, 1, "pill", "tr"),
                    (92, 1105, 552, 1192, 2, "pill", "tl"),
                ],
            },
            {
                "file": "03_carteira_inicio.jpg",
                "circles": [
                    (8, 8, 628, 175, 1, "pill", "bl"),
                    (16, 555, 620, 745, 2, "pill", "tr"),
                    (16, 755, 315, 935, 3, "pill", "tr"),
                    (8, 1175, 628, 1250, 4, "pill", "tl"),
                ],
            },
            {
                "file": "04_contratos_trabalho.jpg",
                "circles": [
                    (10, 12, 628, 228, 1, "pill", "bl"),
                    (18, 255, 618, 650, 2, "pill", "tr"),
                    (20, 1105, 616, 1218, 3, "pill", "tl"),
                ],
            },
            {
                "file": "05_outros_vinculos.jpg",
                "circles": [
                    (10, 185, 626, 615, 1, "pill", "tr"),
                    (18, 710, 618, 800, 2, "pill", "tr"),
                ],
            },
            {
                "file": "06_enviar_carteira.jpg",
                "circles": [
                    (14, 130, 622, 505, 1, "pill", "tr"),
                    (14, 515, 622, 795, 2, "pill", "tr"),
                    (18, 1150, 618, 1235, 3, "pill", "tl"),
                ],
            },
            {
                "file": "07_beneficios.jpg",
                "circles": [
                    (16, 98, 620, 305, 1, "pill", "tr"),
                    (16, 315, 620, 520, 2, "pill", "tr"),
                    (16, 530, 620, 1155, 3, "pill", "tr"),
                    (130, 1175, 255, 1250, 4, "pill", "tl"),
                ],
            },
            {
                "file": "08_emprego.jpg",
                "circles": [
                    (18, 725, 618, 855, 1, "pill", "tr"),
                    (20, 875, 616, 1020, 2, "pill", "tr"),
                    (256, 1175, 380, 1250, 3, "pill", "tl"),
                ],
            },
            {
                "file": "09_emprestimos.jpg",
                "circles": [
                    (12, 130, 420, 365, 1, "pill", "tr"),
                    (14, 880, 622, 1140, 2, "pill", "tl"),
                    (385, 1175, 510, 1250, 3, "pill", "tl"),
                ],
            },
            {
                "file": "10_menu.jpg",
                "circles": [
                    (12, 95, 624, 675, 1, "pill", "tr"),
                    (12, 682, 624, 765, 2, "pill", "tr"),
                    (512, 1175, 628, 1250, 3, "pill", "tl"),
                ],
            },
        ],
    },
    "meu-inss": {
        "orig_dir": "INSS",
        "steps": [
            {
                "file": "01_boas_vindas.jpg",
                "circles": [
                    (24, 150, 612, 480, 1, "pill", "tr"),
                    (18, 1152, 618, 1236, 2, "pill", "tl"),
                ],
            },
            {
                "file": "02_politica_privacidade.jpg",
                "circles": [
                    (18, 20, 618, 1020, 1, "pill", "tr"),
                    (18, 1070, 618, 1236, 2, "pill", "tl"),
                ],
            },
            {
                "file": "03_entrar_gov_br.jpg",
                "circles": [
                    (62, 290, 574, 378, 1, "pill", "tr"),
                    (14, 675, 622, 1245, 2, "pill", "tr"),
                ],
            },
            {
                "file": "04_autorizar_compartilhamento.jpg",
                "circles": [
                    (36, 150, 600, 665, 1, "pill", "tr"),
                    (92, 1105, 552, 1192, 2, "pill", "tl"),
                ],
            },
            {
                "file": "05_acesso_biometria.jpg",
                "circles": [
                    (10, 110, 626, 615, 1, "pill", "tr"),
                    (18, 1075, 618, 1236, 2, "pill", "tl"),
                ],
            },
            {
                "file": "06_notificacao_celular.jpg",
                "circles": [
                    (10, 110, 626, 600, 1, "pill", "tr"),
                    (18, 1075, 618, 1236, 2, "pill", "tl"),
                ],
            },
            {
                "file": "07_inicio.jpg",
                "circles": [
                    (4, 4, 632, 78, 1, "pill", "bl"),
                    (18, 195, 618, 605, 2, "pill", "tr"),
                    (18, 635, 618, 945, 3, "pill", "tr"),
                ],
            },
            {
                "file": "08_chat_helo.jpg",
                "circles": [
                    (4, 578, 632, 650, 1, "pill", "tr"),
                    (110, 665, 526, 1025, 2, "pill", "tr"),
                ],
            },
            {
                "file": "09_menu_lateral.jpg",
                "circles": [
                    (4, 86, 630, 385, 1, "pill", "tr"),
                    (4, 392, 630, 705, 2, "pill", "tr"),
                    (4, 712, 630, 1185, 3, "pill", "tr"),
                ],
            },
            {
                "file": "10_buscar_servico.jpg",
                "circles": [
                    (22, 86, 614, 165, 1, "pill", "br"),
                    (18, 185, 618, 1235, 2, "pill", "tr"),
                ],
            },
            {
                "file": "11_notificacoes.jpg",
                "circles": [
                    (18, 175, 618, 1045, 1, "pill", "tr"),
                    (18, 1075, 618, 1236, 2, "pill", "tl"),
                ],
            },
            {
                "file": "12_meu_perfil.jpg",
                "circles": [
                    (20, 86, 520, 175, 1, "pill", "br"),
                    (22, 185, 614, 490, 2, "pill", "tr"),
                    (22, 498, 614, 625, 3, "pill", "tr"),
                    (18, 1152, 618, 1236, 4, "pill", "tl"),
                ],
            },
            {
                "file": "13_extratos_e_comprovantes.jpg",
                "circles": [
                    (22, 185, 614, 260, 1, "pill", "br"),
                    (22, 275, 614, 520, 2, "pill", "tr"),
                    (18, 1152, 618, 1236, 3, "pill", "tl"),
                ],
            },
            {
                "file": "14_extrato_contribuicoes_cnis.jpg",
                "circles": [
                    (20, 280, 616, 800, 1, "pill", "tr"),
                    (20, 815, 616, 1055, 2, "pill", "tr"),
                    (18, 1075, 618, 1236, 3, "pill", "tl"),
                ],
            },
            {
                "file": "15_beneficio_afastamento_protetivo.jpg",
                "circles": [
                    (18, 175, 618, 515, 1, "pill", "tr"),
                    (18, 1075, 618, 1236, 2, "pill", "tl"),
                ],
            },
            {
                "file": "16_beneficios_por_incapacidade.jpg",
                "circles": [
                    (22, 185, 614, 260, 1, "pill", "br"),
                    (22, 275, 614, 685, 2, "pill", "tr"),
                    (22, 695, 614, 1135, 3, "pill", "tr"),
                ],
            },
            {
                "file": "17_novo_pedido.jpg",
                "circles": [
                    (20, 125, 616, 650, 1, "pill", "tr"),
                    (18, 1075, 618, 1236, 2, "pill", "tl"),
                ],
            },
            {
                "file": "18_mais_servicos.jpg",
                "circles": [
                    (22, 86, 614, 165, 1, "pill", "br"),
                    (18, 190, 618, 705, 2, "pill", "tr"),
                    (18, 720, 618, 1145, 3, "pill", "tr"),
                ],
            },
            {
                "file": "19_ajuda.jpg",
                "circles": [
                    (20, 150, 616, 330, 1, "pill", "tr"),
                    (20, 338, 616, 418, 2, "pill", "tr"),
                    (20, 425, 616, 585, 3, "pill", "tr"),
                    (18, 1152, 618, 1236, 4, "pill", "tl"),
                ],
            },
        ],
    },
    "e-titulo": {
        "orig_dir": "ETitulo",
        "steps": [
            {
                "file": "passo_1.webp",
                "circles": [
                    (135, 195, 585, 815, 1, "pill", "tr"),
                    (50, 845, 490, 945, 2, "pill", "tr"),
                    (12, 1345, 708, 1435, 3, "pill", "tl"),
                ],
            },
            {
                "file": "passo_2.webp",
                "circles": [
                    (45, 135, 468, 575, 1, "pill", "tr"),
                    (18, 585, 488, 905, 2, "pill", "tr"),
                    (8, 925, 501, 1018, 3, "pill", "tl"),
                ],
            },
            {
                "file": "passo_3.webp",
                "circles": [
                    (12, 68, 494, 625, 1, "pill", "tr"),
                    (12, 635, 494, 920, 2, "pill", "tr"),
                    (8, 928, 498, 1018, 3, "pill", "tl"),
                ],
            },
            {
                "file": "passo_4.webp",
                "circles": [
                    (28, 125, 745, 690, 1, "pill", "tr"),
                    (18, 1360, 780, 1480, 2, "pill", "tl"),
                    (475, 1490, 628, 1590, 3, "pill", "tl"),
                ],
            },
            {
                "file": "passo_5.webp",
                "circles": [
                    (18, 150, 780, 885, 1, "pill", "tr"),
                    (632, 1490, 790, 1590, 2, "pill", "tl"),
                ],
            },
            {
                "file": "passo_6.webp",
                "circles": [
                    (18, 165, 774, 595, 1, "pill", "tr"),
                    (18, 635, 774, 975, 2, "pill", "tr"),
                    (18, 1020, 774, 1485, 3, "pill", "tl"),
                ],
            },
        ],
    },
    "fgts": {
        "orig_dir": "FGTS",
        "steps": [
            {
                "file": "passo_1.webp",
                "circles": [
                    (80, 215, 714, 655, 1, "pill", "tr"),
                    (24, 1055, 770, 1185, 2, "pill", "tr"),
                    (130, 1280, 665, 1365, 3, "pill", "tr"),
                ],
            },
            {
                "file": "passo_2.webp",
                "circles": [
                    (45, 455, 748, 560, 1, "pill", "tr"),
                    (45, 570, 748, 675, 2, "pill", "tr"),
                    (160, 690, 635, 845, 3, "pill", "tr"),
                ],
            },
            {
                "file": "passo_3.webp",
                "circles": [
                    (18, 60, 776, 1245, 1, "pill", "tr"),
                    (115, 1300, 680, 1385, 2, "pill", "tl"),
                    (24, 1430, 770, 1555, 3, "pill", "tl"),
                ],
            },
            {
                "file": "passo_4.webp",
                "circles": [
                    (18, 885, 772, 1090, 1, "pill", "tr"),
                    (18, 1275, 772, 1515, 2, "pill", "tl"),
                ],
            },
            {
                "file": "passo_5.webp",
                "circles": [
                    (18, 400, 772, 1185, 1, "pill", "tr"),
                    (18, 1255, 772, 1510, 2, "pill", "tl"),
                ],
            },
            {
                "file": "passo_6.webp",
                "circles": [
                    (18, 108, 520, 275, 1, "pill", "br"),
                    (24, 335, 770, 910, 2, "pill", "tr"),
                    (24, 935, 770, 1485, 3, "pill", "tr"),
                    (8, 1500, 787, 1610, 4, "pill", "tl"),
                ],
            },
            {
                "file": "passo_7.webp",
                "circles": [
                    (18, 365, 778, 580, 1, "pill", "tr"),
                    (18, 595, 778, 795, 2, "pill", "tr"),
                    (195, 1500, 395, 1595, 3, "pill", "tl"),
                ],
            },
            {
                "file": "passo_8.webp",
                "circles": [
                    (18, 345, 782, 855, 1, "pill", "tr"),
                    (18, 870, 782, 1345, 2, "pill", "tr"),
                    (18, 1360, 782, 1585, 3, "pill", "tl"),
                ],
            },
            {
                "file": "passo_9.webp",
                "circles": [
                    (18, 115, 788, 435, 1, "pill", "tr"),
                    (18, 450, 788, 635, 2, "pill", "tr"),
                    (18, 650, 788, 825, 3, "pill", "tr"),
                ],
            },
            {
                "file": "passo_10.webp",
                "circles": [
                    (28, 445, 774, 710, 1, "pill", "tr"),
                    (68, 935, 734, 1055, 2, "pill", "tr"),
                    (68, 1070, 734, 1185, 3, "pill", "tl"),
                ],
            },
            {
                "file": "passo_11.webp",
                "circles": [
                    (18, 115, 778, 495, 1, "pill", "tr"),
                    (18, 508, 778, 1030, 2, "pill", "tr"),
                    (18, 1040, 778, 1485, 3, "pill", "tl"),
                ],
            },
            {
                "file": "passo_12.webp",
                "circles": [
                    (45, 215, 756, 975, 1, "pill", "tr"),
                    (45, 1020, 756, 1520, 2, "pill", "tl"),
                ],
            },
        ],
    },
    "instagram": {
        "orig_dir": "Instagram",
        "steps": [
            {
                "file": "passo_1.webp",
                "circles": [
                    (14, 140, 1066, 455, 1, "pill", "br"),
                    (800, 18, 940, 120, 2, "ellipse", "bl"),
                    (18, 1715, 340, 1820, 3, "pill", "tr"),
                    (14, 1825, 1066, 1928, 4, "pill", "tl"),
                ],
            },
            {
                "file": "passo_2.webp",
                "circles": [
                    (260, 18, 820, 118, 1, "pill", "br"),
                    (910, 880, 1068, 1550, 2, "pill", "tl"),
                    (20, 1570, 720, 1775, 3, "pill", "tr"),
                ],
            },
            {
                "file": "passo_3.webp",
                "circles": [
                    (24, 160, 1056, 375, 1, "pill", "br"),
                    (14, 495, 355, 1055, 2, "pill", "tr"),
                    (362, 495, 1066, 1620, 3, "pill", "tl"),
                ],
            },
            {
                "file": "passo_4.webp",
                "circles": [
                    (955, 18, 1068, 720, 1, "pill", "bl"),
                    (24, 1800, 480, 1925, 2, "pill", "tr"),
                    (495, 1800, 1062, 1925, 3, "pill", "tl"),
                ],
            },
            {
                "file": "passo_5.webp",
                "circles": [
                    (14, 165, 1066, 575, 1, "pill", "tr"),
                    (14, 585, 1066, 755, 2, "pill", "tr"),
                    (14, 765, 1066, 1750, 3, "pill", "tr"),
                ],
            },
            {
                "file": "passo_6.webp",
                "circles": [
                    (24, 145, 1056, 238, 1, "pill", "br"),
                    (18, 248, 1062, 522, 2, "pill", "br"),
                    (14, 535, 1066, 1780, 3, "pill", "tr"),
                ],
            },
            {
                "file": "passo_7.webp",
                "circles": [
                    (18, 12, 950, 115, 1, "pill", "bl"),
                    (10, 125, 1070, 1810, 2, "pill", "tr"),
                ],
            },
            {
                "file": "passo_8.webp",
                "circles": [
                    (120, 12, 1060, 115, 1, "pill", "bl"),
                    (14, 155, 1066, 1465, 2, "pill", "tr"),
                ],
            },
            {
                "file": "passo_9.webp",
                "circles": [
                    (14, 12, 1066, 125, 1, "pill", "bl"),
                    (14, 150, 1066, 625, 2, "pill", "br"),
                    (14, 915, 1066, 2060, 3, "pill", "tr"),
                ],
            },
            {
                "file": "passo_10.webp",
                "circles": [
                    (14, 115, 782, 495, 1, "pill", "br"),
                    (14, 520, 782, 1110, 2, "pill", "tr"),
                    (14, 1460, 782, 1590, 3, "pill", "tl"),
                ],
            },
            {
                "file": "passo_11.webp",
                "circles": [
                    (18, 25, 1062, 145, 1, "pill", "bl"),
                    (20, 185, 1060, 1740, 2, "pill", "tr"),
                    (14, 1785, 1066, 1925, 3, "pill", "tl"),
                ],
            },
        ],
    },
}


def make_contact_sheet(chave: str, images: list[tuple[int, Image.Image]], out_path: str) -> None:
    cols = 4
    rows = (len(images) + cols - 1) // cols
    tw, th, pad = 270, 580, 14
    sheet = Image.new("RGB", (cols * (tw + pad) + pad, rows * (th + pad) + pad), (242, 244, 248))
    draw = ImageDraw.Draw(sheet)
    font = load_font(20)
    for i, (step_num, im) in enumerate(images):
        c = i % cols
        r = i // cols
        x0 = pad + c * (tw + pad)
        y0 = pad + r * (th + pad)
        thumb = im.copy()
        thumb.thumbnail((tw, th), Image.Resampling.LANCZOS)
        sheet.paste(thumb, (x0, y0))
        tag = f"#{step_num}"
        draw.rectangle((x0, y0, x0 + 54, y0 + 28), fill=(20, 20, 20))
        draw.text((x0 + 8, y0 + 4), tag, font=font, fill=(255, 255, 255))
    _atomic_save_jpg(sheet, out_path, quality=88, optimize=True)


def main() -> None:
    parser = argparse.ArgumentParser(description="Processa e anota os guias visuais da Memora.")
    parser.add_argument(
        "--verify",
        action="store_true",
        help="Gera folhas de contato de verificacao em diretorio temporario.",
    )
    parser.add_argument(
        "--verify-dir",
        default=None,
        help="Diretorio explicito opcional para salvar folhas de contato de verificacao.",
    )
    args = parser.parse_args()

    verify_dir: str | None = args.verify_dir
    if verify_dir is None and args.verify:
        verify_dir = tempfile.mkdtemp(prefix="memora_guias_verify_")
    if verify_dir is not None:
        os.makedirs(verify_dir, exist_ok=True)

    blurred_checks: list[tuple[str, Image.Image]] = []

    for chave, cfg in SPECS.items():
        orig_dir = os.path.join(ORIG, cfg["orig_dir"])
        clean_dir = os.path.join(APPS, cfg["orig_dir"])
        out_dir = os.path.join(ASSETS_GUIAS, chave)
        os.makedirs(orig_dir, exist_ok=True)
        os.makedirs(clean_dir, exist_ok=True)
        os.makedirs(out_dir, exist_ok=True)

        # Remove old/stale files in out_dir except .gitkeep
        expected = {f"passo_{i}.jpg" for i in range(1, len(cfg["steps"]) + 1)}
        for existing in os.listdir(out_dir):
            if existing == ".gitkeep":
                continue
            if existing not in expected:
                os.remove(os.path.join(out_dir, existing))

        verify_imgs: list[tuple[int, Image.Image]] = []
        for idx, step in enumerate(cfg["steps"], start=1):
            src_path = os.path.join(orig_dir, step["file"])
            clean_path = os.path.join(clean_dir, step["file"])
            if not os.path.exists(src_path):
                if os.path.exists(clean_path):
                    shutil.copy2(clean_path, src_path)
                else:
                    raise FileNotFoundError(f"Arquivo original ausente: {src_path}")

            im = Image.open(src_path).convert("RGB")
            if step["blur"]:
                im = apply_blurs(im, step["blur"], step.get("keep"), radius=28)
                if verify_dir is not None:
                    blurred_checks.append(
                        (f"{chave}_{idx}", im.crop((0, step["top_crop"], im.width, im.height)))
                    )

            top_crop = step["top_crop"]
            if top_crop > 0:
                im = im.crop((0, top_crop, im.width, im.height))

            # Clean cropped+blurred copy in apps/<DIR>/ (skip overwriting tracked .jfif raw source if identical name)
            if not step["file"].lower().endswith(".jfif"):
                _atomic_save_jpg(im, clean_path, quality=92, optimize=True)

            # Annotated version for app/assets/guias/<chave>/passo_<n>.jpg
            annotated = draw_annotations(im, step["circles"], top_crop=top_crop)
            dst_path = os.path.join(out_dir, f"passo_{idx}.jpg")
            save_asset_jpg(annotated, dst_path, target_width=480, quality=80)
            if verify_dir is not None:
                verify_imgs.append((idx, Image.open(dst_path)))

        if verify_dir is not None:
            make_contact_sheet(chave, verify_imgs, os.path.join(verify_dir, f"verify_{chave}.jpg"))
        print(f"[{chave}] {len(cfg['steps'])} passos processados e anotados -> {out_dir}")

    for chave, cfg in WEBP_SPECS.items():
        orig_dir = os.path.join(ORIG, cfg["orig_dir"])
        clean_dir = os.path.join(APPS, cfg["orig_dir"])
        out_dir = os.path.join(ASSETS_GUIAS, chave)
        os.makedirs(clean_dir, exist_ok=True)
        os.makedirs(out_dir, exist_ok=True)

        expected = {f"passo_{i}.webp" for i in range(1, len(cfg["steps"]) + 1)}
        for existing in os.listdir(out_dir):
            if existing == ".gitkeep":
                continue
            if existing not in expected:
                os.remove(os.path.join(out_dir, existing))

        verify_imgs_webp: list[tuple[int, Image.Image]] = []
        for idx, step in enumerate(cfg["steps"], start=1):
            clean_path = os.path.join(clean_dir, step["file"])
            orig_path = os.path.join(orig_dir, step["file"])
            if os.path.exists(clean_path):
                src_path = clean_path
            elif os.path.exists(orig_path):
                src_path = orig_path
                shutil.copy2(orig_path, clean_path)
            else:
                raise FileNotFoundError(f"Arquivo base ausente: {clean_path}")

            im = Image.open(src_path).convert("RGB")
            if chave == "instagram":
                im = _sanitize_instagram_clean(idx, im)
                _atomic_save_webp(im, clean_path, quality=90)

            annotated = draw_annotations(im, step["circles"], top_crop=0)
            dst_path = os.path.join(out_dir, f"passo_{idx}.webp")
            save_asset_webp(annotated, dst_path, target_width=636, quality=80)
            if verify_dir is not None:
                verify_imgs_webp.append((idx, Image.open(dst_path)))

        if verify_dir is not None:
            make_contact_sheet(chave, verify_imgs_webp, os.path.join(verify_dir, f"verify_{chave}.jpg"))
        print(f"[{chave}] {len(cfg['steps'])} passos WebP processados e anotados -> {out_dir}")

    if verify_dir is not None and blurred_checks:
        cols = 4
        rows = (len(blurred_checks) + cols - 1) // cols
        tw, th, pad = 270, 580, 14
        sheet = Image.new("RGB", (cols * (tw + pad) + pad, rows * (th + pad) + pad), (242, 244, 248))
        draw = ImageDraw.Draw(sheet)
        font = load_font(18)
        for i, (label, bim) in enumerate(blurred_checks):
            c = i % cols
            r = i // cols
            x0, y0 = pad + c * (tw + pad), pad + r * (th + pad)
            thumb = bim.copy()
            thumb.thumbnail((tw, th), Image.Resampling.LANCZOS)
            sheet.paste(thumb, (x0, y0))
            draw.rectangle((x0, y0, x0 + 130, y0 + 26), fill=(20, 20, 20))
            draw.text((x0 + 6, y0 + 3), label, font=font, fill=(255, 255, 255))
        _atomic_save_jpg(sheet, os.path.join(verify_dir, "verify_blurs.jpg"), quality=90, optimize=True)
        print(f"Folhas de verificacao salvas em: {verify_dir}")

    total_bytes = sum(
        os.path.getsize(os.path.join(dp, f))
        for dp, _, filenames in os.walk(ASSETS_GUIAS)
        for f in filenames
    )
    mb = total_bytes / (1024 * 1024)
    print(f"Tamanho total de {ASSETS_GUIAS}: {mb:.2f} MB ({total_bytes} bytes)")
    assert total_bytes <= 12 * 1024 * 1024, f"Excedeu limite de 12 MB: {mb:.2f} MB"


if __name__ == "__main__":
    main()
