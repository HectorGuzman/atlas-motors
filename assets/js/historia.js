/* Atlas Motors · Historia de una inspección (portada).
   Seis escenas ilustradas en SVG que avanzan solas, como un documental corto:
   ruta → pintura → motor → bajo el auto → escáner → informe.
   Todo es vectorial y local (sin imágenes externas). Expone window.AtlasHistoria. */
(function () {
  'use strict';

  const ESCENAS = [
    ['Vamos donde está el auto', 'Llegamos a la automotora o a la casa del vendedor, en La Serena o Coquimbo.'],
    ['Medimos la pintura, panel por panel', 'Un repintado o un choque escondido se nota en el espesor de la pintura.'],
    ['Revisamos motor y transmisión', 'Con linterna, buscamos fugas, ruidos y señales de una falla grave.'],
    ['Nos metemos bajo el auto', 'Chasis, suspensión, frenos y escape: lo que desde arriba no se ve.'],
    ['Lo conectamos al escáner', 'Leemos cada módulo y revisamos que el kilometraje sea el real.'],
    ['Te entregamos el informe', 'En PDF, con fotos de cada hallazgo y lo que cuesta repararlo.'],
  ];
  const DUR = 6200;

  const ICON = {
    check: '<path d="m5 12.5 4.2 4.2L19 7"/>',
    doc: '<path d="M7 3h7l5 5v13H7z"/><path d="M14 3v5h5M10 13h6M10 17h6"/>',
  };
  const ic = (n) => `<svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${ICON[n]}</svg>`;

  /* ---------- piezas reutilizables ---------- */
  // SUV de perfil, mirando a la derecha. Suelo en y=418.
  const CUERPO = 'M128,352 C126,330 130,312 140,302 L152,272 C156,262 166,256 190,253 L300,246 L456,244 C492,250 526,272 552,294 C590,298 630,300 652,306 C668,312 676,324 676,338 L676,358 C676,367 670,372 660,372 L640,372 A52,52 0 0 0 536,372 L288,372 A52,52 0 0 0 184,372 L142,372 C133,372 128,364 128,352 Z';
  const VIDRIOS = 'M200,260 L352,254 L352,290 L192,290 Z M364,254 L452,252 C482,256 508,270 530,290 L364,290 Z';
  const VIDRIO_TRAS = 'M164,266 L188,262 L182,288 L156,288 Z';

  const rueda = (cx, cy, id = '') => {
    const rayos = [0, 72, 144, 216, 288].map((a) => `<path d="M-4,-8 L-7,-27 L7,-27 L4,-8Z" transform="rotate(${a})"/>`).join('');
    return `<g transform="translate(${cx},${cy})" ${id}>
      <circle r="44" fill="#0a0b0b"/>
      <circle r="40" fill="none" stroke="#1a1d1c" stroke-width="5"/>
      <circle r="30" fill="url(#hLlanta)"/>
      <circle r="21" fill="#2b302d"/><circle r="17" fill="none" stroke="#7d8781" stroke-opacity=".5" stroke-width="1"/>
      <g fill="#a9b3ad">${rayos}</g>
      <circle r="7" fill="#d5dcd8"/><circle r="2.5" fill="#1a1d1c"/>
    </g>`;
  };

  const suv = () => `
    <g class="h-suv">
      <ellipse cx="402" cy="420" rx="300" ry="14" fill="#000" opacity=".55" filter="url(#hBlur)"/>
      <path d="${CUERPO}" fill="url(#hPintura)"/>
      <path d="${CUERPO}" fill="url(#hBrillo)" opacity=".55"/>
      <path d="${VIDRIOS}" fill="url(#hVidrio)"/>
      <path d="${VIDRIO_TRAS}" fill="url(#hVidrio)"/>
      <path d="M244,258 L270,257 L244,289 L218,289Z M412,253 L430,253 L404,289 L386,289Z" fill="#fff" opacity=".07"/>
      <path d="M352,254 L364,254 L364,292 L352,292Z" fill="#101312"/><path d="M196,248 L452,240" stroke="#8a948f" stroke-opacity=".6" stroke-width="3" stroke-linecap="round"/>
      <path d="M150,298 C300,294 500,300 650,310" stroke="#d9e4dd" stroke-opacity=".28" stroke-width="1.5" fill="none"/>
      <path d="M140,324 C320,320 520,326 668,334" stroke="#000" stroke-opacity=".35" stroke-width="2" fill="none"/>
      <path d="M358,292 L360,368 M470,296 L472,368 M250,292 L248,368" stroke="#000" stroke-opacity=".45" stroke-width="1.6" fill="none"/>
      <rect x="320" y="304" width="24" height="5" rx="2.5" fill="#cfd8d2" opacity=".5"/>
      <rect x="432" y="306" width="24" height="5" rx="2.5" fill="#cfd8d2" opacity=".5"/>
      <path d="M520,288 C528,280 544,280 548,290 L540,298 L522,298Z" fill="#141716"/>
      <path d="M640,308 C656,310 668,316 672,326 L650,324 C644,318 640,314 640,308Z" fill="url(#hFaro)"/>
      <path d="M132,268 L146,266 L142,292 L132,292Z" fill="#d84a3a"/>
      <path d="M134,270 L142,269 L139,288 L134,288Z" fill="#ff8f7d" opacity=".7"/>
      <rect x="128" y="346" width="40" height="10" rx="3" fill="#0d0f0e"/>
      <rect x="628" y="350" width="48" height="10" rx="3" fill="#0d0f0e"/>
      ${rueda(236, 374)}${rueda(588, 374)}
    </g>`;

  const defs = `
    <defs>
      <linearGradient id="hPintura" x1="0" x2="0" y1="0" y2="1">
        <stop offset="0" stop-color="#3d4742"/><stop offset=".42" stop-color="#262c29"/><stop offset=".43" stop-color="#1c211e"/><stop offset="1" stop-color="#0f1211"/>
      </linearGradient>
      <linearGradient id="hBrillo" x1="0" x2="1" y1="0" y2="0">
        <stop offset="0" stop-color="#fff" stop-opacity="0"/><stop offset=".55" stop-color="#d9f2dc" stop-opacity=".0"/><stop offset=".68" stop-color="#d9f2dc" stop-opacity=".22"/><stop offset=".8" stop-color="#fff" stop-opacity="0"/>
      </linearGradient>
      <linearGradient id="hVidrio" x1="0" x2="1" y1="0" y2="1"><stop offset="0" stop-color="#2c3a33"/><stop offset=".6" stop-color="#0e1512"/><stop offset="1" stop-color="#070a09"/></linearGradient>
      <radialGradient id="hLlanta" cx=".4" cy=".35" r=".7"><stop offset="0" stop-color="#5a625e"/><stop offset="1" stop-color="#1b1f1d"/></radialGradient>
      <linearGradient id="hFaro" x1="0" x2="1"><stop offset="0" stop-color="#e9fff0"/><stop offset="1" stop-color="#9fe8a8"/></linearGradient>
      <radialGradient id="hFondo" cx=".55" cy=".45" r=".8"><stop offset="0" stop-color="#1f3226"/><stop offset=".55" stop-color="#121a15"/><stop offset="1" stop-color="#0a0d0b"/></radialGradient>
      <radialGradient id="hLuz" cx=".5" cy=".5" r=".5"><stop offset="0" stop-color="#000"/><stop offset=".55" stop-color="#000" stop-opacity=".85"/><stop offset="1" stop-color="#fff"/></radialGradient>
      <radialGradient id="hHalo" cx=".5" cy=".5" r=".5"><stop offset="0" stop-color="#eaffec" stop-opacity=".35"/><stop offset="1" stop-color="#6cc472" stop-opacity="0"/></radialGradient>
      <linearGradient id="hRojo" x1="0" x2="0" y1="0" y2="1"><stop offset="0" stop-color="#e0473a"/><stop offset="1" stop-color="#9c2219"/></linearGradient>
      <linearGradient id="hTapa" x1="0" x2="0" y1="0" y2="1"><stop offset="0" stop-color="#4a524e"/><stop offset="1" stop-color="#1e2321"/></linearGradient>
      <linearGradient id="hPapel" x1="0" x2="0" y1="0" y2="1"><stop offset="0" stop-color="#fbfcfb"/><stop offset="1" stop-color="#e5e9e6"/></linearGradient>
      <linearGradient id="hFoto" x1="0" x2="1" y1="0" y2="1"><stop offset="0" stop-color="#5d6b63"/><stop offset="1" stop-color="#2a332e"/></linearGradient>
      <pattern id="hRejilla" width="10" height="10" patternUnits="userSpaceOnUse"><path d="M0,5 H10" stroke="#2c3430" stroke-width="2"/></pattern>
      <pattern id="hPuntos" width="24" height="24" patternUnits="userSpaceOnUse"><circle cx="2" cy="2" r="1" fill="#6cc472" fill-opacity=".18"/></pattern>
      <filter id="hBlur" x="-20%" y="-200%" width="140%" height="500%"><feGaussianBlur stdDeviation="6"/></filter>
      <filter id="hGlow" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="4" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter>
      <clipPath id="hClipCuerpo"><path d="${CUERPO}"/></clipPath>
      <mask id="hMaskLinterna" maskUnits="userSpaceOnUse" x="0" y="0" width="800" height="480">
        <rect width="800" height="480" fill="#fff"/>
        <circle class="h-linterna" cx="0" cy="0" r="150" fill="url(#hLuz)"/>
      </mask>
    </defs>`;

  const fondo = `<rect width="800" height="480" fill="url(#hFondo)"/><rect width="800" height="480" fill="url(#hPuntos)"/>`;

  /* ---------- escena 1: la ruta ---------- */
  const RUTA = 'M612,118 C560,136 500,150 452,184 C408,216 392,250 366,282 C346,306 318,326 286,338';
  const e1 = `
    <g class="h-esc" data-esc="1"><g class="h-cam">
      <rect width="800" height="480" fill="#0a1311"/>
      <path d="M300,-10 C290,60 310,120 318,170 C326,220 322,250 300,272 C270,300 220,300 196,318 C184,330 198,348 226,350 C262,352 290,354 300,374 C312,398 300,440 296,490 L810,490 L810,-10 Z" fill="#141c17"/>
      <path d="M300,-10 C290,60 310,120 318,170 C326,220 322,250 300,272 C270,300 220,300 196,318 C184,330 198,348 226,350 C262,352 290,354 300,374 C312,398 300,440 296,490" fill="none" stroke="#6cc472" stroke-opacity=".35" stroke-width="1.5"/>
      <g fill="none" stroke="#6cc472" stroke-opacity=".07" stroke-width="1">${[1, 2, 3, 4, 5, 6].map((i) => `<path d="M${300 - i * 14},-10 C${290 - i * 14},60 ${310 - i * 14},120 ${318 - i * 14},170 C${326 - i * 14},220 ${322 - i * 14},250 ${300 - i * 14},${272 + i * 4}"/>`).join('')}</g>
      <g stroke="#26322b" stroke-width="1.2">${Array.from({ length: 9 }, (_, i) => `<line x1="${344 + i * 16}" y1="96" x2="${330 + i * 16}" y2="214"/><line x1="332" y1="${100 + i * 13}" x2="476" y2="${96 + i * 13}"/>`).join('')}
        ${Array.from({ length: 6 }, (_, i) => `<line x1="${226 + i * 14}" y1="318" x2="${232 + i * 14}" y2="352"/><line x1="222" y1="${322 + i * 6}" x2="300" y2="${322 + i * 6}"/>`).join('')}</g>
      <path d="M380,-10 C368,120 372,220 352,300 C340,360 350,420 360,490" fill="none" stroke="#2a3530" stroke-width="7" stroke-linecap="round"/>
      <path d="M560,-10 C540,80 600,140 612,118" fill="none" stroke="#2a3530" stroke-width="4"/>
      <path d="${RUTA}" fill="none" stroke="#6cc472" stroke-opacity=".25" stroke-width="3" stroke-dasharray="2 9" stroke-linecap="round"/>
      <path class="h-trazo" d="${RUTA}" pathLength="1" fill="none" stroke="#8fe096" stroke-width="4" stroke-linecap="round" filter="url(#hGlow)"/>
      <g transform="translate(612,118)">
        <circle r="22" fill="#43a047"/><circle r="22" fill="none" stroke="#b9f5bd" stroke-opacity=".5" stroke-width="2"/>
        <path d="M-8,8 L0,-10 L8,8 M-4.5,2 H4.5" stroke="#fff" stroke-width="3" fill="none" stroke-linecap="round" stroke-linejoin="round"/>
      </g>
      <g transform="translate(286,338)"><g class="h-destino">
        <circle class="h-onda" r="16" fill="none" stroke="#8fe096" stroke-width="2"/>
        <circle class="h-onda h-onda--2" r="16" fill="none" stroke="#8fe096" stroke-width="2"/>
        <path d="M0,0 C-14,-16 -18,-24 -18,-32 A18,18 0 1 1 18,-32 C18,-24 14,-16 0,0Z" fill="#eef7ef"/>
        <path d="M-9,-30 L-6,-37 H6 L9,-30 V-25 H-9Z" fill="#141c17"/><circle cx="-5" cy="-24" r="2.4" fill="#141c17"/><circle cx="5" cy="-24" r="2.4" fill="#141c17"/>
      </g></g>
    </g></g>`;

  /* ---------- escena 2: medidor de pintura ---------- */
  const PANELES = [[128, 250], [250, 358], [358, 470], [470, 556], [556, 680]];
  const e2 = `
    <g class="h-esc" data-esc="2"><g class="h-cam">
      ${fondo}
      <rect y="418" width="800" height="62" fill="#0b0e0c"/><line x1="0" y1="418.5" x2="800" y2="418.5" stroke="#6cc472" stroke-opacity=".25"/>
      ${suv()}
      <g clip-path="url(#hClipCuerpo)">
        ${PANELES.map(([a, b], i) => `<rect class="h-panel h-panel--${i}${i === 3 ? ' warn' : ''}" x="${a}" y="230" width="${b - a}" height="150"/>`).join('')}
        <rect class="h-barre" x="-80" y="230" width="80" height="150" fill="url(#hBarrido)"/>
      </g>
      <g class="h-medidor">
        <g transform="rotate(-18) scale(.82)">
          <circle class="h-toque" cx="0" cy="0" r="10" fill="none" stroke="#b9f5bd" stroke-width="2"/>
          <path d="M-30,-14 C-30,-24 -22,-30 -12,-30 L12,-30 C22,-30 30,-24 30,-14 L30,-96 C30,-106 22,-112 12,-112 L-12,-112 C-22,-112 -30,-106 -30,-96Z" fill="url(#hTapa)" stroke="#5b6560" stroke-width="1"/>
          <rect x="-12" y="-28" width="24" height="26" rx="5" fill="#1b201e"/>
          <rect x="-22" y="-104" width="44" height="40" rx="5" fill="#0b120e"/>
          <rect class="h-lcd" x="-18" y="-99" width="36" height="9" rx="2" fill="#8fe096"/>
          <rect x="-18" y="-86" width="22" height="5" rx="2" fill="#8fe096" opacity=".5"/>
          <rect x="-18" y="-77" width="30" height="5" rx="2" fill="#8fe096" opacity=".3"/>
          <circle cx="0" cy="-52" r="7" fill="#43a047" stroke="#b9f5bd" stroke-opacity=".5"/>
          <path d="M26,-74 C46,-78 70,-70 96,-52 L120,-36 L104,-4 L76,-22 C60,-30 44,-34 30,-36Z" fill="#0c0d0d"/>
          ${[0, 1, 2, 3].map((i) => `<rect x="-6" y="${-70 + i * 9}" width="40" height="9" rx="4.5" fill="#141616" stroke="#000" stroke-opacity=".6"/>`).join('')}
          <path d="M24,-78 C14,-84 2,-84 -4,-78" stroke="#141616" stroke-width="9" stroke-linecap="round" fill="none"/>
        </g>
      </g>
    </g></g>`;

  /* ---------- escena 3: motor con linterna ---------- */
  const e3 = `
    <g class="h-esc" data-esc="3"><g class="h-cam">
      <rect width="800" height="480" fill="#0b0d0c"/>
      <path d="M150,40 L650,40 C684,40 708,64 708,98 L708,392 C708,426 684,450 650,450 L150,450 C116,450 92,426 92,392 L92,98 C92,64 116,40 150,40Z" fill="#121614" stroke="#2b332e" stroke-width="2"/>
      <rect x="132" y="56" width="536" height="26" rx="6" fill="url(#hRejilla)" stroke="#2b332e"/>
      <path d="M230,130 C230,96 270,92 300,104 M520,104 C560,90 600,110 600,140" stroke="#2c3430" stroke-width="12" fill="none" stroke-linecap="round"/>
      <path d="M262,240 C240,260 240,320 280,340 M540,300 C580,300 600,330 600,360" stroke="#262d29" stroke-width="10" fill="none" stroke-linecap="round"/>
      <rect x="128" y="112" width="128" height="112" rx="16" fill="#1b211e" stroke="#343d38"/>
      <path d="M150,136 H234 M150,152 H234 M150,168 H234" stroke="#2d3531" stroke-width="3"/>
      <path d="M256,168 C276,168 282,160 300,160" stroke="#2f3733" stroke-width="22" fill="none"/>
      <rect x="292" y="124" width="224" height="196" rx="30" fill="url(#hTapa)" stroke="#5a645f" stroke-opacity=".6"/>
      ${[0, 1, 2, 3].map((i) => `<rect x="${318 + i * 46}" y="150" width="28" height="140" rx="12" fill="#2a302d" stroke="#59635e" stroke-opacity=".35"/>`).join('')}
      <circle cx="350" cy="134" r="13" fill="#d9a22a" stroke="#7a5a12" stroke-width="2"/><path d="M344,134 h12" stroke="#7a5a12" stroke-width="2"/>
      <rect x="552" y="112" width="120" height="86" rx="7" fill="#1a1f1d" stroke="#3a4440"/>
      <rect x="560" y="104" width="16" height="10" rx="2" fill="#c43b2f"/><rect x="644" y="104" width="16" height="10" rx="2" fill="#2b302d"/>
      <path d="M568,140 H656 M568,154 H630" stroke="#2f3733" stroke-width="5" stroke-linecap="round"/>
      <path d="M560,236 h92 a10,10 0 0 1 10,10 v62 a10,10 0 0 1 -10,10 h-92 a10,10 0 0 1 -10,-10 v-62 a10,10 0 0 1 10,-10Z" fill="#cfe8d3" fill-opacity=".12" stroke="#7fbf88" stroke-opacity=".45"/>
      <path d="M552,272 H660" stroke="#7fd889" stroke-opacity=".6" stroke-width="2" stroke-dasharray="6 4"/>
      <rect x="586" y="226" width="34" height="12" rx="4" fill="#3a4440"/>
      <rect x="138" y="290" width="76" height="58" rx="8" fill="#d9dcc8" fill-opacity=".12" stroke="#a8ad8f" stroke-opacity=".4"/>
      <circle cx="176" cy="290" r="10" fill="#d9b42a"/>
      <circle cx="176" cy="398" r="30" fill="#1b201e" stroke="#3a4440" stroke-width="2"/>
      <circle cx="624" cy="398" r="30" fill="#1b201e" stroke="#3a4440" stroke-width="2"/>
      ${[0, 120, 240].map((a) => `<circle cx="${176 + 18 * Math.cos(a * Math.PI / 180)}" cy="${398 + 18 * Math.sin(a * Math.PI / 180)}" r="3.5" fill="#59635e"/><circle cx="${624 + 18 * Math.cos(a * Math.PI / 180)}" cy="${398 + 18 * Math.sin(a * Math.PI / 180)}" r="3.5" fill="#59635e"/>`).join('')}
      <rect x="92" y="430" width="616" height="20" fill="#0d100e"/>
      <rect width="800" height="480" fill="#030404" opacity=".86" mask="url(#hMaskLinterna)"/>
      <circle class="h-linterna" cx="0" cy="0" r="150" fill="url(#hHalo)" style="mix-blend-mode:screen"/>
    </g></g>`;

  /* ---------- escena 4: bajo el auto (rayos X) ---------- */
  const resorte = (x) => `<polyline points="${Array.from({ length: 9 }, (_, i) => `${x + (i % 2 ? 10 : -10)},${302 + i * 7}`).join(' ')}" fill="none"/>`;
  const e4 = `
    <g class="h-esc" data-esc="4"><g class="h-cam">
      ${fondo}
      <rect y="440" width="800" height="40" fill="#0b0e0c"/><line x1="0" y1="440.5" x2="800" y2="440.5" stroke="#6cc472" stroke-opacity=".25"/>
      <g fill="#1b211e" stroke="#33403a"><rect x="58" y="120" width="26" height="320" rx="4"/><rect x="716" y="120" width="26" height="320" rx="4"/></g>
      <g fill="#6cc472" opacity=".5"><rect x="62" y="402" width="18" height="38"/><rect x="720" y="402" width="18" height="38"/></g>
      <path d="M84,384 H190 M716,384 H610" stroke="#3a4741" stroke-width="8" stroke-linecap="round"/>
      <g class="h-rx" transform="translate(0,-32)">
        <path class="h-dibuja" pathLength="1" d="${CUERPO}" fill="#6cc472" fill-opacity=".04" stroke="#8fe096" stroke-opacity=".7" stroke-width="2"/>
        <path class="h-dibuja" pathLength="1" d="${VIDRIOS}" fill="none" stroke="#8fe096" stroke-opacity=".35" stroke-width="1.5"/>
        <path class="h-dibuja" pathLength="1" d="M150,364 H650" fill="none" stroke="#8fe096" stroke-opacity=".45" stroke-width="2"/>
        ${[236, 588].map((x) => `<g class="h-dibuja-g" stroke="#8fe096" stroke-opacity=".55" fill="none" stroke-width="2"><circle cx="${x}" cy="374" r="44"/><circle cx="${x}" cy="374" r="30" stroke-opacity=".3"/></g>`).join('')}
        <g class="h-pieza h-pieza--a" stroke="#d6ffd9" stroke-width="3" fill="none">${resorte(236)}${resorte(588)}<path d="M236,300 V364 M588,300 V364" stroke-width="2" stroke-dasharray="4 4"/></g>
        <g class="h-pieza h-pieza--b"><circle cx="236" cy="374" r="22" fill="none" stroke="#ffd27a" stroke-width="4"/><circle cx="588" cy="374" r="22" fill="none" stroke="#ffd27a" stroke-width="4"/><path d="M220,356 A24,24 0 0 1 252,356 M572,356 A24,24 0 0 1 604,356" stroke="#ffd27a" stroke-width="7" fill="none" stroke-linecap="round"/></g>
        <g class="h-pieza h-pieza--c" stroke="#d6ffd9" fill="none" stroke-width="3"><path d="M600,352 C560,372 480,378 400,378 L250,378 C200,378 170,376 150,368" stroke-linecap="round"/><rect x="176" y="368" width="62" height="18" rx="9"/><rect x="290" y="346" width="96" height="24" rx="6" stroke-dasharray="5 4"/></g>
        <g class="h-pieza h-pieza--d" stroke="#d6ffd9" fill="none" stroke-width="2.5"><path d="M180,352 H630 M206,340 L206,364 M330,340 V364 M454,340 V364 M560,340 V364"/></g>
      </g>
      <rect class="h-scan" x="-100" y="210" width="100" height="200" fill="url(#hBarrido)" opacity=".6"/>
    </g></g>`;

  /* ---------- escena 5: escáner ---------- */
  const MODULOS = ['Motor', 'Transmisión', 'ABS', 'Airbag', 'Carrocería', 'Tablero'];
  const e5 = `
    <g class="h-esc" data-esc="5"><g class="h-cam">
      ${fondo}
      <path d="M560,430 C600,470 700,440 720,490" stroke="#111" stroke-width="10" fill="none" stroke-linecap="round"/>
      <g transform="rotate(-3 400 240)">
        <rect x="150" y="62" width="500" height="352" rx="34" fill="url(#hRojo)"/>
        <rect x="150" y="62" width="500" height="352" rx="34" fill="none" stroke="#ff9a8c" stroke-opacity=".35" stroke-width="2"/>
        ${[[150, 62], [610, 62], [150, 374], [610, 374]].map(([x, y]) => `<rect x="${x}" y="${y}" width="40" height="40" rx="14" fill="#7d1a12" opacity=".55"/>`).join('')}
        <rect x="180" y="88" width="440" height="300" rx="14" fill="#0b100d"/>
        <rect x="180" y="88" width="440" height="40" rx="14" fill="#13201a"/><rect x="180" y="114" width="440" height="14" fill="#13201a"/>
        <circle cx="206" cy="108" r="9" fill="#43a047"/><path d="M202,112 L206,103 L210,112" stroke="#fff" stroke-width="2" fill="none" stroke-linecap="round"/>
        <rect x="224" y="102" width="110" height="10" rx="5" fill="#cfe8d3" opacity=".8"/>
        <rect x="540" y="101" width="62" height="14" rx="7" fill="#43a047" opacity=".25"/><circle class="h-led" cx="552" cy="108" r="3.5" fill="#8fe096"/>
        ${MODULOS.map((m, i) => `
          <g transform="translate(200,${146 + i * 30})">
            <rect width="${[56, 92, 34, 52, 84, 60][i]}" height="9" y="6" rx="4.5" fill="#cfe8d3" opacity=".7"/>
            <rect x="130" y="7" width="210" height="7" rx="3.5" fill="#1d2a22"/>
            <rect class="h-barra h-barra--${i}" x="130" y="7" width="210" height="7" rx="3.5" fill="#43a047"/>
            <g class="h-ok h-ok--${i}"><circle cx="372" cy="10" r="10" fill="#43a047"/><path d="M367,10.5 l3.4,3.4 6-7" stroke="#fff" stroke-width="2.4" fill="none" stroke-linecap="round" stroke-linejoin="round"/></g>
          </g>`).join('')}
        <g class="h-km">
          <rect x="200" y="330" width="400" height="44" rx="10" fill="#122019" stroke="#43a047" stroke-opacity=".6"/>
          <rect x="216" y="346" width="70" height="10" rx="5" fill="#cfe8d3" opacity=".8"/>
          <rect x="300" y="343" width="78" height="16" rx="8" fill="#1d2a22"/><rect x="390" y="343" width="78" height="16" rx="8" fill="#1d2a22"/>
          <path d="M378,351 H390" stroke="#8fe096" stroke-width="2"/>
          <rect x="488" y="342" width="98" height="18" rx="9" fill="#43a047"/><rect x="500" y="348" width="58" height="6" rx="3" fill="#fff" opacity=".9"/><path d="M566,351 l3,3 6-6.5" stroke="#fff" stroke-width="2" fill="none" stroke-linecap="round"/>
        </g>
      </g>
      <path d="M98,330 C120,300 150,292 176,300 L186,336 C168,334 150,342 140,362 C130,382 116,400 92,410Z" fill="#0c0d0d"/>
      <path d="M150,300 C160,280 176,276 190,286 L196,312 C184,306 172,308 164,316Z" fill="#161818"/>
      <path d="M702,318 C680,290 652,284 626,292 L616,330 C634,328 652,336 662,356 C672,376 686,394 710,404Z" fill="#0c0d0d"/>
      <path d="M652,290 C642,270 626,266 612,276 L606,302 C618,296 630,298 638,306Z" fill="#161818"/>
    </g></g>`;

  /* ---------- escena 6: informe ---------- */
  const fila = (y, color, w) => `<circle cx="168" cy="${y + 4}" r="5" fill="${color}"/><rect x="182" y="${y}" width="${w}" height="8" rx="4" fill="#c2c9c4"/><rect x="${190 + w}" y="${y}" width="40" height="8" rx="4" fill="#dde2de"/>`;
  const e6 = `
    <g class="h-esc" data-esc="6"><g class="h-cam">
      ${fondo}
      <g class="h-hoja"><g transform="rotate(-4 280 250)">
        <rect x="136" y="52" width="300" height="400" rx="12" fill="#000" opacity=".4" filter="url(#hBlur)"/>
        <rect x="130" y="44" width="300" height="400" rx="12" fill="url(#hPapel)"/>
        <rect x="130" y="44" width="300" height="56" rx="12" fill="#141a17"/><rect x="130" y="80" width="300" height="20" fill="#141a17"/>
        <path d="M152,82 L160,62 L168,82 M155,75 H165" stroke="#6cc472" stroke-width="3" fill="none" stroke-linecap="round" stroke-linejoin="round"/>
        <rect x="178" y="64" width="80" height="8" rx="4" fill="#e9f3ea"/><rect x="178" y="78" width="120" height="6" rx="3" fill="#6cc472" opacity=".7"/>
        <rect x="150" y="116" width="122" height="86" rx="6" fill="url(#hFoto)"/><rect x="282" y="116" width="128" height="40" rx="6" fill="url(#hFoto)"/><rect x="282" y="162" width="128" height="40" rx="6" fill="url(#hFoto)"/>
        <path d="M164,186 C174,170 190,166 206,166 L232,166 C244,168 252,176 258,186Z" fill="#1b211e" opacity=".75"/>
        <circle cx="180" cy="188" r="7" fill="#111"/><circle cx="240" cy="188" r="7" fill="#111"/>
        <rect x="150" y="220" width="110" height="10" rx="5" fill="#2b332e"/>
        ${fila(244, '#4caf50', 150)}${fila(266, '#4caf50', 120)}${fila(288, '#e0a42a', 136)}${fila(310, '#4caf50', 104)}${fila(332, '#e5604f', 146)}
        <rect x="150" y="360" width="260" height="62" rx="8" fill="#eef4ef" stroke="#cfe0d2"/>
        <rect x="164" y="374" width="90" height="8" rx="4" fill="#2b332e"/><rect x="164" y="390" width="150" height="7" rx="3.5" fill="#aab3ad"/><rect x="164" y="403" width="120" height="7" rx="3.5" fill="#aab3ad"/>
        <rect x="338" y="378" width="56" height="24" rx="12" fill="#43a047"/><path d="M356,390 l5,5 10-10" stroke="#fff" stroke-width="3" fill="none" stroke-linecap="round" stroke-linejoin="round"/>
      </g></g>
      <g class="h-tel">
        <rect x="486" y="38" width="210" height="412" rx="34" fill="#050606"/>
        <rect x="486" y="38" width="210" height="412" rx="34" fill="none" stroke="#3a4440" stroke-width="2"/>
        <rect x="498" y="50" width="186" height="388" rx="24" fill="#0f1512"/>
        <rect x="566" y="58" width="50" height="12" rx="6" fill="#050606"/>
        <rect x="498" y="80" width="186" height="46" fill="#16201b"/>
        <circle cx="522" cy="103" r="13" fill="#43a047"/><path d="M516,109 L522,96 L528,109 M518.5,104 H525.5" stroke="#fff" stroke-width="2" fill="none" stroke-linecap="round"/>
        <rect x="542" y="96" width="74" height="8" rx="4" fill="#e9f3ea"/><rect x="542" y="108" width="44" height="6" rx="3" fill="#6cc472" opacity=".7"/>
        <g class="h-msj h-msj--1">
          <rect x="510" y="146" width="150" height="66" rx="14" fill="#1d2a22"/>
          <rect x="520" y="156" width="130" height="46" rx="9" fill="#0f1512"/>
          <rect x="528" y="164" width="24" height="30" rx="4" fill="#e5604f"/><rect x="532" y="176" width="16" height="4" rx="2" fill="#fff" opacity=".9"/>
          <rect x="560" y="168" width="78" height="7" rx="3.5" fill="#e9f3ea"/><rect x="560" y="182" width="40" height="6" rx="3" fill="#9ba29e"/>
        </g>
        <g class="h-msj h-msj--2">
          <rect x="510" y="222" width="140" height="44" rx="14" fill="#1d2a22"/>
          <rect x="522" y="234" width="110" height="7" rx="3.5" fill="#cfe8d3" opacity=".8"/><rect x="522" y="248" width="80" height="7" rx="3.5" fill="#cfe8d3" opacity=".55"/>
        </g>
        <g class="h-msj h-msj--3">
          <rect x="566" y="278" width="104" height="34" rx="14" fill="#43a047"/>
          <rect x="578" y="291" width="66" height="7" rx="3.5" fill="#fff" opacity=".9"/>
        </g>
      </g>
    </g></g>`;

  const html = () => `
    <div class="historia" data-e="1">
      <div class="h-escena">
        <svg viewBox="0 0 800 480" role="img" aria-labelledby="hTit">
          <title id="hTit">Ilustración animada: así revisa un auto Atlas Motors, en seis pasos</title>
          ${defs}
          <linearGradient id="hBarrido" x1="0" x2="1"><stop offset="0" stop-color="#8fe096" stop-opacity="0"/><stop offset=".5" stop-color="#d6ffd9" stop-opacity=".55"/><stop offset="1" stop-color="#8fe096" stop-opacity="0"/></linearGradient>
          ${e1}${e2}${e3}${e4}${e5}${e6}
        </svg>
        <div class="h-capa" aria-hidden="true">
          <span class="h-tag e1" style="left:76.5%;top:13%">Atlas Motors</span>
          <span class="h-tag e1 h-tag--luz" style="left:19%;top:57%">El auto que quieres comprar</span>
          <span class="h-lugar e1" style="left:50%;top:15%">La Serena</span>
          <span class="h-lugar e1" style="left:27%;top:85%">Coquimbo</span>
          ${['Original', 'Original', 'Original', 'Repintado', 'Original'].map((t, i) => `<span class="h-chip e2 h-d${i}${i === 3 ? ' warn' : ''}" style="left:${[23.6, 38.1, 51.5, 64.1, 77.1][i]}%;top:${i % 2 ? 40 : 34}%">${i === 3 ? '' : ic('check')}${t}</span>`).join('')}
          <span class="h-chip e3 h-d0" style="left:44%;top:22%">${ic('check')} Aceite</span>
          <span class="h-chip e3 h-d2" style="left:76%;top:58%">${ic('check')} Refrigerante</span>
          <span class="h-chip e3 h-d3" style="left:76%;top:20%">${ic('check')} Batería</span>
          <span class="h-chip e3 h-d4" style="left:47%;top:72%">${ic('check')} Sin fugas</span>
          <span class="h-chip e4 h-d1" style="left:29.5%;top:52%">${ic('check')} Suspensión</span>
          <span class="h-chip e4 h-d2" style="left:73.5%;top:64%">${ic('check')} Frenos</span>
          <span class="h-chip e4 h-d3" style="left:24%;top:84%">${ic('check')} Escape</span>
          <span class="h-chip e4 h-d4" style="left:50%;top:84%">${ic('check')} Chasis</span>
          <span class="h-chip e5 h-d4" style="left:50%;top:91%">${ic('check')} Kilometraje real</span>
          <span class="h-chip e6 h-d2" style="left:35%;top:6%">${ic('doc')} PDF con fotos</span>
        </div>
      </div>
      <div class="h-pie">
        <div class="h-barras">${ESCENAS.map((e, i) => `<button type="button" data-ir="${i + 1}" aria-label="Paso ${i + 1}: ${e[0]}"><i></i></button>`).join('')}</div>
        <div class="h-texto" aria-live="polite"><span class="h-num">Paso 1 de 6</span><b>${ESCENAS[0][0]}</b><p>${ESCENAS[0][1]}</p></div>
      </div>
    </div>`;

  function bind() {
    const h = document.querySelector('.historia'); if (!h) return;
    const quieto = matchMedia('(prefers-reduced-motion: reduce)').matches;
    let e = 1, t = null, visible = true;
    const programar = () => {
      clearTimeout(t);
      if (quieto || !visible || document.hidden) { h.classList.add('pausa'); return; }
      h.classList.remove('pausa');
      t = setTimeout(() => { if (document.body.contains(h)) ir(e + 1); }, DUR);
    };
    const ir = (n) => {
      e = ((n - 1 + ESCENAS.length) % ESCENAS.length) + 1;
      // Reinicia las animaciones de la escena: se quita y vuelve a poner el atributo.
      h.dataset.e = '0'; void h.offsetWidth; h.dataset.e = String(e);
      const [tit, txt] = ESCENAS[e - 1];
      h.querySelector('.h-texto').innerHTML = `<span class="h-num">Paso ${e} de ${ESCENAS.length}</span><b>${tit}</b><p>${txt}</p>`;
      h.querySelectorAll('.h-barras button').forEach((b, i) => {
        b.classList.toggle('hecho', i + 1 < e); b.classList.toggle('ahora', i + 1 === e);
        b.setAttribute('aria-current', i + 1 === e ? 'step' : 'false');
      });
      programar();
    };
    h.querySelector('.h-barras').addEventListener('click', (ev) => {
      const b = ev.target.closest('[data-ir]'); if (b) ir(Number(b.dataset.ir));
    });
    if ('IntersectionObserver' in window) {
      new IntersectionObserver(([x]) => { const antes = visible; visible = x.isIntersecting; if (visible && !antes) ir(e); else programar(); }, { threshold: 0.3 }).observe(h);
    }
    document.addEventListener('visibilitychange', () => { if (document.body.contains(h)) programar(); });
    ir(1);
  }

  window.AtlasHistoria = { html, bind };
})();
