/* Atlas Motors — mockup SPA (sin dependencias, router por hash) */
(function () {
  const { CARS, CHECKLIST, PLANES, TESTIMONIOS, ABONO } = window.ATLAS;
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
  const carCard = (c) => `
    <a class="car-card" href="#/auto/${c.id}">
      <div class="car-card__media">
        <img src="${c.fotos[0]}" alt="${esc(title(c))}" loading="lazy">
        <span class="seal"><img src="assets/img/logo-shield.jpg" alt="">Inspeccionado</span>
        <span class="score">${c.score}/100</span>
        <span class="count">${ic('camera')} ${c.fotos.length} · ${ic('play')} Video</span>
      </div>
      <div class="car-card__body">
        <h3 class="car-card__title">${esc(c.marca)} ${esc(c.modelo)} ${c.anio}</h3>
        <div class="car-card__ver">${esc(c.version)}</div>
        <div class="car-card__specs"><span>${km(c.km)}</span><span>${c.transmision}</span><span>${c.combustible}</span><span>${c.traccion}</span></div>
        <div class="car-card__foot">
          <span class="price">${clp(c.precio)}</span>
          <span class="car-card__loc">${ic('pin')} ${c.comuna}</span>
        </div>
      </div>
    </a>`;

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

  /* ---------------- vistas ---------------- */
  function viewHome() {
    const feat = CARS.filter((c) => c.destacado);
    const hero = CARS[0];
    const marcas = [...new Set(CARS.map((c) => c.marca))].sort();
    return `
    <section class="hero">
      <div class="container hero__inner">
        <div>
          <span class="hero__badge"><span>NUEVO</span> Región de Coquimbo</span>
          <h1>Compra tu próximo auto con <span class="gold-text">ojo de águila</span>
            <small>El primer marketplace con vehículos <b>inspeccionados por Atlas Motors</b> en la Región de Coquimbo. Cada auto trae fotos, video e informe técnico descargable.</small>
          </h1>
          <div class="hero__cta">
            <a href="#/autos" class="btn btn--gold btn--lg">Ver vehículos inspeccionados ${ic('arrow')}</a>
            <a href="#/inspeccion" class="btn btn--ghost btn--lg">Inspeccionar un auto</a>
          </div>
          <div class="hero__stats">
            <div><b>+480</b><span>inspecciones realizadas</span></div>
            <div><b>8</b><span>etapas de revisión</span></div>
            <div><b>24 h</b><span>entrega del informe</span></div>
          </div>
        </div>
        <div class="hero__visual">
          <a class="hero-card" href="#/auto/${hero.id}">
            <img src="${hero.fotos[0]}" alt="${esc(title(hero))}">
            <div class="hero-card__info">
              <div><h3>${esc(title(hero))}</h3><p>${clp(hero.precio)}</p></div>
              <span class="score" style="position:static">${hero.score}/100</span>
            </div>
          </a>
          <div class="float-chip float-chip--a"><span class="ic">${ic('shield')}</span><div><b>Inspección aprobada</b>Sin choques estructurales</div></div>
          <div class="float-chip float-chip--b"><span class="ic">${ic('doc')}</span><div><b>Informe PDF</b>Checklist en 8 etapas</div></div>
        </div>
      </div>
    </section>

    <div class="container">
      <form class="search" id="homeSearch">
        <div class="field"><label for="q">¿Qué buscas?</label><input class="input" id="q" name="q" placeholder="Ej: Ranger Raptor, SUV, Kia…"></div>
        <div class="field"><label for="hm">Marca</label><select class="select" id="hm" name="marca"><option value="">Todas</option>${marcas.map((m) => `<option>${m}</option>`).join('')}</select></div>
        <div class="field"><label for="hp">Precio hasta</label><select class="select" id="hp" name="max"><option value="">Sin límite</option><option value="10000000">$10.000.000</option><option value="15000000">$15.000.000</option><option value="20000000">$20.000.000</option><option value="30000000">$30.000.000</option></select></div>
        <button class="btn btn--gold" type="submit">${ic('search')} Buscar</button>
      </form>

      <div class="trust">
        <div class="trust__item"><span class="ic">${ic('shield')}</span><div><b>100 % inspeccionados</b><span>Ningún auto se publica sin pasar por Atlas.</span></div></div>
        <div class="trust__item"><span class="ic">${ic('doc')}</span><div><b>Informe descargable</b><span>Checklist completo, fotos y escáner.</span></div></div>
        <div class="trust__item"><span class="ic">${ic('camera')}</span><div><b>Fotos y video reales</b><span>Tomados el día de la inspección.</span></div></div>
        <div class="trust__item"><span class="ic">${ic('pin')}</span><div><b>Hecho en Coquimbo</b><span>La Serena, Coquimbo, Ovalle y más.</span></div></div>
      </div>
    </div>

    <section class="section">
      <div class="container">
        <div class="section__head">
          <div><span class="eyebrow">Marketplace</span><h2>Vehículos inspeccionados</h2><p>Autos revisados punto por punto. Pincha uno para ver fotos, video y descargar su informe.</p></div>
          <a href="#/autos" class="btn btn--outline">Ver los ${CARS.length} vehículos ${ic('arrow')}</a>
        </div>
        <div class="grid grid--cars">${feat.map(carCard).join('')}</div>
      </div>
    </section>

    <section class="section dark">
      <div class="container">
        <div class="section__head">
          <div><span class="eyebrow">Servicios</span><h2>¿Cómo te ayudamos?</h2><p>Dos formas de comprar seguro: revisamos el auto que encontraste, o buscamos el auto por ti.</p></div>
        </div>
        <div class="services">
          <a class="service-card" href="#/inspeccion">
            <span class="bg-icon">${ic('scan')}</span>
            <span class="pill" style="align-self:start;margin-bottom:auto">Desde ${clp(PLANES[0].precio)}</span>
            <h3>Inspección precompra</h3>
            <p>Vamos a donde está el auto con escáner y medidor de pintura. ¿No puedes ir? Te mandamos cada hallazgo con foto en tiempo real y el informe en PDF.</p>
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
          <div class="step"><h4>Elige o encuentra</h4><p>Explora el marketplace o pídenos que busquemos el auto ideal para ti.</p></div>
          <div class="step"><h4>Agenda online</h4><p>Elige día, hora y dirección. Reserva con el 50 % de abono.</p></div>
          <div class="step"><h4>Inspeccionamos</h4><p>8 etapas: carrocería, estructura, motor, parte baja, interior, escáner y prueba de ruta.</p></div>
          <div class="step"><h4>Decide con datos</h4><p>Recibe el informe con fotos y video. Compra o negocia con respaldo.</p></div>
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
              <button class="btn btn--outline" data-action="whatsapp">${ic('chat')} Hablar por WhatsApp</button>
            </div>
          </div>
        </div>
      </div>
    </section>

    <section class="section dark">
      <div class="container">
        <div class="section__head"><div><span class="eyebrow">Clientes</span><h2>Lo que dicen de nosotros</h2></div></div>
        <div class="testis">
          ${TESTIMONIOS.map((t) => `
            <figure class="testi" style="margin:0">
              <div class="stars">★★★★★</div>
              <p>“${esc(t.texto)}”</p>
              <footer><span class="avatar">${t.nombre[0]}</span><div><b>${esc(t.nombre)}</b><small>${t.ciudad} · ${esc(t.auto)}</small></div></footer>
            </figure>`).join('')}
        </div>
      </div>
    </section>

    <section class="section">
      <div class="container">
        <div class="cta-band">
          <div><h2>¿Encontraste un auto y no estás seguro?</h2><p>Agenda una inspección precompra hoy. Vamos donde esté el vehículo.</p></div>
          <a href="#/agendar" class="btn btn--gold btn--lg">${ic('calendar')} Agendar ahora</a>
        </div>
      </div>
    </section>`;
  }

  const state = { tipo: '', marca: '', max: '', q: '', sort: 'recientes', trans: '' };

  function viewAutos(params) {
    Object.assign(state, { q: params.get('q') || '', marca: params.get('marca') || '', max: params.get('max') || '' });
    const tipos = [...new Set(CARS.map((c) => c.tipo))];
    const marcas = [...new Set(CARS.map((c) => c.marca))].sort();
    return `
    <section class="page-hero">
      <div class="container">
        <div class="crumbs"><a href="#/">Inicio</a> / Vehículos</div>
        <h1>Vehículos inspeccionados</h1>
        <p>Todos los autos de este marketplace fueron revisados por Atlas Motors. Descarga el informe antes de decidir.</p>
      </div>
    </section>
    <section class="section--tight">
      <div class="container market">
        <aside class="filters" id="filters">
          <h3>Filtros <button type="button" data-action="clear">Limpiar</button></h3>
          <div class="field"><label for="fq">Buscar</label><input class="input" id="fq" value="${esc(state.q)}" placeholder="Marca, modelo…"></div>
          <div class="field"><label>Tipo</label><div class="chips" data-group="tipo">${['', ...tipos].map((t) => `<button type="button" class="chip ${state.tipo === t ? 'on' : ''}" data-v="${t}">${t || 'Todos'}</button>`).join('')}</div></div>
          <div class="field"><label for="fm">Marca</label><select class="select" id="fm"><option value="">Todas</option>${marcas.map((m) => `<option ${state.marca === m ? 'selected' : ''}>${m}</option>`).join('')}</select></div>
          <div class="field"><label>Transmisión</label><div class="chips" data-group="trans">${['', 'Automática', 'Manual'].map((t) => `<button type="button" class="chip ${state.trans === t ? 'on' : ''}" data-v="${t}">${t || 'Todas'}</button>`).join('')}</div></div>
          <div class="field"><label for="fp">Precio máximo</label><select class="select" id="fp"><option value="">Sin límite</option>${[10, 15, 20, 30, 45].map((m) => `<option value="${m}000000" ${state.max === m + '000000' ? 'selected' : ''}>${clp(m * 1e6)}</option>`).join('')}</select></div>
        </aside>
        <div>
          <div class="toolbar">
            <div style="display:flex;gap:10px;align-items:center">
              <button class="btn btn--outline btn--sm filters-toggle" data-action="toggle-filters">${ic('filter')} Filtros</button>
              <b id="resultCount"></b>
            </div>
            <select class="select" id="fs" aria-label="Ordenar">
              <option value="recientes">Más recientes</option><option value="precio-asc">Menor precio</option><option value="precio-desc">Mayor precio</option><option value="score">Mejor puntaje</option><option value="km">Menos kilómetros</option>
            </select>
          </div>
          <div class="grid grid--cars" id="results"></div>
        </div>
      </div>
    </section>`;
  }

  function bindAutos() {
    const render = () => {
      const q = state.q.trim().toLowerCase();
      let list = CARS.filter((c) =>
        (!state.tipo || c.tipo === state.tipo) && (!state.marca || c.marca === state.marca) && (!state.trans || c.transmision === state.trans) &&
        (!state.max || c.precio <= +state.max) &&
        (!q || `${c.marca} ${c.modelo} ${c.version} ${c.tipo} ${c.anio}`.toLowerCase().includes(q)));
      const s = { 'precio-asc': (a, b) => a.precio - b.precio, 'precio-desc': (a, b) => b.precio - a.precio, score: (a, b) => b.score - a.score, km: (a, b) => a.km - b.km, recientes: (a, b) => b.fechaInspeccion.localeCompare(a.fechaInspeccion) }[state.sort];
      list = list.sort(s);
      $('#resultCount').textContent = `${list.length} vehículo${list.length === 1 ? '' : 's'}`;
      $('#results').innerHTML = list.length ? list.map(carCard).join('') : `<div class="empty" style="grid-column:1/-1"><p><b>No encontramos vehículos con esos filtros.</b></p><p>¿Quieres que lo busquemos por ti?</p><a class="btn btn--gold" href="#/busqueda">Búsqueda personalizada</a></div>`;
    };
    $('#fq').addEventListener('input', (e) => { state.q = e.target.value; render(); });
    $('#fm').addEventListener('change', (e) => { state.marca = e.target.value; render(); });
    $('#fp').addEventListener('change', (e) => { state.max = e.target.value; render(); });
    $('#fs').addEventListener('change', (e) => { state.sort = e.target.value; render(); });
    $('#fs').value = state.sort;
    $$('.chips[data-group]').forEach((g) => g.addEventListener('click', (e) => {
      const b = e.target.closest('.chip'); if (!b) return;
      state[g.dataset.group] = b.dataset.v;
      $$('.chip', g).forEach((x) => x.classList.toggle('on', x === b)); render();
    }));
    app.addEventListener('click', (e) => {
      const a = e.target.closest('[data-action]'); if (!a) return;
      if (a.dataset.action === 'clear') { Object.assign(state, { tipo: '', marca: '', max: '', q: '', trans: '' }); route(); }
      if (a.dataset.action === 'toggle-filters') $('#filters').classList.toggle('open');
    });
    render();
  }

  function viewAuto(id) {
    const c = carById(id);
    if (!c) return viewNotFound();
    const cats = CHECKLIST.map((k, i) => ({ ...k, st: catStatus(c, i) }));
    const related = CARS.filter((x) => x.id !== c.id && x.tipo === c.tipo).slice(0, 3);
    return `
    <section class="section--tight" style="padding-top:28px">
      <div class="container">
        <div class="crumbs" style="color:var(--muted);margin-bottom:18px"><a href="#/">Inicio</a> / <a href="#/autos">Vehículos</a> / ${esc(title(c))}</div>
        <div class="detail">
          <div>
            <div class="gallery" id="gallery">
              <div class="gallery__tabs">
                <button class="tab on" data-tab="fotos">${ic('camera')} Fotos (${c.fotos.length})</button>
                <button class="tab" data-tab="video">${ic('play')} Video inspección</button>
              </div>
              <div id="galleryStage"></div>
              <div class="gallery__thumbs">
                ${c.fotos.map((f, i) => `<button class="${i === 0 ? 'on' : ''}" data-i="${i}" aria-label="Foto ${i + 1}"><img src="${f}" alt="" loading="lazy"></button>`).join('')}
                <button class="vid" data-tab="video" aria-label="Ver video">${ic('play')}</button>
              </div>
            </div>

            <div class="panel" style="margin-top:20px">
              <h3>Resultado de la inspección</h3>
              <p style="color:var(--muted)">${esc(c.resumen)}</p>
              <ul class="obs-list">
                ${c.observaciones.map((o) => `<li><span class="dot dot--${o.nivel}">${o.nivel === 'ok' ? '✓' : '!'}</span><span>${esc(o.texto)}</span></li>`).join('')}
              </ul>
            </div>

            <div class="panel">
              <h3>Checklist por categoría</h3>
              <div class="cat-grid">
                ${cats.map((k) => `<div class="cat">${ic(k.icon)} ${k.cat}<em class="${statusCls[k.st]}">${statusLabel[k.st]}</em></div>`).join('')}
              </div>
              <a class="btn btn--outline btn--block" style="margin-top:16px" href="#/informe/${c.id}">${ic('doc')} Ver checklist completo</a>
            </div>
          </div>

          <aside>
            <div class="panel">
              <span class="pill">${ic('shield')} Inspeccionado por Atlas Motors</span>
              <h1>${esc(c.marca)} ${esc(c.modelo)} ${c.anio}</h1>
              <div class="ver">${esc(c.version)}</div>
              <div class="price">${clp(c.precio)}</div>
              <small style="color:var(--muted)">Publicado por ${c.vendedor.toLowerCase()} · ${c.comuna}</small>
              <div class="specs">
                <div class="spec">${ic('gauge')}<div><small>Kilometraje</small><b>${km(c.km)}</b></div></div>
                <div class="spec">${ic('calendar')}<div><small>Año</small><b>${c.anio}</b></div></div>
                <div class="spec">${ic('gear')}<div><small>Transmisión</small><b>${c.transmision}</b></div></div>
                <div class="spec">${ic('fuel')}<div><small>Combustible</small><b>${c.combustible}</b></div></div>
                <div class="spec">${ic('car')}<div><small>Tipo</small><b>${c.tipo} · ${c.traccion}</b></div></div>
                <div class="spec">${ic('sparkle')}<div><small>Color</small><b>${c.color}</b></div></div>
              </div>
              <div class="verified">
                <div class="ring" style="--v:${c.score}"><div>${c.score}<small>de 100</small></div></div>
                <div><h3>Informe de inspección</h3><p>Realizado el ${fecha(c.fechaInspeccion)} · Checklist en 8 etapas, escáner y fotos.</p></div>
                <a class="btn btn--gold" href="#/informe/${c.id}">${ic('download')} Descargar informe</a>
              </div>
              <div class="contact-actions">
                <button class="btn btn--green btn--block" data-action="whatsapp">${ic('chat')} Contactar vendedor</button>
                <button class="btn btn--outline btn--block" data-action="favorito">${ic('star')} Guardar en favoritos</button>
              </div>
            </div>
          </aside>
        </div>

        ${related.length ? `
        <div class="section__head" style="margin-top:56px"><div><span class="eyebrow">También te puede interesar</span><h2>Otros ${c.tipo === 'SUV' ? 'SUV' : c.tipo.toLowerCase() + 's'} inspeccionados</h2></div></div>
        <div class="grid grid--cars">${related.map(carCard).join('')}</div>` : ''}
      </div>
    </section>`;
  }

  function bindAuto(id) {
    const c = carById(id); if (!c) return;
    let idx = 0, mode = 'fotos';
    const stage = $('#galleryStage');
    const draw = () => {
      $$('.gallery__tabs .tab').forEach((t) => t.classList.toggle('on', t.dataset.tab === mode));
      $$('.gallery__thumbs button[data-i]').forEach((b) => b.classList.toggle('on', mode === 'fotos' && +b.dataset.i === idx));
      if (mode === 'fotos') {
        stage.innerHTML = `<div class="gallery__main" data-action="zoom"><img src="${c.fotos[idx]}" alt="${esc(title(c))}, foto ${idx + 1}">
          <button class="gallery__nav gallery__nav--prev" data-nav="-1" aria-label="Anterior">${ic('left')}</button>
          <button class="gallery__nav gallery__nav--next" data-nav="1" aria-label="Siguiente">${ic('right')}</button></div>`;
      } else {
        const f = [...c.fotos, ...c.fotos].slice(0, 4);
        const caps = ['Revisión exterior', 'Escáner OBD', 'Prueba en ruta', 'Bajo carrocería'];
        stage.innerHTML = `<div class="video" id="video">${f.map((x) => `<img src="${x}" alt="">`).join('')}
          <span class="video__caption"><i class="rec"></i> <span id="vcap">Video de inspección · ${esc(title(c))}</span></span>
          <button class="video__play" data-action="play" aria-label="Reproducir video"><span>${ic('play')}</span></button>
          <div class="video__hud">${ic('play')}<div class="video__bar"><i></i></div><span>0:16</span></div></div>`;
        stage._caps = caps;
      }
    };
    $('#gallery').addEventListener('click', (e) => {
      const t = e.target.closest('[data-tab]'); if (t) { mode = t.dataset.tab; draw(); return; }
      const th = e.target.closest('[data-i]'); if (th) { mode = 'fotos'; idx = +th.dataset.i; draw(); return; }
      const n = e.target.closest('[data-nav]'); if (n) { e.stopPropagation(); idx = (idx + +n.dataset.nav + c.fotos.length) % c.fotos.length; draw(); return; }
      const p = e.target.closest('[data-action="play"]');
      if (p) {
        const v = $('#video'); v.classList.add('playing'); p.remove();
        let k = 0; const cap = $('#vcap'); clearInterval(bindAuto._t);
        bindAuto._t = setInterval(() => { if (!document.body.contains(cap)) return clearInterval(bindAuto._t); cap.textContent = stage._caps[k++ % 4]; }, 4000);
        cap.textContent = stage._caps[k++];
        return;
      }
      if (e.target.closest('[data-action="zoom"]')) openLightbox(c.fotos, idx);
    });
    draw();
  }

  function openLightbox(fotos, i) {
    const lb = $('#lightbox');
    const draw = () => {
      lb.innerHTML = `<button class="close" aria-label="Cerrar">${ic('x')}</button>
        <button class="gallery__nav gallery__nav--prev" data-n="-1" aria-label="Anterior">${ic('left')}</button>
        <img src="${fotos[i]}" alt="Foto ${i + 1} de ${fotos.length}">
        <button class="gallery__nav gallery__nav--next" data-n="1" aria-label="Siguiente">${ic('right')}</button>`;
    };
    lb.onclick = (e) => {
      const n = e.target.closest('[data-n]');
      if (n) { i = (i + +n.dataset.n + fotos.length) % fotos.length; draw(); return; }
      if (e.target === lb || e.target.closest('.close')) close();
    };
    const key = (e) => { if (e.key === 'Escape') close(); if (e.key === 'ArrowRight') { i = (i + 1) % fotos.length; draw(); } if (e.key === 'ArrowLeft') { i = (i - 1 + fotos.length) % fotos.length; draw(); } };
    const close = () => { lb.classList.remove('open'); document.removeEventListener('keydown', key); document.body.style.overflow = ''; };
    document.addEventListener('keydown', key);
    document.body.style.overflow = 'hidden';
    draw(); lb.classList.add('open');
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
          <a class="btn btn--outline btn--sm" href="#/auto/${c.id}">${ic('left')} Volver al vehículo</a>
          <button class="btn btn--gold" data-action="print">${ic('download')} Descargar PDF</button>
        </div>
        <article class="report">
          <header class="report__head">
            <img src="assets/img/logo-wordmark.jpg" alt="Atlas Motors">
            <div class="meta"><b>INFORME DE INSPECCIÓN PRECOMPRA</b>Folio ${folio}<br>Fecha: ${fecha(c.fechaInspeccion)} · ${c.comuna}</div>
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
                <tr><td>Inspector</td><td>Matías · Atlas Motors</td></tr>
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
              <div><img src="assets/img/logo-shield.jpg" alt=""><br>Este informe refleja el estado del vehículo a la fecha de inspección.<br>Verificable en atlasmotors.cl con folio ${folio}.</div>
              <div class="line">Matías — Inspector Atlas Motors</div>
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
        <div class="stat"><b>+480</b><span>clientes atendidos</span></div>
        <div class="stat"><b>8</b><span>etapas de revisión</span></div>
        <div class="stat"><b>${clp(completa.precio * ABONO)}</b><span>abono para reservar</span></div>
        <div class="stat"><b>4,9 ★</b><span>calificación de clientes</span></div>
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
        <div class="section__head" style="justify-content:center;text-align:center"><div><span class="eyebrow">Valores</span><h2>Elige tu inspección</h2><p style="margin-inline:auto">Reservas tu hora con el ${ABONO * 100} % de abono y pagas el resto el día de la inspección. Traslado sin costo en La Serena y Coquimbo.</p></div></div>
        <div class="plans">
          ${PLANES.map((p) => `
            <div class="plan ${p.destacado ? 'featured' : ''}">
              ${p.destacado ? '<span class="tag">MÁS ELEGIDA</span>' : ''}
              <h3>${p.nombre}</h3>
              <div class="amount">${clp(p.precio)} <small>CLP</small></div>
              <p>${p.desc} Reserva con ${clp(p.precio * ABONO)}.</p>
              <ul>${p.incluye.map((i) => `<li>${ic('check')} ${i}</li>`).join('')}</ul>
              <a class="btn ${p.destacado ? 'btn--gold' : 'btn--green'} btn--block" href="#/agendar?plan=${p.id}">Agendar ${p.nombre}</a>
            </div>`).join('')}
        </div>
      </div>
    </section>

    <section class="section--tight" style="padding-bottom:88px">
      <div class="container">
        <div class="cta-band">
          <div><h2>Agenda en 2 minutos</h2><p>Elige día y hora, deja la dirección del auto y reserva con el ${ABONO * 100} % de abono.</p></div>
          <a href="#/agendar" class="btn btn--gold btn--lg">${ic('calendar')} Agendar aquí</a>
        </div>
      </div>
    </section>`;
  }

  /* -------- Agenda -------- */
  const booking = { step: 0, plan: 'completa', date: null, time: null, data: { presente: 'si' }, pay: 'transferencia', month: null };
  const LEJOS = ['Ovalle', 'Vicuña', 'Andacollo', 'Illapel'];
  const totalReserva = (p) => p.precio + (LEJOS.includes(booking.data.comuna) ? 10000 : 0);
  const abonoReserva = (p) => Math.round(totalReserva(p) * ABONO);
  const STEPS = ['Servicio', 'Fecha y hora', 'Tus datos', 'Pago'];
  const SLOTS = ['09:00', '10:30', '12:00', '14:00', '15:30', '17:00', '18:30'];
  const takenSlots = (d) => { const n = d.getDate(); return SLOTS.filter((_, i) => (n * 3 + i * 5) % 7 < 2); };
  const iso = (d) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;

  function viewAgendar(params) {
    if (params.get('plan')) { booking.plan = params.get('plan'); booking.step = Math.max(booking.step, 0); }
    return `
    <section class="page-hero" style="padding:44px 0 50px">
      <div class="container">
        <div class="crumbs"><a href="#/">Inicio</a> / <a href="#/inspeccion">Inspección precompra</a> / Agendar</div>
        <h1>Agenda tu inspección</h1>
        <p>Elige el servicio, el día y la hora, y reserva con el 50 % de abono. Si no puedes estar presente, la hacemos en modalidad remota.</p>
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
    const plan = () => PLANES.find((p) => p.id === booking.plan) || PLANES[1];
    const canNext = () => [true, booking.date && booking.time, ['nombre', 'telefono', 'email', 'direccion', 'comuna'].every((k) => (booking.data[k] || '').trim()), true][booking.step];

    const stepBody = () => {
      if (booking.step === 0) return `
        <h3>¿Qué inspección necesitas?</h3>
        <div class="plan-pick">${PLANES.map((p) => `
          <button type="button" class="plan-opt ${booking.plan === p.id ? 'on' : ''}" data-plan="${p.id}">
            <span class="radio"></span><span><b>${p.nombre}${p.destacado ? ' · <span style="color:var(--gold-700)">Más elegida</span>' : ''}</b><small>${p.desc}</small></span><span class="amt">${clp(p.precio)}</span>
          </button>`).join('')}</div>`;
      if (booking.step === 1) {
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
        const sel = booking.date ? new Date(booking.date + 'T12:00:00') : null;
        const taken = sel ? takenSlots(sel) : [];
        return `
          <h3>Elige día y hora</h3>
          <div class="cal">
            <div class="cal__head"><button type="button" data-month="-1" aria-label="Mes anterior">${ic('left')}</button><b>${label}</b><button type="button" data-month="1" aria-label="Mes siguiente">${ic('right')}</button></div>
            <div class="cal__grid">${cells}</div>
          </div>
          ${sel ? `<p style="margin:18px 0 0;font-weight:600">Horarios disponibles para el ${sel.toLocaleDateString('es-CL', { weekday: 'long', day: 'numeric', month: 'long' })}</p>
          <div class="slots">${SLOTS.map((s) => `<button type="button" class="slot ${booking.time === s ? 'on' : ''}" data-time="${s}" ${taken.includes(s) ? 'disabled' : ''}>${s}</button>`).join('')}</div>` : '<p style="margin:16px 0 0;color:var(--muted)">Selecciona un día para ver los horarios. Atendemos de lunes a sábado.</p>'}`;
      }
      if (booking.step === 2) {
        const d = booking.data; const v = (k) => esc(d[k] || '');
        return `
          <h3>Datos de la inspección</h3>
          <div class="form-grid" id="dataForm">
            <div class="field"><label for="b-nombre">Nombre completo *</label><input class="input" id="b-nombre" data-k="nombre" value="${v('nombre')}" autocomplete="name"></div>
            <div class="field"><label for="b-tel">Teléfono *</label><input class="input" id="b-tel" data-k="telefono" value="${v('telefono')}" inputmode="tel" placeholder="+56 9 …" autocomplete="tel"></div>
            <div class="field full"><label for="b-email">Correo electrónico *</label><input class="input" id="b-email" data-k="email" type="email" value="${v('email')}" autocomplete="email"><span class="hint">Aquí te llegará la confirmación y el informe.</span></div>
            <div class="field full"><label for="b-dir">Dirección donde está el vehículo *</label><input class="input" id="b-dir" data-k="direccion" value="${v('direccion')}" placeholder="Ej: Av. del Mar 1234, estacionamiento"></div>
            <div class="field"><label for="b-com">Comuna *</label><select class="select" id="b-com" data-k="comuna"><option value="">Selecciona</option>${['La Serena', 'Coquimbo', 'Ovalle', 'Vicuña', 'Andacollo', 'Illapel'].map((c) => `<option ${d.comuna === c ? 'selected' : ''}>${c}</option>`).join('')}</select></div>
            <div class="field"><label for="b-veh">Vehículo a inspeccionar</label><input class="input" id="b-veh" data-k="vehiculo" value="${v('vehiculo')}" placeholder="Ej: Toyota Hilux 2021"></div>
            <div class="field full"><label for="b-pres">¿Estarás presente en la inspección?</label><select class="select" id="b-pres" data-k="presente"><option value="si" ${d.presente !== 'no' ? 'selected' : ''}>Sí, voy a estar</option><option value="no" ${d.presente === 'no' ? 'selected' : ''}>No, prefiero la inspección remota (te enviamos todo en vivo)</option></select></div>
            <div class="field full"><label for="b-link">Link de la publicación (opcional)</label><input class="input" id="b-link" data-k="link" value="${v('link')}" placeholder="Yapo, Chileautos, Marketplace…"></div>
            <div class="field full"><label for="b-nota">Comentarios para el inspector</label><textarea class="textarea" id="b-nota" data-k="nota" placeholder="Ej: el vendedor solo puede después de las 14:00">${v('nota')}</textarea></div>
          </div>`;
      }
      return `
        <h3>Reserva con el ${ABONO * 100} % de abono</h3>
        <p style="color:var(--muted)">Pagas ${clp(abonoReserva(plan()))} ahora para dejar la hora reservada y el resto el día de la inspección. En esta demo no se realiza ningún cobro.</p>
        <div class="pay-methods">
          ${[['transferencia', 'Transferencia a cuenta empresa', 'Confirmamos tu reserva al recibirla', '#113221'], ['webpay', 'Webpay', 'Tarjetas de débito y crédito', '#c1121f'], ['mercadopago', 'Mercado Pago', 'Saldo, tarjetas o cuotas', '#009ee3']].map(([id, n, d, col]) => `
            <button type="button" class="pay ${booking.pay === id ? 'on' : ''}" data-pay="${id}">
              <span class="logo" style="background:${col}">${ic(id === 'transferencia' ? 'doc' : 'card')}</span>
              <span><b>${n}</b><br><small style="color:var(--muted)">${d}</small></span>
              <span class="radio" style="margin-left:auto;width:22px;height:22px;border-radius:50%;border:2px solid ${booking.pay === id ? 'var(--gold)' : 'var(--line)'};display:grid;place-items:center">${booking.pay === id ? '<i style="width:11px;height:11px;border-radius:50%;background:var(--gold)"></i>' : ''}</span>
            </button>`).join('')}
        </div>
        <p style="font-size:13px;color:var(--muted);margin-top:14px">Al pagar aceptas los términos del servicio. Puedes reagendar sin costo hasta 12 horas antes.</p>`;
    };

    const summary = () => {
      const p = plan(); const d = booking.date ? new Date(booking.date + 'T12:00:00') : null;
      return `
        <aside class="panel summary">
          <h3>Resumen</h3>
          <dl>
            <dt>Servicio</dt><dd>Inspección ${p.nombre}</dd>
            <dt>Fecha</dt><dd>${d ? d.toLocaleDateString('es-CL', { weekday: 'short', day: 'numeric', month: 'short' }) : '—'}</dd>
            <dt>Hora</dt><dd>${booking.time || '—'}</dd>
            <dt>Lugar</dt><dd>${esc(booking.data.direccion || '—')}${booking.data.comuna ? ', ' + esc(booking.data.comuna) : ''}</dd>
            <dt>Modalidad</dt><dd>${booking.data.presente === 'no' ? 'Remota' : 'Presencial'}</dd>
            <dt>Traslado</dt><dd>${LEJOS.includes(booking.data.comuna) ? clp(10000) : 'Gratis'}</dd>
            <dt>Total del servicio</dt><dd>${clp(totalReserva(p))}</dd>
            <dt>Saldo el día</dt><dd>${clp(totalReserva(p) - abonoReserva(p))}</dd>
          </dl>
          <div class="total"><span>Abono para reservar</span><span>${clp(abonoReserva(p))}</span></div>
          <div style="display:flex;gap:10px;align-items:center;margin-top:16px;font-size:13px;color:var(--muted)">${ic('shield')} Reagenda gratis hasta 12 h antes</div>
        </aside>`;
    };

    const draw = () => {
      if (booking.step === 4) return drawSuccess();
      root.innerHTML = `
        <div class="booking">
          <div class="panel">
            <div class="stepper">${STEPS.map((s, i) => `<div class="${i <= booking.step ? 'on' : ''}">${i + 1}. ${s}</div>`).join('')}</div>
            ${stepBody()}
            <div class="wizard-nav">
              ${booking.step > 0 ? `<button type="button" class="btn btn--outline" data-go="-1">${ic('left')} Atrás</button>` : '<span></span>'}
              <button type="button" class="btn btn--gold" data-go="1" ${canNext() ? '' : 'disabled'}>${booking.step === 3 ? `${ic('card')} ${booking.pay === 'transferencia' ? 'Reservar y transferir' : 'Pagar abono'} ${clp(abonoReserva(plan()))}` : `Continuar ${ic('arrow')}`}</button>
            </div>
          </div>
          ${summary()}
        </div>`;
    };

    const drawSuccess = () => {
      const p = plan(); const d = new Date(booking.date + 'T12:00:00');
      const fecha = d.toLocaleDateString('es-CL', { weekday: 'long', day: 'numeric', month: 'long' });
      root.innerHTML = `
        <div class="panel success">
          <div class="check">${ic('check')}</div>
          <h2 class="display" style="color:var(--green-950)">${booking.pay === 'transferencia' ? '¡Hora reservada!' : '¡Inspección agendada!'}</h2>
          <p style="color:var(--muted);max-width:520px;margin:0 auto">${booking.pay === 'transferencia' ? `Te enviamos los datos de la cuenta empresa por correo y WhatsApp. Tu hora queda confirmada al recibir el abono de ${clp(abonoReserva(p))}.` : `Abono de ${clp(abonoReserva(p))} recibido.`} ${booking.data.presente === 'no' ? 'Inspeccionaremos el vehículo el' : 'Nos vemos el'} <b>${fecha} a las ${booking.time}</b> en ${esc(booking.data.direccion)}, ${esc(booking.data.comuna)}.</p>
          <div class="notif-preview">
            <div class="notif"><span class="ic">${ic('mail')}</span><div><b>Correo enviado a ${esc(booking.data.email)}</b>Confirmación de inspección ${p.nombre} · ${booking.pay === 'transferencia' ? 'Datos para transferir' : 'Comprobante de abono'}</div></div>
            <div class="notif"><span class="ic">${ic('bell')}</span><div><b>Notificación para Atlas Motors</b>Nueva inspección: ${fecha}, ${booking.time} · ${esc(booking.data.comuna)} · ${esc(booking.data.vehiculo || 'Vehículo por confirmar')}</div></div>
            <div class="notif"><span class="ic">${ic('calendar')}</span><div><b>${booking.data.presente === 'no' ? 'Inspección remota' : 'Agregado al calendario'}</b>${booking.data.presente === 'no' ? 'Ese día te enviaremos cada hallazgo con foto por WhatsApp' : 'Te recordaremos 24 h antes por WhatsApp'}</div></div>
          </div>
          <div style="display:flex;gap:10px;justify-content:center;flex-wrap:wrap;margin-top:28px">
            <a class="btn btn--gold" href="#/">Volver al inicio</a>
            <button class="btn btn--outline" data-action="reset-booking">Agendar otra</button>
          </div>
        </div>`;
    };

    root.addEventListener('click', (e) => {
      const t = e.target;
      const pl = t.closest('[data-plan]'); if (pl) { booking.plan = pl.dataset.plan; return draw(); }
      const mo = t.closest('[data-month]'); if (mo) {
        const n = new Date(booking.month.getFullYear(), booking.month.getMonth() + +mo.dataset.month, 1);
        if (n >= new Date(today.getFullYear(), today.getMonth(), 1) && n <= new Date(today.getFullYear(), today.getMonth() + 2, 1)) booking.month = n;
        return draw();
      }
      const dt = t.closest('[data-date]'); if (dt) { booking.date = dt.dataset.date; booking.time = null; return draw(); }
      const tm = t.closest('[data-time]'); if (tm) { booking.time = tm.dataset.time; return draw(); }
      const py = t.closest('[data-pay]'); if (py) { booking.pay = py.dataset.pay; return draw(); }
      const go = t.closest('[data-go]'); if (go) {
        const dir = +go.dataset.go;
        if (dir > 0 && booking.step === 3) {
          go.innerHTML = booking.pay === 'transferencia' ? 'Reservando…' : 'Procesando pago…'; go.disabled = true;
          return setTimeout(() => { booking.step = 4; draw(); window.scrollTo({ top: 0, behavior: 'smooth' }); }, 1200);
        }
        booking.step = Math.max(0, booking.step + dir); draw();
        root.scrollIntoView({ behavior: 'smooth', block: 'start' });
        return;
      }
      if (t.closest('[data-action="reset-booking"]')) { Object.assign(booking, { step: 0, date: null, time: null, data: { presente: 'si' } }); draw(); }
    });
    root.addEventListener('input', (e) => {
      const k = e.target.dataset.k; if (!k) return;
      booking.data[k] = e.target.value;
      const btn = $('[data-go="1"]', root); if (btn) btn.disabled = !canNext();
      const s = $('.summary', root); if (s) s.outerHTML = summary();
    });
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
          <p style="color:#c7cfc9">Te contactaremos en menos de 24 horas hábiles para entender bien lo que necesitas.</p>
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
          <button class="btn btn--gold btn--lg btn--block" style="margin-top:18px" type="submit">${ic('target')} Enviar solicitud de búsqueda</button>
          <p style="font-size:12.5px;color:var(--muted);margin:10px 0 0;text-align:center">Sin costo ni compromiso.</p>
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
      const nombre = esc(fd.nombre.split(' ')[0]);
      f.innerHTML = `
        <div class="success" style="padding:20px 6px">
          <div class="check">${ic('check')}</div>
          <h2 class="display" style="color:var(--green-950)">¡Solicitud recibida, ${nombre}!</h2>
          <p style="color:var(--muted)">Te llamaremos dentro de las próximas 24 horas hábiles.</p>
          <div class="call-script">
            <b>Así sonará nuestra llamada:</b><br><br>
            “Hola ${nombre}, ¿cómo estás? Soy Matías de Atlas Motors. Recibí tu solicitud de búsqueda personalizada: vi que andas buscando un <b>${esc(fd.marca)} ${esc(fd.modelo)}</b> entre ${esc(fd.desde)} y ${esc(fd.hasta)}, con un presupuesto de <b>${clp(+fd.presupuesto)}</b>. Voy a hacer un estudio de mercado y vemos juntos las mejores opciones.”
          </div>
          <a class="btn btn--green" style="margin-top:20px" href="#/autos">Ver autos inspeccionados</a>
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
            <a href="#/autos">${ic('car')} Ver autos inspeccionados</a>
            <button data-action="whatsapp">${ic('chat')} Hablar por WhatsApp</button>
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
    const [path, qs] = raw.split('?');
    const params = new URLSearchParams(qs || '');
    const parts = path.split('/').filter(Boolean);
    let html, bind, nav = parts[0] || 'home';
    switch (parts[0]) {
      case undefined: html = viewHome(); bind = bindHome; break;
      case 'autos': html = viewAutos(params); bind = bindAutos; break;
      case 'auto': html = viewAuto(parts[1]); bind = () => bindAuto(parts[1]); nav = 'autos'; break;
      case 'informe': html = viewInforme(parts[1]); nav = 'autos'; break;
      case 'inspeccion': html = viewInspeccion(); break;
      case 'agendar': html = viewAgendar(params); bind = bindAgendar; break;
      case 'busqueda': html = viewBusqueda(); bind = bindBusqueda; break;
      default: html = viewNotFound();
    }
    const fresh = app.cloneNode(false); app.replaceWith(fresh); app = fresh;
    app.innerHTML = html;
    $$('#nav a').forEach((a) => a.classList.toggle('active', a.dataset.nav === nav));
    $('#nav').classList.remove('open'); $('#menuBtn').setAttribute('aria-expanded', 'false');
    window.scrollTo(0, 0);
    bind && bind();
    document.title = ({ home: 'Atlas Motors · Vehículos inspeccionados en la Región de Coquimbo', autos: 'Vehículos inspeccionados · Atlas Motors', inspeccion: 'Inspección precompra · Atlas Motors', agendar: 'Agendar inspección · Atlas Motors', busqueda: 'Búsqueda personalizada · Atlas Motors' })[nav] || 'Atlas Motors';
  }

  function bindHome() {
    $('#homeSearch').addEventListener('submit', (e) => {
      e.preventDefault();
      const p = new URLSearchParams(Object.entries(Object.fromEntries(new FormData(e.target))).filter(([, v]) => v));
      location.hash = '#/autos' + (p.toString() ? '?' + p : '');
    });
  }

  /* acciones globales */
  document.addEventListener('click', (e) => {
    const a = e.target.closest('[data-action]'); if (!a) return;
    const act = a.dataset.action;
    if (act === 'whatsapp') toast('Demo: aquí se abrirá WhatsApp con Atlas Motors');
    if (act === 'favorito') { a.innerHTML = `${ic('star')} Guardado en favoritos`; toast('Vehículo guardado en favoritos'); }
    if (act === 'print') window.print();
  });

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
