/* Atlas Motors — sitio web (sin dependencias, router por hash) */
(function () {
  const { CARS, CHECKLIST, PLANES, ABONO } = window.ATLAS;
  const $ = (s, el = document) => el.querySelector(s);
  const $$ = (s, el = document) => [...el.querySelectorAll(s)];
  let app = $('#app'); // se reemplaza en cada ruta para soltar listeners viejos

  /* ---------------- utilidades ---------------- */
  const clp = (n) => '$' + Math.round(n).toLocaleString('es-CL');
  const km = (n) => n.toLocaleString('es-CL') + ' km';
  const fecha = (iso, opts = { day: 'numeric', month: 'long', year: 'numeric' }) =>
    new Date(iso + 'T12:00:00').toLocaleDateString('es-CL', opts);
  const esc = (s) => String(s).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  const carById = (id) => CARS.find((c) => c.id === id);
  const title = (c) => `${c.marca} ${c.modelo} ${c.anio}`;

  /* Contacto: WhatsApp Business de Atlas Motors */
  const WA = '56935595554';
  const TEL = '+56 9 3559 5554';
  const IG = 'https://www.instagram.com/atlas.motors.cl/';
  const waLink = (msg) => `https://wa.me/${WA}${msg ? '?text=' + encodeURIComponent(msg) : ''}`;

  const ICONS = {
    menu: '<path d="M4 6h16M4 12h16M4 18h16"/>',
    x: '<path d="M18 6 6 18M6 6l12 12"/>',
    search: '<circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/>',
    arrow: '<path d="M5 12h14M13 6l6 6-6 6"/>',
    left: '<path d="m15 18-6-6 6-6"/>',
    right: '<path d="m9 18 6-6-6-6"/>',
    check: '<path d="m5 12 5 5L20 7"/>',
    shield: '<path d="M12 3 4 6v6c0 5 3.5 8 8 9 4.5-1 8-4 8-9V6l-8-3Z"/><path d="m9 12 2 2 4-4"/>',
    car: '<path d="M5 17h14M3 13l2-5a2 2 0 0 1 2-1.3h10A2 2 0 0 1 19 8l2 5v4a1 1 0 0 1-1 1h-1M3 13v4a1 1 0 0 0 1 1h1M3 13h18"/><circle cx="7.5" cy="17" r="1.8"/><circle cx="16.5" cy="17" r="1.8"/>',
    engine: '<path d="M4 10h2V8h3V6h6v2h2l2 3h2v5h-2l-2 2H9l-2-2H4z"/><path d="M12 10v3"/>',
    scan: '<rect x="6" y="2.5" width="12" height="19" rx="2"/><rect x="8.5" y="5" width="7" height="6" rx="1"/><path d="M10 15h4M10 18h4"/>',
    gear: '<circle cx="12" cy="12" r="3"/><path d="M12 2v3M12 19v3M4.2 4.2l2.1 2.1M17.7 17.7l2.1 2.1M2 12h3M19 12h3M4.2 19.8l2.1-2.1M17.7 6.3l2.1-2.1"/>',
    disc: '<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="3"/><path d="M12 3v3M21 12h-3M12 21v-3M3 12h3"/>',
    seat: '<path d="M7 3h5a2 2 0 0 1 2 2v7H8L6 5a1.6 1.6 0 0 1 1-2Z"/><path d="M6 12h11a2 2 0 0 1 2 2v2H6zM8 16v5M17 16v5"/>',
    doc: '<path d="M14 3H6a1 1 0 0 0-1 1v16a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1V8z"/><path d="M14 3v5h5M8 13h8M8 17h5"/>',
    download: '<path d="M12 3v12M7 10l5 5 5-5M5 21h14"/>',
    play: '<path d="M7 4v16l13-8z"/>',
    pin: '<path d="M12 21s-7-6-7-11a7 7 0 0 1 14 0c0 5-7 11-7 11Z"/><circle cx="12" cy="10" r="2.5"/>',
    calendar: '<rect x="3" y="5" width="18" height="16" rx="2"/><path d="M3 10h18M8 3v4M16 3v4"/>',
    clock: '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
    user: '<circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/>',
    phone: '<path d="M5 3h4l2 5-2.5 1.5a11 11 0 0 0 6 6L16 13l5 2v4a2 2 0 0 1-2 2A16 16 0 0 1 3 5a2 2 0 0 1 2-2Z"/>',
    chat: '<path d="M21 12a8 8 0 0 1-11.8 7L4 20l1.1-4.6A8 8 0 1 1 21 12Z"/>',
    mail: '<rect x="3" y="5" width="18" height="14" rx="2"/><path d="m3 7 9 6 9-6"/>',
    bell: '<path d="M6 8a6 6 0 0 1 12 0c0 7 3 8 3 8H3s3-1 3-8"/><path d="M10 20a2 2 0 0 0 4 0"/>',
    eye: '<path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12Z"/><circle cx="12" cy="12" r="3"/>',
    gauge: '<path d="M4 18a9 9 0 1 1 16 0"/><path d="m12 14 4-5"/>',
    fuel: '<path d="M4 21V5a2 2 0 0 1 2-2h7a2 2 0 0 1 2 2v16M3 21h13M15 9h2a2 2 0 0 1 2 2v6a1.5 1.5 0 0 0 3 0V8l-3-3"/><path d="M7 7h5"/>',
    camera: '<path d="M4 8h3l2-3h6l2 3h3a1 1 0 0 1 1 1v10a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V9a1 1 0 0 1 1-1Z"/><circle cx="12" cy="13" r="3.5"/>',
    handshake: '<path d="m11 17 2 2a1.4 1.4 0 0 0 2-2M14 14l2.5 2.5a1.4 1.4 0 0 0 2-2L15 11M3 7l4-3 5 2 3-2 6 3v7l-2 1M3 7v7l3 2M12 6 8.5 9.5a1.4 1.4 0 0 0 2 2L13 9"/>',
    target: '<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="5"/><circle cx="12" cy="12" r="1"/>',
    star: '<path d="m12 3 2.8 5.8 6.2.9-4.5 4.4 1 6.3L12 17.5 6.5 20.4l1-6.3L3 9.7l6.2-.9z"/>',
    filter: '<path d="M3 5h18l-7 8v6l-4 2v-8z"/>',
    card: '<rect x="2" y="5" width="20" height="14" rx="2"/><path d="M2 10h20M6 15h4"/>',
    print: '<path d="M6 9V3h12v6M6 18H4a1 1 0 0 1-1-1v-6a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v6a1 1 0 0 1-1 1h-2"/><rect x="6" y="14" width="12" height="7"/>',
    video: '<rect x="2.5" y="6" width="13" height="12" rx="2"/><path d="m15.5 10.5 6-3.5v10l-6-3.5"/>',
    glasses: '<circle cx="6.5" cy="14" r="3.5"/><circle cx="17.5" cy="14" r="3.5"/><path d="M10 14h4M3 14 4.5 7h2M21 14l-1.5-7h-2"/>',
    mic: '<rect x="9" y="3" width="6" height="11" rx="3"/><path d="M5 11a7 7 0 0 0 14 0M12 18v3"/>',
    instagram: '<rect x="3" y="3" width="18" height="18" rx="5"/><circle cx="12" cy="12" r="4"/><circle cx="17.5" cy="6.5" r=".6" fill="currentColor"/>',
    sparkle: '<path d="M12 3v4M12 17v4M3 12h4M17 12h4M6 6l2.5 2.5M15.5 15.5 18 18M6 18l2.5-2.5M15.5 8.5 18 6"/>',
  };
  const ic = (name, cls = '') => `<svg class="icon ${cls}" viewBox="0 0 24 24" aria-hidden="true">${ICONS[name] || ''}</svg>`;

  const toast = (msg) => {
    const t = $('#toast'); t.textContent = msg; t.classList.add('show');
    clearTimeout(toast._t); toast._t = setTimeout(() => t.classList.remove('show'), 2800);
  };

  const catStatus = (car, i) => {
    // Deriva un estado por categoría desde las observaciones del auto (demo)
    const fails = car.observaciones.filter((o) => o.nivel !== 'ok');
    const keyword = [/pintura|rayón|parachoques|repintad|golpe|pisadera|plumillas/i, /estructural/i, /motor|turbo|fuga/i, /neumático|amortiguador|suspensión|bujes/i, /tapiz|filtro de habitáculo|interior/i, /escáner|batería|códigos/i, /embrague|caja|tracción|pastilla|freno/i, /document|mantenci/i][i];
    const hit = fails.find((o) => keyword.test(o.texto));
    return hit ? hit.nivel : 'ok';
  };
  const statusLabel = { ok: 'Aprobado', obs: 'Observación', fail: 'Requiere reparación' };
  const statusCls = { ok: '', obs: 'w', fail: 'b' };

  /* ---------------- componentes ---------------- */
  const scannerArt = () => `
    <svg viewBox="0 0 600 460" role="img" aria-label="Escáner automotriz conectado al puerto OBD">
      <defs>
        <linearGradient id="g" x1="0" x2="1" y1="0" y2="1"><stop offset="0" stop-color="#f8e6a6"/><stop offset=".45" stop-color="#d4a62a"/><stop offset="1" stop-color="#9c7310"/></linearGradient>
        <linearGradient id="scr" x1="0" x2="0" y1="0" y2="1"><stop offset="0" stop-color="#0e2c1d"/><stop offset="1" stop-color="#05120b"/></linearGradient>
        <radialGradient id="glow" cx=".5" cy=".5" r=".5"><stop offset="0" stop-color="#d4a62a" stop-opacity=".35"/><stop offset="1" stop-color="#d4a62a" stop-opacity="0"/></radialGradient>
      </defs>
      <circle cx="300" cy="230" r="230" fill="url(#glow)"/>
      <g opacity=".14" stroke="#f3d36b">
        ${Array.from({ length: 12 }, (_, i) => `<line x1="0" y1="${i * 40}" x2="600" y2="${i * 40}"/>`).join('')}
      </g>
      <!-- cable -->
      <path d="M300 395 C 300 440, 470 440, 510 400" stroke="#1a1f1c" stroke-width="14" fill="none" stroke-linecap="round"/>
      <path d="M300 395 C 300 440, 470 440, 510 400" stroke="url(#g)" stroke-width="3" fill="none" stroke-dasharray="4 10"/>
      <rect x="490" y="360" width="70" height="44" rx="8" fill="#1a1f1c" stroke="url(#g)" stroke-width="3"/>
      <g fill="#d4a62a">${Array.from({ length: 8 }, (_, i) => `<rect x="${500 + i * 7}" y="372" width="3" height="8" rx="1"/>`).join('')}${Array.from({ length: 8 }, (_, i) => `<rect x="${500 + i * 7}" y="386" width="3" height="8" rx="1"/>`).join('')}</g>
      <text x="525" y="425" fill="#f3d36b" font-family="Inter" font-size="12" font-weight="700" text-anchor="middle">OBD-II</text>
      <!-- device -->
      <rect x="180" y="40" width="240" height="370" rx="34" fill="#0b0f0c" stroke="url(#g)" stroke-width="5"/>
      <rect x="204" y="70" width="192" height="190" rx="14" fill="url(#scr)" stroke="#24603f"/>
      <text x="300" y="98" fill="#f3d36b" font-family="Cinzel" font-size="15" font-weight="700" text-anchor="middle" letter-spacing="2">ATLAS SCAN</text>
      <!-- gauge -->
      <path d="M240 190 A60 60 0 0 1 360 190" stroke="#1a4630" stroke-width="12" fill="none" stroke-linecap="round"/>
      <path d="M240 190 A60 60 0 0 1 345 150" stroke="url(#g)" stroke-width="12" fill="none" stroke-linecap="round"/>
      <line x1="300" y1="190" x2="336" y2="150" stroke="#fff" stroke-width="3" stroke-linecap="round"/>
      <circle cx="300" cy="190" r="6" fill="#f3d36b"/>
      <text x="300" y="222" fill="#fff" font-family="Inter" font-size="22" font-weight="800" text-anchor="middle">96/100</text>
      <text x="300" y="244" fill="#7fd1a2" font-family="Inter" font-size="11" font-weight="600" text-anchor="middle">● 0 CÓDIGOS DE FALLA</text>
      <!-- buttons -->
      <circle cx="300" cy="320" r="34" fill="#113221" stroke="url(#g)" stroke-width="3"/>
      <circle cx="300" cy="320" r="12" fill="url(#g)"/>
      <rect x="216" y="300" width="34" height="14" rx="7" fill="#1a4630"/><rect x="216" y="326" width="34" height="14" rx="7" fill="#1a4630"/>
      <rect x="350" y="300" width="34" height="14" rx="7" fill="#1a4630"/><rect x="350" y="326" width="34" height="14" rx="7" fill="#1a4630"/>
      <!-- chips -->
      <g font-family="Inter" font-size="12" font-weight="700">
        <rect x="24" y="92" width="150" height="40" rx="12" fill="#fff"/><circle cx="46" cy="112" r="8" fill="#1f8a4c"/><text x="60" y="116" fill="#1a1f1c">Motor OK</text>
        <rect x="14" y="160" width="160" height="40" rx="12" fill="#fff"/><circle cx="36" cy="180" r="8" fill="#1f8a4c"/><text x="50" y="184" fill="#1a1f1c">ABS / Airbag OK</text>
        <rect x="430" y="110" width="150" height="40" rx="12" fill="#fff"/><circle cx="452" cy="130" r="8" fill="#c98a06"/><text x="466" y="134" fill="#1a1f1c">Batería 82 %</text>
        <rect x="440" y="180" width="140" height="40" rx="12" fill="#fff"/><circle cx="462" cy="200" r="8" fill="#1f8a4c"/><text x="476" y="204" fill="#1a1f1c">Km reales ✓</text>
      </g>
    </svg>`;

  const FAQS = () => [
    ['¿Cuánto cuesta la inspección?', `La inspección completa vale ${clp(PLANES[0].precio)}. Reservas tu hora con el ${ABONO * 100} % de abono (${clp(PLANES[0].precio * ABONO)}) por transferencia y pagas el resto el día de la inspección.`],
    ['¿Tengo que estar presente?', 'No. Si no puedes ir, hacemos la inspección remota: grabamos todo, te mandamos cada hallazgo con foto por WhatsApp en el momento y después te explicamos el estado real del auto por llamada o audio.'],
    ['¿La inspección es un diagnóstico?', 'No. La inspección precompra busca que no te vendan un auto chocado, con fallas graves escondidas o con el kilometraje alterado. Un diagnóstico requiere el auto varias horas en taller.'],
    ['¿Qué recibo al final?', 'Un informe en PDF con el checklist de las 8 etapas, fotos de lo que encontramos y una idea de cuánto cuesta reparar cada detalle, para que negocies el precio con respaldo.'],
    ['¿Revisan cualquier marca?', 'Sí. Revisamos autos, SUV y camionetas multimarca, a bencina y diésel, incluidos vehículos de alta gama.'],
    ['¿A qué comunas van?', 'La Serena, Coquimbo y Ovalle. Para otras comunas de la región, escríbenos y lo coordinamos.'],
  ];
  const faq = () => `
    <section class="section">
      <div class="container faq-wrap">
        <div><span class="eyebrow">Preguntas frecuentes</span><h2 class="display" style="font-size:clamp(26px,3.4vw,38px);color:var(--green-950);margin-top:10px">Lo que más nos preguntan</h2>
          <p style="color:var(--muted)">¿Tienes otra duda? Escríbenos y te respondemos al tiro.</p>
          <a class="btn btn--outline" href="${waLink('Hola Atlas Motors, tengo una consulta.')}" target="_blank" rel="noopener">${ic('chat')} Preguntar por WhatsApp</a>
        </div>
        <div class="faq">${FAQS().map(([q, a], i) => `<details ${i === 0 ? 'open' : ''}><summary>${q}<span class="faq__ic">${ic('right')}</span></summary><p>${a}</p></details>`).join('')}</div>
      </div>
    </section>`;

  /* ---------------- vistas ---------------- */
  function viewHome() {
    const completa = PLANES[0];
    return `
    <section class="hero">
      <div class="container hero__inner">
        <div>
          <span class="hero__badge"><span>ATLAS</span> Región de Coquimbo</span>
          <h1>Compra tu próximo auto con <span class="gold-text">ojo de águila</span>
            <small>Inspección precompra profesional en la Región de Coquimbo. Revisamos el auto <b>antes de que pagues</b>: carrocería, estructura, motor, escáner y prueba de ruta. Presencial o remota.</small>
          </h1>
          <div class="hero__cta">
            <a href="#/agendar" class="btn btn--gold btn--lg">${ic('calendar')} Agendar inspección</a>
            <a href="${waLink('Hola Atlas Motors, quiero agendar una inspección precompra.')}" target="_blank" rel="noopener" class="btn btn--ghost btn--lg">${ic('chat')} Escríbenos por WhatsApp</a>
          </div>
          <div class="hero__stats">
            <div><b>8</b><span>etapas de revisión</span></div>
            <div><b>${clp(completa.precio)}</b><span>inspección completa</span></div>
            <div><b>${ABONO * 100} %</b><span>de abono para reservar</span></div>
          </div>
        </div>
        <div class="hero__visual">
          <div class="scanner-art">${scannerArt()}</div>
          <div class="float-chip float-chip--a"><span class="ic">${ic('shield')}</span><div><b>Medidor de pintura</b>Detecta repintados y choques</div></div>
          <div class="float-chip float-chip--b"><span class="ic">${ic('doc')}</span><div><b>Informe PDF</b>Con fotos y costos de reparación</div></div>
        </div>
      </div>
    </section>

    <div class="container">
      <div class="trust">
        <div class="trust__item"><span class="ic">${ic('scan')}</span><div><b>Recorrido en 8 etapas</b><span>Siempre en el mismo orden, sin saltarse nada.</span></div></div>
        <div class="trust__item"><span class="ic">${ic('doc')}</span><div><b>Informe con fotos</b><span>Checklist completo y costo estimado de reparaciones.</span></div></div>
        <div class="trust__item"><span class="ic">${ic('video')}</span><div><b>Inspección remota</b><span>Si no puedes ir, te mandamos todo en vivo.</span></div></div>
        <div class="trust__item"><span class="ic">${ic('pin')}</span><div><b>Hecho en Coquimbo</b><span>La Serena, Coquimbo, Ovalle y más.</span></div></div>
      </div>
    </div>

    <section class="section dark">
      <div class="container">
        <div class="section__head">
          <div><span class="eyebrow">Servicios</span><h2>¿Cómo te ayudamos?</h2><p>Dos formas de comprar seguro: revisamos el auto que encontraste, o buscamos el auto por ti.</p></div>
        </div>
        <div class="services">
          <a class="service-card" href="#/inspeccion">
            <span class="bg-icon">${ic('scan')}</span>
            <span class="pill" style="align-self:start;margin-bottom:auto">${clp(completa.precio)}</span>
            <h3>Inspección precompra</h3>
            <p>Vamos a donde está el auto con escáner y medidor de pintura. ¿No puedes ir? Te mandamos cada hallazgo con foto en el momento y el informe en PDF.</p>
            <span class="link">Ver servicio y agendar ${ic('arrow')}</span>
          </a>
          <a class="service-card" href="#/busqueda">
            <span class="bg-icon">${ic('target')}</span>
            <span class="pill" style="align-self:start;margin-bottom:auto">Sin costo para ti</span>
            <h3>Búsqueda personalizada</h3>
            <p>Dinos qué auto buscas y tu presupuesto. Hacemos el estudio de mercado, lo inspeccionamos y negociamos por ti.</p>
            <span class="link">Quiero que me busquen un auto ${ic('arrow')}</span>
          </a>
        </div>
      </div>
    </section>

    <section class="section">
      <div class="container">
        <div class="section__head"><div><span class="eyebrow">Así funciona</span><h2>Comprar seguro en 4 pasos</h2></div></div>
        <div class="steps">
          <div class="step"><h4>Agenda</h4><p>Cuéntanos qué auto es, dónde está y qué día te acomoda. Aquí o por WhatsApp.</p></div>
          <div class="step"><h4>Reserva tu hora</h4><p>Con el ${ABONO * 100} % de abono (${clp(completa.precio * ABONO)}) por transferencia. El resto, el día de la inspección.</p></div>
          <div class="step"><h4>Inspeccionamos</h4><p>8 etapas: carrocería, estructura, motor, parte baja, interior, escáner y prueba de ruta.</p></div>
          <div class="step"><h4>Decide con datos</h4><p>Recibe el informe con fotos y el costo de cada reparación. Compra o negocia con respaldo.</p></div>
        </div>
      </div>
    </section>

    <section class="section--tight">
      <div class="container">
        <div class="mascot">
          <div class="mascot__img"><img src="assets/img/mascota.jpg" alt="Águila mascota de Atlas Motors con overol de mecánico levantando el pulgar" loading="lazy"></div>
          <div style="position:relative;z-index:1">
            <span class="bubble">¡Hola! ¿Te ayudo? 👋</span>
            <h2>Soy el ojo de águila de Atlas</h2>
            <p>No se me escapa nada: un repintado, un código de falla escondido o un kilometraje alterado. Cuéntame qué necesitas y te guío al tiro.</p>
            <div class="mascot__actions">
              <a class="btn btn--green" href="#/agendar">${ic('calendar')} Agendar inspección</a>
              <a class="btn btn--outline" href="#/busqueda">${ic('target')} Búscame un auto</a>
              <a class="btn btn--outline" href="${waLink()}" target="_blank" rel="noopener">${ic('chat')} Hablar por WhatsApp</a>
              <a class="btn btn--outline" href="${IG}" target="_blank" rel="noopener">${ic('instagram')} Ver Instagram</a>
            </div>
          </div>
        </div>
      </div>
    </section>

    ${faq()}

    <section class="section--tight">
      <div class="container">
        <a class="ig-band" href="${IG}" target="_blank" rel="noopener">
          <span class="ig-band__icon">${ic('instagram')}</span>
          <span class="ig-band__text"><b>Síguenos en Instagram</b><span>Inspecciones reales, hallazgos y consejos para comprar seguro. Mira nuestras historias en <b>@atlas.motors.cl</b></span></span>
          <span class="btn btn--gold">${ic('instagram')} Seguir</span>
        </a>
      </div>
    </section>

    <section class="section">
      <div class="container">
        <div class="cta-band">
          <div><span class="eyebrow">Próximamente</span><h2>Marketplace de autos inspeccionados</h2><p>Muy pronto podrás comprar autos que ya pasaron por la inspección de Atlas, con su informe a la vista.</p></div>
          <a href="#/agendar" class="btn btn--gold btn--lg">${ic('calendar')} Agendar inspección</a>
        </div>
      </div>
    </section>`;
  }

  function viewProximamente() {
    return `
    <section class="page-hero">
      <div class="container">
        <div class="crumbs"><a href="#/">Inicio</a> / Vehículos</div>
        <h1>Autos inspeccionados</h1>
        <p>Estamos preparando el marketplace de Atlas Motors: autos que ya pasaron nuestra inspección, con fotos e informe a la vista. Muy pronto.</p>
      </div>
    </section>
    <section class="section">
      <div class="container">
        <div class="callout">
          <span class="ic">${ic('target')}</span>
          <div>
            <h3>¿Buscas auto ahora?</h3>
            <p>Mientras tanto, podemos buscarlo por ti o inspeccionar el que ya encontraste.</p>
            <div style="display:flex;gap:10px;flex-wrap:wrap;margin-top:14px">
              <a class="btn btn--gold" href="#/busqueda">${ic('target')} Búsqueda personalizada</a>
              <a class="btn btn--outline" href="#/agendar">${ic('calendar')} Agendar inspección</a>
            </div>
          </div>
        </div>
      </div>
    </section>`;
  }

  function viewInforme(id) {
    const c = carById(id);
    if (!c) return viewNotFound();
    const folio = 'ATM-' + c.fechaInspeccion.replace(/-/g, '').slice(2) + '-' + String(CARS.indexOf(c) + 101);
    const patente = ['RTKZ', 'PLVB', 'SDFG', 'RHWX', 'PKTL', 'LXJR', 'PZHV', 'LRCF'][CARS.indexOf(c) % 8] + '·' + (20 + CARS.indexOf(c) * 7);
    const cats = CHECKLIST.map((k, i) => ({ ...k, st: catStatus(c, i) }));
    const rowStatus = (cat, j) => {
      if (cat.st === 'ok') return 'ok';
      return j === 0 || (cat.st === 'fail' && j === 1) ? cat.st : 'ok';
    };
    const counts = { ok: 0, obs: 0, fail: 0 };
    cats.forEach((k) => k.items.forEach((_, j) => counts[rowStatus(k, j)]++));
    return `
    <div class="report-wrap">
      <div class="container">
        <div class="report-actions">
          <a class="btn btn--outline btn--sm" href="#/inspeccion">${ic('left')} Volver</a>
          <a class="btn btn--gold" href="#/agendar">${ic('calendar')} Agendar mi inspección</a>
        </div>
        <article class="report">
          <header class="report__head">
            <img src="assets/img/logo-wordmark.png" alt="Atlas Motors">
            <div class="meta"><b>INFORME DE INSPECCIÓN PRECOMPRA · EJEMPLO</b>Folio ${folio}<br>Fecha: ${fecha(c.fechaInspeccion)} · ${c.comuna}</div>
          </header>
          <div class="report__body">
            <section class="report__top">
              <div>
                <h1>${esc(c.marca)} ${esc(c.modelo)} ${c.anio}</h1>
                <p style="color:var(--muted);margin:4px 0 12px">${esc(c.version)}</p>
                <div class="legend">
                  <span class="status status--ok">✓ ${counts.ok} aprobados</span>
                  <span class="status status--obs">! ${counts.obs} observaciones</span>
                  <span class="status status--fail">✕ ${counts.fail} requieren reparación</span>
                </div>
              </div>
              <div class="ring" style="--v:${c.score};width:110px;height:110px"><div style="width:88px;height:88px;font-size:30px">${c.score}<small>de 100</small></div></div>
            </section>

            <h2>Datos del vehículo</h2>
            <div class="two">
              <table class="kv"><tbody>
                <tr><td>Marca / Modelo</td><td><b>${esc(c.marca)} ${esc(c.modelo)}</b></td></tr>
                <tr><td>Año</td><td>${c.anio}</td></tr>
                <tr><td>Patente</td><td>${patente}</td></tr>
                <tr><td>Kilometraje</td><td>${km(c.km)}</td></tr>
              </tbody></table>
              <table class="kv"><tbody>
                <tr><td>Combustible</td><td>${c.combustible}</td></tr>
                <tr><td>Transmisión</td><td>${c.transmision} · ${c.traccion}</td></tr>
                <tr><td>Color</td><td>${c.color}</td></tr>
                <tr><td>Inspector</td><td>Atlas Motors</td></tr>
              </tbody></table>
            </div>

            <h2>Conclusión del inspector</h2>
            <p>${esc(c.resumen)}</p>
            <ul class="obs-list">${c.observaciones.map((o) => `<li><span class="dot dot--${o.nivel}">${o.nivel === 'ok' ? '✓' : '!'}</span><span>${esc(o.texto)}</span></li>`).join('')}</ul>

            <h2>Checklist de inspección</h2>
            ${cats.map((k, n) => `
              <section style="margin-bottom:16px">
                <table>
                  <thead><tr><th>${n + 1}. ${k.cat}</th><th style="width:170px;text-align:right">Estado</th></tr></thead>
                  <tbody>${k.items.map((it, j) => { const s = rowStatus(k, j); return `<tr><td>${it}</td><td style="text-align:right"><span class="status status--${s}">${statusLabel[s]}</span></td></tr>`; }).join('')}</tbody>
                </table>
              </section>`).join('')}

            <h2>Registro fotográfico</h2>
            <div class="photos">${c.fotos.map((f) => `<img src="${f}" alt="">`).join('')}</div>

            <h2>Alcance de la inspección</h2>
            <div class="alcance">
              <p><b>${c.observaciones.some((o) => o.nivel === 'fail') ? 'Durante la inspección se detectaron las fallas indicadas en este informe.' : 'Durante todo el tiempo que duró la inspección, el vehículo no presentó fallas graves.'}</b></p>
              <ul>
                <li>Este informe refleja el estado del vehículo solo en la fecha, hora y lugar de la inspección.</li>
                <li>Una inspección precompra no es un diagnóstico mecánico: es una revisión visual, electrónica y en ruta que busca reducir el riesgo de una mala compra o de una estafa.</li>
                <li>Atlas Motors no se responsabiliza por fallas que aparezcan después de la inspección, ya que dependen del uso, la conducción, el estado de los caminos y la mantención del vehículo.</li>
                <li>Los costos de reparación indicados son referenciales.</li>
              </ul>
            </div>

            <div class="sign">
              <div><img src="assets/img/logo-shield.png" alt=""><br>Informe de ejemplo: así se ve el que recibes después de tu inspección.</div>
              <div class="line">Inspector Atlas Motors</div>
            </div>
          </div>
        </article>
      </div>
    </div>`;
  }

  function viewInspeccion() {
    const completa = PLANES.find((p) => p.destacado) || PLANES[0];
    return `
    <section class="page-hero">
      <div class="container">
        <div class="crumbs"><a href="#/">Inicio</a> / Servicios / Inspección precompra</div>
        <h1>Inspección precompra</h1>
        <p>Antes de pagar, deja que el ojo de águila revise el auto. Vamos a donde esté el vehículo, en toda la Región de Coquimbo. Y si no puedes estar presente, te lo mostramos en vivo.</p>
      </div>
    </section>

    <section class="section">
      <div class="container split">
        <div class="scanner-art">${scannerArt()}</div>
        <div>
          <span class="eyebrow">¿Qué es?</span>
          <h2 class="display" style="font-size:clamp(26px,3.4vw,38px);color:var(--green-950);margin-top:10px">Una revisión profesional antes de que pongas tu plata</h2>
          <p>Revisamos el vehículo en el mismo orden, siempre: carrocería 360° con <b>medidor de pintura</b>, estructura y chasis, motor, parte baja, interior, <b>escáner</b> y <b>prueba de ruta</b>. Multimarca, bencineros, diésel y alta gama.</p>
          <p>Te decimos el estado real del auto. Si tiene detalles menores, te damos <b>una idea de cuánto cuesta repararlos</b> para que negocies el precio con respaldo. Si tiene fallas graves, te lo decimos claro: no te lo recomendamos.</p>
          <div style="display:flex;gap:12px;flex-wrap:wrap;margin-top:22px">
            <a class="btn btn--gold btn--lg" href="#/agendar">${ic('calendar')} Agendar inspección</a>
            <a class="btn btn--outline btn--lg" href="#/informe/${CARS[0].id}">${ic('doc')} Ver informe de ejemplo</a>
          </div>
        </div>
      </div>
    </section>

    <section class="section--tight">
      <div class="container stats">
        <div class="stat"><b>8</b><span>etapas de revisión</span></div>
        <div class="stat"><b>${clp(completa.precio)}</b><span>inspección completa</span></div>
        <div class="stat"><b>${clp(completa.precio * ABONO)}</b><span>abono para reservar</span></div>
        <div class="stat"><b>2</b><span>modalidades: presencial o remota</span></div>
      </div>
    </section>

    <section class="section dark">
      <div class="container">
        <div class="section__head"><div><span class="eyebrow">Nuestro recorrido</span><h2>Así revisamos tu próximo auto</h2><p>Las mismas 8 etapas en cada inspección, en este orden.</p></div></div>
        <div class="includes">
          ${CHECKLIST.map((k, n) => `<div class="include"><span class="ic">${ic(k.icon)}</span><h4>${n + 1}. ${k.cat}</h4><ul>${k.items.slice(0, 4).map((i) => `<li>${i}</li>`).join('')}</ul></div>`).join('')}
        </div>
      </div>
    </section>

    <section class="section">
      <div class="container split" style="align-items:start">
        <div>
          <span class="eyebrow">Inspección remota</span>
          <h2 class="display" style="font-size:clamp(26px,3.4vw,38px);color:var(--green-950);margin-top:10px">¿No puedes estar presente? Igual lo ves todo</h2>
          <p>Muchos autos están en otra comuna o en una automotora en horario de oficina. Para eso inventamos la inspección remota.</p>
        </div>
        <div class="remote-steps">
          <div class="remote-step"><span class="ic">${ic('glasses')}</span><div><b>Grabamos la inspección completa</b><p>Con lentes inteligentes: ves exactamente lo que ve el inspector.</p></div></div>
          <div class="remote-step"><span class="ic">${ic('camera')}</span><div><b>Te mandamos cada hallazgo con foto</b><p>Por WhatsApp y en el momento: un choque, una fuga, una pieza repintada.</p></div></div>
          <div class="remote-step"><span class="ic">${ic('mic')}</span><div><b>Te explicamos el estado real</b><p>Por llamada o audio: qué es grave, qué es un detalle y cuánto costaría repararlo.</p></div></div>
          <div class="remote-step"><span class="ic">${ic('doc')}</span><div><b>Recibes el informe en PDF</b><p>Con fotos y checklist, para negociar con el vendedor o la automotora.</p></div></div>
        </div>
      </div>
    </section>

    <section class="section--tight">
      <div class="container">
        <div class="callout">
          <span class="ic">${ic('eye')}</span>
          <div>
            <h3>Una inspección precompra no es un diagnóstico</h3>
            <p>La inspección busca que no te vendan un auto chocado, con fallas graves escondidas o con el kilometraje alterado. Un diagnóstico es otra cosa: requiere el auto varias horas en taller para, por ejemplo, analizar el fluido de la caja o medir la compresión. El informe refleja el estado del vehículo el día de la inspección; no cubre fallas que aparezcan después, que dependen del uso y la mantención.</p>
          </div>
        </div>
      </div>
    </section>

    <section class="section">
      <div class="container">
        <div class="section__head" style="justify-content:center;text-align:center"><div><span class="eyebrow">Valores</span><h2>Inspección completa</h2><p style="margin-inline:auto">Reservas tu hora con el ${ABONO * 100} % de abono por transferencia y pagas el resto el día de la inspección.</p></div></div>
        <div class="plans" style="grid-template-columns:minmax(0,1fr);max-width:480px;margin-inline:auto">
          ${PLANES.map((p) => `
            <div class="plan ${p.destacado ? 'featured' : ''}">
              
              <h3>${p.nombre}</h3>
              <div class="amount">${clp(p.precio)} <small>CLP</small></div>
              <p>${p.desc} Reserva con ${clp(p.precio * ABONO)}.</p>
              <ul>${p.incluye.map((i) => `<li>${ic('check')} ${i}</li>`).join('')}</ul>
              <a class="btn ${p.destacado ? 'btn--gold' : 'btn--green'} btn--block" href="#/agendar">${ic('calendar')} Agendar inspección</a>
            </div>`).join('')}
        </div>
      </div>
    </section>

    ${faq()}

    <section class="section--tight" style="padding-bottom:88px">
      <div class="container">
        <div class="cta-band">
          <div><h2>Agenda en 2 minutos</h2><p>Elige día y hora, cuéntanos del auto y te confirmamos por WhatsApp.</p></div>
          <a href="#/agendar" class="btn btn--gold btn--lg">${ic('calendar')} Agendar aquí</a>
        </div>
      </div>
    </section>`;
  }

  /* -------- Agenda: arma la solicitud y la envía por WhatsApp -------- */
  const booking = { step: 0, date: null, time: null, data: { presente: 'si', donde: 'Particular' }, month: null, sent: false };
  const COMUNAS = ['La Serena', 'Coquimbo', 'Ovalle', 'Otra comuna'];
  const STEPS = ['Fecha y hora', 'Vehículo y datos', 'Enviar'];
  const SLOTS = ['09:00', '10:30', '12:00', '14:00', '15:30', '17:00', '18:30'];
  const iso = (d) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
  const diaLargo = (isoDate) => new Date(isoDate + 'T12:00:00').toLocaleDateString('es-CL', { weekday: 'long', day: 'numeric', month: 'long' });

  const mensajeReserva = () => {
    const d = booking.data;
    return [
      'Hola Atlas Motors, quiero agendar una inspección precompra.',
      '',
      `Vehículo: ${d.vehiculo}`,
      `Vendedor: ${d.donde}`,
      `Día y hora: ${diaLargo(booking.date)}, ${booking.time}`,
      `Lugar: ${[d.direccion, d.comuna].filter(Boolean).join(', ')}`,
      `Modalidad: ${d.presente === 'no' ? 'remota (no estaré presente)' : 'presencial'}`,
      d.link ? `Publicación: ${d.link}` : '',
      d.nota ? `Comentarios: ${d.nota}` : '',
      '',
      `Nombre: ${d.nombre}`,
      `Teléfono: ${d.telefono}`,
    ].filter((l, i, a) => l !== '' || a[i - 1] !== '').join('\n').trim();
  };

  function viewAgendar() {
    return `
    <section class="page-hero" style="padding:44px 0 50px">
      <div class="container">
        <div class="crumbs"><a href="#/">Inicio</a> / <a href="#/inspeccion">Inspección precompra</a> / Agendar</div>
        <h1>Agenda tu inspección</h1>
        <p>Elige el día y la hora, cuéntanos del auto y te confirmamos por WhatsApp. Reservas con el ${ABONO * 100} % de abono. Si no puedes estar presente, la hacemos en modalidad remota.</p>
      </div>
    </section>
    <section class="section--tight" style="padding-bottom:88px">
      <div class="container" id="booking"></div>
    </section>`;
  }

  function bindAgendar() {
    const root = $('#booking');
    const today = new Date(); today.setHours(0, 0, 0, 0);
    if (!booking.month) booking.month = new Date(today.getFullYear(), today.getMonth(), 1);
    const plan = PLANES[0];
    const canNext = () => [booking.date && booking.time, ['nombre', 'telefono', 'vehiculo', 'comuna'].every((k) => (booking.data[k] || '').trim()), true][booking.step];

    const stepBody = () => {
      if (booking.step === 0) {
        const m = booking.month; const first = (m.getDay() + 6) % 7; const days = new Date(m.getFullYear(), m.getMonth() + 1, 0).getDate();
        const label = m.toLocaleDateString('es-CL', { month: 'long', year: 'numeric' });
        const max = new Date(today); max.setDate(max.getDate() + 60);
        let cells = ['L', 'M', 'M', 'J', 'V', 'S', 'D'].map((d) => `<span class="dow">${d}</span>`).join('');
        cells += '<span></span>'.repeat(first);
        for (let d = 1; d <= days; d++) {
          const dt = new Date(m.getFullYear(), m.getMonth(), d);
          const dis = dt < today || dt.getDay() === 0 || dt > max;
          cells += `<button type="button" data-date="${iso(dt)}" ${dis ? 'disabled' : ''} class="${booking.date === iso(dt) ? 'on' : ''} ${+dt === +today ? 'today' : ''}">${d}</button>`;
        }
        return `
          <h3>¿Qué día y a qué hora?</h3>
          <div class="cal">
            <div class="cal__head"><button type="button" data-month="-1" aria-label="Mes anterior">${ic('left')}</button><b>${label}</b><button type="button" data-month="1" aria-label="Mes siguiente">${ic('right')}</button></div>
            <div class="cal__grid">${cells}</div>
          </div>
          ${booking.date ? `<p style="margin:18px 0 0;font-weight:600">Hora preferida para el ${diaLargo(booking.date)}</p>
          <div class="slots">${SLOTS.map((s) => `<button type="button" class="slot ${booking.time === s ? 'on' : ''}" data-time="${s}">${s}</button>`).join('')}</div>
          <p style="margin:12px 0 0;font-size:13px;color:var(--muted)">Te confirmamos la disponibilidad por WhatsApp.</p>` : '<p style="margin:16px 0 0;color:var(--muted)">Selecciona un día. Atendemos de lunes a sábado.</p>'}`;
      }
      if (booking.step === 1) {
        const d = booking.data; const v = (k) => esc(d[k] || '');
        return `
          <h3>El vehículo y tus datos</h3>
          <div class="form-grid" id="dataForm">
            <div class="field full"><label for="b-veh">Vehículo a inspeccionar *</label><input class="input" id="b-veh" data-k="vehiculo" value="${v('vehiculo')}" placeholder="Marca, modelo y año. Ej: Toyota Hilux 2021"></div>
            <div class="field"><label for="b-donde">¿Quién lo vende?</label><select class="select" id="b-donde" data-k="donde">${['Particular', 'Automotora'].map((o) => `<option ${d.donde === o ? 'selected' : ''}>${o}</option>`).join('')}</select></div>
            <div class="field"><label for="b-com">Comuna *</label><select class="select" id="b-com" data-k="comuna"><option value="">Selecciona</option>${COMUNAS.map((c) => `<option ${d.comuna === c ? 'selected' : ''}>${c}</option>`).join('')}</select></div>
            <div class="field full"><label for="b-dir">Dirección donde está el auto</label><input class="input" id="b-dir" data-k="direccion" value="${v('direccion')}" placeholder="Si aún no la tienes, la coordinamos por WhatsApp"></div>
            <div class="field full"><label for="b-pres">¿Estarás presente en la inspección?</label><select class="select" id="b-pres" data-k="presente"><option value="si" ${d.presente !== 'no' ? 'selected' : ''}>Sí, voy a estar</option><option value="no" ${d.presente === 'no' ? 'selected' : ''}>No, prefiero la inspección remota</option></select></div>
            <div class="field"><label for="b-nombre">Tu nombre *</label><input class="input" id="b-nombre" data-k="nombre" value="${v('nombre')}" autocomplete="name"></div>
            <div class="field"><label for="b-tel">Tu teléfono *</label><input class="input" id="b-tel" data-k="telefono" value="${v('telefono')}" inputmode="tel" placeholder="+56 9 …" autocomplete="tel"></div>
            <div class="field full"><label for="b-link">Link de la publicación (opcional)</label><input class="input" id="b-link" data-k="link" value="${v('link')}" placeholder="Yapo, Chileautos, Marketplace…"></div>
            <div class="field full"><label for="b-nota">Comentarios (opcional)</label><textarea class="textarea" id="b-nota" data-k="nota" placeholder="Ej: el vendedor solo puede después de las 14:00">${v('nota')}</textarea></div>
          </div>`;
      }
      return `
        <h3>Envía tu solicitud</h3>
        <p style="color:var(--muted)">Se abrirá WhatsApp con tu solicitud lista para enviar. Te confirmamos la hora y te mandamos los datos de la cuenta empresa para el abono.</p>
        <div class="remote-steps" style="margin-top:16px">
          <div class="remote-step"><span class="ic">${ic('chat')}</span><div><b>1. Envías el mensaje</b><p>Con el auto, el día y la hora que elegiste.</p></div></div>
          <div class="remote-step"><span class="ic">${ic('card')}</span><div><b>2. Transfieres el abono de ${clp(plan.precio * ABONO)}</b><p>El ${ABONO * 100} % del servicio, para dejar la hora reservada.</p></div></div>
          <div class="remote-step"><span class="ic">${ic('check')}</span><div><b>3. Inspeccionamos</b><p>El saldo de ${clp(plan.precio - plan.precio * ABONO)} se paga el día de la inspección.</p></div></div>
        </div>
        ${booking.sent ? `<p style="margin-top:16px;font-size:14px">¿No se abrió WhatsApp? <a href="${waLink(mensajeReserva())}" target="_blank" rel="noopener" style="color:var(--gold-700);font-weight:700">Toca aquí</a> o escríbenos al ${TEL}.</p>` : ''}`;
    };

    const summary = () => {
      const d = booking.data;
      return `
        <aside class="panel summary">
          <h3>Resumen</h3>
          <dl>
            <dt>Servicio</dt><dd>Inspección ${plan.nombre}</dd>
            <dt>Día</dt><dd>${booking.date ? new Date(booking.date + 'T12:00:00').toLocaleDateString('es-CL', { weekday: 'short', day: 'numeric', month: 'short' }) : '—'}</dd>
            <dt>Hora</dt><dd>${booking.time || '—'}</dd>
            <dt>Vehículo</dt><dd>${esc(d.vehiculo || '—')}</dd>
            <dt>Lugar</dt><dd>${esc([d.direccion, d.comuna].filter(Boolean).join(', ') || '—')}</dd>
            <dt>Modalidad</dt><dd>${d.presente === 'no' ? 'Remota' : 'Presencial'}</dd>
            <dt>Valor</dt><dd>${clp(plan.precio)}</dd>
          </dl>
          <div class="total"><span>Abono para reservar</span><span>${clp(plan.precio * ABONO)}</span></div>
          ${d.comuna === 'Otra comuna' ? '<p style="margin:14px 0 0;font-size:13px;color:var(--muted)">Para otras comunas te confirmamos disponibilidad y traslado por WhatsApp.</p>' : ''}
        </aside>`;
    };

    const draw = () => {
      root.innerHTML = `
        <div class="booking">
          <div class="panel">
            <div class="stepper">${STEPS.map((s, i) => `<div class="${i <= booking.step ? 'on' : ''}">${i + 1}. ${s}</div>`).join('')}</div>
            ${stepBody()}
            <div class="wizard-nav">
              ${booking.step > 0 ? `<button type="button" class="btn btn--outline" data-go="-1">${ic('left')} Atrás</button>` : '<span></span>'}
              ${booking.step === 2
                ? `<a class="btn btn--gold" data-action="send-booking" href="${waLink(mensajeReserva())}" target="_blank" rel="noopener">${ic('chat')} Enviar por WhatsApp</a>`
                : `<button type="button" class="btn btn--gold" data-go="1" ${canNext() ? '' : 'disabled'}>Continuar ${ic('arrow')}</button>`}
            </div>
          </div>
          ${summary()}
        </div>`;
    };

    root.addEventListener('click', (e) => {
      const t = e.target;
      const mo = t.closest('[data-month]'); if (mo) {
        const n = new Date(booking.month.getFullYear(), booking.month.getMonth() + +mo.dataset.month, 1);
        if (n >= new Date(today.getFullYear(), today.getMonth(), 1) && n <= new Date(today.getFullYear(), today.getMonth() + 2, 1)) booking.month = n;
        return draw();
      }
      const dt = t.closest('[data-date]'); if (dt) { booking.date = dt.dataset.date; booking.time = null; return draw(); }
      const tm = t.closest('[data-time]'); if (tm) { booking.time = tm.dataset.time; return draw(); }
      if (t.closest('[data-action="send-booking"]')) { booking.sent = true; setTimeout(draw, 300); return; }
      const go = t.closest('[data-go]'); if (go) {
        booking.step = Math.min(2, Math.max(0, booking.step + +go.dataset.go)); draw();
        root.scrollIntoView({ behavior: 'smooth', block: 'start' });
      }
    });
    const onField = (e) => {
      const k = e.target.dataset.k; if (!k) return;
      booking.data[k] = e.target.value;
      const btn = $('[data-go="1"]', root); if (btn) btn.disabled = !canNext();
      const s = $('.summary', root); if (s) s.outerHTML = summary();
    };
    root.addEventListener('input', onField);
    root.addEventListener('change', onField);
    draw();
  }

  function viewBusqueda() {
    const marcas = ['Toyota', 'Ford', 'Chevrolet', 'Hyundai', 'Kia', 'Mazda', 'Mitsubishi', 'Nissan', 'Suzuki', 'Volkswagen', 'Peugeot', 'Subaru', 'MG', 'Otra'];
    return `
    <section class="page-hero">
      <div class="container">
        <div class="crumbs"><a href="#/">Inicio</a> / Servicios / Búsqueda personalizada</div>
        <h1>Búsqueda personalizada</h1>
        <p>Nosotros buscamos el vehículo por ti. Tú nos dices qué quieres y cuánto tienes; nosotros hacemos el estudio de mercado, lo inspeccionamos y negociamos.</p>
      </div>
    </section>

    <section class="section">
      <div class="container">
        <div class="section__head"><div><span class="eyebrow">Cómo funciona</span><h2>Tu auto ideal, sin perder fines de semana</h2></div></div>
        <div class="how">
          <div class="step"><h4>Cuéntanos qué buscas</h4><p>Marca, modelo, años y presupuesto. Completa el formulario en 1 minuto.</p></div>
          <div class="step"><h4>Te llamamos y estudiamos el mercado</h4><p>Matías te contacta, afina lo que necesitas y analiza las opciones reales disponibles.</p></div>
          <div class="step"><h4>Inspeccionamos y negociamos</h4><p>Solo te presentamos autos que pasaron nuestra inspección, y negociamos el mejor precio.</p></div>
        </div>
        <div class="callout" style="margin-top:24px">
          <span class="ic">${ic('handshake')}</span>
          <div>
            <h3>Sin ningún costo adicional para ti</h3>
            <p>Nuestro trabajo se paga con el descuento que negociamos con el vendedor. Firmamos un <b>contrato de preferencia</b>: tú tienes prioridad sobre el auto que encontramos para ti y nosotros jugamos de tu lado en la negociación.</p>
          </div>
        </div>
      </div>
    </section>

    <section class="section dark" id="formSection">
      <div class="container split" style="align-items:start">
        <div>
          <span class="eyebrow">Solicitud</span>
          <h2 class="display" style="font-size:clamp(28px,3.6vw,42px);color:#fff;margin-top:10px">Envíanos lo que buscas</h2>
          <p style="color:#c7cfc9">Te contactamos para entender bien lo que necesitas.</p>
          <div class="mascot__img" style="max-width:320px;margin-top:20px;border-radius:24px"><img src="assets/img/mascota.jpg" alt="Mascota de Atlas Motors" loading="lazy"></div>
        </div>
        <form class="panel" id="searchForm" novalidate>
          <div class="form-grid">
            <div class="field"><label for="s-nombre">Nombre *</label><input class="input" id="s-nombre" name="nombre" required autocomplete="name"></div>
            <div class="field"><label for="s-tel">Teléfono / WhatsApp *</label><input class="input" id="s-tel" name="telefono" required inputmode="tel" placeholder="+56 9 …" autocomplete="tel"></div>
            <div class="field full"><label for="s-email">Correo</label><input class="input" id="s-email" name="email" type="email" autocomplete="email"></div>
            <div class="field"><label for="s-marca">Marca *</label><select class="select" id="s-marca" name="marca" required><option value="">Selecciona</option>${marcas.map((m) => `<option>${m}</option>`).join('')}</select></div>
            <div class="field"><label for="s-modelo">Modelo *</label><input class="input" id="s-modelo" name="modelo" required placeholder="Ej: Hilux, Tucson…"></div>
            <div class="field"><label for="s-desde">Año desde</label><select class="select" id="s-desde" name="desde">${Array.from({ length: 12 }, (_, i) => 2025 - i).map((y) => `<option ${y === 2020 ? 'selected' : ''}>${y}</option>`).join('')}</select></div>
            <div class="field"><label for="s-hasta">Año hasta</label><select class="select" id="s-hasta" name="hasta">${Array.from({ length: 12 }, (_, i) => 2026 - i).map((y) => `<option ${y === 2023 ? 'selected' : ''}>${y}</option>`).join('')}</select></div>
            <div class="field full">
              <label for="s-budget">Presupuesto máximo</label>
              <div class="budget-out" id="budgetOut">${clp(10000000)}</div>
              <input type="range" id="s-budget" name="presupuesto" min="3000000" max="50000000" step="500000" value="10000000">
            </div>
            <div class="field full"><label>Transmisión</label><div class="chips" data-group="trans">${['Indiferente', 'Automática', 'Manual'].map((t, i) => `<button type="button" class="chip ${i === 0 ? 'on' : ''}">${t}</button>`).join('')}</div></div>
            <div class="field full"><label for="s-nota">¿Algo más que debamos saber?</label><textarea class="textarea" id="s-nota" name="nota" placeholder="Ej: necesito 4x4, uso en faena, color preferido…"></textarea></div>
          </div>
          <button class="btn btn--gold btn--lg btn--block" style="margin-top:18px" type="submit">${ic('chat')} Enviar por WhatsApp</button>
          <p style="font-size:12.5px;color:var(--muted);margin:10px 0 0;text-align:center">Se abre WhatsApp con tu solicitud. Sin costo ni compromiso.</p>
        </form>
      </div>
    </section>`;
  }

  function bindBusqueda() {
    const r = $('#s-budget'); const o = $('#budgetOut');
    r.addEventListener('input', () => { o.textContent = clp(+r.value); });
    $$('.chips[data-group]').forEach((g) => g.addEventListener('click', (e) => { const b = e.target.closest('.chip'); if (!b) return; $$('.chip', g).forEach((x) => x.classList.toggle('on', x === b)); }));
    $('#searchForm').addEventListener('submit', (e) => {
      e.preventDefault();
      const f = e.target; const fd = Object.fromEntries(new FormData(f));
      const missing = ['nombre', 'telefono', 'marca', 'modelo'].filter((k) => !(fd[k] || '').trim());
      $$('.input, .select', f).forEach((el) => el.style.borderColor = missing.includes(el.name) ? 'var(--bad)' : '');
      if (missing.length) return toast('Completa los campos obligatorios (*)');
      const trans = $('.chips[data-group="trans"] .chip.on', f)?.textContent || 'Indiferente';
      const msg = [
        'Hola Atlas Motors, quiero una búsqueda personalizada.',
        '',
        `Busco: ${fd.marca} ${fd.modelo}, años ${fd.desde} a ${fd.hasta}`,
        `Presupuesto máximo: ${clp(+fd.presupuesto)}`,
        `Transmisión: ${trans}`,
        fd.nota ? `Comentarios: ${fd.nota}` : '',
        '',
        `Nombre: ${fd.nombre}`,
        `Teléfono: ${fd.telefono}`,
        fd.email ? `Correo: ${fd.email}` : '',
      ].filter((l, i, a) => l !== '' || a[i - 1] !== '').join('\n').trim();
      const link = waLink(msg);
      window.open(link, '_blank', 'noopener');
      const nombre = esc(fd.nombre.trim().split(' ')[0]);
      f.innerHTML = `
        <div class="success" style="padding:20px 6px">
          <div class="check">${ic('check')}</div>
          <h2 class="display" style="color:var(--green-950)">¡Gracias, ${nombre}!</h2>
          <p style="color:var(--muted)">Abrimos WhatsApp con tu solicitud. Envía el mensaje y te contactamos para partir la búsqueda.</p>
          <a class="btn btn--gold" style="margin-top:12px" href="${link}" target="_blank" rel="noopener">${ic('chat')} Abrir WhatsApp de nuevo</a>
        </div>`;
      f.scrollIntoView({ behavior: 'smooth', block: 'center' });
    });
  }

  function viewNotFound() {
    return `<section class="section"><div class="container" style="text-align:center"><h1 class="display">Página no encontrada</h1><p>El vehículo o la página que buscas no existe.</p><a class="btn btn--gold" href="#/">Volver al inicio</a></div></section>`;
  }

  /* ---------------- ayudante flotante (mascota) ---------------- */
  function mountHelper() {
    const h = $('#helper'); let open = false;
    const draw = () => {
      h.innerHTML = `
        ${open ? `<div class="helper__panel">
          <header><img src="assets/img/mascota.jpg" alt=""><div><b>¿Te ayudo?</b><small>El ojo de águila de Atlas Motors</small></div></header>
          <div class="opts">
            <a href="#/agendar">${ic('calendar')} Quiero agendar una inspección</a>
            <a href="#/busqueda">${ic('target')} Búsquenme un auto</a>
            <a href="${waLink()}" target="_blank" rel="noopener">${ic('chat')} Hablar por WhatsApp</a>
            <a href="${IG}" target="_blank" rel="noopener">${ic('instagram')} Ver nuestro Instagram</a>
          </div>
        </div>` : (sessionStorageSafe('hint') ? '' : '<div class="helper__hint">¿Te ayudo? 🦅</div>')}
        <button class="helper__btn" aria-label="${open ? 'Cerrar ayuda' : 'Abrir ayuda'}" aria-expanded="${open}"><img src="assets/img/mascota.jpg" alt=""></button>`;
    };
    h.addEventListener('click', (e) => {
      if (e.target.closest('.helper__btn')) { open = !open; sessionStorageSafe('hint', '1'); draw(); }
      else if (e.target.closest('a')) { open = false; draw(); }
    });
    window.addEventListener('hashchange', () => { if (open) { open = false; draw(); } });
    draw();
    setTimeout(() => { sessionStorageSafe('hint', '1'); if (!open) draw(); }, 9000);
  }
  function sessionStorageSafe(k, v) {
    try { if (v === undefined) return sessionStorage.getItem('atlas-' + k); sessionStorage.setItem('atlas-' + k, v); } catch (e) { return null; }
  }

  /* ---------------- router ---------------- */
  function route() {
    const raw = location.hash.replace(/^#/, '') || '/';
    const [path] = raw.split('?');
    const parts = path.split('/').filter(Boolean);
    let html, bind, nav = parts[0] || 'home';
    switch (parts[0]) {
      case undefined: html = viewHome(); break;
      case 'autos': case 'auto': html = viewProximamente(); nav = 'autos'; break;
      case 'informe': html = viewInforme(parts[1] || CARS[0].id); nav = 'inspeccion'; break;
      case 'inspeccion': html = viewInspeccion(); break;
      case 'agendar': html = viewAgendar(); bind = bindAgendar; break;
      case 'busqueda': html = viewBusqueda(); bind = bindBusqueda; break;
      default: html = viewNotFound();
    }
    const fresh = app.cloneNode(false); app.replaceWith(fresh); app = fresh;
    app.innerHTML = html;
    $$('#nav a').forEach((a) => a.classList.toggle('active', a.dataset.nav === nav));
    $('#nav').classList.remove('open'); $('#menuBtn').setAttribute('aria-expanded', 'false');
    window.scrollTo(0, 0);
    bind && bind();
    document.body.classList.toggle('on-agendar', nav === 'agendar');
    reveal();
    document.title = ({ home: 'Atlas Motors · Inspección precompra de vehículos en la Región de Coquimbo', autos: 'Autos inspeccionados · Atlas Motors', inspeccion: 'Inspección precompra · Atlas Motors', agendar: 'Agendar inspección · Atlas Motors', busqueda: 'Búsqueda personalizada · Atlas Motors' })[nav] || 'Atlas Motors';
  }

  /* Aparición suave de las secciones al hacer scroll */
  let io;
  function reveal() {
    if (!('IntersectionObserver' in window) || matchMedia('(prefers-reduced-motion: reduce)').matches) return;
    if (io) io.disconnect();
    io = new IntersectionObserver((es) => es.forEach((e) => {
      if (e.isIntersecting) { e.target.classList.add('in'); io.unobserve(e.target); }
    }), { rootMargin: '0px 0px -8% 0px' });
    $$('#app > section:not(:first-child)').forEach((el) => { el.classList.add('reveal'); io.observe(el); });
  }

  // menú móvil
  const menuBtn = $('#menuBtn');
  menuBtn.innerHTML = ic('menu');
  menuBtn.addEventListener('click', () => {
    const open = $('#nav').classList.toggle('open');
    menuBtn.setAttribute('aria-expanded', String(open));
    menuBtn.innerHTML = ic(open ? 'x' : 'menu');
  });
  window.addEventListener('hashchange', () => { menuBtn.innerHTML = ic('menu'); });

  window.addEventListener('hashchange', route);
  mountHelper();
  route();
})();
