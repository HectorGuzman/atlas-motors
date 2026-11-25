/* "¿Por qué comprar en Atlas Motors?": recorrido animado de 4 pasos.
   Un auto avanza por la pista de un paso al siguiente; el paso activo se enciende
   y su ilustración se anima (escaneo de carrocería, escáner, informe, publicación).
   Se puede tocar un paso para ir a él. Con prefers-reduced-motion queda todo encendido y quieto. */
(function () {
  const DUR = 3400; // ms por paso

  const PASOS = [
    ['Revisión completa', '8 etapas, siempre en el mismo orden'],
    ['Escáner profesional', 'Todos los módulos electrónicos'],
    ['Informe detallado', 'Con fotos de cada hallazgo'],
    ['Publicado con su informe', 'A la vista de cualquier comprador'],
  ];

  // Onda periódica cada 60 unidades para que el desplazamiento no tenga saltos.
  const onda = () => {
    const p = [];
    for (let x = 0; x <= 120; x += 3) {
      const t = (2 * Math.PI * x) / 60;
      p.push(`${x},${(41 + 6 * Math.sin(2 * t) + 3 * Math.sin(5 * t + 1)).toFixed(1)}`);
    }
    return p.join(' ');
  };

  const AUTO = 'M14 54 L17 44 Q21 38 33 36 L50 34 L62 24 Q66 21 74 21 L96 21 Q104 21 110 28 L118 36 Q128 38 128 46 L128 54 Z';

  const ARTE = [
    // 1. Revisión: un haz recorre la carrocería y se encienden las 8 etapas.
    `<svg viewBox="0 0 140 80" aria-hidden="true">
      <path d="${AUTO}" class="vj-trazo"/>
      <path d="M64 25 L60 34 L104 34 L100 25 Z M66 34 V27" class="vj-trazo vj-fino"/>
      <circle cx="38" cy="55" r="8" class="vj-rueda"/><circle cx="106" cy="55" r="8" class="vj-rueda"/>
      <circle cx="38" cy="55" r="3" class="vj-centro"/><circle cx="106" cy="55" r="3" class="vj-centro"/>
      <g class="vj-haz"><rect x="10" y="14" width="2" height="48" rx="1" class="vj-luz"/><rect x="-6" y="14" width="16" height="48" class="vj-estela"/></g>
      ${Array.from({ length: 8 }, (_, i) => `<circle cx="${35 + i * 10}" cy="73" r="2.6" class="vj-etapa" style="--d:${0.25 + i * 0.3}s"/>`).join('')}
    </svg>`,
    // 2. Escáner: equipo con señal en vivo y barras de módulos que se completan.
    `<svg viewBox="0 0 140 80" aria-hidden="true">
      <rect x="30" y="6" width="80" height="68" rx="10" class="vj-caja"/>
      <rect x="37" y="13" width="66" height="36" rx="4" class="vj-pantalla"/>
      <svg x="37" y="13" width="66" height="36" viewBox="0 20 66 36" overflow="hidden"><polyline points="${onda()}" class="vj-onda"/></svg>
      ${[0, 1, 2].map((i) => `<rect x="38" y="${55 + i * 5.5}" width="64" height="3" rx="1.5" class="vj-pista"/><rect x="38" y="${55 + i * 5.5}" width="64" height="3" rx="1.5" class="vj-barra" style="--d:${0.3 + i * 0.55}s"/>`).join('')}
      <path d="M110 40 C 124 40, 126 58, 134 58" class="vj-cable"/>
    </svg>`,
    // 3. Informe: el documento se escribe solo y aparecen las fotos.
    `<svg viewBox="0 0 140 80" aria-hidden="true">
      <path d="M44 4 H86 L98 16 V76 H44 Z" class="vj-caja"/>
      <path d="M86 4 V16 H98" class="vj-trazo vj-fino"/>
      ${[0, 1, 2, 3].map((i) => `<rect x="51" y="${14 + i * 7}" width="${[28, 38, 32, 36][i]}" height="2.6" rx="1.3" class="vj-linea" style="--d:${0.15 + i * 0.3}s"/>`).join('')}
      ${[0, 1, 2].map((i) => `<g class="vj-foto" style="--d:${1.3 + i * 0.3}s"><rect x="${51 + i * 14}" y="48" width="11" height="11" rx="2"/><path d="M${52 + i * 14} 57.5 l3 -3.5 2.5 2.5 2 -2 2.5 3" /></g>`).join('')}
      <g class="vj-sello" style="--d:2.2s"><circle cx="93" cy="66" r="9"/><path d="m89 66 3 3 5-6"/></g>
    </svg>`,
    // 4. Publicado: aviso del auto con el sello "Inspeccionado".
    `<svg viewBox="0 0 140 80" aria-hidden="true">
      <rect x="22" y="4" width="96" height="72" rx="8" class="vj-caja"/>
      <rect x="27" y="9" width="86" height="38" rx="5" class="vj-foto-auto"/>
      <g transform="translate(41 14) scale(.42)"><path d="${AUTO}" class="vj-trazo vj-grueso"/><circle cx="38" cy="55" r="8" class="vj-rueda"/><circle cx="106" cy="55" r="8" class="vj-rueda"/></g>
      <rect x="28" y="53" width="44" height="3.5" rx="1.75" class="vj-texto"/>
      <rect x="28" y="61" width="28" height="3.5" rx="1.75" class="vj-texto vj-oro"/>
      <g class="vj-insignia" style="--d:.5s"><rect x="76" y="54" width="38" height="16" rx="8"/><path d="M83 58.5 l3.5 -1.4 3.5 1.4 v2.6 c0 2.3 -1.5 3.6 -3.5 4.3 c-2 -.7 -3.5 -2 -3.5 -4.3z"/><text x="94" y="64.6">OK</text></g>
      <defs><clipPath id="vjAviso"><rect x="22" y="4" width="96" height="72" rx="8"/></clipPath></defs>
      <g clip-path="url(#vjAviso)"><g class="vj-brillo"><rect x="-10" y="0" width="16" height="80" transform="skewX(-20)"/></g></g>
    </svg>`,
  ];

  const html = () => `
    <div class="mk-viaje" aria-label="Cómo llega un auto a Atlas Motors">
      <div class="mk-viaje__pista" aria-hidden="true">
        <span class="mk-viaje__linea"></span><span class="mk-viaje__fill"></span>
        <span class="mk-viaje__auto"><svg viewBox="0 0 24 24"><path d="M5 17h14M3 13l2-5a2 2 0 0 1 2-1.3h10A2 2 0 0 1 19 8l2 5v4a1 1 0 0 1-1 1h-1M3 13v4a1 1 0 0 0 1 1h1M3 13h18"/><circle cx="7.5" cy="17" r="1.8"/><circle cx="16.5" cy="17" r="1.8"/></svg></span>
      </div>
      <ol class="mk-viaje__pasos">
        ${PASOS.map(([t, s], i) => `
        <li class="mk-paso hecho ahora">
          <button type="button" class="mk-paso__btn" data-paso="${i}" aria-label="Paso ${i + 1}: ${t}">
            <span class="mk-paso__n">${i + 1}</span>
            <span class="mk-paso__arte">${ARTE[i]}</span>
            <b>${t}</b><small>${s}</small>
            <span class="mk-paso__tiempo"><i></i></span>
          </button>
        </li>`).join('')}
      </ol>
    </div>`;

  function bind() {
    const v = document.querySelector('.mk-viaje'); if (!v) return;
    const pasos = [...v.querySelectorAll('.mk-paso')];
    if (matchMedia('(prefers-reduced-motion: reduce)').matches) { v.classList.add('quieto'); return; }
    v.classList.add('vivo');
    let p = 0, t = null, visible = false, encima = false;
    const programar = () => {
      clearTimeout(t);
      const parar = !visible || encima || document.hidden;
      v.classList.toggle('pausa', parar);
      if (!parar) t = setTimeout(() => { if (document.body.contains(v)) ir(p + 1); }, DUR);
    };
    const ir = (n) => {
      p = (n + pasos.length) % pasos.length;
      v.style.setProperty('--p', p);
      pasos.forEach((li, i) => {
        li.classList.remove('ahora');
        li.classList.toggle('hecho', i < p);
        li.querySelector('button').setAttribute('aria-current', i === p ? 'step' : 'false');
      });
      void v.offsetWidth; // reinicia las animaciones del paso
      pasos[p].classList.add('ahora');
      programar();
    };
    v.addEventListener('click', (e) => { const b = e.target.closest('[data-paso]'); if (b) ir(Number(b.dataset.paso)); });
    v.addEventListener('pointerenter', (e) => { if (e.pointerType === 'mouse') { encima = true; programar(); } });
    v.addEventListener('pointerleave', () => { encima = false; programar(); });
    if ('IntersectionObserver' in window) {
      new IntersectionObserver(([x]) => { const antes = visible; visible = x.isIntersecting; if (visible && !antes) ir(0); else programar(); }, { threshold: 0.35 }).observe(v);
    } else { visible = true; }
    document.addEventListener('visibilitychange', () => { if (document.body.contains(v)) programar(); });
    ir(0);
  }

  window.AtlasViaje = { html, bind };
})();
