import os
import shutil
from PIL import Image, ImageDraw, ImageFilter, ImageFont

def make_avatar(radius, bg_color=(42, 171, 238), fg_color=(255, 255, 255)):
    """Generates an antialiased Telegram-style avatar with circular silhouette."""
    scale = 4
    size = radius * 2 * scale
    cx = size // 2
    cy = size // 2
    r = radius * scale
    
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=bg_color + (255,))
    
    hr = int(r * 0.35)
    hcy = int(r * 0.70)
    draw.ellipse([cx - hr, hcy - hr, cx + hr, hcy + hr], fill=fg_color + (255,))
    
    body_img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    bdraw = ImageDraw.Draw(body_img)
    brx = int(r * 0.68)
    bry = int(r * 0.60)
    bcy = int(r * 1.55)
    bdraw.ellipse([cx - brx, bcy - bry, cx + brx, bcy + bry], fill=fg_color + (255,))
    
    img = Image.alpha_composite(img, body_img)
    
    mask = Image.new('L', (size, size), 0)
    mdraw = ImageDraw.Draw(mask)
    mdraw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=255)
    
    final_img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    final_img.paste(img, (0, 0), mask)
    return final_img.resize((radius * 2, radius * 2), Image.Resampling.LANCZOS)

def draw_camera_badge(draw, cx=426, cy=289, r=29):
    """Draws Telegram camera badge at avatar bottom-right."""
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(255, 255, 255))
    inner_r = r - 3
    draw.ellipse([cx - inner_r, cy - inner_r, cx + inner_r, cy + inner_r], fill=(41, 169, 234))
    
    cw, ch = 14, 10
    draw.rounded_rectangle([cx - cw, cy - ch + 2, cx + cw, cy + ch + 2], radius=3, fill=(255, 255, 255))
    draw.polygon([(cx - 5, cy - ch + 2), (cx - 3, cy - ch - 2), (cx + 3, cy - ch - 2), (cx + 5, cy - ch + 2)], fill=(255, 255, 255))
    draw.ellipse([cx - 5, cy - 2, cx + 5, cy + 8], fill=(41, 169, 234))
    draw.ellipse([cx - 3, cy, cx + 3, cy + 6], fill=(255, 255, 255))

def run_censoring():
    orig_t = 'apps/.originais/Telegram'
    orig_w = 'apps/.originais/WhatsApp'
    
    dest_t = 'apps/Telegram'
    dest_w = 'apps/WhatsApp'

    os.makedirs(dest_t, exist_ok=True)
    os.makedirs(dest_w, exist_ok=True)

    font_name = ImageFont.truetype('C:/Windows/Fonts/segoeuib.ttf', 32)
    font_phone = ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf', 24)
    font_banner = ImageFont.truetype('C:/Windows/Fonts/segoeuib.ttf', 27)
    font_card_num = ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf', 28)
    font_header_tg = ImageFont.truetype('C:/Windows/Fonts/segoeuib.ttf', 34)
    font_header_wa = ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf', 42)

    av_big = make_avatar(96)
    tab_av_inactive = make_avatar(22, bg_color=(180, 185, 192))
    tab_av_active = make_avatar(22, bg_color=(41, 169, 234))

    # ==========================================
    # TELEGRAM
    # ==========================================

    # 1. Telegram Chats: WhatsApp Image 2026-11-09 at 14.25.20.jpeg
    f1 = os.path.join(orig_t, 'WhatsApp Image 2026-11-09 at 14.25.20.jpeg')
    if os.path.exists(f1):
        im1 = Image.open(f1).convert('RGB')
        
        # Save floating action buttons with antialiased circular masks
        cam_crop = im1.crop((632 - 35, 1182 - 35, 632 + 35, 1182 + 35)).convert('RGBA')
        mask_cam = Image.new('L', (70, 70), 0)
        ImageDraw.Draw(mask_cam).ellipse([0, 0, 70, 70], fill=255)
        cam_crop.putalpha(mask_cam)

        comp_crop = im1.crop((631 - 46, 1299 - 46, 631 + 46, 1299 + 46)).convert('RGBA')
        mask_comp = Image.new('L', (92, 92), 0)
        ImageDraw.Draw(mask_comp).ellipse([0, 0, 92, 92], fill=255)
        comp_crop.putalpha(mask_comp)

        # Save bottom tab bar
        tab_bar = im1.crop((0, 1370, 720, 1500))

        # Blur chat list region
        chat_box = (0, 350, 720, 1530)
        blurred = im1.crop(chat_box).filter(ImageFilter.GaussianBlur(radius=25))
        im1.paste(blurred, chat_box)

        # Restore crisp buttons and tab bar
        im1.paste(cam_crop, (632 - 35, 1182 - 35), cam_crop)
        im1.paste(comp_crop, (631 - 46, 1299 - 46), comp_crop)
        im1.paste(tab_bar, (0, 1370))

        # Neutralize profile tab avatar
        im1.paste(tab_av_inactive, (618 - 22, 1417 - 22), tab_av_inactive)

        # Clean Android navigation bar area below tab bar
        d1 = ImageDraw.Draw(im1)
        d1.rectangle([0, 1505, 720, 1600], fill=(255, 255, 255))
        nav_gray = (130, 130, 130)
        d1.line([(212, 1545), (212, 1565)], fill=nav_gray, width=3)
        d1.line([(220, 1545), (220, 1565)], fill=nav_gray, width=3)
        d1.line([(228, 1545), (228, 1565)], fill=nav_gray, width=3)
        d1.rounded_rectangle([348, 1545, 372, 1565], radius=6, outline=nav_gray, width=3)
        d1.line([(495, 1545), (485, 1555)], fill=nav_gray, width=3)
        d1.line([(485, 1555), (495, 1565)], fill=nav_gray, width=3)

        out1 = os.path.join(dest_t, 'WhatsApp Image 2026-11-09 at 14.25.20.jpeg')
        im1.save(out1, 'JPEG', quality=95)
        print("Censored:", out1)

    # 2. Telegram Nova Mensagem: WhatsApp Image 2026-11-09 at 14.25.20 (1).jpeg (Clean)
    f2 = os.path.join(orig_t, 'WhatsApp Image 2026-11-09 at 14.25.20 (1).jpeg')
    if os.path.exists(f2):
        out2 = os.path.join(dest_t, 'WhatsApp Image 2026-11-09 at 14.25.20 (1).jpeg')
        shutil.copyfile(f2, out2)
        print("Copied clean:", out2)

    # 3. Telegram Novo Contato: WhatsApp Image 2026-11-09 at 14.25.20 (2).jpeg (Clean)
    f3 = os.path.join(orig_t, 'WhatsApp Image 2026-11-09 at 14.25.20 (2).jpeg')
    if os.path.exists(f3):
        out3 = os.path.join(dest_t, 'WhatsApp Image 2026-11-09 at 14.25.20 (2).jpeg')
        shutil.copyfile(f3, out3)
        print("Copied clean:", out3)

    # 4. Telegram Contatos: WhatsApp Image 2026-11-09 at 14.25.20 (3).jpeg
    f4 = os.path.join(orig_t, 'WhatsApp Image 2026-11-09 at 14.25.20 (3).jpeg')
    if os.path.exists(f4):
        im4 = Image.open(f4).convert('RGB')
        im4.paste(tab_av_inactive, (618 - 22, 1417 - 22), tab_av_inactive)
        out4 = os.path.join(dest_t, 'WhatsApp Image 2026-11-09 at 14.25.20 (3).jpeg')
        im4.save(out4, 'JPEG', quality=95)
        print("Censored:", out4)

    # 5. Telegram Configuracoes main: WhatsApp Image 2026-11-09 at 14.25.21.jpeg
    f5 = os.path.join(orig_t, 'WhatsApp Image 2026-11-09 at 14.25.21.jpeg')
    if os.path.exists(f5):
        im5 = Image.open(f5).convert('RGB')
        im5.paste(av_big, (360 - 96, 224 - 96), av_big)
        d5 = ImageDraw.Draw(im5)
        draw_camera_badge(d5, 426, 289, 29)

        d5.rectangle([100, 335, 620, 450], fill=(244, 245, 247))
        d5.text((360, 370), 'Nome do Usuário', font=font_name, fill=(33, 33, 33), anchor='mm')
        d5.text((360, 415), '+55 (11) 9••••-••••', font=font_phone, fill=(130, 136, 144), anchor='mm')

        d5.rectangle([50, 495, 670, 580], fill=(255, 255, 255))
        d5.text((360, 523), '+55 (11) 9••••-•••• ainda é o seu', font=font_banner, fill=(33, 33, 33), anchor='mm')
        d5.text((360, 558), 'número?', font=font_banner, fill=(33, 33, 33), anchor='mm')

        im5.paste(tab_av_inactive, (618 - 22, 1417 - 22), tab_av_inactive)
        out5 = os.path.join(dest_t, 'WhatsApp Image 2026-11-09 at 14.25.21.jpeg')
        im5.save(out5, 'JPEG', quality=95)
        print("Censored:", out5)

    # 6. Telegram Configuracoes middle: WhatsApp Image 2026-11-09 at 14.25.21 (1).jpeg
    f6 = os.path.join(orig_t, 'WhatsApp Image 2026-11-09 at 14.25.21 (1).jpeg')
    if os.path.exists(f6):
        im6 = Image.open(f6).convert('RGB')
        btn_dots = im6.crop((15, 70, 115, 160))
        d6 = ImageDraw.Draw(im6)
        d6.rectangle([90, 75, 535, 145], fill=(244, 245, 247))
        im6.paste(btn_dots, (15, 70))
        d6.text((360, 114), 'Configurações', font=font_header_tg, fill=(33, 33, 33), anchor='mm')
        im6.paste(tab_av_inactive, (618 - 22, 1417 - 22), tab_av_inactive)
        out6 = os.path.join(dest_t, 'WhatsApp Image 2026-11-09 at 14.25.21 (1).jpeg')
        im6.save(out6, 'JPEG', quality=95)
        print("Censored:", out6)

    # 7. Telegram Configuracoes bottom: WhatsApp Image 2026-11-09 at 14.25.21 (2).jpeg
    f7 = os.path.join(orig_t, 'WhatsApp Image 2026-11-09 at 14.25.21 (2).jpeg')
    if os.path.exists(f7):
        im7 = Image.open(f7).convert('RGB')
        btn_dots = im7.crop((15, 70, 115, 160))
        d7 = ImageDraw.Draw(im7)
        d7.rectangle([90, 75, 535, 145], fill=(244, 245, 247))
        im7.paste(btn_dots, (15, 70))
        d7.text((360, 114), 'Configurações', font=font_header_tg, fill=(33, 33, 33), anchor='mm')
        im7.paste(tab_av_inactive, (618 - 22, 1417 - 22), tab_av_inactive)
        out7 = os.path.join(dest_t, 'WhatsApp Image 2026-11-09 at 14.25.21 (2).jpeg')
        im7.save(out7, 'JPEG', quality=95)
        print("Censored:", out7)

    # 8. Telegram Perfil: WhatsApp Image 2026-11-09 at 14.25.21 (3).jpeg
    f8 = os.path.join(orig_t, 'WhatsApp Image 2026-11-09 at 14.25.21 (3).jpeg')
    if os.path.exists(f8):
        im8 = Image.open(f8).convert('RGB')
        im8.paste(av_big, (360 - 96, 224 - 96), av_big)
        d8 = ImageDraw.Draw(im8)

        d8.rectangle([100, 345, 620, 460], fill=(244, 245, 247))
        d8.text((360, 380), 'Nome do Usuário', font=font_name, fill=(33, 33, 33), anchor='mm')
        d8.text((360, 425), 'online', font=font_phone, fill=(130, 136, 144), anchor='mm')

        d8.rectangle([50, 650, 500, 700], fill=(255, 255, 255))
        d8.text((62, 675), '+55 (11) 9••••-••••', font=font_card_num, fill=(33, 33, 33), anchor='lm')

        im8.paste(tab_av_active, (618 - 22, 1417 - 22), tab_av_active)
        out8 = os.path.join(dest_t, 'WhatsApp Image 2026-11-09 at 14.25.21 (3).jpeg')
        im8.save(out8, 'JPEG', quality=95)
        print("Censored:", out8)

    # ==========================================
    # WHATSAPP
    # ==========================================

    # 9. WhatsApp 3-dots: WhatsApp Image 2026-11-09 at 14.25.21 (4).jpeg
    fw1 = os.path.join(orig_w, 'WhatsApp Image 2026-11-09 at 14.25.21 (4).jpeg')
    if os.path.exists(fw1):
        imw1 = Image.open(fw1).convert('RGB')
        menu_box = (285, 155, 715, 985)
        menu_crop = imw1.crop(menu_box)

        chat_box = (0, 200, 720, 1430)
        blurred = imw1.crop(chat_box).filter(ImageFilter.GaussianBlur(radius=35))
        imw1.paste(blurred, chat_box)
        imw1.paste(menu_crop, menu_box)

        outw1 = os.path.join(dest_w, 'WhatsApp Image 2026-11-09 at 14.25.21 (4).jpeg')
        imw1.save(outw1, 'JPEG', quality=95)
        print("Censored:", outw1)

    # 10. WhatsApp Settings: (5) and (22)
    for fname in ['WhatsApp Image 2026-11-09 at 14.25.21 (5).jpeg', 'WhatsApp Image 2026-11-09 at 14.25.22.jpeg']:
        fwa = os.path.join(orig_w, fname)
        if os.path.exists(fwa):
            imwa = Image.open(fwa).convert('RGB')
            dwa = ImageDraw.Draw(imwa)
            dwa.rectangle([95, 80, 440, 145], fill=(11, 16, 20))
            dwa.text((115, 112), 'Configurações', font=font_header_wa, fill=(233, 237, 239), anchor='lm')
            outwa = os.path.join(dest_w, fname)
            imwa.save(outwa, 'JPEG', quality=95)
            print("Censored:", outwa)

    # 11. WhatsApp Menu Crop: WhatsApp Image 2026-11-09 at 14.37.40.jpeg (Clean)
    fw4 = os.path.join(orig_w, 'WhatsApp Image 2026-11-09 at 14.37.40.jpeg')
    if os.path.exists(fw4):
        outw4 = os.path.join(dest_w, 'WhatsApp Image 2026-11-09 at 14.37.40.jpeg')
        shutil.copyfile(fw4, outw4)
        print("Copied clean:", outw4)

if __name__ == '__main__':
    run_censoring()
    print("All images processed successfully!")
