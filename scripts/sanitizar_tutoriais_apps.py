"""
Gera imagens de tutoriais sanitizadas e padronizadas para os aplicativos
CLT (Carteira de Trabalho Digital), CNH Digital, Poupatempo, Google Fotos e
YouTube a partir dos originais em ``apps/.originais/<App>/``.

- Remove barras de sistema do Android (status bar superior e navegação 3 botões inferior).
- Substitui dados pessoais, imagens sensíveis e identificadores por conteúdo genérico;
  no YouTube, substitui vídeos, enquetes, Shorts e canais por temas adequados ao Memora.
- Salva os arquivos ordenados em ``apps/<App>/``.
"""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
ORIG_DIR = ROOT / "apps" / ".originais"
APPS_DIR = ROOT / "apps"

FONT_REG = "C:/Windows/Fonts/segoeui.ttf"
FONT_BOLD = "C:/Windows/Fonts/segoeuib.ttf"
FONT_ITALIC = "C:/Windows/Fonts/segoeuii.ttf"


def load_font(size: int, bold: bool = False, italic: bool = False):
    path = FONT_BOLD if bold else (FONT_ITALIC if italic else FONT_REG)
    try:
        return ImageFont.truetype(path, size)
    except OSError:
        return ImageFont.load_default()


def make_avatar(size: int, bg_color=(40, 100, 200), fg_color=(255, 255, 255)) -> Image.Image:
    """Gera avatar circular genérico com silhueta limpa em superamostragem 4x."""
    ss = size * 4
    av = Image.new("RGBA", (ss, ss), (0, 0, 0, 0))
    d = ImageDraw.Draw(av)
    d.ellipse((0, 0, ss - 1, ss - 1), fill=(*bg_color, 255))

    cx = ss // 2
    head_r = int(ss * 0.17)
    head_cy = int(ss * 0.36)
    d.ellipse(
        (cx - head_r, head_cy - head_r, cx + head_r, head_cy + head_r),
        fill=(*fg_color, 255),
    )

    body_w = int(ss * 0.56)
    body_h = int(ss * 0.44)
    body_top = int(ss * 0.58)
    body_layer = Image.new("RGBA", (ss, ss), (0, 0, 0, 0))
    bd = ImageDraw.Draw(body_layer)
    bd.ellipse(
        (cx - body_w // 2, body_top, cx + body_w // 2, body_top + body_h),
        fill=(*fg_color, 255),
    )

    mask = Image.new("L", (ss, ss), 0)
    md = ImageDraw.Draw(mask)
    md.ellipse((0, 0, ss - 1, ss - 1), fill=255)
    clipped = Image.new("RGBA", (ss, ss), (0, 0, 0, 0))
    clipped.paste(body_layer, (0, 0), mask)
    av = Image.alpha_composite(av, clipped)
    return av.resize((size, size), Image.Resampling.LANCZOS)


def make_initial_badge(size: int, letter: str, bg_color=(94, 94, 94), fg_color=(255, 255, 255)) -> Image.Image:
    """Gera botão circular com inicial genérica."""
    ss = size * 4
    im = Image.new("RGBA", (ss, ss), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.ellipse((0, 0, ss - 1, ss - 1), fill=(*bg_color, 255))
    font = load_font(int(ss * 0.48), bold=True)
    d.text((ss // 2, ss // 2), letter, font=font, fill=(*fg_color, 255), anchor="mm")
    return im.resize((size, size), Image.Resampling.LANCZOS)


def fill_scanline_gradient(im: Image.Image, box: tuple[int, int, int, int], sample_x_range: tuple[int, int]):
    """Preenche ``box`` copiando a cor média limpa por linha de pixels em ``sample_x_range``."""
    x0, y0, x1, y1 = box
    sx0, sx1 = sample_x_range
    px = im.load()
    d = ImageDraw.Draw(im)
    for y in range(y0, y1):
        samples = [px[x, y] for x in range(sx0, sx1, 4)]
        avg = tuple(sum(c[i] for c in samples) // len(samples) for i in range(3))
        d.line([(x0, y), (x1 - 1, y)], fill=avg)


def crop_system_bars(im: Image.Image, y_top: int, y_bottom: int) -> Image.Image:
    return im.crop((0, y_top, im.width, y_bottom))


def save_jpg(im: Image.Image, out_path: Path):
    out_path.parent.mkdir(parents=True, exist_ok=True)
    im.convert("RGB").save(out_path, "JPEG", quality=95)


# ==============================================================================
# CLT - Carteira de Trabalho Digital
# ==============================================================================

def process_clt():
    src = ORIG_DIR / "CLT"
    dst = APPS_DIR / "CLT"
    y_top, y_bot = 62, 1318

    simple_map = {
        "d628ec3e-9e3b-476e-a41a-45409dac266e.jpg": "01_entrar_gov_br.jpg",
        "a6010668-0cbd-43e5-9384-8137d8da8f4a.jpg": "02_autorizar_compartilhamento.jpg",
        "10c13b67-1076-4143-9581-ea9cb0c3b559.jpg": "05_outros_vinculos.jpg",
        "37495186-49f6-41be-b2f2-8fc8bb359742.jpg": "07_beneficios.jpg",
        "12f5d8ac-6e9e-404e-a65d-5483266b977e.jpg": "08_emprego.jpg",
        "b6866243-3a00-4178-a599-87b8f8c5cd06.jpg": "09_emprestimos.jpg",
        "ce89dbb7-cbd1-49ec-be1a-4239881c94be.jpg": "10_menu.jpg",
    }
    for orig_name, out_name in simple_map.items():
        im = Image.open(src / orig_name).convert("RGB")
        save_jpg(crop_system_bars(im, y_top, y_bot), dst / out_name)

    # 03 - Início: avatar, saudação e CPF mascarado
    im3 = Image.open(src / "3c00f8fc-ce7d-4b5d-be4d-cbbc9ac11d90.jpg").convert("RGB")
    fill_scanline_gradient(im3, (24, 102, 480, 210), (4, 20))
    av = make_avatar(92, bg_color=(19, 81, 180), fg_color=(255, 255, 255))
    im3.paste(av, (33, 109), av)
    d3 = ImageDraw.Draw(im3)
    d3.ellipse((32, 108, 125, 201), outline=(255, 255, 255), width=2)
    d3.text((146, 122), "Olá, Usuário", font=load_font(28, bold=True), fill=(255, 255, 255))
    d3.text((146, 165), "CPF: ***.***.***-**", font=load_font(21), fill=(213, 233, 222))
    save_jpg(crop_system_bars(im3, y_top, y_bot), dst / "03_carteira_inicio.jpg")

    # 04 - Contratos de trabalho
    im4 = Image.open(src / "fe271942-02a8-46d6-a6cc-b0ee6196f608.jpg").convert("RGB")
    d4 = ImageDraw.Draw(im4)
    # Timestamp apenas na linha de cima (preserva contagem de contratos abaixo)
    d4.rectangle((12, 216, 440, 241), fill=(248, 248, 248))
    d4.text((16, 220), "Atualizado em 01/01/2025 às 10:00", font=load_font(16), fill=(95, 95, 95))
    # Cartão 1
    d4.rectangle((26, 336, 606, 478), fill=(255, 255, 255))
    d4.text((33, 340), "AUXILIAR ADMINISTRATIVO", font=load_font(18), fill=(115, 115, 115))
    d4.text((598, 340), "R$ •.•••,••", font=load_font(18), fill=(70, 70, 70), anchor="ra")
    d4.text((33, 378), "EMPRESA EXEMPLO 1 LTDA", font=load_font(24, bold=True), fill=(0, 41, 151))
    d4.text((33, 436), "01/01/2024 - ABERTO", font=load_font(18), fill=(105, 105, 105))
    # Cartão 2
    d4.rectangle((26, 518, 606, 694), fill=(255, 255, 255))
    d4.text((33, 522), "AUXILIAR DE ATENDIMENTO", font=load_font(18), fill=(115, 115, 115))
    d4.text((598, 522), "R$ •.•••,••", font=load_font(18), fill=(70, 70, 70), anchor="ra")
    d4.text((33, 562), "EMPRESA EXEMPLO 2 S.A.", font=load_font(24, bold=True), fill=(0, 41, 151))
    d4.text((33, 646), "01/01/2021 - 31/12/2023", font=load_font(18), fill=(105, 105, 105))
    save_jpg(crop_system_bars(im4, y_top, y_bot), dst / "04_contratos_trabalho.jpg")

    # 06 - Enviar carteira digital (apenas empregadores sob TODOS OS CONTRATOS)
    im6 = Image.open(src / "6cccc12d-d6ee-4592-a9ff-ad6d32b63215.jpg").convert("RGB")
    d6 = ImageDraw.Draw(im6)
    d6.rectangle((66, 698, 580, 742), fill=(248, 248, 248))
    d6.text((70, 705), "EMPRESA EXEMPLO 1 LTDA", font=load_font(19), fill=(55, 55, 55))
    d6.rectangle((66, 756, 580, 825), fill=(248, 248, 248))
    d6.text((70, 764), "EMPRESA EXEMPLO 2 S.A.", font=load_font(19), fill=(55, 55, 55))
    save_jpg(crop_system_bars(im6, y_top, y_bot), dst / "06_enviar_carteira.jpg")


# ==============================================================================
# CNH Digital
# ==============================================================================

def _draw_cnh_card_upright(card: Image.Image):
    """Substitui todos os dados pessoais na frente da CNH Digital em posição horizontal."""
    d = ImageDraw.Draw(card)
    bg_paper = (234, 247, 238)
    fg_dark = (22, 28, 24)

    # Bloco completo da foto (cobre todo o retrato original sem invadir rótulos)
    photo_box = (378, 212, 620, 523)
    d.rectangle(photo_box, fill=(224, 232, 229), outline=(170, 185, 175), width=2)
    sil = make_avatar(192, bg_color=(188, 202, 212), fg_color=(120, 138, 152))
    card.paste(sil, (403, 271), sil)

    # Assinatura sintética abaixo da foto (dentro da moldura da assinatura)
    d.rectangle((380, 525, 620, 588), fill=bg_paper)
    pts = [
        (408, 560), (424, 540), (438, 564), (456, 544), (474, 558),
        (494, 544), (516, 556), (538, 540), (562, 554), (586, 548),
    ]
    d.line(pts, fill=(35, 42, 48), width=3, joint="curve")
    d.line([(404, 568), (594, 562)], fill=(60, 68, 72), width=2)

    # Linha 1 (y=189..209): 2 e 1 NOME E SOBRENOME | 1ª HABILITAÇÃO
    d.rectangle((385, 189, 908, 209), fill=bg_paper)
    d.text((390, 189), "NOME COMPLETO DO USUÁRIO", font=load_font(17, bold=True), fill=fg_dark)
    d.rectangle((924, 189, 1076, 209), fill=bg_paper)
    d.text((929, 189), "01/01/2010", font=load_font(17, bold=True), fill=fg_dark)

    # Linha 2 (y=233..258): Emissão e Validade
    d.rectangle((636, 232, 916, 258), fill=bg_paper)
    d.text((641, 236), "01/01/2025", font=load_font(17, bold=True), fill=fg_dark)
    d.text((766, 236), "01/01/2030", font=load_font(17, bold=True), fill=fg_dark)

    # Linha 3 (y=280..309): Data, Local e UF de Nascimento
    d.rectangle((636, 280, 1076, 309), fill=bg_paper)
    d.text((641, 284), "01/01/1965, SÃO PAULO, SP", font=load_font(16, bold=True), fill=fg_dark)

    # Linha 4 (y=332..358): Doc. Identidade / Órgão Emissor / UF
    d.rectangle((636, 332, 1076, 358), fill=bg_paper)
    d.text((641, 335), "00000000000 SSP SP", font=load_font(17, bold=True), fill=fg_dark)

    # Linha 5 (y=381..409): CPF e Nº Registro
    d.rectangle((636, 381, 1076, 409), fill=bg_paper)
    d.text((641, 385), "000.000.000-00", font=load_font(17, bold=True), fill=fg_dark)
    d.text((796, 385), "00000000000", font=load_font(17, bold=True), fill=(175, 30, 30))

    # Linha 6 (y=432..458): Nacionalidade e Categoria
    d.rectangle((636, 432, 1076, 458), fill=bg_paper)
    d.text((641, 436), "BRASILEIRA", font=load_font(17, bold=True), fill=fg_dark)
    d.text((955, 436), "AB", font=load_font(17, bold=True), fill=(175, 30, 30))

    # Linha 7 (y=484..586): Filiação
    d.rectangle((636, 484, 1076, 586), fill=bg_paper)
    d.text((641, 490), "NOME EXEMPLO FILIAÇÃO 1", font=load_font(17, bold=True), fill=fg_dark)
    d.text((641, 542), "NOME EXEMPLO FILIAÇÃO 2", font=load_font(17, bold=True), fill=fg_dark)


def process_cnh():
    src = ORIG_DIR / "CNH"
    dst = APPS_DIR / "CNH"
    y_top, y_bot = 62, 1316

    simple_map = {
        "91ed6bb2-6772-4f77-8b7a-b7b673fa712f.jpg": "06_credencial_estacionamento.jpg",
        "09c34951-338e-48bd-bcde-1feaaf5fdbe7.jpg": "08_infracoes_menu.jpg",
        "b8353bf7-e6e4-4e25-968e-86219939264e.jpg": "09_infracoes_lista.jpg",
    }
    for orig_name, out_name in simple_map.items():
        im = Image.open(src / orig_name).convert("RGB")
        save_jpg(crop_system_bars(im, y_top, y_bot), dst / out_name)

    # 01 - Início
    im1 = Image.open(src / "47b8020e-74c7-457d-8c75-b7179af4e314.jpg").convert("RGB")
    d1 = ImageDraw.Draw(im1)
    d1.rectangle((80, 95, 260, 142), fill=(51, 51, 51))
    d1.text((88, 103), "USUÁRIO", font=load_font(23, bold=True), fill=(255, 255, 255))
    d1.rectangle((550, 82, 622, 150), fill=(51, 51, 51))
    badge1 = make_initial_badge(56, "U", bg_color=(94, 94, 94))
    im1.paste(badge1, (558, 88), badge1)
    save_jpg(crop_system_bars(im1, y_top, y_bot), dst / "01_inicio.jpg")

    # 02 - Menu lateral
    im2 = Image.open(src / "8c433fb2-b70e-44b0-b2df-4acf0886ff29.jpg").convert("RGB")
    d2 = ImageDraw.Draw(im2)
    d2.rectangle((18, 92, 110, 174), fill=(27, 27, 27))
    badge2 = make_initial_badge(70, "U", bg_color=(94, 94, 94))
    im2.paste(badge2, (25, 96), badge2)
    d2.rectangle((36, 178, 430, 242), fill=(27, 27, 27))
    d2.text((40, 181), "NOME DO USUÁRIO", font=load_font(22, bold=True), fill=(255, 255, 255))
    d2.text((40, 214), "•••.•••.•••-••", font=load_font(18), fill=(225, 225, 225))
    # Substitui também o botão "E" escurecido ao fundo à direita
    d2.rectangle((552, 84, 620, 150), fill=(20, 20, 20))
    badge_dim = make_initial_badge(56, "U", bg_color=(36, 36, 36), fg_color=(120, 120, 120))
    im2.paste(badge_dim, (558, 88), badge_dim)
    d2.ellipse((558, 88, 613, 143), outline=(90, 90, 90), width=2)
    save_jpg(crop_system_bars(im2, y_top, y_bot), dst / "02_menu_lateral.jpg")

    # 03 - Resumo do Condutor
    im3 = Image.open(src / "aaee9137-4256-42ac-8237-c1e690f5d420.jpg").convert("RGB")
    d3 = ImageDraw.Draw(im3)
    d3.rectangle((42, 302, 310, 334), fill=(51, 51, 51))
    d3.text((46, 304), "N*** D* U******", font=load_font(19), fill=(255, 255, 255))
    d3.rectangle((42, 368, 220, 398), fill=(51, 51, 51))
    d3.text((46, 370), "***.***.***-**", font=load_font(19), fill=(255, 255, 255))
    d3.rectangle((42, 496, 490, 526), fill=(51, 51, 51))
    d3.text((46, 498), "01/01/2030", font=load_font(19), fill=(255, 255, 255))
    d3.text((322, 498), "01/01/2025", font=load_font(19), fill=(255, 255, 255))
    save_jpg(crop_system_bars(im3, y_top, y_bot), dst / "03_condutor_resumo.jpg")

    # 04 - Habilitação Digital (documento rotacionado 90 graus)
    im4 = Image.open(src / "f29e3353-3dd2-4ff7-b309-247b4f92b103.jpg").convert("RGB")
    d4 = ImageDraw.Draw(im4)
    # Timestamp mantendo 'Atualizado em:' alinhado ao cabeçalho (38, 38, 38) sem cortar 'HABILITAÇÃO'
    d4.rectangle((105, 120, 430, 149), fill=(38, 38, 38))
    d4.text((108, 122), "Atualizado em: 01/01/2025 - 10:00:00", font=load_font(16), fill=(205, 205, 205))
    # Número grande horizontal no topo-esquerdo do documento (y=298..336 antes de rotacionar)
    d4.rectangle((28, 296, 370, 336), fill=(234, 247, 238))
    d4.text((38, 298), "0000000000", font=load_font(30, bold=True), fill=(22, 28, 24))
    upright = im4.transpose(Image.Transpose.ROTATE_90)
    _draw_cnh_card_upright(upright)
    im4 = upright.transpose(Image.Transpose.ROTATE_270)
    save_jpg(crop_system_bars(im4, y_top, y_bot), dst / "04_habilitacao_digital.jpg")

    # 05 - Condutor Serviços
    im5 = Image.open(src / "2e173b65-6f83-4277-9a4b-9262618bb410.jpg").convert("RGB")
    d5 = ImageDraw.Draw(im5)
    d5.rectangle((42, 361, 490, 390), fill=(51, 51, 51))
    d5.text((46, 363), "01/01/2030", font=load_font(19), fill=(255, 255, 255))
    d5.text((322, 363), "01/01/2025", font=load_font(19), fill=(255, 255, 255))
    save_jpg(crop_system_bars(im5, y_top, y_bot), dst / "05_condutor_servicos.jpg")

    # 07 - Veículos (timestamp)
    im7 = Image.open(src / "6bf541d0-d9bd-47eb-9d51-c4534445d8b8.jpg").convert("RGB")
    d7 = ImageDraw.Draw(im7)
    d7.rectangle((105, 120, 430, 149), fill=(38, 38, 38))
    d7.text((108, 122), "Atualizado em: 01/01/2025 - 10:00:00", font=load_font(16), fill=(205, 205, 205))
    save_jpg(crop_system_bars(im7, y_top, y_bot), dst / "07_veiculos.jpg")

    # 10 - Cadastro positivo (timestamp abaixo de 'Autorizado em')
    im10 = Image.open(src / "d67e2640-abb6-46e2-aad0-17140ed4b951.jpg").convert("RGB")
    d10 = ImageDraw.Draw(im10)
    d10.rectangle((44, 304, 290, 336), fill=(51, 51, 51))
    d10.text((46, 306), "01/01/2025 - 10:00:00", font=load_font(19), fill=(235, 235, 235))
    save_jpg(crop_system_bars(im10, y_top, y_bot), dst / "10_cadastro_positivo.jpg")


# ==============================================================================
# Poupatempo
# ==============================================================================

def process_poupatempo():
    src = ORIG_DIR / "Poupatempo"
    dst = APPS_DIR / "Poupatempo"

    # Chrome + Splash (y_top=62, y_bot=1318)
    for orig_name, out_name in [
        ("fd865256-2ab4-4d95-b996-bf18a4916ae3.jpg", "01_boas_vindas.jpg"),
        ("035a78f8-9c40-4539-8b2a-5f33d98e603a.jpg", "02_login_cpf.jpg"),
    ]:
        im = Image.open(src / orig_name).convert("RGB")
        save_jpg(crop_system_bars(im, 62, 1318), dst / out_name)

    # 03 - Login senha gov.br: limpa rabisco vermelho sobre o CPF
    im3 = Image.open(src / "069d88ba-208a-4b36-8401-0a0bd9797453.jpg").convert("RGB")
    d3 = ImageDraw.Draw(im3)
    d3.rectangle((80, 375, 340, 430), fill=(255, 255, 255))
    d3.text((92, 388), "000.000.000-00", font=load_font(24), fill=(51, 51, 51))
    save_jpg(crop_system_bars(im3, 62, 1318), dst / "03_login_senha.jpg")

    # 04 - Início: substitui saudação com nome real
    im4 = Image.open(src / "f104caa8-be96-4805-8c3f-cc6a93def8de.jpg").convert("RGB")
    d4 = ImageDraw.Draw(im4)
    d4.rectangle((20, 108, 280, 150), fill=(255, 255, 255))
    d4.text((24, 110), "Olá, Usuário", font=load_font(28, bold=True), fill=(0, 0, 0))
    save_jpg(crop_system_bars(im4, 80, 1318), dst / "04_inicio.jpg")

    native_map = {
        "5f2702e6-7f53-40ac-b0d6-06829a5d44a1.jpg": "05_categorias.jpg",
        "870ece5d-8cf7-455f-8db5-74b8376a4933.jpg": "06_buscar.jpg",
        "7835dc65-d7c8-47df-b355-ba3b78354ee8.jpg": "07_agendamento.jpg",
        "03e5b2db-2e50-4a02-91d1-cbe93652b7cb.jpg": "08_agenda_mensal.jpg",
        "d1f99383-aeee-4a91-b396-39ee1999effb.jpg": "09_servicos_solicitados.jpg",
        "fb32e7a0-ef9b-4568-aba8-42ed410637bd.jpg": "10_carteira_digital.jpg",
    }
    for orig_name, out_name in native_map.items():
        im = Image.open(src / orig_name).convert("RGB")
        save_jpg(crop_system_bars(im, 80, 1318), dst / out_name)


# ---------------------------------------------------------------------------
# Helpers de ilustracao vetorial / anti-aliased para Google Fotos e YouTube
# ---------------------------------------------------------------------------

def _aa_draw(size: tuple[int, int], bg: tuple[int, int, int], scale: int = 2):
    w, h = size
    im = Image.new("RGB", (w * scale, h * scale), bg)
    return im, ImageDraw.Draw(im), scale


def _aa_finish(im: Image.Image, target_size: tuple[int, int]) -> Image.Image:
    return im.resize(target_size, Image.Resampling.LANCZOS)


def _vgradient(im: Image.Image, top_rgb: tuple[int, int, int], bot_rgb: tuple[int, int, int]):
    w, h = im.size
    px = im.load()
    for y in range(h):
        t = y / max(1, h - 1)
        c = tuple(int(top_rgb[i] + (bot_rgb[i] - top_rgb[i]) * t) for i in range(3))
        for x in range(w):
            px[x, y] = c


def _paste_rounded(dst: Image.Image, tile: Image.Image, pos: tuple[int, int], radius: int):
    if radius <= 0:
        dst.paste(tile, pos)
        return
    w, h = tile.size
    mask = Image.new("L", (w * 2, h * 2), 0)
    md = ImageDraw.Draw(mask)
    md.rounded_rectangle((0, 0, w * 2 - 1, h * 2 - 1), radius=radius * 2, fill=255)
    mask = mask.resize((w, h), Image.Resampling.LANCZOS)
    dst.paste(tile, pos, mask)


def _preserve_pill_mask(
    im_orig: Image.Image, box: tuple[int, int, int, int], radius: int
) -> tuple[Image.Image, Image.Image]:
    crop = im_orig.crop(box)
    w, h = crop.size
    mask = Image.new("L", (w * 2, h * 2), 0)
    md = ImageDraw.Draw(mask)
    md.rounded_rectangle((0, 0, w * 2 - 1, h * 2 - 1), radius=radius * 2, fill=255)
    return crop, mask.resize((w, h), Image.Resampling.LANCZOS)


def _draw_cloud(d: ImageDraw.ImageDraw, cx: int, cy: int, r: int, color=(255, 255, 255)):
    d.ellipse((cx - r * 2, cy - r, cx, cy + r), fill=color)
    d.ellipse((cx - r, cy - int(r * 1.4), cx + int(r * 1.1), cy + r), fill=color)
    d.ellipse((cx, cy - int(r * 0.9), cx + r * 2, cy + r), fill=color)


def _draw_person_silhouette(
    d: ImageDraw.ImageDraw,
    cx: int,
    cy: int,
    scale: float,
    shirt_color: tuple[int, int, int],
    skin_color: tuple[int, int, int] = (238, 200, 174),
    hair_color: tuple[int, int, int] = (180, 185, 195),
    glasses: bool = False,
):
    s = scale
    # Ombros
    d.ellipse(
        (int(cx - 46 * s), int(cy + 14 * s), int(cx + 46 * s), int(cy + 98 * s)),
        fill=shirt_color,
    )
    # Cabeca
    hr = int(22 * s)
    hy = int(cy - 14 * s)
    d.ellipse((cx - hr, hy - hr, cx + hr, hy + hr), fill=skin_color)
    # Cabelo suave no topo
    d.chord((cx - hr, hy - hr - int(2 * s), cx + hr, hy + int(4 * s)), 180, 360, fill=hair_color)
    if glasses:
        gw = max(4, int(7 * s))
        gy = hy + int(1 * s)
        lw = max(2, int(2.2 * s))
        d.ellipse((cx - int(14 * s), gy - gw // 2, cx - int(2 * s), gy + gw), outline=(45, 50, 60), width=lw)
        d.ellipse((cx + int(2 * s), gy - gw // 2, cx + int(14 * s), gy + gw), outline=(45, 50, 60), width=lw)
        d.line([(cx - int(2 * s), gy), (cx + int(2 * s), gy)], fill=(45, 50, 60), width=lw)


def draw_illustration(scene: str, w: int, h: int) -> Image.Image:
    sc = 2
    W, H = w * sc, h * sc
    im = Image.new("RGB", (W, H), (35, 55, 85))
    d = ImageDraw.Draw(im)

    if scene == "sunset_beach":
        _vgradient(im, (34, 48, 102), (240, 128, 78))
        # Sol
        sr = min(W, H) // 5
        sx, sy = int(W * 0.65), int(H * 0.45)
        d.ellipse((sx - sr, sy - sr, sx + sr, sy + sr), fill=(255, 224, 130))
        # Mar
        sea_y = int(H * 0.62)
        d.rectangle((0, sea_y, W, H), fill=(26, 78, 124))
        for k in range(5):
            ry = sea_y + int((H - sea_y) * (k + 0.5) / 6)
            rw = max(16, int(sr * (1.2 - k * 0.16)))
            d.rounded_rectangle((sx - rw, ry, sx + rw, ry + max(4, H // 60)), radius=4, fill=(255, 195, 115))
        # Areia
        d.polygon([(0, int(H * 0.85)), (W, int(H * 0.76)), (W, H), (0, H)], fill=(224, 186, 134))

    elif scene == "mountain_lake":
        _vgradient(im, (62, 132, 206), (174, 214, 244))
        _draw_cloud(d, int(W * 0.25), int(H * 0.22), max(10, W // 16))
        _draw_cloud(d, int(W * 0.72), int(H * 0.18), max(8, W // 20))
        d.polygon([(0, int(H * 0.64)), (int(W * 0.35), int(H * 0.30)), (int(W * 0.72), int(H * 0.64))], fill=(72, 96, 126))
        d.polygon([(int(W * 0.38), int(H * 0.64)), (int(W * 0.74), int(H * 0.26)), (W, int(H * 0.64))], fill=(54, 78, 106))
        d.polygon([(int(W * 0.35), int(H * 0.30)), (int(W * 0.27), int(H * 0.40)), (int(W * 0.43), int(H * 0.40))], fill=(242, 248, 255))
        d.polygon([(int(W * 0.74), int(H * 0.26)), (int(W * 0.65), int(H * 0.38)), (int(W * 0.83), int(H * 0.38))], fill=(242, 248, 255))
        d.rectangle((0, int(H * 0.64), W, H), fill=(44, 112, 162))
        d.rectangle((0, int(H * 0.82), W, H), fill=(46, 128, 72))

    elif scene == "garden_flowers":
        _vgradient(im, (118, 198, 238), (195, 234, 196))
        d.rectangle((0, int(H * 0.56), W, H), fill=(66, 148, 78))
        d.ellipse((-int(W * 0.2), int(H * 0.50), int(W * 0.7), int(H * 1.1)), fill=(82, 166, 90))
        petals = [
            (int(W * 0.26), int(H * 0.56), (255, 196, 48)),
            (int(W * 0.52), int(H * 0.48), (240, 96, 126)),
            (int(W * 0.76), int(H * 0.58), (255, 255, 255)),
        ]
        pr = max(12, min(W, H) // 8)
        for fx, fy, fc in petals:
            d.line([(fx, fy), (fx, H - 10)], fill=(42, 112, 52), width=max(4, pr // 4))
            for ox, oy in [(-pr, 0), (pr, 0), (0, -pr), (0, pr), (-int(pr * 0.7), -int(pr * 0.7)), (int(pr * 0.7), int(pr * 0.7)), (-int(pr * 0.7), int(pr * 0.7)), (int(pr * 0.7), -int(pr * 0.7))]:
                d.ellipse((fx + ox - pr // 2, fy + oy - pr // 2, fx + ox + pr // 2, fy + oy + pr // 2), fill=fc)
            d.ellipse((fx - pr // 2, fy - pr // 2, fx + pr // 2, fy + pr // 2), fill=(250, 170, 40))

    elif scene == "birthday_cake":
        _vgradient(im, (250, 214, 165), (238, 154, 134))
        cx, cy = W // 2, int(H * 0.62)
        bw, bh = int(W * 0.44), int(H * 0.22)
        d.rounded_rectangle((cx - bw // 2, cy, cx + bw // 2, cy + bh), radius=14, fill=(255, 245, 232))
        d.rounded_rectangle((cx - bw // 2, cy, cx + bw // 2, cy + bh // 3), radius=10, fill=(214, 78, 108))
        uw, uh = int(bw * 0.72), int(bh * 0.75)
        d.rounded_rectangle((cx - uw // 2, cy - uh, cx + uw // 2, cy + 4), radius=12, fill=(255, 248, 238))
        d.rounded_rectangle((cx - uw // 2, cy - uh, cx + uw // 2, cy - uh + uh // 3), radius=10, fill=(242, 184, 72))
        for k in (-1, 0, 1):
            kx = cx + k * (uw // 4)
            d.rectangle((kx - 4, cy - uh - uh // 2, kx + 4, cy - uh), fill=(86, 174, 224))
            d.ellipse((kx - 7, cy - uh - uh // 2 - 16, kx + 7, cy - uh - uh // 2 - 1), fill=(255, 200, 45))

    elif scene == "coffee_book":
        _vgradient(im, (82, 58, 44), (132, 92, 66))
        # Mesa
        d.rectangle((0, int(H * 0.66), W, H), fill=(166, 118, 82))
        # Livro aberto
        bx, by = int(W * 0.34), int(H * 0.60)
        lw, lh = int(W * 0.22), int(H * 0.16)
        d.polygon([(bx - lw, by - lh // 2), (bx, by - lh // 3), (bx, by + lh), (bx - lw, by + lh - 10)], fill=(246, 240, 224))
        d.polygon([(bx, by - lh // 3), (bx + lw, by - lh // 2), (bx + lw, by + lh - 10), (bx, by + lh)], fill=(235, 226, 206))
        # Xicara
        mx, my = int(W * 0.72), int(H * 0.56)
        mr = max(24, min(W, H) // 7)
        d.rounded_rectangle((mx - mr, my - mr // 2, mx + mr, my + mr), radius=18, fill=(245, 244, 240))
        d.arc((mx + mr - 12, my - mr // 4, mx + mr + mr // 2, my + mr // 2 + 10), -90, 90, fill=(245, 244, 240), width=max(5, mr // 5))
        d.ellipse((mx - mr + 6, my - mr // 2 - 8, mx + mr - 6, my - mr // 2 + 12), fill=(104, 62, 36))

    elif scene == "cat_portrait":
        _vgradient(im, (72, 148, 152), (126, 198, 194))
        cx, cy = W // 2, int(H * 0.54)
        r = max(28, min(W, H) // 4)
        d.polygon([(cx - r, cy - r // 3), (cx - r + r // 5, cy - int(r * 1.45)), (cx - r // 6, cy - r + 10)], fill=(242, 168, 92))
        d.polygon([(cx + r, cy - r // 3), (cx + r - r // 5, cy - int(r * 1.45)), (cx + r // 6, cy - r + 10)], fill=(242, 168, 92))
        d.ellipse((cx - r, cy - r, cx + r, cy + int(r * 0.9)), fill=(248, 184, 108))
        er = max(4, r // 8)
        d.ellipse((cx - r // 2, cy - r // 6 - er, cx - r // 2 + 2 * er, cy - r // 6 + er), fill=(40, 40, 42))
        d.ellipse((cx + r // 2 - 2 * er, cy - r // 6 - er, cx + r // 2, cy - r // 6 + er), fill=(40, 40, 42))
        d.polygon([(cx - 8, cy + 4), (cx + 8, cy + 4), (cx, cy + 14)], fill=(232, 118, 132))

    elif scene == "dog_park":
        _vgradient(im, (110, 188, 236), (176, 224, 250))
        d.rectangle((0, int(H * 0.62), W, H), fill=(78, 168, 86))
        cx, cy = W // 2, int(H * 0.56)
        r = max(26, min(W, H) // 4)
        d.ellipse((cx - int(r * 1.25), cy - r // 2, cx - r // 2, cy + r), fill=(142, 92, 54))
        d.ellipse((cx + r // 2, cy - r // 2, cx + int(r * 1.25), cy + r), fill=(142, 92, 54))
        d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(198, 146, 94))
        er = max(4, r // 7)
        d.ellipse((cx - r // 2, cy - r // 6, cx - r // 2 + 2 * er, cy - r // 6 + 2 * er), fill=(36, 32, 30))
        d.ellipse((cx + r // 2 - 2 * er, cy - r // 6, cx + r // 2, cy - r // 6 + 2 * er), fill=(36, 32, 30))
        d.ellipse((cx - r // 4, cy + r // 6, cx + r // 4, cy + r // 2), fill=(52, 40, 34))

    elif scene == "family_call":
        _vgradient(im, (38, 76, 132), (76, 136, 198))
        # Moldura de tablet/videochamada
        px0, py0, px1, py1 = int(W * 0.18), int(H * 0.14), int(W * 0.82), int(H * 0.88)
        d.rounded_rectangle((px0, py0, px1, py1), radius=24, fill=(246, 248, 252), outline=(22, 42, 76), width=8)
        d.rounded_rectangle((px0 + 18, py0 + 22, px1 - 18, py1 - 54), radius=16, fill=(224, 238, 252))
        s = min(W, H) / 360.0
        _draw_person_silhouette(d, int(W * 0.42), int(H * 0.56), s * 1.15, (48, 128, 108), hair_color=(212, 216, 224), glasses=True)
        _draw_person_silhouette(d, int(W * 0.62), int(H * 0.60), s * 0.85, (220, 118, 66), hair_color=(90, 62, 42))
        # Botao verde de chamada
        bx, by = W // 2, py1 - 26
        d.ellipse((bx - 22, by - 16, bx + 22, by + 16), fill=(36, 178, 92))

    elif scene == "phone_tips":
        _vgradient(im, (24, 48, 108), (44, 108, 206))
        if H > W * 1.3:
            # Formato vertical para Shorts: celular centralizado e livre das barras laterais
            pw, ph = int(W * 0.42), int(H * 0.48)
            cx, cy = int(W * 0.46), int(H * 0.56)
            rad = 26
        else:
            pw, ph = int(W * 0.27), int(H * 0.72)
            cx, cy = int(W * 0.78), H // 2
            rad = 22
        d.rounded_rectangle((cx - pw // 2, cy - ph // 2, cx + pw // 2, cy + ph // 2), radius=rad, fill=(26, 30, 42), outline=(185, 212, 248), width=6)
        d.rounded_rectangle((cx - pw // 2 + 12, cy - ph // 2 + 16, cx + pw // 2 - 12, cy + ph // 2 - 16), radius=max(10, rad - 8), fill=(248, 250, 255))
        f_aa = load_font(max(24, pw // 3), bold=True)
        d.text((cx, cy - 10), "Aa+", font=f_aa, fill=(28, 92, 198), anchor="mm")
        d.rounded_rectangle((cx - pw // 3, cy + ph // 6, cx + pw // 3, cy + ph // 6 + 24), radius=10, fill=(46, 138, 240))

    elif scene == "security_shield":
        _vgradient(im, (18, 66, 78), (34, 132, 112))
        cx, cy = int(W * 0.78), H // 2
        sw, sh = max(44, min(W, H) // 3), max(56, int(min(W, H) * 0.42))
        d.polygon([
            (cx, cy - sh // 2),
            (cx + sw // 2, cy - sh // 3),
            (cx + sw // 2 - 8, cy + sh // 8),
            (cx, cy + sh // 2),
            (cx - sw // 2 + 8, cy + sh // 8),
            (cx - sw // 2, cy - sh // 3),
        ], fill=(246, 204, 68), outline=(255, 242, 180))
        d.line([(cx - sw // 5, cy + 4), (cx - 4, cy + sh // 5), (cx + sw // 4, cy - sh // 6)], fill=(24, 96, 62), width=max(8, sw // 9))

    elif scene == "stretching":
        _vgradient(im, (52, 148, 142), (168, 224, 188))
        d.rectangle((0, int(H * 0.74), W, H), fill=(228, 214, 186))
        cx, cy = int(W * 0.78), int(H * 0.48)
        r = max(14, min(W, H) // 11)
        d.ellipse((cx - r, cy - r * 3, cx + r, cy - r), fill=(238, 196, 168))
        d.rounded_rectangle((cx - r, cy - r + 4, cx + r, cy + r * 2), radius=r // 2, fill=(38, 96, 142))
        # Bracos erguidos
        d.line([(cx - r, cy - r // 2), (cx - r * 2, cy - r * 2 - 8)], fill=(38, 96, 142), width=max(8, r // 2))
        d.line([(cx + r, cy - r // 2), (cx + r * 2, cy - r * 2 - 8)], fill=(38, 96, 142), width=max(8, r // 2))

    elif scene == "recipe_kitchen":
        _vgradient(im, (176, 86, 48), (228, 152, 82))
        d.rectangle((0, int(H * 0.68), W, H), fill=(124, 74, 48))
        cx, cy = int(W * 0.68), int(H * 0.56)
        pw, ph = int(W * 0.34), int(H * 0.28)
        d.rounded_rectangle((cx - pw // 2, cy - ph // 2, cx + pw // 2, cy + ph // 2), radius=24, fill=(214, 62, 54))
        d.rounded_rectangle((cx - pw // 2 - 18, cy - ph // 4, cx + pw // 2 + 18, cy), radius=10, fill=(242, 242, 242))
        for dx in (-pw // 4, 0, pw // 4):
            d.arc((cx + dx - 14, cy - ph // 2 - 64, cx + dx + 14, cy - ph // 2 - 8), 80, 280, fill=(255, 244, 224), width=5)

    elif scene == "classic_music":
        _vgradient(im, (98, 28, 52), (178, 74, 54))
        cx, cy = int(W * 0.70), H // 2
        vr = max(48, int(min(W, H) * 0.36))
        d.ellipse((cx - vr, cy - vr, cx + vr, cy + vr), fill=(28, 28, 32), outline=(228, 186, 94), width=6)
        d.ellipse((cx - vr // 2, cy - vr // 2, cx + vr // 2, cy + vr // 2), outline=(65, 65, 72), width=3)
        d.ellipse((cx - vr // 4, cy - vr // 4, cx + vr // 4, cy + vr // 4), fill=(224, 168, 62))
        d.ellipse((cx - 10, cy - 10, cx + 10, cy + 10), fill=(28, 28, 32))

    elif scene == "gardening_tips":
        _vgradient(im, (42, 126, 74), (114, 192, 122))
        cx, cy = W // 2, int(H * 0.68)
        pw, ph = int(W * 0.28), int(H * 0.26)
        d.polygon([(cx - pw // 2, cy), (cx + pw // 2, cy), (cx + pw // 3, cy + ph), (cx - pw // 3, cy + ph)], fill=(196, 96, 58))
        d.rounded_rectangle((cx - pw // 2 - 8, cy - 16, cx + pw // 2 + 8, cy + 8), radius=8, fill=(214, 110, 68))
        # Folhas e flor
        d.line([(cx, cy - 16), (cx, cy - int(H * 0.34))], fill=(32, 92, 48), width=8)
        d.ellipse((cx - 56, cy - int(H * 0.24), cx - 4, cy - int(H * 0.14)), fill=(48, 138, 66))
        d.ellipse((cx + 4, cy - int(H * 0.28), cx + 58, cy - int(H * 0.18)), fill=(48, 138, 66))
        fr = max(24, min(W, H) // 7)
        fy = cy - int(H * 0.36)
        d.ellipse((cx - fr, fy - fr, cx + fr, fy + fr), fill=(242, 96, 122))
        d.ellipse((cx - fr // 2, fy - fr // 2, cx + fr // 2, fy + fr // 2), fill=(255, 214, 72))

    elif scene == "whatsapp_guide":
        _vgradient(im, (14, 96, 82), (38, 166, 124))
        cx, cy = int(W * 0.70), H // 2
        br = max(44, int(min(W, H) * 0.32))
        d.ellipse((cx - br, cy - br, cx + br, cy + br), fill=(255, 255, 255))
        d.polygon([(cx - br + 10, cy + br // 2), (cx - br - 16, cy + br), (cx - br // 3, cy + br - 8)], fill=(255, 255, 255))
        d.ellipse((cx - br // 2 - 12, cy - 12, cx - br // 2 + 12, cy + 12), fill=(24, 138, 102))
        d.ellipse((cx - 12, cy - 12, cx + 12, cy + 12), fill=(24, 138, 102))
        d.ellipse((cx + br // 2 - 12, cy - 12, cx + br // 2 + 12, cy + 12), fill=(24, 138, 102))

    else:  # memory_album
        _vgradient(im, (96, 76, 148), (186, 126, 164))
        cx, cy = W // 2, H // 2
        d.rounded_rectangle((cx - int(W * 0.24), cy - int(H * 0.28), cx + int(W * 0.24), cy + int(H * 0.28)), radius=14, fill=(250, 248, 244))
        d.rounded_rectangle((cx - int(W * 0.19), cy - int(H * 0.22), cx + int(W * 0.19), cy + int(H * 0.10)), radius=8, fill=(104, 174, 224))
        d.ellipse((cx + int(W * 0.04), cy - int(H * 0.16), cx + int(W * 0.14), cy - int(H * 0.04)), fill=(255, 218, 96))

    return _aa_finish(im, (w, h))


def draw_generic_person_avatar(size: int, idx: int) -> Image.Image:
    sc = 2
    S = size * sc
    palettes = [
        ((76, 134, 198), (44, 88, 148), True, (212, 216, 224)),
        ((96, 162, 126), (196, 102, 72), False, (86, 62, 46)),
        ((158, 118, 184), (62, 112, 152), True, (232, 232, 236)),
        ((204, 136, 78), (74, 132, 92), False, (64, 52, 44)),
    ]
    bg, shirt, glass, hair = palettes[idx % len(palettes)]
    im = Image.new("RGB", (S, S), bg)
    d = ImageDraw.Draw(im)
    if idx % 4 == 3:
        # Bichinho de estimacao estilizado
        sub = draw_illustration("cat_portrait", size, size).resize((S, S), Image.Resampling.LANCZOS)
        im = sub
    else:
        _draw_person_silhouette(d, S // 2, int(S * 0.56), S / 120.0, shirt, hair_color=hair, glasses=glass)
    out = _aa_finish(im, (size, size))
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, S - 1, S - 1), fill=255)
    mask = mask.resize((size, size), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.paste(out, (0, 0), mask)
    return canvas


def draw_youtube_thumb(
    img: Image.Image,
    box: tuple[int, int, int, int],
    scene: str,
    banner: str = "",
    badge: str = "",
    badge_red: bool = False,
    radius: int = 0,
):
    x0, y0, x1, y1 = box
    w, h = x1 - x0, y1 - y0
    tile = draw_illustration(scene, w, h).convert("RGBA")

    if banner:
        overlay = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        od = ImageDraw.Draw(overlay)
        for x in range(int(w * 0.62)):
            a = int(175 * (1.0 - x / max(1, w * 0.62)))
            od.line([(x, 0), (x, h)], fill=(10, 14, 24, a))
        tile = Image.alpha_composite(tile, overlay)

        td = ImageDraw.Draw(tile)
        lines = banner.split("\n")
        f_sz = max(18, min(38, int(h * 0.11)))
        f_ban = load_font(f_sz, bold=True)
        total_h = len(lines) * (f_sz + 8)
        ty = max(18, (h - total_h) // 2)
        for line in lines:
            td.text((26, ty + 2), line, font=f_ban, fill=(0, 0, 0, 190))
            td.text((24, ty), line, font=f_ban, fill=(255, 255, 255, 255))
            ty += f_sz + 8

    if badge:
        td = ImageDraw.Draw(tile)
        f_b = load_font(max(13, min(18, int(h * 0.055))), bold=True)
        bb = td.textbbox((0, 0), badge, font=f_b)
        bw, bh = bb[2] - bb[0] + 16, bb[3] - bb[1] + 10
        bx0, by0 = w - bw - 14, h - bh - 12
        fill_c = (210, 28, 28, 240) if badge_red else (15, 15, 15, 220)
        td.rounded_rectangle((bx0, by0, bx0 + bw, by0 + bh), radius=6, fill=fill_c)
        td.text((bx0 + bw // 2, by0 + bh // 2 - 1), badge, font=f_b, fill=(255, 255, 255, 255), anchor="mm")

    _paste_rounded(img, tile.convert("RGB"), (x0, y0), radius)


# ---------------------------------------------------------------------------
# GOOGLE FOTOS (apps/.originais/GoogleFotos -> apps/GoogleFotos)
# ---------------------------------------------------------------------------

def _gf_replace_top_avatar(im: Image.Image, bg_color: tuple[int, int, int]):
    d = ImageDraw.Draw(im)
    d.rectangle((552, 72, 628, 152), fill=bg_color)
    badge = make_initial_badge(50, "U", bg_color=(45, 110, 195))
    im.paste(badge, (565, 85), badge)


def _gf_capture_floating_nav(im_orig: Image.Image, has_sparkle: bool = False):
    pill = _preserve_pill_mask(im_orig, (118, 1224, 428, 1294), radius=35)
    search = _preserve_pill_mask(im_orig, (446, 1224, 516, 1294), radius=35)
    sparkle = _preserve_pill_mask(im_orig, (37, 1237, 76, 1267), radius=15) if has_sparkle else None
    return pill, search, sparkle


def _gf_restore_floating_nav(dst: Image.Image, nav_items):
    (pill_crop, pill_mask), (sr_crop, sr_mask), sp = nav_items
    dst.paste(pill_crop, (118, 1224), pill_mask)
    dst.paste(sr_crop, (446, 1224), sr_mask)
    if sp is not None:
        sp_crop, sp_mask = sp
        dst.paste(sp_crop, (37, 1237), sp_mask)


def process_google_fotos():
    src = ROOT / "apps" / ".originais" / "GoogleFotos"
    dst = ROOT / "apps" / "GoogleFotos"
    dst.mkdir(parents=True, exist_ok=True)
    y_top, y_bot = 62, 1320
    bg_dark = (21, 19, 24)

    # 1. 01_fotos.jpg
    im = Image.open(src / "745eb1c6-cc43-4cbc-b391-60ed751ef4b9.jpg").convert("RGB")
    nav_items = _gf_capture_floating_nav(im)
    _gf_replace_top_avatar(im, bg_dark)

    d = ImageDraw.Draw(im)
    # Strip de memorias no topo
    d.rectangle((0, 174, 636, 534), fill=bg_dark)
    memories = [
        ((21, 178, 293, 528), "sunset_beach", "Fim de tarde\nna praia"),
        ((304, 178, 575, 528), "family_call", "Momentos\nem família"),
        ((585, 178, 636, 528), "garden_flowers", ""),
    ]
    f_mem = load_font(22, bold=True)
    for box, scene, cap in memories:
        x0, y0, x1, y1 = box
        tile = draw_illustration(scene, x1 - x0, y1 - y0).convert("RGBA")
        if cap:
            ov = Image.new("RGBA", tile.size, (0, 0, 0, 0))
            od = ImageDraw.Draw(ov)
            th = tile.size[1]
            for yy in range(th - 110, th):
                a = int(190 * (yy - (th - 110)) / 110)
                od.line([(0, yy), (tile.size[0], yy)], fill=(12, 12, 16, a))
            tile = Image.alpha_composite(tile, ov)
            ImageDraw.Draw(tile).text((16, th - 68), cap, font=f_mem, fill=(255, 255, 255, 255))
        _paste_rounded(im, tile.convert("RGB"), (x0, y0), radius=18)

    # Grade de fotos (preserva cabecalho da data em y=535..562)
    d.rectangle((0, 563, 636, 1320), fill=bg_dark)
    cols = [(0, 157), (160, 316), (319, 476), (479, 636)]
    rows = [(563, 724), (727, 885), (888, 1045), (1048, 1205), (1208, 1320)]
    scenes = [
        "mountain_lake", "garden_flowers", "coffee_book", "cat_portrait",
        "birthday_cake", "sunset_beach", "dog_park", "recipe_kitchen",
        "gardening_tips", "memory_album", "family_call", "stretching",
        "classic_music", "mountain_lake", "coffee_book", "garden_flowers",
        "sunset_beach", "cat_portrait", "birthday_cake", "dog_park",
    ]
    idx = 0
    for r0, r1 in rows:
        for c0, c1 in cols:
            tile = draw_illustration(scenes[idx % len(scenes)], c1 - c0, r1 - r0)
            im.paste(tile, (c0, r0))
            idx += 1

    _gf_restore_floating_nav(im, nav_items)
    save_jpg(crop_system_bars(im, y_top, y_bot), dst / "01_fotos.jpg")

    # 2. 02_albuns.jpg
    im = Image.open(src / "60e827d5-58db-4e6b-a973-0558600a59c5.jpg").convert("RGB")
    nav_items = _gf_capture_floating_nav(im)
    _gf_replace_top_avatar(im, bg_dark)
    d = ImageDraw.Draw(im)

    # Fixados
    d.rectangle((0, 238, 636, 472), fill=bg_dark)
    f_alb = load_font(17)
    dev_items = [
        (22, 165, "mountain_lake", "Câmera"),
        (178, 321, "garden_flowers", "Flores"),
        (334, 477, "coffee_book", "Favoritas"),
        (490, 633, "recipe_kitchen", "Receitas"),
    ]
    for x0, x1, sc_name, lbl in dev_items:
        _paste_rounded(im, draw_illustration(sc_name, x1 - x0, 174), (x0, 240), radius=14)
        d.text((x0 + 2, 424), lbl, font=f_alb, fill=(230, 228, 235))

    # Albuns linha 1 & 2 (3 colunas)
    f_alb_sub = load_font(15)
    alb_rows = [
        (571, 735, 742, [
            (22, 206, "sunset_beach", "Viagem à Praia", "24 itens"),
            (222, 406, "family_call", "Família", "48 itens"),
            (422, 606, "birthday_cake", "Aniversários", "19 itens"),
        ]),
        (904, 1070, 1077, [
            (22, 206, "garden_flowers", "Meu Jardim", "32 itens"),
            (222, 406, "cat_portrait", "Bichinhos", "15 itens"),
            (422, 606, "recipe_kitchen", "Receitas", "12 itens"),
        ]),
    ]
    for ty0, ty1, ly, items in alb_rows:
        d.rectangle((0, ty0 - 4, 636, ly + 62), fill=bg_dark)
        for x0, x1, sc_name, title, sub in items:
            _paste_rounded(im, draw_illustration(sc_name, x1 - x0, ty1 - ty0), (x0, ty0), radius=16)
            d.text((x0 + 2, ly), title, font=f_alb, fill=(238, 236, 242))
            d.text((x0 + 2, ly + 22), sub, font=f_alb_sub, fill=(165, 162, 172))

    # Pessoas e animais de estimacao (4 rostos)
    d.rectangle((0, 1222, 636, 1320), fill=bg_dark)
    for k, x0 in enumerate((22, 178, 334, 490)):
        av = draw_generic_person_avatar(140, k)
        im.paste(av, (x0, 1226), av)

    _gf_restore_floating_nav(im, nav_items)
    save_jpg(crop_system_bars(im, y_top, y_bot), dst / "02_albuns.jpg")

    # 3. 03_criar.jpg
    im = Image.open(src / "e32af5a1-4510-4f3d-9e84-bc554926feeb.jpg").convert("RGB")
    nav_items = _gf_capture_floating_nav(im, has_sparkle=True)
    _gf_replace_top_avatar(im, im.getpixel((550, 108)))
    d = ImageDraw.Draw(im)
    bot_bg = im.getpixel((10, 1140))
    d.rectangle((0, 1148, 636, 1320), fill=bot_bg)
    remix_scenes = ["sunset_beach", "mountain_lake", "garden_flowers", "coffee_book"]
    for x0, x1, sc_name in zip((22, 184, 346, 508), (170, 332, 494, 636), remix_scenes):
        _paste_rounded(im, draw_illustration(sc_name, x1 - x0, 168), (x0, 1150), radius=16)

    _gf_restore_floating_nav(im, nav_items)
    save_jpg(crop_system_bars(im, y_top, y_bot), dst / "03_criar.jpg")

    # 4. 04_conta.jpg
    im = Image.open(src / "d18f84b4-c7f9-478f-98fa-c001e872fdb2.jpg").convert("RGB")
    d = ImageDraw.Draw(im)
    card1_bg = im.getpixel((30, 210))
    # Card 1: avatar na esquerda (36..134, 170..268), nome, e-mail e badge Pro
    d.rectangle((34, 166, 138, 270), fill=card1_bg)
    av_acc = make_initial_badge(92, "U", bg_color=(45, 110, 195))
    im.paste(av_acc, (38, 172), av_acc)
    d.rectangle((144, 168, 520, 272), fill=card1_bg)
    d.text((152, 188), "Usuário Exemplo", font=load_font(22, bold=True), fill=(242, 242, 246), anchor="lm")
    d.text((152, 224), "usuario@exemplo.com", font=load_font(17), fill=(185, 185, 194), anchor="lm")

    # Card 4: armazenamento (y=520..608)
    st_bg = im.getpixel((30, 540))
    d.rectangle((90, 520, 420, 558), fill=st_bg)
    d.text((94, 538), "Você usou 3% de 15 GB", font=load_font(18), fill=(230, 230, 236), anchor="lm")
    d.rectangle((46, 574, 340, 608), fill=st_bg)
    d.text((50, 590), "0,5 GB de 15 GB usados", font=load_font(16), fill=(178, 178, 186), anchor="lm")
    save_jpg(crop_system_bars(im, y_top, y_bot), dst / "04_conta.jpg")


# ---------------------------------------------------------------------------
# YOUTUBE (apps/.originais/YouTube -> apps/YouTube)
# ---------------------------------------------------------------------------

YT_BG = (15, 15, 15)


def _yt_replace_bottom_avatar(im: Image.Image):
    d = ImageDraw.Draw(im)
    d.rectangle((535, 1275, 578, 1317), fill=YT_BG)
    badge = make_initial_badge(34, "U", bg_color=(36, 98, 200))
    im.paste(badge, (539, 1279), badge)


def _yt_draw_video_meta(
    im: Image.Image,
    y_top: int,
    y_bot: int,
    initials: str,
    av_color: tuple[int, int, int],
    title: str,
    subtitle: str,
):
    d = ImageDraw.Draw(im)
    d.rectangle((0, y_top, 636, y_bot), fill=YT_BG)
    badge = make_initial_badge(48, initials, bg_color=av_color)
    im.paste(badge, (18, y_top + 10), badge)
    f_t = load_font(20, bold=True)
    f_s = load_font(16)
    words = title.split()
    lines, cur = [], ""
    for w in words:
        cand = f"{cur} {w}".strip()
        if d.textlength(cand, font=f_t) <= 505:
            cur = cand
        else:
            lines.append(cur)
            cur = w
    if cur:
        lines.append(cur)
    ty = y_top + 8
    for line in lines[:2]:
        d.text((80, ty), line, font=f_t, fill=(242, 242, 242))
        ty += 26
    d.text((80, ty + 4), subtitle, font=f_s, fill=(170, 170, 170))
    for k in range(3):
        d.ellipse((610, y_top + 14 + k * 8, 615, y_top + 19 + k * 8), fill=(220, 220, 220))


def _composite_bright_icons(dst: Image.Image, overlay_crop: Image.Image, pos: tuple[int, int], luma_thresh: int = 195):
    ow, oh = overlay_crop.size
    rgba = Image.new("RGBA", (ow, oh), (0, 0, 0, 0))
    src_px = overlay_crop.load()
    dst_px = rgba.load()
    for y in range(oh):
        for x in range(ow):
            r, g, b = src_px[x, y]
            lum = int(0.299 * r + 0.587 * g + 0.114 * b)
            if lum >= luma_thresh:
                dst_px[x, y] = (255, 255, 255, min(255, int((lum - luma_thresh) * 4 + 140)))
    ox, oy = pos
    base = dst.crop((ox, oy, ox + ow, oy + oh)).convert("RGBA")
    merged = Image.alpha_composite(base, rgba)
    dst.paste(merged.convert("RGB"), (ox, oy))


def process_youtube():
    src = ROOT / "apps" / ".originais" / "YouTube"
    dst = ROOT / "apps" / "YouTube"
    dst.mkdir(parents=True, exist_ok=True)
    y_top, y_bot = 62, 1322

    # 1. 01_inicio_enquete.jpg
    im = Image.open(src / "c17181a0-b3a2-4aa4-a2e3-c32f00bd619e.jpg").convert("RGB")
    draw_youtube_thumb(
        im,
        (0, 62, 636, 448),
        "phone_tips",
        banner="Como Aumentar a\nLetra no Celular",
        badge="6:42",
    )

    _yt_draw_video_meta(
        im,
        452,
        580,
        "M",
        (36, 118, 210),
        "Como aumentar o tamanho da letra no celular passo a passo",
        "Canal Memora · 12 mil visualizações · há 2 dias",
    )

    # Enquete da Comunidade (substitui post sensivel por enquete Memora)
    d = ImageDraw.Draw(im)
    d.rectangle((0, 620, 636, 1255), fill=YT_BG)
    d.rectangle((0, 620, 636, 626), fill=(36, 36, 36))
    av_c = make_initial_badge(48, "M", bg_color=(36, 148, 92))
    im.paste(av_c, (20, 644), av_c)
    d.text((82, 646), "Memora · Dicas Digitais", font=load_font(20, bold=True), fill=(242, 242, 242))
    d.text((82, 672), "há 3 horas", font=load_font(16), fill=(165, 165, 165))
    d.rounded_rectangle((468, 646, 594, 686), radius=20, fill=(242, 242, 242))
    d.text((531, 666), "Inscrever-se", font=load_font(16, bold=True), fill=(15, 15, 15), anchor="mm")

    d.text(
        (20, 718),
        "Qual tutorial você gostaria de ver aqui esta semana?",
        font=load_font(21, bold=True),
        fill=(242, 242, 242),
    )
    d.text(
        (20, 748),
        "Vote na sua opção favorita para o próximo vídeo:",
        font=load_font(18),
        fill=(205, 205, 205),
    )

    poll_opts = [
        ("Fazer videochamada com a família", "58%", 0.58, True),
        ("Identificar mensagens falsas e golpes", "24%", 0.24, False),
        ("Organizar álbuns no Google Fotos", "12%", 0.12, False),
        ("Salvar músicas e vídeos favoritos", "6%", 0.06, False),
    ]
    py = 804
    f_opt = load_font(18, bold=False)
    f_pct = load_font(17, bold=True)
    for label, pct, ratio, selected in poll_opts:
        d.rounded_rectangle((20, py, 616, py + 62), radius=10, fill=(32, 32, 32), outline=(66, 66, 66), width=2)
        bar_w = max(18, int((616 - 20) * ratio))
        bar_col = (40, 86, 138) if selected else (52, 52, 56)
        d.rounded_rectangle((22, py + 2, 22 + bar_w, py + 60), radius=8, fill=bar_col)
        d.text((40, py + 31), label, font=f_opt, fill=(245, 245, 245), anchor="lm")
        d.text((596, py + 31), pct, font=f_pct, fill=(225, 232, 245), anchor="rm")
        py += 76

    d.text((20, 1126), "1,4 mil votos · Há 3 horas", font=load_font(16), fill=(165, 165, 165))
    # Icones simples desenhados (sem glifos faltando)
    d.rounded_rectangle((24, 1184, 34, 1200), radius=2, outline=(210, 210, 210), width=2)
    d.polygon([(34, 1188), (40, 1178), (44, 1180), (42, 1188), (48, 1188), (46, 1200), (34, 1200)], outline=(210, 210, 210), width=2)
    d.text((58, 1181), "248", font=load_font(17), fill=(215, 215, 215))
    d.rounded_rectangle((140, 1182, 164, 1199), radius=4, outline=(210, 210, 210), width=2)
    d.polygon([(145, 1199), (145, 1205), (153, 1199)], fill=(210, 210, 210))
    d.text((174, 1181), "34", font=load_font(17), fill=(215, 215, 215))

    _yt_replace_bottom_avatar(im)
    save_jpg(crop_system_bars(im, y_top, y_bot), dst / "01_inicio_enquete.jpg")

    # 2. 02_inicio_ao_vivo.jpg
    im = Image.open(src / "8bc5946d-5094-4a8f-9065-150063a7857e.jpg").convert("RGB")
    draw_youtube_thumb(
        im,
        (0, 214, 636, 580),
        "classic_music",
        banner="Clássicos Brasileiros\nAo Vivo",
        badge="• AO VIVO",
        badge_red=True,
    )
    _yt_draw_video_meta(
        im,
        580,
        690,
        "MM",
        (168, 62, 52),
        "Rádio Memória Musical: Sucessos de Ouro 24h (Sem Anúncios)",
        "Memória Musical · 1,8 mil assistindo",
    )
    draw_youtube_thumb(
        im,
        (0, 718, 636, 1082),
        "stretching",
        banner="Alongamento Suave\nem Casa",
        badge="14:20",
    )
    _yt_draw_video_meta(
        im,
        1084,
        1195,
        "SM",
        (42, 138, 128),
        "15 Minutos de Alongamento Matinal para Mobilidade e Bem-Estar",
        "Saúde & Movimento · 84 mil visualizações · há 1 mês",
    )
    peek = draw_illustration("recipe_kitchen", 636, 360).crop((0, 0, 636, 40))
    im.paste(peek, (0, 1218))
    _yt_replace_bottom_avatar(im)
    save_jpg(crop_system_bars(im, y_top, y_bot), dst / "02_inicio_ao_vivo.jpg")

    # 3. 03_shorts.jpg
    im = Image.open(src / "3c3d153a-2c00-4c21-b3c1-a8622037fe88.jpg").convert("RGB")
    top_shorts_icons = im.crop((0, 62, 636, 136))
    right_shorts_icons = im.crop((548, 740, 636, 1155))

    shorts_art = draw_illustration("phone_tips", 636, 1184)
    im.paste(shorts_art, (0, 62))
    sd = ImageDraw.Draw(im)
    sd.text((292, 190), "Dica Rápida Memora", font=load_font(30, bold=True), fill=(255, 255, 255), anchor="mm")
    sd.text((292, 234), "Deixe a letra maior e mais nítida", font=load_font(20), fill=(210, 230, 255), anchor="mm")

    grad_ov = Image.new("RGBA", (636, 220), (0, 0, 0, 0))
    gd = ImageDraw.Draw(grad_ov)
    for yy in range(220):
        gd.line([(0, yy), (636, yy)], fill=(10, 10, 14, int(195 * yy / 220)))
    bot_reg = im.crop((0, 1026, 636, 1246)).convert("RGBA")
    im.paste(Image.alpha_composite(bot_reg, grad_ov).convert("RGB"), (0, 1026))

    _composite_bright_icons(im, top_shorts_icons, (0, 62), luma_thresh=205)
    _composite_bright_icons(im, right_shorts_icons, (548, 740), luma_thresh=205)

    # Miniatura de audio generica no canto inferior direito (substitui logo antigo)
    sd.rounded_rectangle((566, 1170, 616, 1220), radius=10, fill=(28, 86, 178), outline=(255, 255, 255), width=2)
    sd.text((591, 1195), "M", font=load_font(22, bold=True), fill=(255, 255, 255), anchor="mm")

    av_s = make_initial_badge(42, "M", bg_color=(36, 128, 210))
    im.paste(av_s, (18, 1110), av_s)
    sd.text((70, 1131), "@Memora.Oficial", font=load_font(19, bold=True), fill=(255, 255, 255), anchor="lm")
    sd.rounded_rectangle((246, 1112, 370, 1148), radius=18, fill=(255, 255, 255))
    sd.text((308, 1130), "Inscrever-se", font=load_font(15, bold=True), fill=(15, 15, 15), anchor="mm")
    sd.text((18, 1170), "Como aumentar as letras do celular em 3 cliques", font=load_font(19), fill=(248, 248, 248))
    # Nota musical desenhada + texto sem glifo quebrado
    sd.ellipse((20, 1212, 28, 1219), fill=(235, 240, 248))
    sd.line([(27, 1215), (27, 1202), (35, 1200)], fill=(235, 240, 248), width=2)
    sd.text((42, 1201), "Som original - Memora Dicas", font=load_font(16), fill=(220, 225, 232))

    sd.rectangle((0, 1246, 636, 1252), fill=(90, 90, 96))
    sd.rectangle((0, 1246, 260, 1252), fill=(235, 36, 36))

    _yt_replace_bottom_avatar(im)
    save_jpg(crop_system_bars(im, y_top, y_bot), dst / "03_shorts.jpg")

    # 4. 04_inscricoes.jpg
    im = Image.open(src / "8c699f8f-742c-4d73-ba9e-1e1fb38fbc1c.jpg").convert("RGB")
    d = ImageDraw.Draw(im)
    # Apaga ate x=566 (antes do botao Todos) para remover 6o avatar parcial
    d.rectangle((0, 222, 566, 344), fill=YT_BG)
    channels = [
        (56, "Memora", "whatsapp_guide"),
        (158, "Receitas", "recipe_kitchen"),
        (259, "Saúde+", "stretching"),
        (360, "Jardim", "gardening_tips"),
        (462, "Música", "classic_music"),
    ]
    f_ch = load_font(14)
    for cx, cname, csc in channels:
        tile = draw_illustration(csc, 74, 74)
        mask = Image.new("L", (148, 148), 0)
        ImageDraw.Draw(mask).ellipse((0, 0, 147, 147), fill=255)
        im.paste(tile, (cx - 37, 228), mask.resize((74, 74), Image.Resampling.LANCZOS))
        d.text((cx, 314), cname, font=f_ch, fill=(210, 210, 210), anchor="mt")

    d.rectangle((0, 428, 636, 766), fill=YT_BG)
    shelf_cards = [
        (18, 214, "gardening_tips", "Regando orquídeas\ndo jeito certo"),
        (228, 424, "coffee_book", "Chá de camomila\npara relaxar"),
        (438, 634, "recipe_kitchen", "Pão caseiro simples\ne fofinho"),
    ]
    f_sh = load_font(16, bold=True)
    for x0, x1, sc_name, stitle in shelf_cards:
        tile = draw_illustration(sc_name, x1 - x0, 326).convert("RGBA")
        ov = Image.new("RGBA", tile.size, (0, 0, 0, 0))
        od = ImageDraw.Draw(ov)
        for yy in range(210, 326):
            od.line([(0, yy), (tile.size[0], yy)], fill=(12, 12, 16, int(200 * (yy - 210) / 116)))
        tile = Image.alpha_composite(tile, ov)
        ImageDraw.Draw(tile).text((12, 266), stitle, font=f_sh, fill=(255, 255, 255, 255))
        _paste_rounded(im, tile.convert("RGB"), (x0, 434), radius=14)

    draw_youtube_thumb(
        im,
        (0, 780, 636, 1142),
        "security_shield",
        banner="Golpes no WhatsApp:\nComo se Proteger",
        badge="11:05",
    )
    _yt_draw_video_meta(
        im,
        1146,
        1252,
        "MD",
        (30, 128, 108),
        "5 Sinais para Identificar Mensagens Falsas e Evitar Golpes",
        "Memora Digital · 95 mil visualizações · há 4 dias",
    )
    _yt_replace_bottom_avatar(im)
    save_jpg(crop_system_bars(im, y_top, y_bot), dst / "04_inscricoes.jpg")

    # 5. 05_voce_historico.jpg
    im = Image.open(src / "e7002fd4-16d9-4e13-b3ec-b76c7231a3b1.jpg").convert("RGB")
    d = ImageDraw.Draw(im)
    d.rectangle((0, 155, 636, 274), fill=YT_BG)
    av_p = make_initial_badge(96, "U", bg_color=(36, 98, 200))
    im.paste(av_p, (22, 166), av_p)
    d.text((138, 180), "Usuário Exemplo", font=load_font(28, bold=True), fill=(245, 245, 245))
    d.text((138, 222), "@usuario.exemplo  ·  Ver canal >", font=load_font(17), fill=(170, 170, 170))

    d.rectangle((0, 420, 636, 646), fill=YT_BG)
    hist_items = [
        (22, 228, "family_call", "9:18", "Videochamada com\na família", "Canal Memora"),
        (248, 454, "recipe_kitchen", "12:40", "Bolo de fubá\ncremoso fácil", "Receitas da Casa"),
        (474, 636, "stretching", "10:05", "Alongamento\nmatinal leve", "Saúde & Movimento"),
    ]
    f_ht = load_font(16, bold=True)
    f_hs = load_font(14)
    for x0, x1, sc_name, dur, htitle, hch in hist_items:
        draw_youtube_thumb(im, (x0, 424, x1, 544), sc_name, badge=dur if x1 <= 460 else "", radius=10)
        d.text((x0 + 2, 552), htitle, font=f_ht, fill=(240, 240, 240))
        d.text((x0 + 2, 598), hch, font=f_hs, fill=(165, 165, 165))

    d.rectangle((0, 795, 636, 1140), fill=YT_BG)
    pl_items = [
        (22, 228, "classic_music", "Músicas Clássicas\nFavoritas", "Privada · 18 vídeos"),
        (248, 454, "phone_tips", "Tutoriais do\nMemora", "Pública · 12 vídeos"),
        (474, 636, "gardening_tips", "Cuidados com\nPlantas", "Privada · 9 vídeos"),
    ]
    for x0, x1, sc_name, ptitle, psub in pl_items:
        draw_youtube_thumb(im, (x0, 804, x1, 924), sc_name, radius=10)
        d.text((x0 + 2, 932), ptitle, font=f_ht, fill=(240, 240, 240))
        d.text((x0 + 2, 978), psub, font=f_hs, fill=(165, 165, 165))

    # Card "Seus videos" na base (substitui thumb antiga de jogo)
    d.rectangle((16, 1134, 255, 1258), fill=YT_BG)
    draw_youtube_thumb(im, (24, 1148, 244, 1254), "family_call", radius=10)
    d.rounded_rectangle((112, 1180, 156, 1222), radius=8, outline=(255, 255, 255), width=2)
    d.polygon([(128, 1190), (128, 1212), (144, 1201)], fill=(255, 255, 255))

    _yt_replace_bottom_avatar(im)
    save_jpg(crop_system_bars(im, y_top, y_bot), dst / "05_voce_historico.jpg")

    # 6. 06_canal_perfil.jpg
    im = Image.open(src / "0402c386-b470-454a-b71e-a33561be28b6.jpg").convert("RGB")
    d = ImageDraw.Draw(im)
    d.rectangle((0, 172, 636, 502), fill=YT_BG)
    av_ch = make_initial_badge(96, "U", bg_color=(36, 98, 200))
    im.paste(av_ch, (22, 180), av_ch)
    d.text((138, 186), "Usuário Exemplo", font=load_font(28, bold=True), fill=(245, 245, 245))
    d.text((138, 226), "@usuario.exemplo", font=load_font(17), fill=(185, 185, 185))
    d.text((138, 254), "12 inscritos · 4 vídeos", font=load_font(16), fill=(165, 165, 165))
    d.text(
        (22, 316),
        "Compartilhando receitas de família, dicas de jardinagem\ne bons momentos do dia a dia.",
        font=load_font(18),
        fill=(220, 220, 220),
    )
    d.text((22, 396), "memora.app/perfil-exemplo", font=load_font(17), fill=(104, 174, 245))

    d.rectangle((0, 720, 636, 1080), fill=YT_BG)
    draw_youtube_thumb(im, (22, 728, 432, 958), "birthday_cake", badge="8:15", radius=14)
    d.text((24, 968), "Receita de Bolo de Cenoura da Vó", font=load_font(19, bold=True), fill=(242, 242, 242))
    d.text((24, 996), "180 visualizações · há 2 semanas", font=load_font(16), fill=(165, 165, 165))

    draw_youtube_thumb(im, (450, 728, 636, 958), "garden_flowers", radius=14)
    d.text((452, 968), "Passeio no Jardim", font=load_font(19, bold=True), fill=(242, 242, 242))
    d.text((452, 996), "92 visualizações", font=load_font(16), fill=(165, 165, 165))

    # Lista "Videos >" na base (substitui video de jogo antigo)
    d.rectangle((0, 1146, 636, 1262), fill=YT_BG)
    draw_youtube_thumb(im, (22, 1152, 246, 1256), "classic_music", badge="6:20", radius=10)
    d.text((262, 1156), "Músicas Relaxantes para", font=load_font(18, bold=True), fill=(242, 242, 242))
    d.text((262, 1180), "Começar Bem o Dia", font=load_font(18, bold=True), fill=(242, 242, 242))
    d.text((262, 1212), "145 visualizações · há 1 mês", font=load_font(15), fill=(165, 165, 165))
    for k in range(3):
        d.ellipse((612, 1162 + k * 7, 616, 1166 + k * 7), fill=(220, 220, 220))

    _yt_replace_bottom_avatar(im)
    save_jpg(crop_system_bars(im, y_top, y_bot), dst / "06_canal_perfil.jpg")

    # 7. 07_menu_mais.jpg
    im = Image.open(src / "ee8f3333-91b3-4152-b93c-77421f785327.jpg").convert("RGB")
    d = ImageDraw.Draw(im)
    # Remove todo o toast "Captura de tela salva" (inclui borda superior em y=1190)
    d.rectangle((180, 1182, 460, 1266), fill=YT_BG)
    _yt_replace_bottom_avatar(im)
    save_jpg(crop_system_bars(im, y_top, y_bot), dst / "07_menu_mais.jpg")


def main():
    process_clt()
    process_cnh()
    process_poupatempo()
    process_google_fotos()
    process_youtube()
    print("Gerado: CLT (10), CNH (10), Poupatempo (10), GoogleFotos (4), YouTube (7) -> total 41.")


if __name__ == "__main__":
    main()
