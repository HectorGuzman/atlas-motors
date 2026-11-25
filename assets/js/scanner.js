/* Atlas Scan: escáner de diagnóstico animado (página "Inspección precompra").
   Ciclo de 12 s: lee el VIN, recorre 6 módulos uno por uno mientras un haz barre
   el auto, y termina en "Escaneo completo · 0 códigos de falla".
   Sin animación (prefers-reduced-motion) queda el estado final, ya completo. */
(function () {
  const T = 12; // segundos por ciclo

  const MODULOS = [
    { cod: 'ECM', nombre: 'Motor', ok: 'OK', spot: [179, 124] },
    { cod: 'TCM', nombre: 'Transmisión', ok: 'OK', spot: [179, 141] },
    { cod: 'ABS', nombre: 'Frenos ABS / ESP', ok: 'OK', spot: [[148, 131], [210, 131], [148, 209], [210, 209]] },
    { cod: 'SRS', nombre: 'Airbags', ok: 'OK', spot: [179, 170] },
    { cod: 'BCM', nombre: 'Carrocería', ok: 'OK', spot: [179, 196] },
    { cod: 'BAT', nombre: 'Batería y carga', ok: '82 %', warn: true, spot: [194, 118] },
  ];
  const ini = (i) => 6 + i * 8.5; // % del ciclo en que empieza cada módulo
  const fin = (i) => ini(i) + 7;
  const LISTO = fin(MODULOS.length - 1) + 1.5; // escaneo completo
  const RESET = 94;

  // Keyframes de opacidad: visible solo dentro de los rangos [desde, hasta] (en %).
  function kf(nombre, rangos) {
    const p = new Map([[0, 0], [100, 0]]);
    rangos.forEach(([a, b]) => {
      if (a > 0) p.set(+(a - 0.5).toFixed(2), 0);
      p.set(a, 1); p.set(b, 1);
      if (b < 100) p.set(+(b + 0.5).toFixed(2), 0);
    });
    const pasos = [...p.entries()].sort((x, y) => x[0] - y[0]).map(([k, v]) => `${k}%{opacity:${v}}`).join('');
    return `@keyframes ${nombre}{${pasos}}.as-svg .${nombre}{animation:${nombre} ${T}s linear infinite}`;
  }
  function chip(nombre, t) {
    const off = 'opacity:0;transform:translateY(8px) scale(.92)';
    return `@keyframes ${nombre}{0%,${(t - 0.3).toFixed(2)}%{${off}}${(t + 2.5).toFixed(2)}%,${RESET}%{opacity:1;transform:none}${RESET + 1.5}%,100%{${off}}}.as-svg .${nombre}{animation:${nombre} ${T}s cubic-bezier(.2,.8,.3,1.2) infinite}`;
  }

  function estilos() {
    const css = [];
    MODULOS.forEach((_, i) => {
      css.push(kf(`as-w${i}`, [[0, ini(i)], [RESET + 1, 100]]));
      css.push(kf(`as-s${i}`, [[ini(i), fin(i)]]));
      css.push(kf(`as-o${i}`, [[fin(i), RESET]]));
      css.push(kf(`as-h${i}`, [[fin(i), RESET]]));
    });
    css.push(kf('as-busy', [[0, LISTO - 1], [RESET + 1, 100]]));
    css.push(kf('as-done', [[LISTO, RESET]]));
    css.push(kf('as-vin1', [[0, 5], [RESET + 1, 100]]));
    css.push(kf('as-vin2', [[5.5, RESET]]));
    css.push(kf('as-beam', [[1, LISTO - 1], [RESET + 1, 100]]));
    css.push(chip('as-c0', fin(0)), chip('as-c1', fin(3)), chip('as-c2', fin(5)), chip('as-c3', LISTO + 3));
    const prog = MODULOS.map((_, i) => `${fin(i)}%{transform:scaleX(${((i + 1) / MODULOS.length).toFixed(3)})}`).join('');
    css.push(`@keyframes as-prog{0%,3%{transform:scaleX(0)}${prog}${RESET}%{transform:scaleX(1)}${RESET + 2}%,100%{transform:scaleX(0)}}.as-svg .as-prog{animation:as-prog ${T}s linear infinite}`);
    return css.join('');
  }

  // Onda de RPM periódica cada 230 unidades, para que el desplazamiento sea continuo.
  function onda() {
    const pts = [];
    for (let x = 0; x <= 460; x += 4) {
      const t = (2 * Math.PI * x) / 230;
      const y = 300 + 7 * Math.sin(5 * t) + 3.5 * Math.sin(13 * t + 1) + 1.6 * Math.sin(31 * t);
      pts.push(`${x},${y.toFixed(1)}`);
    }
    return pts.join(' ');
  }

  const fila = (m, i) => {
    const y = 106 + i * 23;
    const okPill = m.warn
      ? `<rect x="446" y="${y + 3}" width="42" height="14" rx="7" fill="rgba(224,176,72,.18)"/><text x="467" y="${y + 13.5}" fill="#e0b048" font-size="9.5" font-weight="700" text-anchor="middle">${m.ok}</text>`
      : `<rect x="452" y="${y + 3}" width="36" height="14" rx="7" fill="rgba(67,160,71,.22)"/><text x="470" y="${y + 13.5}" fill="#7fdc86" font-size="9.5" font-weight="700" text-anchor="middle">✓ ${m.ok}</text>`;
    return `
      <rect x="264" y="${y}" width="232" height="20" rx="5" fill="#0f1a14"/>
      <rect class="as-s${i}" opacity="0" x="264" y="${y}" width="232" height="20" rx="5" fill="rgba(67,160,71,.12)" stroke="#43a047" stroke-width="1"/>
      <text x="272" y="${y + 13.5}" fill="#6f8a78" font-size="9" font-family="ui-monospace,Menlo,monospace" font-weight="600">${m.cod}</text>
      <text x="300" y="${y + 13.8}" fill="#e6efe8" font-size="11" font-weight="600">${m.nombre}</text>
      <text class="as-w${i}" opacity="0" x="488" y="${y + 13.5}" fill="#4d6455" font-size="9.5" text-anchor="end">En espera</text>
      <g class="as-s${i}" opacity="0"><circle class="as-spin" cx="${430}" cy="${y + 10}" r="4.5" fill="none" stroke="#e0b048" stroke-width="1.6" stroke-dasharray="18 10"/><text x="488" y="${y + 13.5}" fill="#e0b048" font-size="9.5" font-weight="600" text-anchor="end">Leyendo</text></g>
      <g class="as-o${i}">${okPill}</g>`;
  };

  const spot = (m, i) => {
    const pts = Array.isArray(m.spot[0]) ? m.spot : [m.spot];
    const color = m.warn ? '#e0b048' : '#7fdc86';
    return `<g class="as-h${i}">${pts.map(([x, y]) => `<circle cx="${x}" cy="${y}" r="3.2" fill="${color}"/><circle class="as-ping" cx="${x}" cy="${y}" r="3.2" fill="none" stroke="${color}" stroke-width="1.4"/>`).join('')}</g>`;
  };

  const chipSvg = (cls, x, y, w, color, texto) => `
    <g class="${cls}" style="transform-box:fill-box;transform-origin:center">
      <rect x="${x}" y="${y + 3}" width="${w}" height="36" rx="11" fill="#000" opacity=".28" filter="url(#asBlur)"/>
      <rect x="${x}" y="${y}" width="${w}" height="36" rx="11" fill="#fff"/>
      <circle cx="${x + 19}" cy="${y + 18}" r="8" fill="${color}"/>
      <path d="M${x + 15} ${y + 18.3}l2.6 2.6 5-5.2" stroke="#fff" stroke-width="2" fill="none" stroke-linecap="round" stroke-linejoin="round"/>
      <text x="${x + 33}" y="${y + 22.5}" fill="#1a1f1c" font-size="12.5" font-weight="700">${texto}</text>
    </g>`;

  function html() {
    return `
    <svg class="as-svg" viewBox="0 0 600 460" role="img" aria-label="Escáner de diagnóstico Atlas Scan conectado al puerto OBD-II, revisando los módulos del auto: motor, transmisión, frenos ABS, airbags, carrocería y batería. Resultado: 0 códigos de falla." font-family="Inter, system-ui, sans-serif">
      <style>${estilos()}</style>
      <defs>
        <radialGradient id="asGlow" cx=".5" cy=".45" r=".55"><stop offset="0" stop-color="#43a047" stop-opacity=".32"/><stop offset="1" stop-color="#43a047" stop-opacity="0"/></radialGradient>
        <linearGradient id="asCase" x1="0" x2="0" y1="0" y2="1"><stop offset="0" stop-color="#2a312d"/><stop offset=".5" stop-color="#151a17"/><stop offset="1" stop-color="#0b0e0c"/></linearGradient>
        <linearGradient id="asEdge" x1="0" x2="1" y1="0" y2="1"><stop offset="0" stop-color="#7fdc86"/><stop offset=".5" stop-color="#2e7d32"/><stop offset="1" stop-color="#1b4d23"/></linearGradient>
        <linearGradient id="asScr" x1="0" x2="0" y1="0" y2="1"><stop offset="0" stop-color="#0e1813"/><stop offset="1" stop-color="#070d0a"/></linearGradient>
        <linearGradient id="asGlass" x1="0" x2="1" y1="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity=".09"/><stop offset=".45" stop-color="#fff" stop-opacity=".02"/><stop offset=".46" stop-color="#fff" stop-opacity="0"/></linearGradient>
        <linearGradient id="asBeamG" x1="0" x2="0" y1="0" y2="1"><stop offset="0" stop-color="#43a047" stop-opacity="0"/><stop offset=".85" stop-color="#43a047" stop-opacity=".35"/><stop offset="1" stop-color="#b9ffbf" stop-opacity=".95"/></linearGradient>
        <linearGradient id="asWaveG" x1="0" x2="0" y1="0" y2="1"><stop offset="0" stop-color="#43a047" stop-opacity=".35"/><stop offset="1" stop-color="#43a047" stop-opacity="0"/></linearGradient>
        <clipPath id="asClipCar"><rect x="104" y="100" width="150" height="150" rx="8"/></clipPath>
        <clipPath id="asClipChart"><rect x="104" y="258" width="230" height="64" rx="6"/></clipPath>
        <filter id="asBlur" x="-20%" y="-50%" width="140%" height="200%"><feGaussianBlur stdDeviation="5"/></filter>
        <filter id="asNeon" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="2.2" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter>
      </defs>

      <!-- ambiente -->
      <rect width="600" height="460" fill="#08100b"/>
      <circle cx="300" cy="200" r="290" fill="url(#asGlow)"/>
      <g stroke="#43a047" opacity=".07">${Array.from({ length: 16 }, (_, i) => `<line x1="${i * 40}" y1="0" x2="${i * 40}" y2="460"/>`).join('')}${Array.from({ length: 12 }, (_, i) => `<line x1="0" y1="${i * 40}" x2="600" y2="${i * 40}"/>`).join('')}</g>
      <ellipse cx="300" cy="372" rx="230" ry="16" fill="#000" opacity=".55" filter="url(#asBlur)"/>

      <!-- cable al conector OBD-II, con datos viajando -->
      <path d="M452 352 C 452 404, 470 414, 488 414" stroke="#0b0e0c" stroke-width="11" fill="none" stroke-linecap="round"/>
      <path d="M452 352 C 452 404, 470 414, 488 414" stroke="#232a26" stroke-width="7" fill="none" stroke-linecap="round"/>
      <path class="as-flow" d="M452 352 C 452 404, 470 414, 488 414" stroke="#9cf0a3" stroke-width="2.4" fill="none" stroke-linecap="round" stroke-dasharray="2 13" filter="url(#asNeon)"/>
      <g>
        <path d="M486 398 h10 v32 h-10 z" fill="#151a17"/>
        <path d="M496 392 H562 L556 436 H502 Z" fill="url(#asCase)" stroke="#3a463f" stroke-width="1.5"/>
        <path d="M503 399 H555 L551 429 H507 Z" fill="#0a0d0b"/>
        <g fill="#c9a646">${Array.from({ length: 8 }, (_, i) => `<rect x="${508 + i * 5.6}" y="405" width="2.4" height="6" rx=".8"/>`).join('')}${Array.from({ length: 8 }, (_, i) => `<rect x="${509.5 + i * 5}" y="416" width="2.4" height="6" rx=".8"/>`).join('')}</g>
        <circle class="as-led" cx="555" cy="444" r="3" fill="#7fdc86" filter="url(#asNeon)"/>
        <text x="528" y="452" fill="#6cc472" font-size="10.5" font-weight="700" text-anchor="middle" letter-spacing=".5">OBD-II</text>
      </g>

      <!-- equipo: carcasa robusta -->
      <rect x="66" y="34" width="468" height="324" rx="30" fill="url(#asCase)" stroke="url(#asEdge)" stroke-width="2.5"/>
      <g fill="#0b0e0c" stroke="#2e3832" stroke-width="1">
        <path d="M66 82 V64 a30 30 0 0 1 30 -30 H114 V44 H86 a10 10 0 0 0 -10 10 V82 Z"/>
        <path d="M534 82 V64 a30 30 0 0 0 -30 -30 H486 V44 H514 a10 10 0 0 1 10 10 V82 Z"/>
        <path d="M66 310 V328 a30 30 0 0 0 30 30 H114 V348 H86 a10 10 0 0 1 -10 -10 V310 Z"/>
        <path d="M534 310 V328 a30 30 0 0 1 -30 30 H486 V348 H514 a10 10 0 0 0 10 -10 V310 Z"/>
      </g>
      <g fill="#3a463f">${[[84, 50], [516, 50], [84, 342], [516, 342]].map(([x, y]) => `<circle cx="${x}" cy="${y}" r="2.4"/>`).join('')}</g>
      <rect x="86" y="52" width="428" height="288" rx="14" fill="#040605"/>
      <rect x="96" y="62" width="408" height="268" rx="7" fill="url(#asScr)"/>
      <circle cx="300" cy="57" r="1.8" fill="#1f2924"/>

      <!-- pantalla: encabezado -->
      <rect x="96" y="62" width="408" height="28" rx="7" fill="#0f1a14"/>
      <path d="M106 70 l6 -2.5 6 2.5 v5 c0 4 -2.6 6.4 -6 7.6 c-3.4 -1.2 -6 -3.6 -6 -7.6 z" fill="none" stroke="#e0b048" stroke-width="1.5"/>
      <text x="124" y="80.5" fill="#e6efe8" font-size="12" font-weight="800" letter-spacing="1.6">ATLAS <tspan fill="#6cc472">SCAN</tspan></text>
      <text class="as-vin1" opacity="0" x="250" y="80" fill="#e0b048" font-size="9.5" font-family="ui-monospace,Menlo,monospace">Leyendo VIN…</text>
      <text class="as-vin2" x="250" y="80" fill="#9fb5a6" font-size="9.5" font-family="ui-monospace,Menlo,monospace">VIN 3VW•••••••K4821</text>
      <circle class="as-led" cx="418" cy="76" r="3" fill="#7fdc86"/>
      <text x="425" y="79.5" fill="#7fdc86" font-size="9" font-weight="700">OBD</text>
      <rect x="463" y="70.5" width="22" height="11" rx="2.5" fill="none" stroke="#9fb5a6" stroke-width="1.2"/><rect x="485.5" y="74" width="2" height="4" rx=".8" fill="#9fb5a6"/><rect x="465.5" y="73" width="13" height="6" rx="1" fill="#7fdc86"/>
      <rect x="96" y="90" width="408" height="3" fill="#16241b"/>
      <rect class="as-prog" x="96" y="90" width="408" height="3" fill="#43a047" style="transform-box:fill-box;transform-origin:0 50%"/>

      <!-- pantalla: auto visto desde arriba, con el haz de escaneo -->
      <rect x="104" y="100" width="150" height="150" rx="8" fill="#0a140f" stroke="#1c2e22"/>
      <g clip-path="url(#asClipCar)">
        <g stroke="#43a047" opacity=".1">${Array.from({ length: 8 }, (_, i) => `<line x1="${104 + i * 20}" y1="100" x2="${104 + i * 20}" y2="250"/><line x1="104" y1="${100 + i * 20}" x2="254" y2="${100 + i * 20}"/>`).join('')}</g>
        <g stroke="#6cc472" stroke-width="1.5" fill="none" stroke-linejoin="round">
          <path d="M166 107 Q179 104 192 107 Q207 111 208 132 L209 204 Q209 236 194 240 Q179 243 164 240 Q149 236 149 204 L150 132 Q151 111 166 107 Z" fill="rgba(67,160,71,.07)"/>
          <path d="M152 172 Q150 190 152 206 M206 172 Q208 190 206 206" opacity=".5"/>
          <path d="M156 138 Q179 131 202 138"/>
          <path d="M158 146 Q179 140 200 146 L196 166 Q179 162 162 166 Z" fill="rgba(108,196,114,.16)"/>
          <rect x="162" y="169" width="34" height="34" rx="5"/>
          <path d="M162 206 Q179 209 196 206 L200 222 Q179 227 158 222 Z" fill="rgba(108,196,114,.16)"/>
          <path d="M151 150 l-5 -2 v6 l5 0"/><path d="M207 150 l5 -2 v6 l-5 0"/>
        </g>
        <path d="M155 113 q5 -3 11 -3.5" stroke="#d8ffd9" stroke-width="2.2" fill="none" stroke-linecap="round" opacity=".8"/><path d="M203 113 q-5 -3 -11 -3.5" stroke="#d8ffd9" stroke-width="2.2" fill="none" stroke-linecap="round" opacity=".8"/>
        <path d="M155 236 q6 3 12 3.5" stroke="#ff5a4e" stroke-width="2.2" fill="none" stroke-linecap="round" opacity=".8"/><path d="M203 236 q-6 3 -12 3.5" stroke="#ff5a4e" stroke-width="2.2" fill="none" stroke-linecap="round" opacity=".8"/>
        <g fill="#6cc472" opacity=".55"><rect x="145" y="121" width="6" height="20" rx="2"/><rect x="207" y="121" width="6" height="20" rx="2"/><rect x="145" y="199" width="6" height="20" rx="2"/><rect x="207" y="199" width="6" height="20" rx="2"/></g>
        ${MODULOS.map(spot).join('')}
        <g class="as-beam" opacity="0"><rect class="as-beam-y" x="104" y="84" width="150" height="26" fill="url(#asBeamG)"/></g>
      </g>
      <g stroke="#6cc472" stroke-width="1.6" fill="none" opacity=".8"><path d="M104 112 v-12 h12"/><path d="M254 112 v-12 h-12"/><path d="M104 238 v12 h12"/><path d="M254 238 v12 h-12"/></g>

      <!-- pantalla: módulos -->
      ${MODULOS.map(fila).join('')}

      <!-- pantalla: datos en vivo -->
      <rect x="104" y="258" width="230" height="64" rx="6" fill="#0a140f" stroke="#1c2e22"/>
      <g clip-path="url(#asClipChart)">
        <g stroke="#43a047" opacity=".12">${[274, 290, 306].map((y) => `<line x1="104" y1="${y}" x2="334" y2="${y}"/>`).join('')}</g>
        <g class="as-wave">
          <polygon transform="translate(104 0)" points="0,322 ${onda()} 460,322" fill="url(#asWaveG)"/>
          <polyline transform="translate(104 0)" points="${onda()}" fill="none" stroke="#7fdc86" stroke-width="1.6" stroke-linejoin="round" filter="url(#asNeon)"/>
        </g>
      </g>
      <text x="112" y="271" fill="#6f8a78" font-size="9" font-weight="600">RPM · EN VIVO</text>
      <circle class="as-led" cx="183" cy="268" r="2.4" fill="#ff5a4e"/>

      <g font-size="9" font-weight="600">
        <rect x="342" y="258" width="48" height="32" rx="5" fill="#0f1a14"/><text x="349" y="269" fill="#6f8a78">RPM</text>
        <text class="as-rpm1" x="349" y="284" fill="#e6efe8" font-size="12.5" font-weight="800">812</text>
        <text class="as-rpm2" opacity="0" x="349" y="284" fill="#e6efe8" font-size="12.5" font-weight="800">806</text>
        <text class="as-rpm3" opacity="0" x="349" y="284" fill="#e6efe8" font-size="12.5" font-weight="800">819</text>
        <rect x="395" y="258" width="48" height="32" rx="5" fill="#0f1a14"/><text x="402" y="269" fill="#6f8a78">TEMP.</text>
        <text x="402" y="284" fill="#e6efe8" font-size="12.5" font-weight="800">89°C</text>
        <rect x="448" y="258" width="48" height="32" rx="5" fill="#0f1a14"/><text x="455" y="269" fill="#6f8a78">CARGA</text>
        <text x="455" y="284" fill="#e6efe8" font-size="12.5" font-weight="800">14,2V</text>
      </g>
      <rect x="342" y="296" width="154" height="26" rx="5" fill="#0f1a14"/>
      <g class="as-busy" opacity="0"><circle class="as-spin" cx="355" cy="309" r="5" fill="none" stroke="#e0b048" stroke-width="1.8" stroke-dasharray="20 11"/><text x="366" y="312.5" fill="#e0b048" font-size="10" font-weight="700">Escaneando módulos…</text></g>
      <g class="as-done"><rect x="342" y="296" width="154" height="26" rx="5" fill="rgba(67,160,71,.18)" stroke="#43a047"/><text x="419" y="312.5" fill="#7fdc86" font-size="10" font-weight="800" text-anchor="middle">✓ 0 códigos de falla</text></g>

      <rect x="96" y="62" width="408" height="268" rx="7" fill="url(#asGlass)" pointer-events="none"/>

      <!-- resultados que van apareciendo -->
      ${chipSvg('as-c0', 30, 14, 124, '#1f8a4c', 'Motor OK')}
      ${chipSvg('as-c1', 40, 340, 150, '#1f8a4c', 'ABS / Airbag OK')}
      ${chipSvg('as-c2', 440, 14, 130, '#c98a06', 'Batería 82 %')}
      ${chipSvg('as-c3', 252, 340, 118, '#1f8a4c', 'Km reales')}
    </svg>`;
  }

  window.AtlasScanner = { html };
})();
