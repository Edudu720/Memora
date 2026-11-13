import os
import re
from PIL import Image, ImageFilter

ORIG = "apps/.originais"
APPS = "apps"
ASSETS_GUIAS = "app/assets/guias"
ASSETS_ILUST = "app/assets/ilustracoes"
SCRATCH = r"C:\Users\Edu\.gemini\antigravity\brain\47755337-5c86-4f71-b7d2-44bc7a93f8d7\scratch"


def blur_boxes(im: Image.Image, boxes: list[tuple[int, int, int, int]], radius: int = 28) -> Image.Image:
    """Applies Gaussian Blur on each (x1, y1, x2, y2) region of the image."""
    out = im.copy()
    w, h = out.size
    for (x1, y1, x2, y2) in boxes:
        box = (max(0, x1), max(0, y1), min(w, x2), min(h, y2))
        crop = out.crop(box).filter(ImageFilter.GaussianBlur(radius=radius))
        out.paste(crop, box)
    return out


def make_square_logo(src_path: str, dst_path: str, size: int = 512) -> None:
    """Centers logo on a clean square 512x512 RGBA canvas."""
    im = Image.open(src_path).convert("RGBA")
    # Preserve aspect ratio inside square
    im.thumbnail((size, size), Image.Resampling.LANCZOS)
    # Sample corner color for seamless background if opaque JPEG/JFIF
    bg = (255, 255, 255, 255)
    if src_path.lower().endswith((".jfif", ".jpg", ".jpeg")):
        px = im.getpixel((2, 2))
        bg = (px[0], px[1], px[2], 255)
    canvas = Image.new("RGBA", (size, size), bg)
    x = (size - im.width) // 2
    y = (size - im.height) // 2
    canvas.paste(im, (x, y), im)
    canvas.save(dst_path, optimize=True)


def save_asset_jpg(im: Image.Image, dst_path: str, target_width: int = 480, quality: int = 80) -> None:
    """Resizes screenshot to target_width and saves compressed JPEG to respect the 8 MB budget."""
    os.makedirs(os.path.dirname(dst_path), exist_ok=True)
    if im.width > target_width:
        ratio = target_width / im.width
        new_h = int(im.height * ratio)
        resized = im.resize((target_width, new_h), Image.Resampling.LANCZOS)
    else:
        resized = im.copy()
    resized.convert("RGB").save(dst_path, "JPEG", quality=quality, optimize=True)


def natural_key(s: str):
    return [int(t) if t.isdigit() else t.lower() for t in re.split(r"(\d+)", s)]


def main():
    os.makedirs(ASSETS_ILUST, exist_ok=True)
    os.makedirs(SCRATCH, exist_ok=True)

    # 1. Logos (T017)
    make_square_logo(os.path.join(ORIG, "GOV", "logo.png"), os.path.join(ASSETS_ILUST, "gov_br_logo.png"))
    make_square_logo(os.path.join(ORIG, "Serasa", "serasa_logo.jfif"), os.path.join(ASSETS_ILUST, "serasa_logo.png"))
    make_square_logo(os.path.join(ORIG, "Correios", "correios-perfil-facebook.png"), os.path.join(ASSETS_ILUST, "correios_logo.png"))
    print("Logos 512x512 geradas em", ASSETS_ILUST)

    # 2. Blur Map por pasta (coordenadas verificadas visualmente em 720x1600)
    gov_blurs = {
        "WhatsApp Image 2026-11-13 at 10.54.39 (36).jpeg": [(20, 440, 360, 520)],  # CPF real 524.957.408-47
        "WhatsApp Image 2026-11-13 at 10.54.39 (37).jpeg": [
            (610, 125, 695, 205),  # mini avatar topo
            (285, 210, 435, 360),  # avatar central
            (120, 505, 600, 575),  # nome completo EDUARDO JUNCKER TORAS
        ],
        "WhatsApp Image 2026-11-13 at 10.54.39 (39).jpeg": [
            (600, 115, 715, 205),  # mini avatar topo
            (25, 220, 155, 350),   # avatar grande
            (165, 235, 695, 345),  # "Olá, EDUARDO JUNCKER TORAS"
        ],
    }

    serasa_blurs = {
        "WhatsApp Image 2026-11-11 at 18.53.36 (4).jpeg": [(25, 340, 340, 420), (555, 165, 650, 255)],
        "WhatsApp Image 2026-11-11 at 18.53.36 (5).jpeg": [(25, 340, 340, 420), (555, 165, 650, 255)],
        "WhatsApp Image 2026-11-11 at 18.53.36 (6).jpeg": [(25, 340, 340, 420), (555, 165, 650, 255)],
        "WhatsApp Image 2026-11-11 at 18.53.36 (8).jpeg": [(25, 255, 240, 375)],
        "WhatsApp Image 2026-11-11 at 18.53.36 (9).jpeg": [(25, 345, 260, 465), (500, 90, 645, 180)],
        "WhatsApp Image 2026-11-11 at 18.53.36 (13).jpeg": [(25, 905, 320, 955), (500, 55, 645, 130)],
        "WhatsApp Image 2026-11-11 at 18.53.36 (22).jpeg": [(500, 65, 645, 160)],
    }

    correios_blurs = {
        "WhatsApp Image 2026-11-11 at 18.53.09 (1).jpeg": [(0, 65, 675, 210)],
    }

    blurred_samples = []

    def process_folder(folder_name: str, blur_map: dict, exclude_files: set[str] | None = None):
        src_dir = os.path.join(ORIG, folder_name)
        dst_dir = os.path.join(APPS, folder_name)
        os.makedirs(dst_dir, exist_ok=True)
        files = sorted(os.listdir(src_dir), key=natural_key)
        processed = {}
        for fn in files:
            if exclude_files and fn in exclude_files:
                # Remove accidental duplicate from apps/Serasa
                rem = os.path.join(dst_dir, fn)
                if os.path.exists(rem):
                    os.remove(rem)
                continue
            src_p = os.path.join(src_dir, fn)
            dst_p = os.path.join(dst_dir, fn)
            if fn.lower().endswith((".jpeg", ".jpg")) and "WhatsApp" in fn:
                im = Image.open(src_p).convert("RGB")
                if fn in blur_map:
                    im = blur_boxes(im, blur_map[fn], radius=28)
                    blurred_samples.append((f"{folder_name}/{fn}", im))
                im.save(dst_p, "JPEG", quality=92, optimize=True)
                processed[fn] = im
        return files, processed

    gov_files, gov_imgs = process_folder("GOV", gov_blurs)
    serasa_files, serasa_imgs = process_folder(
        "Serasa",
        serasa_blurs,
        exclude_files={"WhatsApp Image 2026-11-11 at 18.53.36 (28).jpeg"},
    )
    correios_files, correios_imgs = process_folder("Correios", correios_blurs)

    # 3. Mapear índices naturais (mesmos da folha de contato) -> passos em app/assets/guias/
    def by_idx(files_list):
        return [f for f in files_list if f.lower().endswith((".jpeg", ".jpg", ".png", ".jfif"))]

    gov_all = by_idx(gov_files)
    serasa_all = by_idx(serasa_files)
    correios_all = by_idx(correios_files)

    gov_order = [40, 35, 36, 37, 39, 12, 13, 38, 14, 15, 16, 1, 2, 3, 5, 6, 8, 9, 17, 19, 20, 7, 10, 11]
    serasa_order = [29, 1, 2, 4, 8, 9, 10, 18, 12, 20, 21, 22, 13, 14, 15, 16, 24, 7, 11, 23, 26, 27]
    correios_order = [2, 4, 8, 1, 3, 5, 6, 7]

    def export_steps(chave: str, all_files: list[str], imgs: dict[str, Image.Image], order: list[int]):
        out_dir = os.path.join(ASSETS_GUIAS, chave)
        os.makedirs(out_dir, exist_ok=True)
        # Remove old placeholder passo_*.png so directory stays clean & under 8MB
        for old in os.listdir(out_dir):
            if old.startswith("passo_") and old.endswith(".png"):
                os.remove(os.path.join(out_dir, old))
        for step_num, idx in enumerate(order, start=1):
            fn = all_files[idx]
            im = imgs[fn]
            save_asset_jpg(im, os.path.join(out_dir, f"passo_{step_num}.jpg"))
        print(f"Exportados {len(order)} passos para {out_dir}")

    export_steps("gov-br", gov_all, gov_imgs, gov_order)
    export_steps("serasa", serasa_all, serasa_imgs, serasa_order)
    export_steps("correios", correios_all, correios_imgs, correios_order)

    # 4. Gerar folha de verificação visual das imagens censuradas
    if blurred_samples:
        cols = 4
        rows = (len(blurred_samples) + cols - 1) // cols
        tw, th, pad = 260, 560, 12
        sheet = Image.new("RGB", (cols * (tw + pad) + pad, rows * (th + pad) + pad), (245, 245, 245))
        for i, (_, bim) in enumerate(blurred_samples):
            c = i % cols
            r = i // cols
            thumb = bim.copy()
            thumb.thumbnail((tw, th), Image.Resampling.LANCZOS)
            sheet.paste(thumb, (pad + c * (tw + pad), pad + r * (th + pad)))
        verif_path = os.path.join(SCRATCH, "blur_verification.jpg")
        sheet.save(verif_path, quality=85)
        print("Folha de verificacao de Blur salva em:", verif_path)

    # 5. Calcular tamanho total de app/assets/guias/
    total_bytes = sum(
        os.path.getsize(os.path.join(dp, f))
        for dp, _, filenames in os.walk(ASSETS_GUIAS)
        for f in filenames
    )
    print(f"Tamanho total de {ASSETS_GUIAS}: {total_bytes / (1024 * 1024):.2f} MB ({total_bytes} bytes)")


if __name__ == "__main__":
    main()
