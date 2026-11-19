import assert from 'node:assert/strict';
import fs from 'node:fs';
import http from 'node:http';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

const SITE_DIR = path.resolve(import.meta.dirname, '..', '..');
const ORCAMENTO_JS_BYTES = 102_400;

const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.svg': 'image/svg+xml',
  '.png': 'image/png',
  '.webp': 'image/webp',
};

function iniciarServidorEstatico() {
  return new Promise((resolve, reject) => {
    const servidor = http.createServer((req, res) => {
      const urlPath = (req.url || '/').split('?')[0];
      const relativo = urlPath === '/' ? 'index.html' : urlPath.replace(/^\/+/, '');
      const absoluto = path.resolve(SITE_DIR, relativo);

      if (!absoluto.startsWith(SITE_DIR) || !fs.existsSync(absoluto) || fs.statSync(absoluto).isDirectory()) {
        res.writeHead(404);
        res.end('Not found');
        return;
      }

      const ext = path.extname(absoluto).toLowerCase();
      res.writeHead(200, { 'Content-Type': MIME_TYPES[ext] || 'application/octet-stream' });
      fs.createReadStream(absoluto).pipe(res);
    });

    servidor.on('error', reject);
    servidor.listen(0, '127.0.0.1', () => {
      const addr = servidor.address();
      resolve({
        servidor,
        urlBase: `http://127.0.0.1:${addr.port}`,
      });
    });
  });
}

function coletarBytesJsPublicados() {
  let total = 0;
  for (const dirRel of ['scripts', 'vendor']) {
    const dir = path.join(SITE_DIR, dirRel);
    if (!fs.existsSync(dir)) continue;
    for (const nome of fs.readdirSync(dir)) {
      if (nome.endsWith('.js')) {
        total += fs.statSync(path.join(dir, nome)).size;
      }
    }
  }
  const dadosMemora = path.join(SITE_DIR, 'assets', 'memora', 'memora-dados.js');
  if (fs.existsSync(dadosMemora)) {
    total += fs.statSync(dadosMemora).size;
  }
  return total;
}

let servidorHttp;
let urlBase;

test.beforeAll(async () => {
  const iniciado = await iniciarServidorEstatico();
  servidorHttp = iniciado.servidor;
  urlBase = iniciado.urlBase;
});

test.afterAll(async () => {
  if (servidorHttp) {
    await new Promise((resolve) => servidorHttp.close(resolve));
  }
});

test('acessibilidade WCAG 2.2 AA/AAA com axe-core nos 3 temas e zero rede externa', async ({ page }) => {
  const requisicoesExternas = [];
  const errosPagina = [];

  page.on('request', (req) => {
    const u = req.url();
    if (!u.startsWith(urlBase) && !u.startsWith('data:') && !u.startsWith('blob:')) {
      requisicoesExternas.push(u);
    }
  });
  page.on('pageerror', (err) => errosPagina.push(err.message));

  await page.goto(urlBase, { waitUntil: 'load' });
  expect(requisicoesExternas).toEqual([]);
  expect(errosPagina).toEqual([]);

  for (const tema of ['claro', 'escuro', 'alto-contraste']) {
    const botaoTema = page.locator(`[data-acao-tema="${tema}"]`);
    await botaoTema.focus();
    await page.keyboard.press('Enter');
    await expect(page.locator('html')).toHaveAttribute('data-tema', tema);
    await expect(botaoTema).toHaveAttribute('aria-pressed', 'true');
    await expect(botaoTema).toBeFocused();
    await page.evaluate(() =>
      Promise.all(
        document
          .getAnimations()
          .filter((anim) => typeof CSSTransition !== 'undefined' && anim instanceof CSSTransition)
          .map((anim) => anim.finished.catch(() => {}))
      )
    );

    const resultadoAxe = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa', 'wcag22aa'])
      .analyze();

    expect(
      resultadoAxe.violations,
      `Violacoes axe-core no tema ${tema} (com :focus-visible ativo): ${JSON.stringify(resultadoAxe.violations, null, 2)}`
    ).toEqual([]);
  }
});

test('responsivo em 320x568, 390x844 e 768x1024 a 200% e alvos >= 48x48 px', async ({ page }) => {
  for (const largura of [
    { width: 320, height: 568 },
    { width: 390, height: 844 },
    { width: 768, height: 1024 },
  ]) {
    await page.setViewportSize(largura);
    await page.goto(urlBase, { waitUntil: 'load' });

    for (const escala of ['padrao', 'muito-grande']) {
      await page.locator(`[data-acao-escala="${escala}"]`).click();
      await expect(page.locator('html')).toHaveAttribute('data-escala', escala);

      const estouro = await page.evaluate(
        () => document.documentElement.scrollWidth > document.documentElement.clientWidth
      );
      expect(estouro, `Overflow horizontal em ${largura.width}x${largura.height} (${escala})`).toBe(false);
    }
  }

  await page.setViewportSize({ width: 320, height: 568 });
  const metricasAlvos = await page.evaluate(() => {
    const controles = Array.from(
      document.querySelectorAll(
        '.botao-controle, .link-sumario, .duvida-pergunta, .rodape-site .botao-topo, .atalho-topo-fixo .botao-topo'
      )
    );
    let menorLargura = Infinity;
    let menorAltura = Infinity;
    for (const el of controles) {
      const rect = el.getBoundingClientRect();
      if (rect.width === 0 || rect.height === 0) continue;
      menorLargura = Math.min(menorLargura, rect.width);
      menorAltura = Math.min(menorAltura, rect.height);
    }

    let menorEspacamento = Infinity;
    for (const grupo of document.querySelectorAll('.linha-botoes, .sumario-lista, .lista-duvidas')) {
      const itens = Array.from(
        grupo.querySelectorAll('.botao-controle, .link-sumario, .duvida-pergunta')
      ).map((el) => el.getBoundingClientRect());
      for (let i = 0; i < itens.length; i += 1) {
        for (let j = i + 1; j < itens.length; j += 1) {
          const a = itens[i];
          const b = itens[j];
          const dx = Math.max(0, a.left - b.right, b.left - a.right);
          const dy = Math.max(0, a.top - b.bottom, b.top - a.bottom);
          menorEspacamento = Math.min(menorEspacamento, Math.max(dx, dy));
        }
      }
    }
    return { menorLargura, menorAltura, menorEspacamento };
  });

  expect(metricasAlvos.menorLargura).toBeGreaterThanOrEqual(48);
  expect(metricasAlvos.menorAltura).toBeGreaterThanOrEqual(48);
  expect(metricasAlvos.menorEspacamento).toBeGreaterThanOrEqual(7.5);

  const anfitria = page.locator('.anfitria-flutuante');
  await expect(anfitria).toHaveAttribute('data-anfitria-estado', 'recolhida');
  await expect(page.locator('.atalho-topo-fixo')).toBeHidden();

  const posicaoMobile = await anfitria.evaluate((el) => getComputedStyle(el).position);
  expect(posicaoMobile).toBe('static');

  const caixaAlternar = await page.locator('[data-acao-alternar-anfitria]').boundingBox();
  expect(caixaAlternar).not.toBeNull();
  expect(caixaAlternar.width).toBeGreaterThanOrEqual(48);
  expect(caixaAlternar.height).toBeGreaterThanOrEqual(48);

  // Ao expandir a capsula em 320px/200%, opera no fluxo normal com alvos >= 48x48 e zero overflow
  await page.locator('[data-acao-alternar-anfitria]').click();
  await expect(anfitria).toHaveAttribute('data-anfitria-estado', 'expandida');
  await expect(page.locator('[data-acao-alternar-anfitria]')).toHaveAttribute('aria-expanded', 'true');

  const caixaBotaoDica = await page.locator('[data-acao-outra-dica]').boundingBox();
  expect(caixaBotaoDica).not.toBeNull();
  expect(caixaBotaoDica.width).toBeGreaterThanOrEqual(48);
  expect(caixaBotaoDica.height).toBeGreaterThanOrEqual(48);

  const estouroExpandida = await page.evaluate(
    () => document.documentElement.scrollWidth > document.documentElement.clientWidth
  );
  expect(estouroExpandida).toBe(false);

  await page.locator('[data-acao-alternar-anfitria]').click();
  await expect(anfitria).toHaveAttribute('data-anfitria-estado', 'recolhida');
});

test('navegacao por teclado: atalho de salto (#conteudo-principal) e abertura de duvidas por Enter', async ({ page }) => {
  await page.goto(urlBase, { waitUntil: 'load' });

  await page.keyboard.press('Tab');
  const linkSalto = page.locator('.pular-conteudo');
  await expect(linkSalto).toBeFocused();
  await page.keyboard.press('Enter');
  await expect(page.locator('#conteudo-principal')).toBeFocused();

  const primeiraPergunta = page.locator('.duvida-pergunta').first();
  const primeiroDetalhe = page.locator('.duvida-item').first();
  await primeiraPergunta.focus();
  await expect(primeiraPergunta).toBeFocused();
  await page.keyboard.press('Enter');
  await expect(primeiroDetalhe).toHaveAttribute('open', '');
});

test('controle Reduzir movimento respeita prefers-reduced-motion e preferencia manual salva', async ({ page }) => {
  await page.emulateMedia({ reducedMotion: 'reduce' });
  await page.goto(urlBase, { waitUntil: 'load' });

  const botaoMovimento = page.locator('[data-acao-movimento]');
  await expect(page.locator('html')).toHaveAttribute('data-movimento', 'reduzido');
  await expect(botaoMovimento).toHaveAttribute('aria-pressed', 'true');

  // Escolha manual da pessoa prevalece e persiste entre recarregamentos
  await botaoMovimento.click();
  await expect(page.locator('html')).toHaveAttribute('data-movimento', 'normal');
  await expect(botaoMovimento).toHaveAttribute('aria-pressed', 'false');

  await page.reload({ waitUntil: 'load' });
  await expect(page.locator('html')).toHaveAttribute('data-movimento', 'normal');
});

test('abertura local via file:// e orcamento JS <= 102.400 bytes sob CPU 4x', async ({ page, context }) => {
  const bytesJs = coletarBytesJsPublicados();
  assert.ok(bytesJs <= ORCAMENTO_JS_BYTES, `JS total ${bytesJs} > ${ORCAMENTO_JS_BYTES}`);

  const cdp = await context.newCDPSession(page);
  await cdp.send('Emulation.setCPUThrottlingRate', { rate: 4 });

  const errosFile = [];
  page.on('pageerror', (err) => errosFile.push(err.message));

  const urlLocal = pathToFileURL(path.join(SITE_DIR, 'index.html')).href;
  const inicioMs = Date.now();
  await page.goto(urlLocal, { waitUntil: 'domcontentloaded' });
  await page.locator('[data-acao-tema="escuro"]').click();
  const duracaoMs = Date.now() - inicioMs;

  expect(errosFile).toEqual([]);
  await expect(page.locator('html')).toHaveAttribute('data-tema', 'escuro');
  expect(duracaoMs).toBeLessThan(8_000);
});

test('acompanhante global <memora-personagem> fora dos capitulos segue o scroll, muda expressao e recolhe', async ({ page }) => {
  await page.setViewportSize({ width: 1280, height: 800 });
  await page.goto(urlBase, { waitUntil: 'load' });

  const anfitria = page.locator('.anfitria-flutuante');
  await expect(anfitria).toHaveAttribute('data-anfitria-estado', 'expandida');
  const foraDeMain = await page.evaluate(() => {
    const el = document.querySelector('.anfitria-flutuante');
    const main = document.querySelector('main');
    return Boolean(el && el.tagName === 'ASIDE' && main && !main.contains(el));
  });
  expect(foraDeMain).toBe(true);

  const personagens = await page.evaluate(() => {
    const lista = Array.from(document.querySelectorAll('memora-personagem'));
    return lista.map((el) => {
      const svg = el.shadowRoot ? el.shadowRoot.querySelector('svg') : null;
      return {
        expressao: el.getAttribute('expressao'),
        ariaHidden: el.getAttribute('aria-hidden'),
        temShadowRoot: Boolean(el.shadowRoot),
        temSvg: Boolean(svg),
        temCorpo: Boolean(svg && svg.querySelector('#corpo')),
        temCabeca: Boolean(svg && svg.querySelector('#cabeca')),
        temOlhos: Boolean(svg && svg.querySelector('#olhos')),
        temBoca: Boolean(svg && svg.querySelector('#boca')),
      };
    });
  });

  expect(personagens.length).toBeGreaterThanOrEqual(6);
  for (const p of personagens) {
    expect(p.ariaHidden).toBe('true');
    expect(p.temShadowRoot).toBe(true);
    expect(p.temSvg).toBe(true);
    expect(p.temCorpo).toBe(true);
    expect(p.temCabeca).toBe(true);
    expect(p.temOlhos).toBe(true);
    expect(p.temBoca).toBe(true);
  }

  // Ao navegar/rolar para Protecao contra golpes, a anfitria acompanha na tela e muda a expressao
  await page.locator('[data-link-capitulo][href="#protecao-golpes"]').click();
  const personagemGlobal = page.locator('[data-memora-anfitria]');
  await expect(personagemGlobal).toHaveAttribute('expressao', 'preocupada');
  await expect(personagemGlobal).toBeVisible();

  const balao = page.locator('[data-anfitria-balao]');
  const textoInicial = (await balao.innerText()).trim();
  expect(textoInicial.length).toBeGreaterThan(0);

  await page.locator('[data-acao-outra-dica]').click();
  const textoAtualizado = (await balao.innerText()).trim();
  expect(textoAtualizado.length).toBeGreaterThan(0);
  expect(textoAtualizado).not.toBe(textoInicial);

  const anuncio = (await page.locator('#anuncio-acessibilidade').innerText()).trim();
  expect(anuncio).toBe(textoAtualizado);

  // Recolher mantem o personagem visivel na capsula
  await page.locator('[data-acao-alternar-anfitria]').click();
  await expect(anfitria).toHaveAttribute('data-anfitria-estado', 'recolhida');
  await expect(personagemGlobal).toBeVisible();
});

async function coletarSobreposicoesPorPonto(page) {
  return page.evaluate(() => {
    const seletorControles =
      '.botao-controle, .botao-ouvir, .link-sumario, .duvida-pergunta, .botao-topo';
    const vw = document.documentElement.clientWidth;
    const vh = document.documentElement.clientHeight;
    const anfitria = document.querySelector('.anfitria-flutuante');
    const atalhoTopo = document.querySelector('.atalho-topo-fixo');
    const obstrucoes = [];

    for (const el of document.querySelectorAll(seletorControles)) {
      const style = getComputedStyle(el);
      if (style.display === 'none' || style.visibility === 'hidden' || el.closest('[hidden]')) {
        continue;
      }
      const rect = el.getBoundingClientRect();
      if (rect.width <= 0 || rect.height <= 0) {
        continue;
      }

      const insetX = Math.min(10, rect.width / 3);
      const insetY = Math.min(10, rect.height / 3);
      const pontos = [
        ['centro', rect.left + rect.width / 2, rect.top + rect.height / 2],
        ['sup-esq', rect.left + insetX, rect.top + insetY],
        ['sup-dir', rect.right - insetX, rect.top + insetY],
        ['inf-esq', rect.left + insetX, rect.bottom - insetY],
        ['inf-dir', rect.right - insetX, rect.bottom - insetY],
      ];

      for (const [nomePonto, x, y] of pontos) {
        if (x < 2 || x > vw - 2 || y < 2 || y > vh - 2) {
          continue;
        }
        const hit = document.elementFromPoint(x, y);
        const interceptadoPorAnfitria = Boolean(
          anfitria && hit && anfitria.contains(hit) && !anfitria.contains(el)
        );
        const interceptadoPorTopo = Boolean(
          atalhoTopo && hit && atalhoTopo.contains(hit) && !atalhoTopo.contains(el)
        );
        const dentroDoProprioAlvo = Boolean(hit && (el.contains(hit) || hit.contains(el)));

        if (interceptadoPorAnfitria || interceptadoPorTopo || !dentroDoProprioAlvo) {
          obstrucoes.push({
            texto: (el.textContent || '').replace(/\s+/g, ' ').trim(),
            classe: el.className,
            ponto: nomePonto,
            x: Math.round(x),
            y: Math.round(y),
            hitTag: hit ? hit.tagName : null,
            hitClasse: hit ? hit.className : null,
            interceptadoPorAnfitria,
            interceptadoPorTopo,
          });
        }
      }
    }
    return obstrucoes;
  });
}

test('zero sobreposicao de elementos flutuantes sobre controles via elementFromPoint e textos de senha do app', async ({ page }) => {
  await page.goto(urlBase, { waitUntil: 'load' });

  // Alinhamento editorial PR #93 no Capitulo 2 e Capitulo 9
  const textoPrimeirosPassos = await page.locator('#primeiros-passos').innerText();
  const textoDuvidas = await page.locator('#duvidas-frequentes').innerText();
  expect(textoPrimeirosPassos).toContain('Sua senha');
  expect(textoPrimeirosPassos).toContain('Mostrar senha');
  expect(textoPrimeirosPassos).not.toMatch(/Frase Secreta|Mostrar frase|cafe com bolo/i);
  expect(textoDuvidas).toContain('deixe a pessoa criar a senha sozinha, sem olhar');
  expect(textoDuvidas).not.toMatch(/Frase Secreta/i);

  const cenariosViewport = [
    { width: 320, height: 568 },
    { width: 390, height: 844 },
    { width: 1280, height: 800 },
  ];

  for (const viewport of cenariosViewport) {
    await page.setViewportSize(viewport);
    for (const escala of ['padrao', 'muito-grande']) {
      await page.goto(urlBase, { waitUntil: 'load' });
      await page.locator(`[data-acao-escala="${escala}"]`).click();
      await expect(page.locator('html')).toHaveAttribute('data-escala', escala);

      if (viewport.width < 1024 || escala === 'muito-grande') {
        await expect(page.locator('.atalho-topo-fixo')).toBeHidden();
        const pos = await page.locator('.anfitria-flutuante').evaluate((el) => getComputedStyle(el).position);
        expect(pos, `${viewport.width}x${viewport.height} (${escala})`).toBe('static');
      } else {
        await expect(page.locator('.atalho-topo-fixo')).toBeVisible();
        const pos = await page.locator('.anfitria-flutuante').evaluate((el) => getComputedStyle(el).position);
        expect(pos, `${viewport.width}x${viewport.height} (${escala})`).toBe('fixed');
      }

      // Topo da pagina (estado inicial + anfitria expandida manualmente quando aplicavel)
      await page.evaluate(() => window.scrollTo({ top: 0, behavior: 'instant' }));
      expect(
        await coletarSobreposicoesPorPonto(page),
        `Sobreposicao no topo em ${viewport.width}x${viewport.height} (${escala}, inicial)`
      ).toEqual([]);

      const estadoAtual = await page.locator('.anfitria-flutuante').getAttribute('data-anfitria-estado');
      if (estadoAtual !== 'expandida') {
        await page.locator('[data-acao-alternar-anfitria]').click();
        await expect(page.locator('.anfitria-flutuante')).toHaveAttribute('data-anfitria-estado', 'expandida');
      }

      // Rolar por pontos chave (topo, Capitulo 2, Capitulo 9, rodape) mantendo anfitria expandida
      for (const seletorScroll of ['#topo', '#primeiros-passos', '#duvidas-frequentes', '.rodape-site']) {
        await page.locator(seletorScroll).scrollIntoViewIfNeeded();
        expect(
          await coletarSobreposicoesPorPonto(page),
          `Sobreposicao em ${seletorScroll} @ ${viewport.width}x${viewport.height} (${escala}, expandida)`
        ).toEqual([]);
      }
    }
  }
});
