import os
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ORIG = "apps/.originais"
APPS = "apps"
ASSETS_GUIAS = "app/assets/guias"
SCRATCH_VERIFY = r"C:\Users\Edu\.gemini\antigravity\brain\1add142c-f98b-4d25-8da1-4756365d2d82\scratch\verify"

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
    # Reference thickness scaled mildly for images wider or narrower than 720px
    unit = max(0.8, min(1.3, w / 720.0))
    overlay = Image.new("RGBA", (w * scale, h * scale), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    halo_w = int(round(11 * unit * scale))
    stroke_w = int(round(6 * unit * scale))
    badge_r = int(round(20 * unit * scale))
    font = load_font(int(round(24 * unit * scale)))

    orange = (234, 88, 12, 255)   # #EA580C high-contrast warm accent
    white = (255, 255, 255, 245)

    # First pass: draw all rings with white halo then orange stroke
    adj_boxes = []
    for x1, y1, x2, y2, num, shape, badge_pos in circles:
        ax1 = max(6, x1)
        ay1 = max(6, y1 - top_crop)
        ax2 = min(w - 6, x2)
        ay2 = min(h - 6, y2 - top_crop)
        sx1, sy1, sx2, sy2 = ax1 * scale, ay1 * scale, ax2 * scale, ay2 * scale
        box = (sx1, sy1, sx2, sy2)
        bw, bh = sx2 - sx1, sy2 - sy1
        rad = min(bw // 2, bh // 2, int(round(46 * unit * scale)))

        if shape == "ellipse":
            draw.ellipse(box, outline=white, width=halo_w)
            draw.ellipse(box, outline=orange, width=stroke_w)
        else:
            draw.rounded_rectangle(box, radius=rad, outline=white, width=halo_w)
            draw.rounded_rectangle(box, radius=rad, outline=orange, width=stroke_w)
        adj_boxes.append((sx1, sy1, sx2, sy2, num, shape, badge_pos))

    # Second pass: draw numbered circular badges on top
    ow, oh = w * scale, h * scale
    pad = badge_r + int(6 * scale)
    for sx1, sy1, sx2, sy2, num, shape, badge_pos in adj_boxes:
        cx, cy = (sx1 + sx2) // 2, (sy1 + sy2) // 2
        if badge_pos == "tl":
            bx, by = sx1, sy1
        elif badge_pos == "tr":
            bx, by = sx2, sy1
        elif badge_pos == "bl":
            bx, by = sx1, sy2
        elif badge_pos == "br":
            bx, by = sx2, sy2
        elif badge_pos == "left":
            bx, by = sx1, cy
        elif badge_pos == "right":
            bx, by = sx2, cy
        elif badge_pos == "top":
            bx, by = cx, sy1
        else:
            bx, by = cx, sy2

        bx = max(pad, min(ow - pad, bx))
        by = max(pad, min(oh - pad, by))

        outer = (bx - badge_r - 3 * scale, by - badge_r - 3 * scale,
                 bx + badge_r + 3 * scale, by + badge_r + 3 * scale)
        inner = (bx - badge_r, by - badge_r, bx + badge_r, by + badge_r)
        draw.ellipse(outer, fill=white)
        draw.ellipse(inner, fill=orange)

        label = str(num)
        tb = draw.textbbox((0, 0), label, font=font)
        tw, th = tb[2] - tb[0], tb[3] - tb[1]
        tx = bx - tw / 2 - tb[0]
        ty = by - th / 2 - tb[1]
        draw.text((tx, ty), label, font=font, fill=(255, 255, 255, 255))

    overlay_small = overlay.resize((w, h), Image.Resampling.LANCZOS)
    base = im.convert("RGBA")
    out = Image.alpha_composite(base, overlay_small).convert("RGB")
    return out


def save_asset_jpg(im: Image.Image, dst_path: str, target_width: int = 480, quality: int = 82) -> None:
    os.makedirs(os.path.dirname(dst_path), exist_ok=True)
    if im.width > target_width:
        ratio = target_width / im.width
        resized = im.resize((target_width, int(im.height * ratio)), Image.Resampling.LANCZOS)
    else:
        resized = im.copy()
    resized.convert("RGB").save(dst_path, "JPEG", quality=quality, optimize=True)


# Complete validated specification for all 76 screenshots across 6 folders
# Coordinates are in ORIGINAL (uncropped) image pixels.
SPECS: dict[str, dict] = {
    "whatsapp": {
        "orig_dir": "WhatsApp",
        "steps": [
            # Passo 1: Tela inicial + menu de 3 pontos aberto
            {
                "file": "WhatsApp Image 2026-11-09 at 14.25.21 (4).jpeg",
                "top_crop": 58,
                "blur": [
                    (8, 495, 295, 965),    # Chats visíveis à esquerda do menu
                    (8, 975, 580, 1365),   # Chats na parte inferior (excluindo botões à direita)
                ],
                "circles": [
                    (40, 175, 295, 275, 1, "pill", "tl"),     # Barra de pesquisa Pergunte à Meta AI
                    (570, 68, 705, 145, 2, "pill", "bl"),     # Ícones Câmera e 3 pontinhos
                    (300, 165, 705, 970, 3, "pill", "tl"),    # Menu de opções aberto
                    (575, 1085, 705, 1345, 4, "pill", "tl"),  # Botões Meta AI e Nova conversa (+)
                    (12, 1370, 708, 1485, 5, "pill", "tl"),   # Abas inferiores
                ],
            },
            # Passo 2: Menu de três pontinhos detalhado
            {
                "file": "WhatsApp Image 2026-11-09 at 14.37.40.jpeg",
                "top_crop": 0,
                "blur": [],
                "circles": [
                    (25, 160, 490, 415, 1, "pill", "tr"),     # Novo grupo / Nova comunidade
                    (25, 455, 560, 705, 2, "pill", "tr"),     # Listas de transmissão / Dispositivos conectados
                    (25, 745, 570, 995, 3, "pill", "tr"),     # Favoritas / Marcar tudo como lido
                    (25, 1035, 460, 1290, 4, "pill", "tr"),   # Pagamentos / Configurações
                ],
            },
            # Passo 3: Configurações (parte 1)
            {
                "file": "WhatsApp Image 2026-11-09 at 14.25.21 (5).jpeg",
                "top_crop": 58,
                "blur": [(95, 75, 330, 155)],  # Primeiro nome do titular
                "circles": [
                    (440, 72, 705, 152, 1, "pill", "bl"),     # Buscar, QR Code e editar nome
                    (25, 195, 500, 445, 2, "pill", "tr"),     # Pagamentos e Assinaturas
                    (25, 475, 675, 610, 3, "pill", "tr"),     # Dispositivos conectados
                    (25, 635, 685, 980, 4, "pill", "tr"),     # Conta e Privacidade
                    (25, 1015, 695, 1470, 5, "pill", "tr"),   # Listas, Conversas e Aparência
                ],
            },
            # Passo 4: Configurações (parte 2)
            {
                "file": "WhatsApp Image 2026-11-09 at 14.25.22.jpeg",
                "top_crop": 58,
                "blur": [(95, 75, 330, 155)],  # Primeiro nome do titular
                "circles": [
                    (25, 195, 675, 465, 1, "pill", "tr"),     # Listas de transmissão e Notificações
                    (25, 490, 685, 615, 2, "pill", "tr"),     # Armazenamento e dados
                    (25, 645, 690, 935, 3, "pill", "tr"),     # Controle parental e Acessibilidade
                    (25, 960, 695, 1380, 4, "pill", "tr"),    # Idioma do app, Ajuda e feedback, Convidar
                ],
            },
        ],
    },
    "telegram": {
        "orig_dir": "Telegram",
        "steps": [
            # Passo 1: Tela inicial de Chats
            {
                "file": "WhatsApp Image 2026-11-09 at 14.25.20.jpeg",
                "top_crop": 58,
                "blur": [
                    (15, 390, 710, 1135),  # Lista de conversas/grupos
                    (15, 1135, 575, 1365), # Conversas inferiores à esquerda dos botões
                    (15, 1500, 705, 1600), # Linha translucida sob a barra Android
                    (592, 1388, 648, 1442),# Mini avatar Perfil
                ],
                "circles": [
                    (20, 170, 700, 260, 1, "pill", "tr"),     # Buscar Chats
                    (20, 280, 700, 385, 2, "pill", "tr"),     # Cartão de aniversário / avisos no topo
                    (575, 1130, 695, 1360, 3, "pill", "tl"),  # Câmera rápida e Novo chat (+)
                    (25, 1375, 695, 1485, 4, "pill", "tl"),   # Barra Chats, Contatos, Configurações, Perfil
                ],
            },
            # Passo 2: Contatos
            {
                "file": "WhatsApp Image 2026-11-09 at 14.25.20 (3).jpeg",
                "top_crop": 58,
                "blur": [(592, 1388, 648, 1442)],  # Mini avatar Perfil
                "circles": [
                    (610, 68, 705, 160, 1, "ellipse", "bl"),  # Lupa de busca
                    (180, 905, 540, 1020, 2, "pill", "tr"),   # Botão Novo Contato
                    (185, 1375, 345, 1485, 3, "pill", "tl"),  # Aba Contatos ativa
                ],
            },
            # Passo 3: Nova Mensagem
            {
                "file": "WhatsApp Image 2026-11-09 at 14.25.20 (1).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (18, 68, 705, 162, 1, "pill", "bl"),      # Voltar, título Nova Mensagem e Buscar
                    (25, 180, 560, 385, 2, "pill", "tr"),     # Novo Grupo e Novo Canal
                    (180, 1140, 540, 1255, 3, "pill", "tr"),  # Botão Novo Contato
                ],
            },
            # Passo 4: Formulário Novo Contato
            {
                "file": "WhatsApp Image 2026-11-09 at 14.25.20 (2).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (25, 125, 695, 385, 1, "pill", "tr"),     # Nome (obrigatório) e Sobrenome
                    (25, 415, 695, 530, 2, "pill", "tr"),     # DDI +55 e Número de telefone
                    (40, 545, 580, 690, 3, "pill", "tr"),     # Sincronizar com o celular
                    (25, 780, 695, 895, 4, "pill", "tr"),     # Botão Criar Contato
                ],
            },
            # Passo 5: Seu Perfil
            {
                "file": "WhatsApp Image 2026-11-09 at 14.25.21 (3).jpeg",
                "top_crop": 58,
                "blur": [
                    (255, 115, 460, 315),   # Foto grande
                    (190, 325, 530, 400),   # Nome completo do titular
                    (40, 635, 390, 700),    # Telefone pessoal do titular
                    (592, 1388, 648, 1442), # Mini avatar
                ],
                "circles": [
                    (18, 70, 705, 162, 1, "pill", "bl"),      # Código QR e Menu 3 pontinhos
                    (20, 465, 695, 590, 2, "pill", "tr"),     # Definir Foto, Editar Informações e Configurações
                    (20, 610, 695, 740, 3, "pill", "tr"),     # Telefone cadastrado
                    (165, 1265, 555, 1360, 4, "pill", "tr"),  # Botão Adicione um post
                ],
            },
            # Passo 6: Configurações (topo)
            {
                "file": "WhatsApp Image 2026-11-09 at 14.25.21.jpeg",
                "top_crop": 58,
                "blur": [
                    (255, 115, 460, 315),   # Avatar
                    (200, 312, 520, 372),   # Nome completo do titular
                    (210, 372, 510, 440),   # Telefone
                    (95, 480, 420, 535),    # Telefone na pergunta de confirmação
                    (592, 1388, 648, 1442), # Mini avatar
                ],
                "keep": [(388, 242, 462, 316)],
                "circles": [
                    (385, 240, 468, 320, 1, "ellipse", "tr"), # Botão câmera da foto de perfil
                    (40, 695, 680, 815, 2, "pill", "tr"),     # Confirmar número (Não / Sim)
                    (25, 865, 685, 1105, 3, "pill", "tr"),    # Conta e Configurações de Chat
                    (25, 1110, 685, 1365, 4, "pill", "tr"),   # Privacidade e Segurança / Notificações
                ],
            },
            # Passo 7: Configurações (opções)
            {
                "file": "WhatsApp Image 2026-11-09 at 14.25.21 (1).jpeg",
                "top_crop": 58,
                "blur": [(592, 1388, 648, 1442)],
                "circles": [
                    (18, 68, 705, 158, 1, "pill", "bl"),      # QR Code, título Configurações, Buscar e menu
                    (25, 165, 695, 485, 2, "pill", "tr"),     # Chat, Privacidade e Notificações
                    (25, 495, 695, 755, 3, "pill", "tr"),     # Dados e Armazenamento / Pastas de Chat
                    (25, 765, 695, 1090, 4, "pill", "tr"),    # Dispositivos, Economia de Energia e Idioma
                ],
            },
            # Passo 8: Configurações (recursos e Ajuda)
            {
                "file": "WhatsApp Image 2026-11-09 at 14.25.21 (2).jpeg",
                "top_crop": 58,
                "blur": [(592, 1388, 648, 1442)],
                "circles": [
                    (25, 330, 695, 740, 1, "pill", "tr"),     # Telegram Premium, Estrelas, Business, Presente
                    (25, 770, 695, 965, 2, "pill", "tr"),     # Ajuda -> Fazer uma Pergunta
                    (25, 975, 695, 1255, 3, "pill", "tr"),    # Perguntas Frequentes, Recursos e Privacidade
                ],
            },
        ],
    },
    "facebook": {
        "orig_dir": "FACE",
        "steps": [
            # Passo 1: Feed Principal
            {
                "file": "WhatsApp Image 2026-11-10 at 14.33.34.jpeg",
                "top_crop": 58,
                "blur": [(18, 808, 355, 902)],  # Avatar e nome Gabriela Guimarães no post
                "circles": [
                    (445, 72, 710, 152, 1, "pill", "bl"),     # Botões +, Buscar e Messenger
                    (15, 158, 705, 232, 2, "pill", "tl"),     # Abas Início, Reels, Amigos, Marketplace, Sino, Perfil
                    (105, 240, 705, 345, 3, "pill", "tr"),    # Campo "No que você está pensando?" e foto
                    (12, 368, 225, 765, 4, "pill", "tr"),     # Cartão Criar story
                ],
            },
            # Passo 2: Vídeos Curtos (Reels)
            {
                "file": "WhatsApp Image 2026-11-10 at 14.33.34 (4).jpeg",
                "top_crop": 58,
                "blur": [(145, 1142, 575, 1245)],  # Termo ofensivo na legenda do vídeo
                "circles": [
                    (125, 72, 705, 150, 1, "pill", "bl"),     # Aba Reels selecionada / Buscar / Messenger
                    (55, 168, 695, 255, 2, "pill", "tr"),     # Título Reels e menu
                    (610, 910, 712, 1445, 3, "pill", "tl"),   # Botões Curtir, Comentar, Compartilhar e Salvar
                    (15, 1275, 570, 1385, 4, "pill", "tr"),   # Canal e botão Seguir
                ],
            },
            # Passo 3: Marketplace
            {
                "file": "WhatsApp Image 2026-11-10 at 14.33.34 (3).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (525, 158, 705, 232, 1, "pill", "bl"),    # Lupa de busca e opções do Marketplace
                    (12, 238, 708, 320, 2, "pill", "tr"),     # Abas Vender, Explorar, Local, Mais e pino de localização
                    (12, 330, 708, 765, 3, "pill", "tr"),     # Anúncios com foto, preço e título
                ],
            },
            # Passo 4: Amigos e Solicitações
            {
                "file": "WhatsApp Image 2026-11-10 at 14.33.34 (2).jpeg",
                "top_crop": 58,
                "blur": [
                    (20, 435, 210, 625), (225, 435, 625, 490),   # Pedido 1
                    (20, 650, 210, 840), (225, 650, 470, 705), (225, 745, 278, 785),  # Pedido 2
                    (20, 895, 215, 1085), (225, 895, 620, 955), (225, 985, 315, 1035), # Pedido 3
                    (20, 1140, 215, 1340), (225, 1150, 520, 1210), # Pedido 4
                ],
                "circles": [
                    (240, 72, 345, 145, 1, "ellipse", "bl"),  # Aba Amigos selecionada
                    (12, 235, 465, 315, 2, "pill", "tr"),     # Botões Sugestões e Seus amigos
                    (218, 520, 705, 605, 3, "pill", "tr"),    # Botões Confirmar e Excluir pedido
                ],
            },
            # Passo 5: Notificações
            {
                "file": "WhatsApp Image 2026-11-10 at 14.33.34 (5).jpeg",
                "top_crop": 58,
                "blur": [
                    (20, 325, 162, 460),
                    (20, 480, 162, 615), (170, 485, 625, 615), # Comentário pessoal ("Muito obrigado vô")
                    (20, 640, 162, 775),
                    (20, 800, 162, 935),
                    (20, 960, 162, 1095),
                    (20, 1120, 162, 1255),
                ],
                "circles": [
                    (485, 72, 585, 145, 1, "ellipse", "bl"),  # Aba Notificações (sininho)
                    (610, 160, 705, 232, 2, "ellipse", "bl"), # Lupa de pesquisa
                    (12, 315, 625, 470, 3, "pill", "tr"),     # Item de notificação recente
                    (628, 330, 705, 410, 4, "ellipse", "bl"), # Opções (...) da notificação
                ],
            },
            # Passo 6: Menu de Atalhos
            {
                "file": "WhatsApp Image 2026-11-10 at 14.33.34 (1).jpeg",
                "top_crop": 58,
                "blur": [
                    (145, 115, 425, 180),  # Nome completo do titular
                    (640, 615, 720, 720),  # Mini foto lateral no feed de fundo
                ],
                "circles": [
                    (18, 95, 590, 305, 1, "pill", "tr"),      # Seu perfil no topo e Criar Página
                    (18, 355, 580, 845, 2, "pill", "tr"),     # Meta AI, Salvos, Lembranças, Marketplace, Namoro
                    (18, 865, 600, 1185, 3, "pill", "tr"),    # Ver mais, Ajuda e suporte, Configurações e privacidade
                ],
            },
            # Passo 7: Configurações e Privacidade
            {
                "file": "WhatsApp Image 2026-11-10 at 14.33.34 (7).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (15, 85, 605, 265, 1, "pill", "tr"),      # Configurações e Privacidade -> Configurações
                    (15, 270, 580, 470, 2, "pill", "tr"),     # Central de Privacidade e Solicitações de dispositivos
                    (15, 480, 580, 820, 3, "pill", "tr"),     # Atividade de anúncios, Pedidos/pagamentos, Histórico
                    (15, 880, 600, 1295, 4, "pill", "tr"),    # Atualizações e recursos Meta
                ],
            },
            # Passo 8: Página de Perfil
            {
                "file": "WhatsApp Image 2026-11-10 at 14.33.34 (6).jpeg",
                "top_crop": 58,
                "blur": [
                    (165, 700, 560, 775),   # Nome completo do titular
                    (10, 1365, 710, 1500),  # Sugestões embaixo com telefone comercial
                ],
                "circles": [
                    (465, 165, 705, 245, 1, "pill", "bl"),    # Editar, Pesquisar e Mais opções (...)
                    (425, 540, 512, 628, 2, "ellipse", "tr"), # Botão câmera na foto de perfil
                    (20, 825, 695, 920, 3, "pill", "tr"),     # Botões Adicionar ao story e Editar perfil
                    (20, 960, 700, 1285, 4, "pill", "tr"),    # Cartão Atualizar seu perfil
                ],
            },
            # Passo 9: Editar Perfil (Apresentação e Dados)
            {
                "file": "WhatsApp Image 2026-11-10 at 14.33.34 (8).jpeg",
                "top_crop": 58,
                "blur": [
                    (85, 1020, 470, 1080),  # Data de nascimento
                    (85, 1295, 275, 1350),  # Gênero
                ],
                "circles": [
                    (425, 360, 512, 445, 1, "ellipse", "tr"), # Câmera para trocar foto de perfil/capa
                    (18, 495, 705, 730, 2, "pill", "tr"),     # Apresentação (Sobre você / Detalhes fixados)
                    (18, 770, 705, 1450, 3, "pill", "tr"),    # Dados pessoais (Cidade, aniversário, família, lápis editar)
                ],
            },
            # Passo 10: Editar Perfil (Trabalho, Educação e Interesses)
            {
                "file": "WhatsApp Image 2026-11-10 at 14.33.34 (9).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (18, 125, 705, 480, 1, "pill", "tr"),     # Trabalho e Educação
                    (18, 495, 705, 1170, 2, "pill", "tr"),    # Hobbies e Interesses (Músicas, TV, Filmes, Jogos)
                    (18, 1190, 705, 1480, 3, "pill", "tr"),   # Viagem e Links
                ],
            },
        ],
    },
    "correios": {
        "orig_dir": "Correios",
        "steps": [
            # Passo 1: Home Correios
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.09 (2).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (10, 200, 105, 285, 1, "ellipse", "br"),  # Menu de três tracinhos
                    (520, 195, 705, 285, 2, "pill", "bl"),    # Botões Entrar e Lupa de busca
                    (12, 1005, 705, 1265, 3, "pill", "tl"),   # Área Acompanhe seu Objeto e campo de código
                ],
            },
            # Passo 2: Campo Acompanhe seu Objeto com teclado
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.09 (4).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (180, 520, 685, 650, 1, "pill", "tr"),    # Campo para digitar o código ou CPF
                    (595, 540, 675, 625, 2, "ellipse", "tl"), # Botão de Lupa para pesquisar
                    (20, 710, 700, 915, 3, "pill", "tr"),     # Atalhos Preços, Comprar, App e Busca CEP
                ],
            },
            # Passo 3: Formulário Rastreamento com código de imagem (1046x426)
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.09.jpeg",
                "top_crop": 0,
                "blur": [],
                "circles": [
                    (155, 168, 305, 232, 1, "pill", "tl"),    # Campo CPF/CNPJ ou código de rastreamento
                    (158, 258, 515, 395, 2, "pill", "tl"),    # Código da imagem + áudio e recarregar
                    (555, 280, 965, 342, 3, "pill", "tl"),    # Campo "Digite o texto contido na imagem"
                    (705, 338, 810, 385, 4, "pill", "tr"),    # Botão azul Consultar
                ],
            },
            # Passo 4: Linha do tempo da entrega (675x863)
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.09 (1).jpeg",
                "top_crop": 0,
                "blur": [(198, 100, 365, 148)],  # Fortalecer blur no código de rastreamento
                "circles": [
                    (72, 85, 470, 195, 1, "pill", "tr"),      # Código de rastreio e data da última atualização
                    (110, 215, 615, 330, 2, "pill", "tr"),    # Etapa mais recente no topo (Entregue)
                    (100, 335, 655, 830, 3, "pill", "tr"),    # Histórico completo das movimentações anteriores
                ],
            },
            # Passo 5: Menu aberto
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.09 (3).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (25, 305, 535, 585, 1, "pill", "tr"),     # Enviar, Receber e Comprar
                    (25, 595, 535, 855, 2, "pill", "tr"),     # Logística, Atendimento e Acesso à Informação
                    (180, 1125, 685, 1235, 3, "pill", "tr"),  # Campo Acompanhe seu Objeto abaixo do menu
                ],
            },
            # Passo 6: Simulador de Preços e Prazos
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.09 (5).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (20, 600, 700, 740, 1, "pill", "tr"),     # Campos CEP de Origem e Destino
                    (115, 760, 700, 1020, 2, "pill", "tr"),   # Medidas da caixa: Altura, Largura e Comprimento
                    (125, 1045, 590, 1150, 3, "pill", "tr"),  # Botão azul Calcular Frete
                ],
            },
            # Passo 7: Menu lateral do Rastreamento
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.09 (6).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (20, 300, 580, 460, 1, "pill", "tr"),     # Rastreamento e botão Entrar
                    (20, 480, 580, 725, 2, "pill", "tr"),     # Rastreamento em outros países, Dúvidas e Busca Agências
                    (20, 735, 580, 1085, 3, "pill", "tr"),    # Central de Atendimento, Prazos e Restrição por CEP
                ],
            },
            # Passo 8: Login Meu Correios
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.09 (7).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (75, 620, 640, 825, 1, "pill", "tr"),     # Instrução: informe CPF/CNPJ sem pontos
                    (55, 845, 660, 945, 2, "pill", "tr"),     # Botão azul Entrar
                    (75, 965, 635, 1145, 3, "pill", "tr"),    # Esqueci minha senha, Cadastrar e Fale conosco
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
                    (18, 155, 175, 225, 1, "pill", "br"),     # Botão Menu no alto à esquerda
                    (525, 155, 695, 225, 2, "pill", "bl"),    # Botão Entrar no alto à direita
                    (55, 1345, 665, 1455, 3, "pill", "tr"),   # Botão rosa "Consultar CPF grátis"
                ],
            },
            # Passo 2: Feirão e App oficial (inspect 28)
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.36.jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (20, 72, 695, 210, 1, "pill", "bl"),      # Banner do aplicativo oficial Serasa (Fechar / Baixar)
                    (75, 285, 645, 480, 2, "pill", "tr"),     # Aviso do Feirão Limpa Nome
                    (55, 1345, 665, 1455, 3, "pill", "tr"),   # Botão "Consultar CPF grátis"
                ],
            },
            # Passo 3: Menu lateral de produtos (inspect 01)
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.36 (2).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (40, 72, 225, 145, 1, "pill", "br"),      # Botão Fechar (X)
                    (65, 170, 690, 265, 2, "pill", "tr"),     # Botões Cadastrar e Entrar
                    (20, 275, 690, 765, 3, "pill", "tr"),     # Blog, Ajuda e Canal de Denúncias
                    (20, 795, 680, 1465, 4, "pill", "tr"),    # Lista de Produtos (Crédito, Limpa Nome, Score, Carteira)
                ],
            },
            # Passo 4: Tela inicial autenticada (inspect 03)
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.36 (4).jpeg",
                "top_crop": 58,
                "blur": [
                    (560, 185, 625, 248),  # Iniciais do titular
                    (115, 315, 280, 365),  # Primeiro nome do titular
                ],
                "circles": [
                    (440, 165, 685, 265, 1, "pill", "bl"),    # Troféu de conquistas e menu da conta
                    (55, 790, 370, 895, 2, "pill", "tr"),     # Botão Conectar contas
                    (50, 995, 690, 1210, 3, "pill", "tr"),    # Atalhos Cartão, Consultas CPF e Empréstimo
                    (18, 1280, 702, 1390, 4, "pill", "tl"),   # Barra inferior: Início, Finanças, Meu CPF, Dívidas, Serviços
                ],
            },
            # Passo 5: Cartão Serasa Score na home (inspect 07)
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.36 (8).jpeg",
                "top_crop": 58,
                "blur": [(60, 245, 230, 360)],  # Número do Score pessoal
                "circles": [
                    (45, 185, 675, 435, 1, "pill", "tr"),     # Pontuação Serasa Score e faixa de avaliação
                    (45, 470, 675, 745, 2, "pill", "tr"),     # Botão Conecte suas contas para melhorar análise
                    (35, 770, 685, 920, 3, "pill", "tr"),     # Indicador Serasa Score bloqueado/desbloqueado
                ],
            },
            # Passo 6: Aba Finanças > Seu Serasa Score (inspect 08)
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.36 (9).jpeg",
                "top_crop": 58,
                "blur": [
                    (560, 62, 625, 125),  # Iniciais do titular
                    (85, 320, 265, 425),  # Score pessoal
                ],
                "circles": [
                    (45, 285, 670, 690, 1, "pill", "tr"),     # Nota detalhada, motivo e evolução do Score
                    (75, 1110, 645, 1205, 2, "pill", "tr"),   # Botão Ir para Minhas Contas
                    (145, 1355, 295, 1480, 3, "ellipse", "tl"), # Aba Finanças ativa embaixo
                ],
            },
            # Passo 7: Score rolado - variações e contas conectadas (inspect 09)
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.36 (10).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (30, 560, 690, 865, 1, "pill", "tr"),     # Plano Premium opcional (Assinar agora)
                    (35, 935, 685, 1085, 2, "pill", "tr"),    # Variações na pontuação
                    (35, 1110, 685, 1265, 3, "pill", "tr"),   # Contas conectadas
                ],
            },
            # Passo 8: Alertas do Score e monitoramento (inspect 17)
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.36 (18).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (55, 440, 665, 780, 1, "pill", "tr"),     # Botão Receber alertas do Score
                    (55, 815, 665, 1065, 2, "pill", "tr"),    # Empresas em seu nome e Consulta de Identidade
                    (55, 1080, 665, 1315, 3, "pill", "tr"),   # Consultas em seu nome e Vazamento de dados
                ],
            },
            # Passo 9: Seu nome está limpo (inspect 11)
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.36 (12).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (40, 270, 680, 565, 1, "pill", "tr"),     # Cartão Seu nome está limpo + botão Ver meu CPF
                    (40, 600, 680, 1090, 2, "pill", "tr"),    # Cartão Monitoramento de dados (CPF e Score)
                    (440, 1360, 575, 1480, 3, "ellipse", "tl"), # Aba Dívidas no rodapé
                ],
            },
            # Passo 10: Aba Minhas Dívidas - Ofertas e Acordos (inspect 19)
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.36 (20).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (20, 445, 700, 575, 1, "pill", "tr"),     # Abas Ofertas e Acordos
                    (25, 735, 695, 885, 2, "pill", "tr"),     # Filtros Em andamento, Quitados e Vencidos
                    (40, 965, 680, 1265, 3, "pill", "tr"),    # Área com acordos ativos pela Serasa
                ],
            },
            # Passo 11: Lista de acordos por situação (inspect 20)
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.36 (21).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (65, 110, 650, 635, 1, "pill", "tr"),     # Acordos com a empresa parceira
                    (65, 765, 620, 1030, 2, "pill", "tr"),    # Acordos já quitados
                    (65, 1170, 650, 1505, 3, "pill", "tr"),   # Acordos vencidos ou cancelados
                ],
            },
            # Passo 12: Aba Serviços > Dívidas e pendências (inspect 21)
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.36 (22).jpeg",
                "top_crop": 58,
                "blur": [(560, 62, 625, 125)],  # Iniciais do titular
                "circles": [
                    (50, 515, 670, 780, 1, "pill", "tr"),     # Dívidas negativadas
                    (50, 800, 670, 1070, 2, "pill", "tr"),    # Meus acordos
                    (50, 1090, 670, 1345, 3, "pill", "tr"),   # Propostas e ofertas
                    (575, 1360, 708, 1480, 4, "ellipse", "tl"), # Aba Serviços ativa
                ],
            },
            # Passo 13: Aba Meu CPF topo (inspect 12)
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.36 (13).jpeg",
                "top_crop": 58,
                "blur": [
                    (560, 62, 625, 120),  # Iniciais do titular
                    (115, 895, 275, 945), # Primeiro nome do titular
                ],
                "circles": [
                    (20, 195, 670, 345, 1, "pill", "tr"),     # Área Meu CPF
                    (25, 420, 695, 805, 2, "pill", "tr"),     # Proteção Premium opcional
                    (25, 860, 695, 1320, 3, "pill", "tr"),    # Atalho para extrato veicular e Premium
                    (295, 1360, 425, 1485, 4, "ellipse", "tl"), # Botão central Meu CPF
                ],
            },
            # Passo 14: Saúde financeira gratuita (inspect 13)
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.36 (14).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (510, 105, 675, 180, 1, "pill", "bl"),    # Selo Gratuito
                    (35, 245, 685, 575, 2, "pill", "tr"),     # Dívidas e pendências / Extrato Serasa
                    (35, 585, 685, 895, 3, "pill", "tr"),     # Vazamento de dados e Documentos extraviados
                ],
            },
            # Passo 15: Selo de segurança e Serasa Recomenda (inspect 14)
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.36 (15).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (50, 245, 670, 415, 1, "pill", "tr"),     # Selo de segurança atual da conta
                    (50, 635, 670, 995, 2, "pill", "tr"),     # Serviço Serasa Recomenda (Solicitar análise)
                ],
            },
            # Passo 16: Dark Web e Extrato Veicular (inspect 15)
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.36 (16).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (50, 75, 670, 395, 1, "pill", "br"),      # Consultas e Dark Web (Solicitar relatório)
                    (50, 430, 670, 755, 2, "pill", "tr"),     # Assistência 24h para carro
                    (50, 795, 670, 1140, 3, "pill", "tr"),    # Extrato Veicular (Consultar veículo)
                ],
            },
            # Passo 17: Educação financeira e Consulta Terceiros (inspect 16)
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.36 (17).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (50, 68, 670, 385, 1, "pill", "br"),      # Organize seus gastos (Organizze)
                    (50, 410, 670, 755, 2, "pill", "tr"),     # Cursos de educação financeira
                    (50, 785, 670, 1135, 3, "pill", "tr"),    # Consulta Terceiros Básica (CPF/CNPJ)
                ],
            },
            # Passo 18: Crédito e Empréstimos (inspect 06)
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.36 (7).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (20, 70, 695, 955, 1, "pill", "br"),      # Área Empréstimos e Cartões
                    (25, 1085, 420, 1345, 2, "pill", "tr"),   # Cartão Empréstimo fácil
                ],
            },
            # Passo 19: Bloqueio de consultas e Cadastro Positivo (inspect 10)
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.36 (11).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (35, 70, 685, 180, 1, "pill", "br"),      # Bloqueio de consultas
                    (35, 200, 685, 365, 2, "pill", "tr"),     # Cadastro Positivo
                    (35, 665, 685, 1190, 3, "pill", "tr"),    # Opções selecionadas para tranquilidade financeira
                ],
            },
            # Passo 20: Extrato Serasa e Bloquear Score (inspect 22)
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.36 (23).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (50, 75, 670, 325, 1, "pill", "br"),      # Pendências CPF/CNPJ
                    (50, 355, 670, 600, 2, "pill", "tr"),     # Extrato Serasa
                    (50, 795, 670, 1060, 3, "pill", "tr"),    # Bloquear Score (Premium)
                    (50, 1080, 670, 1340, 4, "pill", "tr"),   # Variações do Score
                ],
            },
            # Passo 21: Proteção de dados e Acompanhar pedidos (inspect 25)
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.36 (26).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (50, 70, 670, 305, 1, "pill", "br"),      # Proteção de dados
                    (50, 340, 670, 600, 2, "pill", "tr"),     # Cadastro Positivo
                    (50, 790, 670, 1055, 3, "pill", "tr"),    # Crédito -> Cartões e empréstimos
                    (50, 1075, 670, 1340, 4, "pill", "tr"),   # Acompanhar meus pedidos
                ],
            },
            # Passo 22: Validador de boleto e Central de Ajuda (inspect 26)
            {
                "file": "WhatsApp Image 2026-11-11 at 18.53.36 (27).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (40, 150, 680, 645, 1, "pill", "tr"),     # Meu perfil, Conectar contas e Histórico de cartões
                    (40, 665, 680, 845, 2, "pill", "tr"),     # Validador de boleto
                    (40, 865, 680, 1215, 3, "pill", "tr"),    # Atualização cadastral e Central de Ajuda
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
                    (115, 175, 470, 248, 1, "pill", "tl"),    # Atalhos gov.br
                    (475, 175, 695, 250, 2, "pill", "bl"),    # Botão azul Entrar
                    (20, 390, 700, 520, 3, "pill", "tr"),     # Barra de pesquisa + microfone e lupa
                    (25, 795, 695, 1465, 4, "pill", "tr"),    # Lista Mais Acessados (1 a 5)
                ],
            },
            # Passo 2: Identifique-se com CPF (inspect 34)
            {
                "file": "WhatsApp Image 2026-11-13 at 10.54.39 (35).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (35, 645, 685, 745, 1, "pill", "tr"),     # Campo para digitar o CPF
                    (35, 790, 685, 885, 2, "pill", "tr"),     # Botão azul Continuar
                    (35, 985, 685, 1345, 3, "pill", "tr"),    # Outras opções: Banco, App gov.br, Certificado
                ],
            },
            # Passo 3: Digite sua senha - BLUR CPF REAL (inspect 35)
            {
                "file": "WhatsApp Image 2026-11-13 at 10.54.39 (36).jpeg",
                "top_crop": 58,
                "blur": [(32, 478, 275, 535)],  # CPF XXX.XXX.XXX-XX
                "circles": [
                    (35, 608, 685, 710, 1, "pill", "tr"),     # Campo de senha + ícone de olho para conferir
                    (35, 750, 685, 840, 2, "pill", "tr"),     # Botão azul Entrar
                    (35, 860, 685, 1085, 3, "pill", "tr"),    # Cancelar e "Esqueci minha senha"
                ],
            },
            # Passo 4: Conta logada - BLUR NOME REAL (inspect 36)
            {
                "file": "WhatsApp Image 2026-11-13 at 10.54.39 (37).jpeg",
                "top_crop": 58,
                "blur": [(155, 482, 565, 538)],  # NOME COMPLETO DO TITULAR
                "circles": [
                    (250, 382, 475, 480, 1, "pill", "tr"),    # Nível da conta (Conta Prata)
                    (135, 540, 585, 625, 2, "pill", "tr"),    # Botão Minha área gov.br
                    (18, 650, 700, 1225, 3, "pill", "tr"),    # Dados Pessoais, Segurança da Conta, Ajuda e Sair
                ],
            },
            # Passo 5: Minha área gov.br - BLUR NOME REAL (inspect 38)
            {
                "file": "WhatsApp Image 2026-11-13 at 10.54.39 (39).jpeg",
                "top_crop": 58,
                "blur": [(175, 220, 660, 340)],  # Olá, NOME COMPLETO DO TITULAR
                "circles": [
                    (395, 520, 700, 625, 1, "pill", "tl"),    # Botão Aumentar Nível
                    (18, 975, 700, 1245, 2, "pill", "tr"),    # Caixa postal e Carteira de documentos
                    (18, 1255, 700, 1465, 3, "pill", "tr"),   # Baixar certidões, Dados de contato e Assinar
                ],
            },
            # Passo 6: Painel Olá! e menu lateral (inspect 11)
            {
                "file": "WhatsApp Image 2026-11-13 at 10.54.39 (12).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (8, 175, 118, 725, 1, "pill", "tr"),      # Menu lateral esquerdo (Início, Agenda, Certidões, Apps)
                    (165, 485, 595, 765, 2, "pill", "tr"),    # Agenda gov.br e Assinar documentos
                    (165, 770, 600, 1020, 3, "pill", "tr"),   # Baixar certidões e Caixa Postal
                ],
            },
            # Passo 7: Grade de serviços gov.br rolada (inspect 12)
            {
                "file": "WhatsApp Image 2026-11-13 at 10.54.39 (13).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (135, 175, 605, 415, 1, "pill", "tr"),    # Carteira de Documentos e Dados Pessoais
                    (135, 435, 605, 715, 2, "pill", "tr"),    # Gerenciar dados de contato e Govinho
                    (135, 745, 605, 1225, 3, "pill", "tr"),   # Notificações, Privacidade, Procurações e Segurança
                ],
            },
            # Passo 8: Lista Minha conta (inspect 37)
            {
                "file": "WhatsApp Image 2026-11-13 at 10.54.39 (38).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (18, 75, 700, 565, 1, "pill", "br"),      # Documentos, certidões, assinaturas e serviços
                    (18, 575, 700, 775, 2, "pill", "tr"),     # Agenda GOV.BR, Notificações e Ajuda
                    (18, 965, 700, 1345, 3, "pill", "tr"),    # Minha conta: Dados Pessoais, Segurança e Privacidade
                ],
            },
            # Passo 9: Agenda gov.br (inspect 13)
            {
                "file": "WhatsApp Image 2026-11-13 at 10.54.39 (14).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (145, 265, 695, 355, 1, "pill", "tr"),    # Navegação de mês (< >)
                    (145, 435, 695, 785, 2, "pill", "tr"),    # Prazos e datas destacadas
                    (245, 1365, 595, 1455, 3, "pill", "tr"),  # Botão Ver Agenda completa
                ],
            },
            # Passo 10: Certidões - parte 1 (inspect 14)
            {
                "file": "WhatsApp Image 2026-11-13 at 10.54.39 (15).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (150, 235, 620, 520, 1, "pill", "tr"),    # Cartão Nacional de Saúde e Vacinação
                    (150, 555, 620, 825, 2, "pill", "tr"),    # Pessoa com Deficiência e Cadastro Único
                    (150, 865, 620, 1135, 3, "pill", "tr"),   # Quitação Eleitoral e Antecedentes Criminais
                ],
            },
            # Passo 11: Certidões - parte 2 (inspect 15)
            {
                "file": "WhatsApp Image 2026-11-13 at 10.54.39 (16).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (150, 235, 620, 520, 1, "pill", "tr"),    # Consultar CNPJ e Situação Cadastral no CPF
                    (150, 555, 620, 840, 2, "pill", "tr"),    # Certidões de Regularidade Fiscal
                    (150, 1175, 415, 1465, 3, "pill", "tr"),  # Certidão de Contas Julgadas
                ],
            },
            # Passo 12: Destaques do portal (inspect 00)
            {
                "file": "WhatsApp Image 2026-11-13 at 10.54.39 (1).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (40, 315, 680, 410, 1, "pill", "tr"),     # Seção Destaque
                    (40, 620, 680, 965, 2, "pill", "tr"),     # Imposto de Renda e Renegociação de Dívidas
                    (40, 1005, 680, 1300, 3, "pill", "tr"),   # Celular Seguro e Bolsa Família
                ],
            },
            # Passo 13: Perfis Agricultor e Turista (inspect 01)
            {
                "file": "WhatsApp Image 2026-11-13 at 10.54.39 (2).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (75, 255, 315, 575, 1, "pill", "tr"),     # Perfil Agricultor
                    (385, 255, 635, 575, 2, "pill", "tr"),    # Perfil Turista
                    (155, 725, 560, 835, 3, "pill", "tr"),    # Botão Todos os Perfis
                ],
            },
            # Passo 14: Perfis Aposentado e Empreendedor (inspect 02)
            {
                "file": "WhatsApp Image 2026-11-13 at 10.54.39 (3).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (75, 255, 325, 575, 1, "pill", "tr"),     # Perfil Aposentado
                    (385, 255, 665, 575, 2, "pill", "tr"),    # Perfil Empreendedor
                    (155, 725, 560, 835, 3, "pill", "tr"),    # Botão Todos os Perfis
                ],
            },
            # Passo 15: Categorias de A até E (inspect 04)
            {
                "file": "WhatsApp Image 2026-11-13 at 10.54.39 (5).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (35, 185, 685, 425, 1, "pill", "tr"),     # Título Navegue por categoria
                    (35, 440, 685, 995, 2, "pill", "tr"),     # Agricultura, Assistência Social, Ciência, Comunicações
                    (35, 1015, 685, 1465, 3, "pill", "tr"),   # Cultura, Defesa Civil e Educação
                ],
            },
            # Passo 16: Categorias de E até T (inspect 05)
            {
                "file": "WhatsApp Image 2026-11-13 at 10.54.39 (6).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (35, 175, 685, 575, 1, "pill", "tr"),     # Educação, Empresa/Comércio e Energia
                    (35, 600, 685, 1005, 2, "pill", "tr"),    # Finanças, Justiça/Segurança e Meio Ambiente
                    (35, 1030, 685, 1475, 3, "pill", "tr"),   # Saúde, Trabalho/Previdência e Infraestrutura
                ],
            },
            # Passo 17: Banner Aplicativos Oficiais (inspect 07)
            {
                "file": "WhatsApp Image 2026-11-13 at 10.54.39 (8).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (55, 370, 665, 710, 1, "pill", "tr"),     # Apresentação dos aplicativos móveis oficiais
                    (95, 735, 625, 1265, 2, "pill", "tr"),    # Cartão oficial do app gov.br
                ],
            },
            # Passo 18: Galeria de Aplicativos (inspect 20)
            {
                "file": "WhatsApp Image 2026-11-13 at 10.54.39 (21).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (105, 185, 695, 330, 1, "pill", "tr"),    # Atalhos gov.br e Entrar
                    (25, 765, 700, 860, 2, "pill", "tr"),     # Opções Filtrar e Ordenar
                    (130, 885, 585, 1385, 3, "pill", "tr"),   # Cartão oficial (Carteira Digital de Trânsito)
                ],
            },
            # Passo 19: Aplicativos mais acessados (inspect 16)
            {
                "file": "WhatsApp Image 2026-11-13 at 10.54.39 (17).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (155, 205, 620, 470, 1, "pill", "tr"),    # gov.br e Carteira Digital de Trânsito
                    (155, 485, 620, 745, 2, "pill", "tr"),    # Meu INSS e Carteira de Trabalho
                    (155, 765, 620, 1020, 3, "pill", "tr"),   # Cadastro Único e Meu SUS Digital
                    (155, 1055, 620, 1455, 4, "pill", "tr"),  # MEI, Jornada do Estudante e Ver aplicativos
                ],
            },
            # Passo 20: Meu INSS e Cadastro Único (inspect 18)
            {
                "file": "WhatsApp Image 2026-11-13 at 10.54.39 (19).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (135, 195, 595, 835, 1, "pill", "tr"),    # App oficial Meu INSS (benefícios)
                    (135, 875, 595, 1475, 2, "pill", "tr"),   # App oficial Cadastro Único (MDS)
                ],
            },
            # Passo 21: MEI e Carteira de Trabalho Digital (inspect 19)
            {
                "file": "WhatsApp Image 2026-11-13 at 10.54.39 (20).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (135, 195, 595, 835, 1, "pill", "tr"),    # App oficial MEI (Receita Federal)
                    (135, 865, 595, 1465, 2, "pill", "tr"),   # Carteira de Trabalho Digital (MTE)
                ],
            },
            # Passo 22: Desempenho dos Serviços (inspect 06)
            {
                "file": "WhatsApp Image 2026-11-13 at 10.54.39 (7).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (35, 365, 685, 465, 1, "pill", "tr"),     # Título Desempenho dos Serviços
                    (125, 515, 590, 775, 2, "pill", "tr"),    # Total de serviços no portal
                    (125, 845, 590, 1455, 3, "pill", "tr"),   # % Serviços Digitais e Avaliações positivas
                ],
            },
            # Passo 23: Ouvidoria Denúncia e Solicitação (inspect 09)
            {
                "file": "WhatsApp Image 2026-11-13 at 10.54.39 (10).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (40, 585, 675, 1020, 1, "pill", "tr"),    # Cartão Denúncia
                    (40, 1065, 675, 1465, 2, "pill", "tr"),   # Cartão Solicitação
                ],
            },
            # Passo 24: Ouvidoria Elogio, Reclamações e Protocolo (inspect 10)
            {
                "file": "WhatsApp Image 2026-11-13 at 10.54.39 (11).jpeg",
                "top_crop": 58,
                "blur": [],
                "circles": [
                    (40, 160, 675, 610, 1, "pill", "tr"),     # Cartão Elogio
                    (40, 665, 675, 1115, 2, "pill", "tr"),    # Cartão Reclamações
                    (155, 1155, 555, 1285, 3, "pill", "tr"),  # Botão Protocolo GOV.BR
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
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    sheet.save(out_path, "JPEG", quality=88)


def main() -> None:
    os.makedirs(SCRATCH_VERIFY, exist_ok=True)
    blurred_checks: list[tuple[str, Image.Image]] = []

    for chave, cfg in SPECS.items():
        orig_dir = os.path.join(ORIG, cfg["orig_dir"])
        clean_dir = os.path.join(APPS, cfg["orig_dir"])
        out_dir = os.path.join(ASSETS_GUIAS, chave)
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
            if not os.path.exists(src_path):
                raise FileNotFoundError(f"Arquivo original ausente: {src_path}")

            im = Image.open(src_path).convert("RGB")
            if step["blur"]:
                im = apply_blurs(im, step["blur"], step.get("keep"), radius=28)
                blurred_checks.append((f"{chave}_{idx}", im.crop((0, step["top_crop"], im.width, im.height))))

            top_crop = step["top_crop"]
            if top_crop > 0:
                im = im.crop((0, top_crop, im.width, im.height))

            # Clean cropped+blurred copy in apps/<DIR>/
            clean_path = os.path.join(clean_dir, step["file"])
            im.save(clean_path, "JPEG", quality=92, optimize=True)

            # Annotated version for app/assets/guias/<chave>/passo_<n>.jpg
            annotated = draw_annotations(im, step["circles"], top_crop=top_crop)
            dst_path = os.path.join(out_dir, f"passo_{idx}.jpg")
            save_asset_jpg(annotated, dst_path, target_width=480, quality=82)
            verify_imgs.append((idx, Image.open(dst_path)))

        make_contact_sheet(chave, verify_imgs, os.path.join(SCRATCH_VERIFY, f"verify_{chave}.jpg"))
        print(f"[{chave}] {len(cfg['steps'])} passos processados e anotados -> {out_dir}")

    # Sheet of all blurred images (cropped, annotated) for PII double-check
    if blurred_checks:
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
        sheet.save(os.path.join(SCRATCH_VERIFY, "verify_blurs.jpg"), "JPEG", quality=90)
        print(f"Folha de verificacao de blurs ({len(blurred_checks)} imgs) salva.")

    total_bytes = sum(
        os.path.getsize(os.path.join(dp, f))
        for dp, _, filenames in os.walk(ASSETS_GUIAS)
        for f in filenames
    )
    mb = total_bytes / (1024 * 1024)
    print(f"Tamanho total de {ASSETS_GUIAS}: {mb:.2f} MB ({total_bytes} bytes)")
    assert total_bytes <= 8 * 1024 * 1024, f"Excedeu limite de 8 MB: {mb:.2f} MB"


if __name__ == "__main__":
    main()
