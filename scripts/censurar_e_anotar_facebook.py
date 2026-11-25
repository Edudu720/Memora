import os
import shutil
from PIL import Image, ImageDraw, ImageFilter, ImageFont

def make_facebook_avatar(radius, bg_color=(24, 119, 242), fg_color=(255, 255, 255), border_radius=None, border_color=(255, 255, 255)):
    """Generates an antialiased Facebook-style avatar with circular silhouette and optional outer border."""
    scale = 4
    effective_r = border_radius if border_radius else radius
    size = effective_r * 2 * scale
    cx = size // 2
    cy = size // 2
    r_scaled = radius * scale
    b_scaled = effective_r * scale

    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    if border_radius and border_radius > radius:
        draw.ellipse([cx - b_scaled, cy - b_scaled, cx + b_scaled, cy + b_scaled], fill=border_color + (255,))

    draw.ellipse([cx - r_scaled, cy - r_scaled, cx + r_scaled, cy + r_scaled], fill=bg_color + (255,))

    # Head
    hr = int(r_scaled * 0.36)
    hcy = int(r_scaled * 0.70)
    draw.ellipse([cx - hr, cy - (r_scaled - hcy) - hr, cx + hr, cy - (r_scaled - hcy) + hr], fill=fg_color + (255,))

    # Body
    body_img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    bdraw = ImageDraw.Draw(body_img)
    brx = int(r_scaled * 0.70)
    bry = int(r_scaled * 0.62)
    bcy = int(cy + r_scaled * 0.55)
    bdraw.ellipse([cx - brx, bcy - bry, cx + brx, bcy + bry], fill=fg_color + (255,))

    img = Image.alpha_composite(img, body_img)

    # Circular mask
    mask = Image.new('L', (size, size), 0)
    mdraw = ImageDraw.Draw(mask)
    mask_r = b_scaled if border_radius else r_scaled
    mdraw.ellipse([cx - mask_r, cy - mask_r, cx + mask_r, cy + mask_r], fill=255)

    final_img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    final_img.paste(img, (0, 0), mask)
    out_size = effective_r * 2
    return final_img.resize((out_size, out_size), Image.Resampling.LANCZOS)

def draw_badge(draw, cx, cy, num, font, bg_color=(234, 67, 53), fg_color=(255, 255, 255), r=22):
    """Draws a numbered circular badge for senior-friendly annotations."""
    # Outer white ring
    draw.ellipse([cx - r - 2, cy - r - 2, cx + r + 2, cy + r + 2], fill=(255, 255, 255))
    # Filled badge
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=bg_color)
    text = str(num)
    bbox = font.getbbox(text)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    draw.text((cx - tw // 2, cy - th // 2 - 2), text, font=font, fill=fg_color)

def draw_highlight_box(draw, box, color=(234, 67, 53), width=4, radius=12):
    """Draws a rounded rectangle highlight outline."""
    draw.rounded_rectangle(box, radius=radius, outline=color, width=width)

def process_facebook():
    orig_dir = 'apps/.originais/FACE'
    dest_dir = 'apps/FACE'
    assets_dir = 'app/assets/guias/facebook'
    artifact_dir = r'C:\Users\Edu\.gemini\antigravity\brain\47755337-5c86-4f71-b7d2-44bc7a93f8d7'

    os.makedirs(dest_dir, exist_ok=True)
    os.makedirs(assets_dir, exist_ok=True)
    os.makedirs(artifact_dir, exist_ok=True)

    # Fonts
    font_badge = ImageFont.truetype('C:/Windows/Fonts/segoeuib.ttf', 26)
    font_name_menu = ImageFont.truetype('C:/Windows/Fonts/segoeuib.ttf', 26)
    font_name_profile = ImageFont.truetype('C:/Windows/Fonts/segoeuib.ttf', 40)
    font_friend_name = ImageFont.truetype('C:/Windows/Fonts/segoeuib.ttf', 28)
    font_mutual = ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf', 22)
    font_dob = ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf', 26)
    font_notif = ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf', 24)
    font_notif_time = ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf', 20)

    # ----------------------------------------------------
    # 0. Feed Principal (WhatsApp Image 2026-11-10 at 14.33.34.jpeg)
    # ----------------------------------------------------
    p0 = os.path.join(orig_dir, 'WhatsApp Image 2026-11-10 at 14.33.34.jpeg')
    im0 = Image.open(p0).convert('RGB')

    # Anonymize avatar in "No que você está pensando?" at (60, 305), radius 40
    av40 = make_facebook_avatar(40)
    im0.paste(av40, (60 - 40, 305 - 40), av40)

    # Anonymize "Criar story" card (x: 8..216, y: 380..635)
    # Save the blue plus button at (110, 655), radius ~32
    plus_btn = im0.crop((110 - 35, 655 - 35, 110 + 35, 655 + 35))
    
    # Draw clean gradient card top with rounded corners
    story_top = Image.new('RGB', (208, 255), (230, 240, 255))
    sdraw = ImageDraw.Draw(story_top)
    # Soft vertical gradient
    for y in range(255):
        r_col = int(220 + 20 * (y / 255.0))
        g_col = int(235 + 15 * (y / 255.0))
        b_col = int(250 + 5 * (y / 255.0))
        sdraw.line([(0, y), (208, y)], fill=(r_col, g_col, b_col))
    # Place a clean neutral silhouette avatar in story card
    av_story = make_facebook_avatar(55, bg_color=(180, 205, 240), fg_color=(255, 255, 255))
    story_top.paste(av_story, (104 - 55, 120 - 55), av_story)

    # Top rounded mask for story card
    mask_story = Image.new('L', (208, 255), 255)
    mdraw = ImageDraw.Draw(mask_story)
    # top rounded corners
    # Card starts at (8, 380)
    im0.paste(story_top, (8, 380))
    # Restore plus button
    im0.paste(plus_btn, (110 - 35, 655 - 35))

    # Anonymize other stories (x: 220..720, y: 380..760) with blur
    stories_box = (220, 380, 720, 760)
    blurred_stories = im0.crop(stories_box).filter(ImageFilter.GaussianBlur(radius=22))
    im0.paste(blurred_stories, stories_box)

    # Anonymize feed post below (y: 780..1530) with blur
    feed_box = (0, 780, 720, 1530)
    blurred_feed = im0.crop(feed_box).filter(ImageFilter.GaussianBlur(radius=25))
    im0.paste(blurred_feed, feed_box)

    im0.save(os.path.join(dest_dir, 'WhatsApp Image 2026-11-10 at 14.33.34.jpeg'), quality=95)
    im0.save(os.path.join(assets_dir, '01_feed_principal.jpeg'), quality=95)

    # ----------------------------------------------------
    # 1. Menu Lateral (WhatsApp Image 2026-11-10 at 14.33.34 (1).jpeg)
    # ----------------------------------------------------
    p1 = os.path.join(orig_dir, 'WhatsApp Image 2026-11-10 at 14.33.34 (1).jpeg')
    im1 = Image.open(p1).convert('RGB')

    # Anonymize avatar at (88, 154), radius 40
    im1.paste(av40, (88 - 40, 154 - 40), av40)

    # Anonymize user display name -> "Nome do Usuário"
    d1 = ImageDraw.Draw(im1)
    d1.rectangle([150, 138, 430, 175], fill=(255, 255, 255))
    d1.text((155, 140), "Nome do Usuário", font=font_name_menu, fill=(5, 5, 5))

    im1.save(os.path.join(dest_dir, 'WhatsApp Image 2026-11-10 at 14.33.34 (1).jpeg'), quality=95)
    im1.save(os.path.join(assets_dir, '02_menu_atalhos.jpeg'), quality=95)

    # ----------------------------------------------------
    # 2. Amigos / Solicitações (WhatsApp Image 2026-11-10 at 14.33.34 (2).jpeg)
    # ----------------------------------------------------
    p2 = os.path.join(orig_dir, 'WhatsApp Image 2026-11-10 at 14.33.34 (2).jpeg')
    im2 = Image.open(p2).convert('RGB')
    d2 = ImageDraw.Draw(im2)

    av91 = make_facebook_avatar(91)

    # Request 1 (cy=529)
    im2.paste(av91, (116 - 91, 529 - 91), av91)
    d2.rectangle([220, 435, 560, 485], fill=(255, 255, 255))
    d2.text((225, 442), "Amigo Exemplo 1", font=font_friend_name, fill=(5, 5, 5))
    d2.rectangle([220, 485, 560, 525], fill=(255, 255, 255))
    d2.text((225, 490), "1 amigo em comum", font=font_mutual, fill=(101, 103, 107))

    # Request 2 (cy=744.5)
    im2.paste(av91, (116 - 91, int(744.5) - 91), av91)
    d2.rectangle([220, 650, 560, 700], fill=(255, 255, 255))
    d2.text((225, 657), "Amigo Exemplo 2", font=font_friend_name, fill=(5, 5, 5))
    d2.rectangle([220, 700, 560, 740], fill=(255, 255, 255))
    d2.text((225, 705), "3 amigos em comum", font=font_mutual, fill=(101, 103, 107))

    # Request 3 (cy=1001.5)
    im2.paste(av91, (116 - 91, int(1001.5) - 91), av91)
    d2.rectangle([220, 910, 560, 960], fill=(255, 255, 255))
    d2.text((225, 917), "Amigo Exemplo 3", font=font_friend_name, fill=(5, 5, 5))
    d2.rectangle([220, 960, 560, 1000], fill=(255, 255, 255))
    d2.text((225, 965), "2 amigos em comum", font=font_mutual, fill=(101, 103, 107))

    # Blur suggestions below y=1100
    sugg_box = (0, 1100, 720, 1530)
    blurred_sugg = im2.crop(sugg_box).filter(ImageFilter.GaussianBlur(radius=22))
    im2.paste(blurred_sugg, sugg_box)

    im2.save(os.path.join(dest_dir, 'WhatsApp Image 2026-11-10 at 14.33.34 (2).jpeg'), quality=95)
    im2.save(os.path.join(assets_dir, '03_amigos_solicitacoes.jpeg'), quality=95)

    # ----------------------------------------------------
    # 3. Marketplace (WhatsApp Image 2026-11-10 at 14.33.34 (3).jpeg)
    # ----------------------------------------------------
    p3 = os.path.join(orig_dir, 'WhatsApp Image 2026-11-10 at 14.33.34 (3).jpeg')
    im3 = Image.open(p3).convert('RGB')
    im3.save(os.path.join(dest_dir, 'WhatsApp Image 2026-11-10 at 14.33.34 (3).jpeg'), quality=95)
    im3.save(os.path.join(assets_dir, '04_marketplace.jpeg'), quality=95)

    # ----------------------------------------------------
    # 4. Vídeos / Reels (WhatsApp Image 2026-11-10 at 14.33.34 (4).jpeg)
    # ----------------------------------------------------
    p4 = os.path.join(orig_dir, 'WhatsApp Image 2026-11-10 at 14.33.34 (4).jpeg')
    im4 = Image.open(p4).convert('RGB')
    im4.save(os.path.join(dest_dir, 'WhatsApp Image 2026-11-10 at 14.33.34 (4).jpeg'), quality=95)
    im4.save(os.path.join(assets_dir, '05_videos_reels.jpeg'), quality=95)

    # ----------------------------------------------------
    # 5. Notificações (WhatsApp Image 2026-11-10 at 14.33.34 (5).jpeg)
    # ----------------------------------------------------
    p5 = os.path.join(orig_dir, 'WhatsApp Image 2026-11-10 at 14.33.34 (5).jpeg')
    im5 = Image.open(p5).convert('RGB')
    d5 = ImageDraw.Draw(im5)

    # Anonymize personal comment item at y: 340..460
    # Light blue background: (230, 244, 255)
    bg_notif = (230, 244, 255)
    d5.rectangle([120, 345, 710, 455], fill=bg_notif)
    d5.text((125, 360), "Você tem uma nova lembrança para ver.", font=font_notif, fill=(5, 5, 5))
    d5.text((125, 395), "Relembre publicações de anos anteriores.", font=font_notif, fill=(101, 103, 107))
    d5.text((125, 428), "há 2 horas", font=font_notif_time, fill=(24, 119, 242))

    im5.save(os.path.join(dest_dir, 'WhatsApp Image 2026-11-10 at 14.33.34 (5).jpeg'), quality=95)
    im5.save(os.path.join(assets_dir, '06_notificacoes.jpeg'), quality=95)

    # ----------------------------------------------------
    # 6. Perfil do Usuário (WhatsApp Image 2026-11-10 at 14.33.34 (6).jpeg)
    # ----------------------------------------------------
    p6 = os.path.join(orig_dir, 'WhatsApp Image 2026-11-10 at 14.33.34 (6).jpeg')
    im6 = Image.open(p6).convert('RGB')

    # Save camera badge at (465, 640)
    cam_badge6 = im6.crop((465 - 38, 640 - 38, 465 + 38, 640 + 38)).convert('RGBA')
    mask_cam6 = Image.new('L', (76, 76), 0)
    ImageDraw.Draw(mask_cam6).ellipse([0, 0, 76, 76], fill=255)
    cam_badge6.putalpha(mask_cam6)

    # Large avatar with white border
    av150 = make_facebook_avatar(150, border_radius=156)
    im6.paste(av150, (360 - 156, 550 - 156), av150)
    im6.paste(cam_badge6, (465 - 38, 640 - 38), cam_badge6)

    # Replace user display name
    d6 = ImageDraw.Draw(im6)
    d6.rectangle([100, 720, 620, 805], fill=(255, 255, 255))
    name_txt = "Nome do Usuário"
    bbox_name = font_name_profile.getbbox(name_txt)
    nw = bbox_name[2] - bbox_name[0]
    d6.text((360 - nw // 2, 735), name_txt, font=font_name_profile, fill=(5, 5, 5))

    # Blur suggestions below y=880
    sugg6_box = (0, 880, 720, 1600)
    blurred_sugg6 = im6.crop(sugg6_box).filter(ImageFilter.GaussianBlur(radius=22))
    im6.paste(blurred_sugg6, sugg6_box)

    im6.save(os.path.join(dest_dir, 'WhatsApp Image 2026-11-10 at 14.33.34 (6).jpeg'), quality=95)
    im6.save(os.path.join(assets_dir, '07_perfil_usuario.jpeg'), quality=95)

    # ----------------------------------------------------
    # 7. Configurações (WhatsApp Image 2026-11-10 at 14.33.34 (7).jpeg)
    # ----------------------------------------------------
    p7 = os.path.join(orig_dir, 'WhatsApp Image 2026-11-10 at 14.33.34 (7).jpeg')
    im7 = Image.open(p7).convert('RGB')
    im7.save(os.path.join(dest_dir, 'WhatsApp Image 2026-11-10 at 14.33.34 (7).jpeg'), quality=95)
    im7.save(os.path.join(assets_dir, '08_configuracoes.jpeg'), quality=95)

    # ----------------------------------------------------
    # 8. Editar Perfil (WhatsApp Image 2026-11-10 at 14.33.34 (8).jpeg)
    # ----------------------------------------------------
    p8 = os.path.join(orig_dir, 'WhatsApp Image 2026-11-10 at 14.33.34 (8).jpeg')
    im8 = Image.open(p8).convert('RGB')

    # Save camera badge at (479, 405)
    cam_badge8 = im8.crop((479 - 38, 405 - 38, 479 + 38, 405 + 38)).convert('RGBA')
    mask_cam8 = Image.new('L', (76, 76), 0)
    ImageDraw.Draw(mask_cam8).ellipse([0, 0, 76, 76], fill=255)
    cam_badge8.putalpha(mask_cam8)

    # Paste large avatar
    im8.paste(av150, (360 - 156, 320 - 156), av150)
    im8.paste(cam_badge8, (479 - 38, 405 - 38), cam_badge8)

    # Censor birth date at (130, 1050, 450, 1085)
    d8 = ImageDraw.Draw(im8)
    d8.rectangle([130, 1050, 450, 1085], fill=(255, 255, 255))
    d8.text((130, 1054), "•• de ••••••• de ••••", font=font_dob, fill=(101, 103, 107))

    im8.save(os.path.join(dest_dir, 'WhatsApp Image 2026-11-10 at 14.33.34 (8).jpeg'), quality=95)
    im8.save(os.path.join(assets_dir, '09_editar_perfil.jpeg'), quality=95)

    # ----------------------------------------------------
    # 9. Editar Perfil Rolagem (WhatsApp Image 2026-11-10 at 14.33.34 (9).jpeg)
    # ----------------------------------------------------
    p9 = os.path.join(orig_dir, 'WhatsApp Image 2026-11-10 at 14.33.34 (9).jpeg')
    im9 = Image.open(p9).convert('RGB')
    im9.save(os.path.join(dest_dir, 'WhatsApp Image 2026-11-10 at 14.33.34 (9).jpeg'), quality=95)
    im9.save(os.path.join(assets_dir, '10_editar_perfil_rolagem.jpeg'), quality=95)

    print("Successfully anonymized all 10 Facebook images!")

    # ----------------------------------------------------
    # GENERATE ANNOTATED SCREENS FOR SENIOR USER GUIDE
    # ----------------------------------------------------
    # Screen 1: Feed Annotated
    im0_annot = im0.copy()
    da0 = ImageDraw.Draw(im0_annot)
    # 1: Barra superior de busca e atalhos
    draw_highlight_box(da0, [10, 80, 710, 150], color=(24, 119, 242), width=4)
    draw_badge(da0, 35, 80, 1, font_badge, bg_color=(24, 119, 242))

    # 2: Abas de navegação principais (Feed, Vídeos, Amigos, Marketplace, Notificações, Menu)
    draw_highlight_box(da0, [10, 152, 710, 225], color=(234, 67, 53), width=4)
    draw_badge(da0, 35, 155, 2, font_badge, bg_color=(234, 67, 53))

    # 3: Caixa de publicação ("No que você está pensando?")
    draw_highlight_box(da0, [10, 240, 710, 360], color=(52, 168, 83), width=4)
    draw_badge(da0, 35, 240, 3, font_badge, bg_color=(52, 168, 83))

    # 4: Seção de Stories e botão "Criar story"
    draw_highlight_box(da0, [6, 370, 714, 765], color=(251, 188, 5), width=4)
    draw_badge(da0, 35, 375, 4, font_badge, bg_color=(230, 140, 0))

    # 5: Feed de Notícias e Publicações de amigos
    draw_highlight_box(da0, [10, 775, 710, 1530], color=(142, 68, 173), width=4)
    draw_badge(da0, 35, 785, 5, font_badge, bg_color=(142, 68, 173))

    im0_annot.save(os.path.join(dest_dir, 'facebook_01_feed_anotado.jpeg'), quality=95)
    im0_annot.save(os.path.join(artifact_dir, 'facebook_feed_anotado.png'))

    # Screen 2: Amigos / Solicitações Annotated
    im2_annot = im2.copy()
    da2 = ImageDraw.Draw(im2_annot)
    # 1: Abas de filtro ("Sugestões" e "Seus amigos")
    draw_highlight_box(da2, [15, 140, 450, 215], color=(24, 119, 242), width=4)
    draw_badge(da2, 35, 140, 1, font_badge, bg_color=(24, 119, 242))

    # 2: Foto e nome de quem enviou o pedido
    draw_highlight_box(da2, [15, 420, 560, 525], color=(52, 168, 83), width=4)
    draw_badge(da2, 35, 420, 2, font_badge, bg_color=(52, 168, 83))

    # 3: Botão azul "Confirmar"
    draw_highlight_box(da2, [215, 530, 455, 600], color=(24, 119, 242), width=4)
    draw_badge(da2, 235, 530, 3, font_badge, bg_color=(24, 119, 242))

    # 4: Botão cinza "Excluir"
    draw_highlight_box(da2, [470, 530, 705, 600], color=(234, 67, 53), width=4)
    draw_badge(da2, 490, 530, 4, font_badge, bg_color=(234, 67, 53))

    im2_annot.save(os.path.join(dest_dir, 'facebook_03_amigos_anotado.jpeg'), quality=95)
    im2_annot.save(os.path.join(artifact_dir, 'facebook_amigos_anotado.png'))

    # Screen 6: Perfil Annotated
    im6_annot = im6.copy()
    da6 = ImageDraw.Draw(im6_annot)
    # 1: Foto de Capa
    draw_highlight_box(da6, [10, 130, 710, 460], color=(24, 119, 242), width=4)
    draw_badge(da6, 35, 135, 1, font_badge, bg_color=(24, 119, 242))

    # 2: Foto de Perfil com botão da câmera
    draw_highlight_box(da6, [195, 385, 525, 715], color=(52, 168, 83), width=4)
    draw_badge(da6, 215, 390, 2, font_badge, bg_color=(52, 168, 83))

    # 3: Nome do usuário
    draw_highlight_box(da6, [120, 725, 600, 800], color=(234, 67, 53), width=4)
    draw_badge(da6, 140, 725, 3, font_badge, bg_color=(234, 67, 53))

    # 4: Botões principais ("Adicionar ao story" e "Editar perfil")
    draw_highlight_box(da6, [15, 805, 705, 875], color=(251, 188, 5), width=4)
    draw_badge(da6, 35, 810, 4, font_badge, bg_color=(230, 140, 0))

    im6_annot.save(os.path.join(dest_dir, 'facebook_07_perfil_anotado.jpeg'), quality=95)
    im6_annot.save(os.path.join(artifact_dir, 'facebook_perfil_anotado.png'))

    # ----------------------------------------------------
    # GENERATE DETAILED CROPS FOR GUIDE CAROUSELS & EXPLANATIONS
    # ----------------------------------------------------
    # Crop 1: Top Nav (Feed)
    c1 = im0.crop((0, 75, 720, 230))
    c1.save(os.path.join(artifact_dir, 'crop_fb_1_navegacao.png'))

    # Crop 2: Publicar pensamento (Feed)
    c2 = im0.crop((0, 235, 720, 365))
    c2.save(os.path.join(artifact_dir, 'crop_fb_2_publicar.png'))

    # Crop 3: Criar Story e Stories (Feed)
    c3 = im0.crop((0, 370, 720, 770))
    c3.save(os.path.join(artifact_dir, 'crop_fb_3_stories.png'))

    # Crop 4: Menu Atalhos Rápidos (Menu)
    c4 = im1.crop((0, 80, 720, 520))
    c4.save(os.path.join(artifact_dir, 'crop_fb_4_menu.png'))

    # Crop 5: Solicitação de Amizade (Amigos)
    c5 = im2.crop((0, 420, 720, 615))
    c5.save(os.path.join(artifact_dir, 'crop_fb_5_solicitacao.png'))

    # Crop 6: Marketplace Cabeçalho & Vitrine
    c6 = im3.crop((0, 80, 720, 520))
    c6.save(os.path.join(artifact_dir, 'crop_fb_6_marketplace.png'))

    # Crop 7: Notificações
    c7 = im5.crop((0, 80, 720, 470))
    c7.save(os.path.join(artifact_dir, 'crop_fb_7_notificacoes.png'))

    # Crop 8: Perfil Cabeçalho
    c8 = im6.crop((0, 120, 720, 880))
    c8.save(os.path.join(artifact_dir, 'crop_fb_8_perfil.png'))

    # Also copy clean facebook logo to artifact dir
    shutil.copyfile(
        os.path.join(dest_dir, 'facebook_logo_clean.png'),
        os.path.join(artifact_dir, 'facebook_logo.png')
    )

    print("All annotations and crops successfully saved!")

if __name__ == '__main__':
    process_facebook()
