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
  // Opiniones en Google (perfil "Atlas Motors Chile spa"). Se actualizan a mano.
  // Revisado el 2026-11-18: 5,0 con 6 opiniones.
  const GOOGLE = { nota: 5, opiniones: 6, url: 'https://www.google.com/maps?cid=15933301111320184842' };
  const googleBadge = (cls = '') => `
    <a class="g-rating ${cls}" href="${GOOGLE.url}" target="_blank" rel="noopener" aria-label="${GOOGLE.nota.toLocaleString('es-CL', { minimumFractionDigits: 1 })} de 5 estrellas en Google, ${GOOGLE.opiniones} opiniones">
      <span class="g-rating__stars" style="--v:${(GOOGLE.nota / 5) * 100}%" aria-hidden="true"></span>
      <b>${GOOGLE.nota.toLocaleString('es-CL', { minimumFractionDigits: 1 })}</b>
      <span>${GOOGLE.opiniones} opiniones en Google</span>
    </a>`;
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
    heart: '<path d="M12 20.5S3 15.2 3 9.2A4.7 4.7 0 0 1 12 6.6a4.7 4.7 0 0 1 9 2.6c0 6-9 11.3-9 11.3Z"/>',
    link: '<path d="M10 14a4.5 4.5 0 0 0 6.4 0l3-3a4.5 4.5 0 0 0-6.4-6.4l-1.2 1.2"/><path d="M14 10a4.5 4.5 0 0 0-6.4 0l-3 3a4.5 4.5 0 0 0 6.4 6.4l1.2-1.2"/>',
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
  // Escáner animado: vive en assets/js/scanner.js.
  const scannerArt = () => (window.AtlasScanner ? window.AtlasScanner.html() : '');

  // Política del abono. PENDIENTE: confirmar con Matías antes de publicar.
  const ABONO_POLITICA = 'Si avisas con al menos 24 horas de anticipación, cambiamos la fecha sin costo o te devolvemos el abono. Si después de la inspección vendes el auto con nosotros, el valor de la inspección se descuenta de lo que nos corresponde por la venta. Si nosotros no podemos ir, te devolvemos el 100 %. Con menos de 24 horas de aviso, el abono cubre el traslado y no se devuelve.';
  const FAQS = () => [
    ['¿Cuánto cuesta la inspección?', `La inspección completa vale ${clp(PLANES[0].precio)}. Reservas tu hora con un abono de ${clp(ABONO)} por transferencia y pagas el resto el día de la inspección.`],
    ['¿Qué pasa con el abono si hay que cambiar la fecha?', ABONO_POLITICA],
    ['¿Tengo que estar presente?', 'No. Si no puedes ir, hacemos la inspección remota: grabamos todo, te mandamos cada hallazgo con foto por WhatsApp en el momento y después te explicamos el estado real del auto por llamada o audio.'],
    ['¿La inspección es un diagnóstico?', 'No. La inspección precompra busca que no te vendan un auto chocado, con fallas graves escondidas o con el kilometraje alterado. Un diagnóstico requiere el auto varias horas en taller.'],
    ['¿Qué recibo al final?', 'Un informe en PDF con el checklist de las 8 etapas, fotos de lo que encontramos y una idea de cuánto cuesta reparar cada detalle, para que negocies el precio con respaldo.'],
    ['¿Revisan cualquier marca?', 'Sí. Revisamos autos, SUV y camionetas multimarca, a bencina y diésel, incluidos vehículos de alta gama.'],
    ['¿A qué comunas van?', 'La Serena y Coquimbo. Para otras comunas de la región, escríbenos y lo coordinamos.'],
  ];
  const faq = () => `
    <section class="section">
      <div class="container faq-wrap">
        <div><span class="eyebrow">Preguntas frecuentes</span><h2 class="display" style="font-size:clamp(26px,3.4vw,38px);color:#fff;margin-top:10px">Lo que más nos preguntan</h2>
          <p style="color:var(--muted)">¿Tienes otra duda? Escríbenos y te respondemos al tiro.</p>
          <a class="btn btn--outline" href="${waLink('Hola Atlas Motors, tengo una consulta.')}" target="_blank" rel="noopener">${ic('chat')} Preguntar por WhatsApp</a>
        </div>
        <div class="faq">${FAQS().map(([q, a], i) => `<details ${i === 0 ? 'open' : ''}><summary>${q}<span class="faq__ic">${ic('right')}</span></summary><p>${a}</p></details>`).join('')}</div>
      </div>
    </section>`;

  /* ---------------- vistas ---------------- */
  /* ---------------- portada: marketplace ---------------- */
  // Buscador de autos (portada y listado). Las marcas y comunas salen de los autos publicados.
  const buscador = (p = {}) => `
    <form class="mk-buscar" data-buscar role="search" aria-label="Buscar autos en venta">
      <label class="mk-buscar__q">${ic('search')}<span class="sr-only">Buscar</span>
        <input type="search" name="q" value="${esc(p.q || '')}" placeholder="Busca por marca o modelo" autocomplete="off" enterkeyhint="search"></label>
      <label class="mk-buscar__sel">${ic('car')}<span class="sr-only">Marca</span>
        <select name="marca" data-valor="${esc(p.marca || '')}"><option value="">Todas las marcas</option></select></label>
      <label class="mk-buscar__sel">${ic('pin')}<span class="sr-only">Comuna</span>
        <select name="comuna" data-valor="${esc(p.comuna || '')}"><option value="">La Serena y Coquimbo</option></select></label>
      <button class="btn btn--gold" type="submit">${ic('search')} Buscar</button>
    </form>`;
  const sinTilde = (s) => String(s || '').normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase();
  function bindBuscador() {
    $$('[data-buscar]').forEach((f) => {
      f.addEventListener('submit', (e) => {
        e.preventDefault();
        const p = new URLSearchParams();
        ['q', 'marca', 'comuna'].forEach((k) => { const v = f.elements[k].value.trim(); if (v) p.set(k, v); });
        evento('buscar');
        const destino = `#/autos${p.toString() ? '?' + p : ''}`;
        if (location.hash === destino) route(); else location.hash = destino;
      });
      cargarAutos().then((list) => {
        const opciones = (sel, valores) => {
          const unicos = [...new Set(valores.filter(Boolean))].sort((a, b) => a.localeCompare(b, 'es'));
          sel.insertAdjacentHTML('beforeend', unicos.map((v) => `<option>${esc(v)}</option>`).join(''));
          sel.value = sel.dataset.valor || '';
        };
        opciones(f.elements.marca, list.map((a) => a.marca));
        opciones(f.elements.comuna, ['La Serena', 'Coquimbo', ...list.map((a) => a.comuna)]);
      }).catch(() => {});
    });
  }
  const filtroAutos = () => {
    const p = new URLSearchParams(location.hash.split('?')[1] || '');
    return { q: p.get('q') || '', marca: p.get('marca') || '', comuna: p.get('comuna') || '' };
  };
  const filtrar = (list, f) => {
    const palabras = sinTilde(f.q).split(/\s+/).filter(Boolean);
    return list.filter((a) => {
      if (f.marca && sinTilde(a.marca) !== sinTilde(f.marca)) return false;
      if (f.comuna && sinTilde(a.comuna) !== sinTilde(f.comuna)) return false;
      const texto = sinTilde([a.marca, a.modelo, a.anio, a.comuna, a.combustible, a.transmision, a.descripcion].join(' '));
      return palabras.every((w) => texto.includes(w));
    });
  };

  // Tarjetas que completan los destacados cuando hay pocos autos publicados.
  const PROMOS = () => [
    { ic: 'handshake', t: '¿Vendes tu auto?', p: 'Lo inspeccionamos y lo publicamos aquí con su informe. Los compradores confían más y se vende antes.', a: 'Quiero vender mi auto', href: waLink('Hola Atlas Motors, quiero vender mi auto con inspección.'), ext: true },
    { ic: 'target', t: '¿No encuentras el tuyo?', p: 'Dinos qué auto buscas y tu presupuesto. Lo buscamos, lo inspeccionamos y negociamos por ti.', a: 'Búscame un auto', href: '#/busqueda' },
    { ic: 'scan', t: '¿Encontraste uno en otro lado?', p: 'Vamos a revisarlo antes de que pagues: carrocería, motor, escáner, parte baja y prueba de ruta.', a: 'Agendar inspección', href: '#/agendar' },
  ];
  const promoCard = (x) => `
    <a class="mk-promo" href="${x.href}" ${x.ext ? 'target="_blank" rel="noopener"' : ''}>
      <span class="mk-promo__ic">${ic(x.ic)}</span>
      <h3>${x.t}</h3><p>${x.p}</p>
      <span class="mk-promo__a">${x.a} ${ic('arrow')}</span>
    </a>`;
  async function bindDestacados() {
    const box = $('#mkAutos'); if (!box) return;
    let list = [];
    try { list = await cargarAutos(); } catch (e) { /* sin conexión: solo las tarjetas de ayuda */ }
    if (!document.body.contains(box)) return;
    const autosV = list.slice(0, 4);
    box.innerHTML = autosV.map(autoCard).join('') + PROMOS().slice(0, Math.max(0, 4 - autosV.length)).map(promoCard).join('');
    const n = $('#mkTotal'); if (n && list.length > 1) n.textContent = `Ver los ${list.length} autos`;
  }

  function viewHome() {
    const completa = PLANES[0];
    return `
    <section class="mk-portada">
      <div class="mk-portada__fondo" aria-hidden="true"></div>
      <img class="mk-portada__img" src="assets/img/hero-autos.webp" alt="" width="1916" height="821" fetchpriority="high" aria-hidden="true">
      <div class="mk-portada__verde" aria-hidden="true"></div>
      <div class="container mk-portada__in">
        <div class="mk-portada__text">
          <h1><span>No compres a ciegas.</span><br><span>Compra con <span class="oro">respaldo.</span></span></h1>
          <p class="mk-portada__lema"><b>El primer marketplace de autos</b> 100% inspeccionados en la Región de Coquimbo.</p>
          <a class="btn mk-cta" href="#/autos">${ic('search')} Explorar vehículos ${ic('arrow')}</a>
        </div>
      </div>
    </section>

    <div class="mk-trust">
      <div class="container mk-trust__in">
        <div><span class="ic">${ic('shield')}</span><p><b>Autos inspeccionados</b> con informe detallado</p></div>
        <div><span class="ic">${ic('play')}</span><p><b>Fotos y videos</b> reales del auto</p></div>
        <div><span class="ic">${ic('handshake')}</span><p><b>Compra y venta</b> con respaldo</p></div>
        <div><span class="ic">${ic('pin')}</span><p><b>La Serena</b> y Coquimbo</p></div>
      </div>
    </div>

    <section class="mk-destacados mk-oscuro">
      <div class="container">
        <div class="mk-head">
          <h2>Autos destacados</h2>
          <a class="btn btn--line btn--sm" href="#/autos"><span id="mkTotal">Ver todos los autos</span> ${ic('arrow')}</a>
        </div>
        <div class="mk-buscar--home">${buscador()}</div>
        <div id="mkAutos" class="mk-grid"><p class="mk-cargando">Cargando autos…</p></div>
      </div>
    </section>

    <section class="mk-porque">
      <div class="container mk-porque__in">
        <div class="mk-porque__t">
          <h2>¿Por qué comprar en <span>Atlas Motors?</span></h2>
          <p>No solo publicamos autos: primero revisamos su estado, para que compres tranquilo.</p>
          <a class="btn btn--gold" href="#/inspeccion">Conoce la inspección ${ic('arrow')}</a>
        </div>
        ${window.AtlasViaje ? window.AtlasViaje.html() : ''}
      </div>
    </section>

    <section class="hero hero--inspeccion">
      <div class="container hero__inner">
        <div>
          <span class="hero__badge"><span>ATLAS</span> Inspección precompra</span>
          <h2 class="hero__titulo">¿Encontraste un auto? Lo revisamos con <span class="gold-text">ojo de águila</span>
            <small>Inspección precompra profesional en la Región de Coquimbo. Revisamos el auto <b>antes de que pagues</b>: carrocería, estructura, motor, escáner y prueba de ruta. Presencial o remota.</small>
          </h2>
          <div class="hero__cta">
            <a href="#/agendar" class="btn btn--gold btn--lg">${ic('calendar')} Agendar inspección</a>
            <a href="${waLink('Hola Atlas Motors, quiero agendar una inspección precompra.')}" target="_blank" rel="noopener" class="btn btn--ghost btn--lg">${ic('chat')} Escríbenos por WhatsApp</a>
          </div>
          ${googleBadge()}
          <div class="hero__stats">
            <div><b>8</b><span>etapas de revisión</span></div>
            <div><b>${clp(completa.precio)}</b><span>inspección completa</span></div>
            <div><b>${clp(ABONO)}</b><span>de abono para reservar</span></div>
          </div>
        </div>
        <div class="hero__visual">${window.AtlasHistoria ? window.AtlasHistoria.html() : `<div class="scanner-art">${scannerArt()}</div>`}</div>
      </div>
    </section>

    <section class="section mk-oscuro mk-oscuro--alt">
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

    <section class="section mk-oscuro">
      <div class="container">
        <div class="section__head"><div><span class="eyebrow">Inspección precompra</span><h2>Así funciona, en 4 pasos</h2></div></div>
        <div class="steps">
          <div class="step"><h4>Agenda</h4><p>Cuéntanos qué auto es, dónde está y qué día te acomoda. Aquí o por WhatsApp.</p></div>
          <div class="step"><h4>Reserva tu hora</h4><p>Con un abono de ${clp(ABONO)} por transferencia. El resto, el día de la inspección.</p></div>
          <div class="step"><h4>Inspeccionamos</h4><p>8 etapas: carrocería, estructura, motor, parte baja, interior, escáner y prueba de ruta.</p></div>
          <div class="step"><h4>Decide con datos</h4><p>Recibe el informe con fotos y el costo de cada reparación. Compra o negocia con respaldo.</p></div>
        </div>
      </div>
    </section>

    <section class="section--tight">
      <div class="container">
        <div class="mascot">
          <div class="mascot__img">
            <button class="eagle" type="button" aria-label="¿Te ayudo? Abrir ayuda">
              <img src="assets/img/aguila.png" alt="Águila mascota de Atlas Motors con overol de mecánico levantando el pulgar" loading="lazy" width="403" height="640">
              <span class="eagle__say" aria-hidden="true">¿Te ayudo?</span>
            </button>
          </div>
          <div style="position:relative;z-index:1">
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
        <div id="igFeed" class="ig-feed"></div>
      </div>
    </section>`;
  }

  /* ---------------- marketplace (autos publicados desde la app de inspecciones) ---------------- */
  // Firestore: colección pública `publicaciones` del proyecto atlas-motors-cl (solo lectura).
  const FS = 'https://firestore.googleapis.com/v1/projects/atlas-motors-cl/databases/(default)/documents/publicaciones';
  const FS_KEY = 'AIzaSyA2LXQSXJFZKdlGvuGuSqqA5uesFft6XSg';
  const fsVal = (v) => {
    if ('stringValue' in v) return v.stringValue;
    if ('integerValue' in v) return Number(v.integerValue);
    if ('doubleValue' in v) return v.doubleValue;
    if ('booleanValue' in v) return v.booleanValue;
    if ('timestampValue' in v) return v.timestampValue;
    if ('arrayValue' in v) return (v.arrayValue.values || []).map(fsVal);
    if ('mapValue' in v) return fsObj(v.mapValue.fields || {});
    return null;
  };
  const fsObj = (f) => Object.fromEntries(Object.entries(f).map(([k, v]) => [k, fsVal(v)]));
  // Lo que viene de Firestore se trata como no confiable: números como números
  // y solo enlaces a nuestro Storage (nada de javascript: ni sitios externos).
  const STORAGE_OK = /^https:\/\/firebasestorage\.googleapis\.com\/v0\/b\/atlas-motors-cl-fotos\/o\/publicaciones%2F[^"'<>\s]*$/;
  const num = (v, min = 0, max = Infinity) => {
    const n = typeof v === 'number' ? v : (typeof v === 'string' && /^\d+$/.test(v) ? Number(v) : NaN);
    return Number.isFinite(n) && n >= min && n <= max ? Math.round(n) : null;
  };
  const DIA = /^\d{4}-\d{2}-\d{2}/;
  const diaCorto = (d) => fecha(String(d).slice(0, 10), { day: 'numeric', month: 'short', year: 'numeric' });
  const txt = (v, max = 3000) => (v == null ? '' : String(v).slice(0, max));
  const lista = (v) => (Array.isArray(v) ? v : []);
  const limpiarAuto = (a) => ({
    id: txt(a.id, 64), folio: txt(a.folio, 40), marca: txt(a.marca, 60), modelo: txt(a.modelo, 80),
    anio: num(a.anio, 1950, 2100), km: num(a.km), precio: num(a.precio, 1), comuna: txt(a.comuna, 60),
    combustible: txt(a.combustible, 30), transmision: txt(a.transmision, 30), descripcion: txt(a.descripcion),
    comentario: txt(a.comentario), puntaje: num(a.puntaje, 0, 100), recomendacion: txt(a.recomendacion, 60),
    nivel: num(a.nivel, 0, 2),
    conteo: { bien: num((a.conteo || {}).bien) || 0, obs: num((a.conteo || {}).obs) || 0, problema: num((a.conteo || {}).problema) || 0 },
    etapas: lista(a.etapas).map((e) => ({ titulo: txt((e || {}).titulo, 60), bien: num((e || {}).bien) || 0, obs: num((e || {}).obs) || 0, problema: num((e || {}).problema) || 0 })),
    hallazgos: lista(a.hallazgos).map((h) => ({
      punto: txt((h || {}).punto, 120), etapa: txt((h || {}).etapa, 60), estado: txt((h || {}).estado, 60), nivel: num((h || {}).nivel, 0, 2),
      corregido: h && h.corregido && DIA.test(String(h.corregido.fecha)) ? { fecha: String(h.corregido.fecha).slice(0, 10), texto: txt(h.corregido.texto, 300) } : null,
    })),
    // Trabajos hechos después de la inspección (las boletas no se publican).
    actualizaciones: lista(a.actualizaciones).filter((u) => u && DIA.test(String(u.fecha))).slice(0, 40).map((u) => ({
      fecha: String(u.fecha).slice(0, 10), punto: txt(u.punto, 120), texto: txt(u.texto, 300), respaldo: u.respaldo === true,
    })),
    tieneMapa: Array.isArray(a.danos),
    danos: lista(a.danos).slice(0, 60).map((d) => ({
      zona: txt((d || {}).zona, 40), pieza: txt((d || {}).pieza, 60), tipo: txt((d || {}).tipo, 40),
      nivel: num((d || {}).nivel, 1, 2) || 1, x: num((d || {}).x, 0, 340) ?? -1, y: num((d || {}).y, 0, 700) ?? -1,
    })),
    mapa: limpiarMapa(a.mapa),
    fotos: lista(a.fotos).filter((u) => STORAGE_OK.test(String(u))).slice(0, 40),
    ficha: STORAGE_OK.test(String(a.ficha || '')) ? a.ficha : null,
    videos: lista(a.videos).filter((v) => v && STORAGE_OK.test(String(v.url))).slice(0, 4).map((v) => ({
      url: v.url, poster: STORAGE_OK.test(String(v.poster || '')) ? v.poster : null, nota: txt(v.nota, 300), segundos: num(v.segundos, 0, 120),
    })),
    fechaInspeccion: /^\d{4}-\d{2}-\d{2}/.test(String(a.fechaInspeccion || '')) ? String(a.fechaInspeccion) : '',
    publicado: txt(a.publicado, 40),
  });
  let autos = null; // caché mientras dura la visita
  async function cargarAutos() {
    if (autos) return autos;
    const r = await fetch(`${FS}?pageSize=300&key=${FS_KEY}`);
    if (!r.ok) throw new Error('HTTP ' + r.status);
    const j = await r.json();
    autos = (j.documents || []).map((d) => limpiarAuto(fsObj(d.fields || {})))
      .sort((a, b) => String(b.publicado || '').localeCompare(String(a.publicado || '')));
    return autos;
  }
  const nombreAuto = (a) => [a.marca, a.modelo, a.anio].filter(Boolean).join(' ');

  /* ---------------- Instagram: copia de @atlas.motors.cl ---------------- */
  // La función `instagram` (functions/instagram) deja cada 20 min las últimas
  // publicaciones e historias en instagram/feed, con las fotos copiadas a Storage.
  const IG_FEED = `https://firestore.googleapis.com/v1/projects/atlas-motors-cl/databases/(default)/documents/instagram/feed?key=${FS_KEY}`;
  const IG_MEDIA = /^https:\/\/firebasestorage\.googleapis\.com\/v0\/b\/atlas-motors-cl-fotos\/o\/instagram%2F[^"'<>\s]*$/;
  const IG_LINK = /^https:\/\/(www\.)?instagram\.com\/[^"'<>\s]*$/;
  const igUrl = (u, re) => (typeof u === 'string' && re.test(u) ? u : '');
  let igCarga = null;
  function cargarInstagram() {
    igCarga = igCarga || fetch(IG_FEED).then((r) => (r.ok ? r.json() : null)).then((d) => {
      const f = d && d.fields ? fsObj(d.fields) : {};
      const ahora = Date.now();
      return {
        posts: lista(f.posts).filter((p) => p && igUrl(p.img, IG_MEDIA)).slice(0, 8).map((p) => ({
          img: p.img, link: igUrl(p.link, IG_LINK) || IG, video: p.tipo === 'video', carrusel: p.tipo === 'carrusel', texto: txt(p.texto, 300),
        })),
        historias: lista(f.historias).filter((h) => h && Date.parse(h.fecha) > ahora - 864e5 && (igUrl(h.img, IG_MEDIA) || igUrl(h.video, IG_MEDIA))).slice(0, 30).map((h) => ({
          img: igUrl(h.img, IG_MEDIA), video: igUrl(h.video, IG_MEDIA), link: igUrl(h.link, IG_LINK) || IG, fecha: Date.parse(h.fecha),
        })),
      };
    }).catch(() => ({ posts: [], historias: [] }));
    return igCarga;
  }
  const haceCuanto = (ms) => {
    const h = Math.floor((Date.now() - ms) / 36e5);
    return h < 1 ? 'Recién' : `Hace ${h} h`;
  };
  async function bindInstagram() {
    const box = $('#igFeed'); if (!box) return;
    const { posts, historias } = await cargarInstagram();
    if (!document.body.contains(box) || (!posts.length && !historias.length)) return;
    box.innerHTML = `
      ${historias.length ? `<div class="ig-stories" role="list" aria-label="Historias de Instagram">${historias.map((h, i) => `
        <button type="button" class="ig-story" role="listitem" data-story="${i}" aria-label="Ver historia ${i + 1} de ${historias.length}">
          <span class="ig-story__ring"><img src="${esc(h.img || 'assets/img/aguila.png')}" alt="" loading="lazy"></span>
          <span class="ig-story__t">${haceCuanto(h.fecha)}</span>
        </button>`).join('')}</div>` : ''}
      ${posts.length ? `<div class="ig-grid">${posts.map((p) => `
        <a class="ig-post" href="${esc(p.link)}" target="_blank" rel="noopener" data-ev="instagram_post">
          <img src="${esc(p.img)}" alt="${esc(p.texto.split('\n')[0].slice(0, 100) || 'Publicación de Atlas Motors en Instagram')}" loading="lazy">
          ${p.video ? `<span class="ig-post__tag">${ic('video')}</span>` : p.carrusel ? `<span class="ig-post__tag">${ic('camera')}</span>` : ''}
        </a>`).join('')}</div>` : ''}`;
    box.addEventListener('click', (e) => {
      const b = e.target.closest('[data-story]');
      if (b) verHistorias(historias, Number(b.dataset.story));
    });
  }
  // Visor de historias: avanza solo (fotos 5 s, videos hasta que terminan).
  function verHistorias(lista, inicio) {
    let i = inicio, timer = null;
    const v = document.createElement('div');
    v.className = 'ig-viewer';
    v.setAttribute('role', 'dialog'); v.setAttribute('aria-modal', 'true'); v.setAttribute('aria-label', 'Historias de Atlas Motors');
    const volverA = document.activeElement;
    const cerrar = () => { clearTimeout(timer); v.remove(); document.removeEventListener('keydown', teclas); document.body.style.overflow = ''; volverA && volverA.focus && volverA.focus(); };
    const ir = (n) => { if (n < 0) n = 0; if (n >= lista.length) return cerrar(); i = n; pintar(); };
    const teclas = (e) => { if (e.key === 'Escape') cerrar(); else if (e.key === 'ArrowRight') ir(i + 1); else if (e.key === 'ArrowLeft') ir(i - 1); };
    function pintar() {
      clearTimeout(timer);
      const h = lista[i];
      v.innerHTML = `
        <div class="ig-viewer__box">
          <div class="ig-viewer__bars">${lista.map((_, n) => `<span class="${n < i ? 'done' : n === i ? 'now' : ''}"><i></i></span>`).join('')}</div>
          <div class="ig-viewer__head"><span class="ig-viewer__user">${ic('instagram')} atlas.motors.cl · ${haceCuanto(h.fecha)}</span>
            <button type="button" class="ig-viewer__x" aria-label="Cerrar">${ic('x')}</button></div>
          ${h.video ? `<video src="${esc(h.video)}" ${h.img ? `poster="${esc(h.img)}"` : ''} autoplay playsinline></video>` : `<img src="${esc(h.img)}" alt="Historia de Atlas Motors">`}
          <button type="button" class="ig-viewer__nav ig-viewer__nav--prev" aria-label="Anterior"></button>
          <button type="button" class="ig-viewer__nav ig-viewer__nav--next" aria-label="Siguiente"></button>
          <a class="btn btn--gold ig-viewer__cta" href="${esc(h.link)}" target="_blank" rel="noopener">${ic('instagram')} Ver en Instagram</a>
        </div>`;
      const bar = v.querySelector('.now i');
      const vid = v.querySelector('video');
      if (vid) {
        vid.addEventListener('timeupdate', () => { if (vid.duration) bar.style.width = `${(vid.currentTime / vid.duration) * 100}%`; });
        vid.addEventListener('ended', () => ir(i + 1));
        vid.play().catch(() => { vid.muted = true; vid.play().catch(() => {}); });
      } else {
        bar.style.transition = 'width 5s linear';
        requestAnimationFrame(() => requestAnimationFrame(() => { bar.style.width = '100%'; }));
        timer = setTimeout(() => ir(i + 1), 5000);
      }
      v.querySelector('.ig-viewer__x').focus();
    }
    v.addEventListener('click', (e) => {
      if (e.target === v || e.target.closest('.ig-viewer__x')) cerrar();
      else if (e.target.closest('.ig-viewer__nav--prev')) ir(i - 1);
      else if (e.target.closest('.ig-viewer__nav--next')) ir(i + 1);
    });
    document.addEventListener('keydown', teclas);
    window.addEventListener('hashchange', cerrar, { once: true });
    document.body.style.overflow = 'hidden';
    document.body.appendChild(v);
    pintar();
  }

  /* ---------------- favoritos (solo en este navegador, sin cuenta) ---------------- */
  const FAV_KEY = 'atlas-favoritos';
  const leerFavs = () => {
    try { const v = JSON.parse(localStorage.getItem(FAV_KEY) || '[]'); return Array.isArray(v) ? v.filter((x) => typeof x === 'string' && x.length <= 64).slice(0, 200) : []; } catch (e) { return []; }
  };
  const toggleFav = (id) => {
    const f = leerFavs(); const i = f.indexOf(id);
    if (i >= 0) f.splice(i, 1); else f.unshift(id);
    try { localStorage.setItem(FAV_KEY, JSON.stringify(f)); } catch (e) { /* modo privado: no se guarda */ }
    return i < 0;
  };
  const favBtn = (id, cls = '') => {
    const on = leerFavs().includes(id);
    return `<button type="button" class="fav ${cls}${on ? ' on' : ''}" data-fav="${esc(id)}" aria-pressed="${on}" aria-label="${on ? 'Quitar de favoritos' : 'Guardar en favoritos'}">${ic('heart')}<span>${on ? 'Guardado' : 'Guardar'}</span></button>`;
  };

  /* ---------------- compartir un auto ---------------- */
  const SITIO = 'https://www.atlasmotors.cl';
  const enlaceAuto = (a) => `${SITIO}/#/auto/${encodeURIComponent(a.id)}`;
  const textoCompartir = (a) => `Mira este auto inspeccionado por Atlas Motors: ${nombreAuto(a)}${a.precio ? ' · ' + clp(a.precio) : ''}${a.puntaje != null ? ' · puntaje ' + a.puntaje + '/100' : ''}\n${enlaceAuto(a)}`;

  /* ---------------- avísame cuando llegue un auto así ---------------- */
  const PRESUPUESTOS = [5, 8, 10, 12, 15, 20, 25, 30, 40, 50].map((m) => m * 1000000);
  const avisameForm = (pref = {}) => {
    const tope = pref.precio ? PRESUPUESTOS.find((p) => p >= pref.precio) || 0 : 0;
    const anio = new Date().getFullYear();
    return `
    <form class="panel avisame" data-avisame novalidate>
      <div class="avisame__head">
        <span class="ic">${ic('bell')}</span>
        <div><h3>${esc(pref.titulo || 'Avísame cuando llegue un auto así')}</h3>
        <p>Cuéntanos qué buscas y te escribimos por WhatsApp cuando publiquemos uno parecido. Sin costo.</p></div>
      </div>
      <div class="avisame__grid">
        <div class="field"><label for="avQue">Qué auto buscas *</label><input class="input" id="avQue" name="que" maxlength="80" placeholder="Ej: Toyota Hilux, SUV automático" value="${esc(pref.que || '')}"></div>
        <div class="field"><label for="avPres">Presupuesto hasta</label><select class="select" id="avPres" name="presupuesto">
          <option value="">Cualquiera</option>${PRESUPUESTOS.map((p) => `<option value="${p}"${p === tope ? ' selected' : ''}>${clp(p)}</option>`).join('')}<option value="mas">Más de ${clp(50000000)}</option></select></div>
        <div class="field"><label for="avAnio">Año desde</label><select class="select" id="avAnio" name="anio">
          <option value="">Cualquiera</option>${Array.from({ length: 16 }, (_, i) => anio - i).map((y) => `<option>${y}</option>`).join('')}</select></div>
        <button class="btn btn--gold" type="submit">${ic('chat')} Avísame por WhatsApp</button>
      </div>
      <p class="avisame__nota">Se abre WhatsApp con tu pedido. <a href="#/privacidad">Cómo usamos tus datos</a>.</p>
    </form>`;
  };
  document.addEventListener('submit', (e) => {
    const f = e.target.closest('[data-avisame]'); if (!f) return;
    e.preventDefault();
    const que = f.que.value.trim();
    if (!que) { f.que.focus(); toast('Cuéntanos qué auto buscas'); return; }
    const pres = f.presupuesto.value === 'mas' ? `más de ${clp(50000000)}` : f.presupuesto.value ? clp(+f.presupuesto.value) : 'cualquiera';
    const msg = `Hola Atlas Motors, avísenme cuando publiquen un auto así:\n• Busco: ${que}\n• Presupuesto hasta: ${pres}\n• Año desde: ${f.anio.value || 'cualquiera'}`;
    sumar(['avisame_enviado']);
    window.open(waLink(msg), '_blank', 'noopener');
    toast('¡Listo! Envía el mensaje en WhatsApp y te avisamos.');
  });

  /* ---------------- estadísticas anónimas ---------------- */
  // Cuenta visitas y clics sin cookies ni datos personales: cada evento suma 1 a un
  // contador del día (estadisticas/AAAA-MM-DD en Firestore). No se guarda IP, navegador
  // ni ningún identificador de la persona. Las reglas solo permiten sumar de a 1.
  // En el navegador queda solo la fecha de la primera y la última visita (para
  // distinguir visitantes nuevos de los que vuelven).
  const STATS_URL = `https://firestore.googleapis.com/v1/projects/atlas-motors-cl/databases/(default)/documents:commit?key=${FS_KEY}`;
  const STATS_DOC = 'projects/atlas-motors-cl/databases/(default)/documents/estadisticas/';
  const hoyCL = () => new Date().toLocaleDateString('sv-SE', { timeZone: 'America/Santiago' });
  const claveAuto = (id) => String(id).toLowerCase().replace(/[^a-z0-9]/g, '').slice(0, 40);
  const SIN_STATS = !/(^|\.)atlasmotors\.cl$/.test(location.hostname) || navigator.webdriver; // ni pruebas locales ni robots
  function sumar(claves) {
    const ks = [...new Set(claves)].filter((k) => /^[a-z0-9_]{1,60}$/.test(k)).slice(0, 4);
    if (!ks.length) return;
    if (SIN_STATS) { if (window.ATLAS_DEBUG_STATS) console.info('[estadísticas]', ks.join(', ')); return; }
    // `_k` declara qué contadores se suman (las reglas lo exigen); el resto son incrementos atómicos.
    const body = JSON.stringify({ writes: [{
      update: { name: STATS_DOC + hoyCL(), fields: { _k: { arrayValue: { values: ks.map((k) => ({ stringValue: k })) } } } },
      updateMask: { fieldPaths: ['_k'] },
      updateTransforms: ks.map((k) => ({ fieldPath: k, increment: { integerValue: '1' } })),
    }] });
    try { fetch(STATS_URL, { method: 'POST', body, keepalive: true, headers: { 'Content-Type': 'application/json' } }).catch(() => {}); } catch (e) { /* sin red: no se cuenta */ }
  }
  const AUTO_EV = { wa_auto: 'wa', compartir_wa: 'compartir', compartir_copiar: 'compartir', fav_agregar: 'fav', ficha: 'ficha' };
  const evento = (ev, autoId) => sumar([ev, ...(autoId && AUTO_EV[ev] ? [`a_${claveAuto(autoId)}_${AUTO_EV[ev]}`] : [])]);
  function contarVisita() {
    const hoy = hoyCL(); let ultima = null, primera = null;
    try { ultima = localStorage.getItem('atlas-ultima-visita'); primera = localStorage.getItem('atlas-primera-visita'); } catch (e) { /* sin almacenamiento */ }
    if (ultima === hoy) return; // una vez por día y navegador
    try { localStorage.setItem('atlas-ultima-visita', hoy); if (!primera) localStorage.setItem('atlas-primera-visita', hoy); } catch (e) { /* idem */ }
    let ref = ''; try { ref = document.referrer ? new URL(document.referrer).hostname : ''; } catch (e) { /* referrer raro */ }
    const ua = navigator.userAgent;
    const origen = /instagram/i.test(ref + ua) ? 'instagram' : /facebook|fban|fbav|fb\.me/i.test(ref + ua) ? 'facebook'
      : /(^|\.)google\./.test(ref) ? 'google' : /whatsapp|wa\.me/i.test(ref + ua) ? 'whatsapp'
      : !ref || ref === location.hostname ? 'directo' : 'otro';
    sumar(['visitantes', primera ? 'visitantes_recurrentes' : 'visitantes_nuevos', `origen_${origen}`, matchMedia('(max-width: 720px)').matches ? 'disp_movil' : 'disp_escritorio']);
  }
  const PAGINAS = ['home', 'autos', 'auto', 'informe', 'inspeccion', 'agendar', 'busqueda', 'privacidad'];
  const contarPagina = (parts) => {
    const pg = parts[0] || 'home';
    if (pg === 'auto' && parts[1]) sumar(['pv_auto', `a_${claveAuto(parts[1])}_vista`]);
    else sumar([`pv_${PAGINAS.includes(pg) ? pg : 'otra'}`]);
  };

  // Clics: favoritos, copiar enlace y enlaces que interesan (WhatsApp, Instagram, Google, llamar).
  document.addEventListener('click', (e) => {
    const fav = e.target.closest('[data-fav]');
    if (fav) {
      e.preventDefault();
      const id = fav.dataset.fav; const on = toggleFav(id);
      $$(`[data-fav="${CSS.escape(id)}"]`).forEach((b) => {
        b.classList.toggle('on', on); b.setAttribute('aria-pressed', on);
        b.setAttribute('aria-label', on ? 'Quitar de favoritos' : 'Guardar en favoritos');
        const t = b.querySelector('span'); if (t) t.textContent = on ? 'Guardado' : 'Guardar';
      });
      if (pintarAutos) pintarAutos();
      evento(on ? 'fav_agregar' : 'fav_quitar', id);
      toast(on ? 'Guardado en tus favoritos (en este dispositivo)' : 'Quitado de tus favoritos');
      return;
    }
    const cp = e.target.closest('[data-copiar]');
    if (cp) {
      const url = `${SITIO}/#/auto/${encodeURIComponent(cp.dataset.copiar)}`;
      const ok = () => toast('Enlace copiado');
      if (navigator.clipboard) navigator.clipboard.writeText(url).then(ok, () => window.prompt('Copia el enlace:', url));
      else window.prompt('Copia el enlace:', url);
      evento('compartir_copiar', cp.dataset.copiar);
      return;
    }
    const a = e.target.closest('a[href]'); if (!a) return;
    const href = a.getAttribute('href');
    const ev = a.dataset.ev || (/wa\.me\//.test(href) ? 'wa' : /instagram\.com/.test(href) ? 'instagram'
      : /^tel:/.test(href) ? 'llamar' : /google\.com\/maps/.test(href) ? 'google_opiniones' : '');
    if (ev) evento(ev, a.dataset.auto);
  });
  const nivelCls = ['ok', 'obs', 'fail'];
  const fechaISO = (ts) => (ts ? fecha(String(ts).slice(0, 10)) : '');

  const autoCard = (a) => `
    <div class="car-card-wrap">
    ${favBtn(a.id, 'fav--card')}
    <a class="car-card" href="#/auto/${esc(a.id)}">
      <div class="car-card__media">
        ${a.fotos && a.fotos[0] ? `<img src="${esc(a.fotos[0])}" alt="${esc(nombreAuto(a))}" loading="lazy">` : ''}
        <span class="seal">${ic('check')} Inspeccionado</span>
        ${a.puntaje != null ? `<span class="score" aria-label="Puntaje ${a.puntaje} de 100">${a.puntaje}<small>de 100</small></span>` : ''}
        ${(a.fotos && a.fotos.length > 1) || (a.videos || []).length ? `<span class="count">${a.fotos.length > 1 ? `${ic('camera')} ${a.fotos.length}` : ''}${(a.videos || []).length ? `${ic('video')} ${a.videos.length}` : ''}</span>` : ''}
      </div>
      <div class="car-card__body">
        <h3 class="car-card__title">${esc(nombreAuto(a))}</h3>
        <div class="car-card__specs">${[a.km != null ? km(a.km) : '', a.transmision, a.combustible].filter(Boolean).map((x) => esc(x)).join('<i>|</i>')}</div>
        ${a.comuna ? `<span class="car-card__loc">${ic('pin')} ${esc(a.comuna)}</span>` : ''}
        ${a.recomendacion ? `<div><span class="status status--${nivelCls[a.nivel] || 'ok'}">${esc(a.recomendacion)}</span></div>` : ''}
        <div class="car-card__foot">
          <span class="price">${a.precio ? clp(a.precio) : 'Consultar'}</span>
          <span class="btn btn--outline btn--sm">Ver detalles</span>
        </div>
      </div>
    </a>
    </div>`;

  function viewAutos() {
    return `
    <section class="page-hero">
      <div class="container">
        <div class="crumbs"><a href="#/">Inicio</a> / Autos en venta</div>
        <h1>Autos inspeccionados</h1>
        <p>Autos en venta que ya pasaron nuestra inspección precompra. Cada uno trae su puntaje, los puntos a considerar y la ficha de inspección para descargar.</p>
      </div>
    </section>
    <section class="section section--tight">
      <div class="container">
        <div class="mk-buscar--pagina">${buscador(filtroAutos())}</div>
        <div class="toolbar" id="autosBar" hidden>
          <span id="autosCount" style="color:var(--muted)"></span>
          <button type="button" class="chip" id="soloFavs" aria-pressed="false">${ic('heart')} Mis favoritos <b id="favsN"></b></button>
        </div>
        <div id="autos" class="grid grid--cars"><p style="color:var(--muted)">Cargando autos…</p></div>
        <div style="margin-top:36px">${avisameForm()}</div>
      </div>
    </section>`;
  }

  const sinAutos = () => `
    <div class="callout" style="grid-column:1/-1">
      <span class="ic">${ic('target')}</span>
      <div>
        <h3>Por ahora no hay autos publicados</h3>
        <p>Podemos buscar el auto por ti o inspeccionar el que ya encontraste. ¿Vas a vender el tuyo? Lo inspeccionamos y lo publicamos aquí con su informe.</p>
        <div style="display:flex;gap:10px;flex-wrap:wrap;margin-top:14px">
          <a class="btn btn--gold" href="#/busqueda">${ic('target')} Búsqueda personalizada</a>
          <a class="btn btn--outline" href="${waLink('Hola Atlas Motors, quiero vender mi auto con inspección.')}" target="_blank" rel="noopener">${ic('chat')} Quiero vender mi auto</a>
        </div>
      </div>
    </div>`;

  let pintarAutos = null; // vuelve a pintar el listado (al cambiar favoritos)
  async function bindAutos() {
    const box = $('#autos');
    bindBuscador();
    try {
      const todos = await cargarAutos();
      if (!document.body.contains(box)) return;
      const f = filtroAutos();
      const filtrando = !!(f.q || f.marca || f.comuna);
      const list = filtrando ? filtrar(todos, f) : todos;
      let soloFavs = false;
      const btn = $('#soloFavs');
      pintarAutos = () => {
        if (!document.body.contains(box)) return;
        const favs = leerFavs();
        const vis = soloFavs ? list.filter((a) => favs.includes(a.id)) : list;
        $('#favsN').textContent = favs.filter((id) => list.some((a) => a.id === id)).length || '';
        btn.classList.toggle('on', soloFavs); btn.setAttribute('aria-pressed', soloFavs);
        $('#autosCount').innerHTML = `${vis.length} ${vis.length === 1 ? 'auto' : 'autos'}${soloFavs ? ' guardados' : filtrando ? ` de ${todos.length} · <a href="#/autos" class="link-verde">Ver todos</a>` : ' publicados'}`;
        box.innerHTML = vis.length ? vis.map(autoCard).join('')
          : soloFavs ? `<div class="empty" style="grid-column:1/-1">Aún no guardas autos. Toca el ${ic('heart')} de un auto para tenerlo a mano aquí.</div>`
          : filtrando && todos.length ? `<div class="empty" style="grid-column:1/-1">No hay autos que calcen con tu búsqueda. <a href="#/autos" class="link-verde">Ver todos los autos</a> o <a href="#/busqueda" class="link-verde">pídenos que te lo busquemos</a>.</div>`
          : sinAutos();
      };
      $('#autosBar').hidden = !todos.length;
      btn.addEventListener('click', () => { soloFavs = !soloFavs; pintarAutos(); });
      pintarAutos();
    } catch (e) {
      if (document.body.contains(box)) box.innerHTML = `<div class="empty" style="grid-column:1/-1">No pudimos cargar los autos. Revisa tu conexión y vuelve a intentar.</div>`;
    }
  }

  function viewAutoShell() {
    return `<section class="section--tight" style="padding-top:28px"><div class="container" id="auto"><p style="color:var(--muted)">Cargando…</p></div></section>`;
  }

  // Mapa de daños de la carrocería: la app publica el dibujo ya hecho (trazos
  // SVG por pieza, según el tipo de vehículo). Aquí solo se valida y se pinta.
  const MAPA_ESTILOS = ['sombra', 'cuerpo', 'panel', 'vidrio', 'pilar', 'faro', 'piloto', 'parrilla', 'clara', 'llanta', 'rin', 'hueco', 'maza', 'arco', 'borde', 'manilla', 'placa', 'piso', 'linea'];
  const limpiarMapa = (m) => {
    if (!m || typeof m !== 'object' || !Array.isArray(m.p)) return null;
    const p = m.p.slice(0, 300).filter((x) => x && /^[MLCZ0-9 .\-]{1,6000}$/.test(String(x.d)) && MAPA_ESTILOS.includes(x.e))
      .map((x) => ({ d: String(x.d), e: x.e, z: /^[a-z_]{1,40}$/.test(String(x.z || '')) ? x.z : '', a: x.a === 1 }));
    const t = lista(m.t).slice(0, 30).map((x) => ({ t: txt((x || {}).t, 30), x: num(Math.round((x || {}).x), 0, 340), y: num(Math.round((x || {}).y), 0, 700), a: ['i', 'c', 'd'].includes((x || {}).a) ? x.a : 'i', s: num(Math.round((x || {}).s), 5, 12) || 8 }))
      .filter((x) => x.x != null && x.y != null);
    return p.length ? { p, t, h: num(Math.round(m.h), 300, 700) || 566 } : null;
  };
  function mapaDanos(mapa, danos) {
    const grav = {};
    danos.forEach((d) => { grav[d.zona] = Math.max(grav[d.zona] || 0, d.nivel); });
    const anc = { i: 'start', c: 'middle', d: 'end' };
    return `<svg class="mapa" viewBox="0 0 340 ${mapa.h}" role="img" aria-label="Mapa de daños de la carrocería">
      ${mapa.p.map((x) => `<path d="${x.d}" class="me me--${x.e}${x.a ? ' me--a' : ''}${x.z && grav[x.z] ? ' me--n' + grav[x.z] : ''}"/>`).join('')}
      ${mapa.t.map((x) => `<text x="${x.x}" y="${x.y + 3}" font-size="${x.s}" text-anchor="${anc[x.a]}" class="mz-t">${esc(x.t)}</text>`).join('')}
      ${danos.map((d, i) => d.x > 0 ? `<g class="mk mk--${d.nivel}"><circle cx="${d.x}" cy="${d.y}" r="9"/><text x="${d.x}" y="${d.y + 3.5}">${i + 1}</text></g>` : '').join('')}
    </svg>`;
  }

  function autoHtml(a) {
    const fotos = a.fotos || [];
    const c = a.conteo || {};
    const hs = a.hallazgos || [];
    const msg = `Hola Atlas Motors, me interesa el ${nombreAuto(a)}${a.precio ? ' de ' + clp(a.precio) : ''} publicado en atlasmotors.cl (ref. ${a.folio || a.id}).`;
    return `
      <div class="crumbs" style="color:var(--muted);margin-bottom:18px"><a href="#/">Inicio</a> / <a href="#/autos">Autos en venta</a> / ${esc(nombreAuto(a))}</div>
      <div class="detail">
        <div>
          ${fotos.length ? `
          <div class="gallery" id="gallery">
            <div id="galleryStage"></div>
            ${fotos.length > 1 ? `<div class="gallery__thumbs">${fotos.map((f, i) => `<button class="${i === 0 ? 'on' : ''}" data-i="${i}" aria-label="Foto ${i + 1}"><img src="${esc(f)}" alt="" loading="lazy"></button>`).join('')}</div>` : ''}
          </div>` : ''}

          ${(a.videos || []).length ? `
          <div class="panel" style="margin-top:20px">
            <h3>Videos</h3>
            <div class="videos">
              ${a.videos.map((v) => `<figure class="clip">
                <video controls playsinline preload="none"${v.poster ? ` poster="${esc(v.poster)}"` : ''} src="${esc(v.url)}"></video>
                ${v.nota ? `<figcaption>${esc(v.nota)}</figcaption>` : ''}
              </figure>`).join('')}
            </div>
          </div>` : ''}

          <div class="panel" style="margin-top:20px">
            <h3>Resultado de la inspección</h3>
            ${a.comentario ? `<p style="color:var(--muted)">${esc(a.comentario)}</p>` : ''}
            <div class="legend" style="margin:8px 0 14px">
              <span class="status status--ok">✓ ${c.bien || 0} en buen estado</span>
              <span class="status status--obs">! ${c.obs || 0} con observación</span>
              <span class="status status--fail">✕ ${c.problema || 0} con problema</span>
            </div>
            <h4 style="margin:0 0 10px">Puntos a considerar</h4>
            ${hs.length ? `<ul class="obs-list">${hs.map((h) => `<li><span class="dot dot--${nivelCls[h.nivel] || 'obs'}">!</span><span><b>${esc(h.punto)}</b>: ${esc(String(h.estado).toLowerCase())} <small style="color:var(--muted)">· ${esc(h.etapa)}</small>${h.corregido ? `<span class="corregido">✓ Corregido el ${esc(diaCorto(h.corregido.fecha))}${h.corregido.texto ? `: ${esc(h.corregido.texto)}` : ''}</span>` : ''}</span></li>`).join('')}</ul>`
              : `<p style="color:var(--muted);margin:0">El inspector no registró observaciones ni problemas.</p>`}
          </div>

          ${(a.actualizaciones || []).length ? `
          <div class="panel">
            <h3>Después de la inspección</h3>
            <p style="color:var(--muted);margin:0 0 12px">Trabajos hechos al auto después de inspeccionarlo. El resultado original de la inspección se mantiene.</p>
            <ul class="obs-list">${a.actualizaciones.map((u) => `<li><span class="dot dot--ok">✓</span><span><b>${esc(diaCorto(u.fecha))}</b>${u.punto ? ` · ${esc(u.punto)}` : ''}: ${esc(u.texto)}${u.respaldo ? ' <small style="color:var(--muted)">· con boleta revisada por Atlas Motors</small>' : ''}</span></li>`).join('')}</ul>
          </div>` : ''}

          ${a.tieneMapa && (a.mapa || a.danos.length) ? `
          <div class="panel">
            <h3>Estado de la carrocería</h3>
            <div class="mapa-wrap${a.mapa ? '' : ' mapa-wrap--sin'}">
              ${a.mapa ? mapaDanos(a.mapa, a.danos) : ''}
              <div>
                ${a.danos.length ? `<p style="color:var(--muted);margin:0 0 12px">Revisamos el auto pieza por pieza. Estos son los detalles que encontramos, marcados con su número en el dibujo:</p>
                <ol class="mapa-lista">${a.danos.map((d, i) => `<li><span class="mk-n mk-n--${d.nivel}">${i + 1}</span><span><b>${esc(d.pieza)}</b>: ${esc(String(d.tipo).toLowerCase())} <small style="color:var(--muted)">· ${d.nivel === 2 ? 'importante' : 'detalle'}</small></span></li>`).join('')}</ol>`
                : `<p style="margin:0"><b style="color:var(--accent-text)">Sin daños en la carrocería.</b></p><p style="color:var(--muted);margin:6px 0 0">Revisamos el auto pieza por pieza y no encontramos golpes, rayones ni repintados.</p>`}
              </div>
            </div>
          </div>` : ''}
          ${(a.etapas || []).length ? `
          <div class="panel">
            <h3>Revisión por etapa</h3>
            <div class="cat-grid">
              ${a.etapas.map((e) => { const st = e.problema ? 'b' : e.obs ? 'w' : ''; const t = e.problema ? `${e.problema} con problema` : e.obs ? `${e.obs} con observación` : 'Sin observaciones'; return `<div class="cat">${esc(e.titulo)}<em class="${st}">${t}</em></div>`; }).join('')}
            </div>
          </div>` : ''}

          ${a.descripcion ? `<div class="panel"><h3>Descripción del vendedor</h3><p style="color:var(--muted);margin:0;white-space:pre-line">${esc(a.descripcion)}</p></div>` : ''}
          <div class="detail__avisame" style="margin-top:20px">${avisameForm({ que: [a.marca, a.modelo].filter(Boolean).join(' '), precio: a.precio, titulo: '¿No es exactamente lo que buscas?' })}</div>
        </div>

        <aside>
          <div class="panel">
            <span class="pill">${ic('shield')} Inspeccionado por Atlas Motors</span>
            <h1>${esc(nombreAuto(a))}</h1>
            <div class="price">${a.precio ? clp(a.precio) : 'Precio a consultar'}</div>
            ${a.comuna ? `<small style="color:var(--muted)">${ic('pin')} ${esc(a.comuna)}</small>` : ''}
            <div class="specs">
              ${a.km != null ? `<div class="spec">${ic('gauge')}<div><small>Kilometraje</small><b>${km(a.km)}</b></div></div>` : ''}
              ${a.anio ? `<div class="spec">${ic('calendar')}<div><small>Año</small><b>${esc(a.anio)}</b></div></div>` : ''}
              ${a.transmision ? `<div class="spec">${ic('gear')}<div><small>Transmisión</small><b>${esc(a.transmision)}</b></div></div>` : ''}
              ${a.combustible ? `<div class="spec">${ic('fuel')}<div><small>Combustible</small><b>${esc(a.combustible)}</b></div></div>` : ''}
            </div>
            <div class="contact-actions">
              <a class="btn btn--green btn--block btn--lg" href="${waLink(msg)}" target="_blank" rel="noopener" data-ev="wa_auto" data-auto="${esc(a.id)}">${ic('chat')} Me interesa: escribir por WhatsApp</a>
            </div>
            <div class="share-row">
              ${favBtn(a.id, 'share-row__btn')}
              <a class="share-row__btn" href="https://wa.me/?text=${encodeURIComponent(textoCompartir(a))}" target="_blank" rel="noopener" data-ev="compartir_wa" data-auto="${esc(a.id)}">${ic('chat')}<span>Enviar a alguien</span></a>
              <button type="button" class="share-row__btn" data-copiar="${esc(a.id)}">${ic('link')}<span>Copiar enlace</span></button>
            </div>
            <div class="verified">
              ${a.puntaje != null ? `<div class="ring" style="--v:${a.puntaje}"><div>${a.puntaje}<small>de 100</small></div></div>` : '<span></span>'}
              <div><h3>${esc(a.recomendacion || 'Ficha de inspección')}</h3><p>Inspección realizada el ${fechaISO(a.fechaInspeccion)}: carrocería, motor, parte baja, interior, escáner y prueba de ruta.</p></div>
              ${a.ficha ? `<a class="btn btn--gold" href="${esc(a.ficha)}" target="_blank" rel="noopener" data-ev="ficha" data-auto="${esc(a.id)}">${ic('download')} Descargar ficha de inspección</a>` : ''}
            </div>
            <p style="color:var(--muted);font-size:12.5px;margin:14px 0 0">El precio y la descripción son del vendedor. La ficha refleja el estado del auto el día de la inspección.</p>
          </div>
        </aside>
      </div>`;
  }

  async function bindAuto(id) {
    const box = $('#auto');
    let a;
    try {
      a = (await cargarAutos()).find((x) => x.id === id);
    } catch (e) {
      if (document.body.contains(box)) box.innerHTML = `<div class="empty">No pudimos cargar el auto. Revisa tu conexión y vuelve a intentar.</div>`;
      return;
    }
    if (!document.body.contains(box)) return;
    if (!a) { box.innerHTML = `<div class="empty">Este auto ya no está publicado. <a href="#/autos">Ver otros autos</a></div>`; return; }
    document.title = `${nombreAuto(a)} en venta · Atlas Motors`;
    box.innerHTML = autoHtml(a);
    const fotos = a.fotos || [];
    if (!fotos.length) return;
    let idx = 0;
    const stage = $('#galleryStage');
    const draw = () => {
      $$('.gallery__thumbs button[data-i]').forEach((b) => b.classList.toggle('on', +b.dataset.i === idx));
      stage.innerHTML = `<div class="gallery__main"><img src="${esc(fotos[idx])}" alt="${esc(nombreAuto(a))}, foto ${idx + 1}">
        <span class="seal">${ic('check')} Inspeccionado</span>
        ${fotos.length > 1 ? `<button class="gallery__nav gallery__nav--prev" data-nav="-1" aria-label="Anterior">${ic('left')}</button>
        <button class="gallery__nav gallery__nav--next" data-nav="1" aria-label="Siguiente">${ic('right')}</button>` : ''}</div>`;
    };
    $('#gallery').addEventListener('click', (e) => {
      const th = e.target.closest('[data-i]'); if (th) { idx = +th.dataset.i; draw(); return; }
      const n = e.target.closest('[data-nav]'); if (n) { idx = (idx + +n.dataset.nav + fotos.length) % fotos.length; draw(); }
    });
    draw();
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
          <h2 class="display" style="font-size:clamp(26px,3.4vw,38px);color:#fff;margin-top:10px">Una revisión profesional antes de que pongas tu plata</h2>
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
        <div class="stat"><b>${clp(ABONO)}</b><span>abono para reservar</span></div>
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
          <h2 class="display" style="font-size:clamp(26px,3.4vw,38px);color:#fff;margin-top:10px">¿No puedes estar presente? Igual lo ves todo</h2>
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
        <div class="section__head" style="justify-content:center;text-align:center"><div><span class="eyebrow">Valores</span><h2>Inspección completa</h2><p style="margin-inline:auto">Reservas tu hora con un abono de ${clp(ABONO)} por transferencia y pagas el resto el día de la inspección.</p></div></div>
        <div class="plans" style="grid-template-columns:minmax(0,1fr);max-width:480px;margin-inline:auto">
          ${PLANES.map((p) => `
            <div class="plan ${p.destacado ? 'featured' : ''}">
              
              <h3>${p.nombre}</h3>
              <div class="amount">${clp(p.precio)} <small>CLP</small></div>
              <p>${p.desc} Reserva con ${clp(ABONO)}.</p>
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
          <div><h2>Agenda en 2 minutos</h2><p>Elige una hora libre, cuéntanos del auto y queda reservada para ti.</p></div>
          <a href="#/agendar" class="btn btn--gold btn--lg">${ic('calendar')} Agendar aquí</a>
        </div>
      </div>
    </section>`;
  }

  /* -------- Agenda: horas libres en línea; la reserva la toma la función `reservar` -------- */
  const booking = { step: 0, date: null, time: null, data: { presente: 'si', donde: 'Particular' }, month: null, enviando: false, error: '', reserva: null };
  const COMUNAS = ['La Serena', 'Coquimbo', 'Otra comuna'];
  const STEPS = ['Fecha y hora', 'Vehículo y datos', 'Reservar'];
  // Mismo horario que la app y la función (functions/reservas/horario.js): lunes a
  // sábado, 45 min de inspección + 45 min de traslado desde las 9:00.
  const SLOTS = ['09:00', '10:30', '12:00', '13:30', '15:00', '16:30', '18:00', '19:30'];
  const RESERVAR_URL = 'https://southamerica-west1-atlas-motors-cl.cloudfunctions.net/reservar';
  const AGENDA_URL = 'https://firestore.googleapis.com/v1/projects/atlas-motors-cl/databases/(default)/documents/agenda/';
  // reCAPTCHA invisible: se carga solo en la página de agendar, al reservar.
  const RECAPTCHA_KEY = '6LeLKC8uAAAAAEXTe0UrVrqC2r41401yk-j4vzrn';
  let captchaListo = null;
  const cargarCaptcha = () => {
    if (!RECAPTCHA_KEY) return Promise.resolve(null);
    if (!captchaListo) {
      captchaListo = new Promise((ok, mal) => {
        const sc = document.createElement('script');
        sc.src = `https://www.google.com/recaptcha/enterprise.js?render=${RECAPTCHA_KEY}`;
        sc.async = true; sc.onload = () => window.grecaptcha.enterprise.ready(ok); sc.onerror = mal;
        document.head.appendChild(sc);
      }).catch(() => { captchaListo = null; });
    }
    return captchaListo;
  };
  const tokenCaptcha = async () => {
    if (!RECAPTCHA_KEY) return '';
    try { await cargarCaptcha(); return await window.grecaptcha.enterprise.execute(RECAPTCHA_KEY, { action: 'reservar' }); } catch (e) { return ''; }
  };
  const iso = (d) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
  const diaLargo = (isoDate) => new Date(isoDate + 'T12:00:00').toLocaleDateString('es-CL', { weekday: 'long', day: 'numeric', month: 'long' });

  // Hora de Chile, para no ofrecer horas que ya pasaron aunque el visitante esté en otro huso.
  const chileFmt = new Intl.DateTimeFormat('en-CA', { timeZone: 'America/Santiago', year: 'numeric', month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit', hour12: false });
  const enChile = (ms) => { const p = Object.fromEntries(chileFmt.formatToParts(new Date(ms)).map((x) => [x.type, x.value])); return Date.UTC(+p.year, +p.month - 1, +p.day, +p.hour % 24, +p.minute); };
  const inicioHora = (fecha, hora) => {
    const [y, m, d] = fecha.split('-').map(Number); const [h, mi] = hora.split(':').map(Number);
    const supuesto = Date.UTC(y, m - 1, d, h, mi);
    return supuesto - (enChile(supuesto) - supuesto);
  };

  // agenda/{AAAA-MM}: qué horas están tomadas (sin datos de clientes).
  const agenda = {};
  const cargarMes = (mes) => {
    if (agenda[mes]) return agenda[mes].promesa;
    const e = agenda[mes] = { h: null };
    e.promesa = fetch(`${AGENDA_URL}${mes}?key=${FS_KEY}`)
      .then((r) => (r.status === 404 ? {} : r.ok ? r.json() : Promise.reject(r.status)))
      .then((doc) => { const f = doc.fields && doc.fields.h ? fsVal(doc.fields.h) : {}; e.h = f && typeof f === 'object' ? f : {}; })
      .catch(() => { e.h = {}; e.fallo = true; });
    return e.promesa;
  };
  const tomada = (fecha, hora) => {
    const c = agenda[fecha.slice(0, 7)]?.h?.[fecha]?.[hora];
    if (!c || typeof c !== 'object') return false;
    if (c.e === 'p') return typeof c.v === 'number' && c.v > Date.now();
    return c.e === 'c' || c.e === 'b';
  };
  const libre = (fecha, hora) => inicioHora(fecha, hora) - Date.now() >= 2 * 3600e3 && !tomada(fecha, hora);
  const mesCargado = (fecha) => !!agenda[fecha.slice(0, 7)]?.h;

  const mensajeReserva = () => {
    const d = booking.data; const r = booking.reserva;
    return [
      r ? `Hola Atlas Motors, reservé una inspección en la web (código ${r.codigo}). ¿Me envían los datos para transferir el abono?` : 'Hola Atlas Motors, quiero agendar una inspección precompra.',
      '',
      `Vehículo: ${d.vehiculo}`,
      `${r ? 'Día y hora' : 'Día y hora que prefiero'}: ${diaLargo(booking.date)}, ${booking.time}`,
      `Lugar: ${[d.direccion, d.comuna].filter(Boolean).join(', ')}`,
      r ? '' : `Vendedor: ${d.donde}`,
      r ? '' : `Modalidad: ${d.presente === 'no' ? 'remota (no estaré presente)' : 'presencial'}`,
      !r && d.link ? `Publicación: ${d.link}` : '',
      !r && d.nota ? `Comentarios: ${d.nota}` : '',
      '',
      `Nombre: ${d.nombre}`,
      r ? '' : `Teléfono: ${d.telefono}`,
    ].filter((l, i, a) => l !== '' || a[i - 1] !== '').join('\n').trim();
  };

  function viewAgendar() {
    return `
    <section class="page-hero" style="padding:44px 0 50px">
      <div class="container">
        <div class="crumbs"><a href="#/">Inicio</a> / <a href="#/inspeccion">Inspección precompra</a> / Agendar</div>
        <h1>Agenda tu inspección</h1>
        <p>Elige un día y una hora libre, cuéntanos del auto y la hora queda reservada para ti. La confirmas con un abono de ${clp(ABONO)}. Si no puedes estar presente, la hacemos en modalidad remota.</p>
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
    if (booking.reserva) { booking.reserva = null; booking.step = 0; booking.date = null; booking.time = null; }
    const plan = PLANES[0];
    const canNext = () => [booking.date && booking.time && libre(booking.date, booking.time), ['nombre', 'telefono', 'vehiculo', 'comuna'].every((k) => (booking.data[k] || '').trim()), true][booking.step];
    const mesDe = (d) => iso(d).slice(0, 7);
    const cargarVisibles = () => {
      const m = booking.month;
      Promise.all([cargarMes(mesDe(m)), cargarMes(mesDe(new Date(m.getFullYear(), m.getMonth() + 1, 1)))]).then(() => { if (document.body.contains(root)) draw(); });
    };

    const stepBody = () => {
      if (booking.reserva) {
        const r = booking.reserva;
        const hasta = new Date(r.vence).toLocaleTimeString('es-CL', { timeZone: 'America/Santiago', hour: '2-digit', minute: '2-digit', hour12: false });
        return `
          <h3>¡Tu hora quedó reservada!</h3>
          <p style="font-size:17px;margin:6px 0 0"><b>${diaLargo(booking.date)}, ${booking.time}</b> · código <b>${esc(r.codigo)}</b></p>
          <div class="remote-steps" style="margin-top:18px">
            <div class="remote-step"><span class="ic">${ic('card')}</span><div><b>Transfiere el abono de ${clp(ABONO)}</b><p>Escríbenos ahora por WhatsApp y te mandamos los datos de la cuenta empresa. Te guardamos la hora hasta las ${esc(hasta)}: si el abono no llega en esa hora, la reserva se cancela sola.</p></div></div>
            <div class="remote-step"><span class="ic">${ic('check')}</span><div><b>Te confirmamos</b><p>Apenas veamos la transferencia, la inspección queda confirmada. El saldo de ${clp(plan.precio - ABONO)} se paga el día de la inspección.</p></div></div>
          </div>
          <p style="margin:16px 0 0;font-size:13.5px;color:var(--muted)">${ABONO_POLITICA}</p>`;
      }
      if (booking.step === 0) {
        const m = booking.month; const first = (m.getDay() + 6) % 7; const days = new Date(m.getFullYear(), m.getMonth() + 1, 0).getDate();
        const label = m.toLocaleDateString('es-CL', { month: 'long', year: 'numeric' });
        const max = new Date(today); max.setDate(max.getDate() + 60);
        let cells = ['L', 'M', 'M', 'J', 'V', 'S', 'D'].map((d) => `<span class="dow">${d}</span>`).join('');
        cells += '<span></span>'.repeat(first);
        for (let d = 1; d <= days; d++) {
          const dt = new Date(m.getFullYear(), m.getMonth(), d); const f = iso(dt);
          const lleno = mesCargado(f) && !SLOTS.some((s) => libre(f, s));
          const dis = dt < today || dt.getDay() === 0 || dt > max || lleno;
          cells += `<button type="button" data-date="${f}" ${dis ? 'disabled' : ''} class="${booking.date === f ? 'on' : ''} ${+dt === +today ? 'today' : ''}" ${lleno && !(dt < today) ? 'title="Sin horas libres"' : ''}>${d}</button>`;
        }
        let horas = '<p style="margin:16px 0 0;color:var(--muted)">Selecciona un día. Atendemos de lunes a sábado, de 9:00 a 20:15.</p>';
        if (booking.date) {
          horas = mesCargado(booking.date)
            ? `<p style="margin:18px 0 0;font-weight:600">Horas libres el ${diaLargo(booking.date)}</p>
              <div class="slots">${SLOTS.map((s) => { const ok = libre(booking.date, s); return `<button type="button" class="slot ${booking.time === s ? 'on' : ''}" data-time="${s}" ${ok ? '' : 'disabled'} aria-label="${s}${ok ? '' : ', no disponible'}">${s}</button>`; }).join('')}</div>
              <p style="margin:12px 0 0;font-size:13px;color:var(--muted)">Cada inspección dura unos 45 minutos. Al reservar, la hora queda guardada para ti por 1 hora mientras transfieres el abono.</p>`
            : '<p style="margin:18px 0 0;color:var(--muted)">Cargando las horas libres…</p>';
        }
        return `
          <h3>¿Qué día y hora te acomodan?</h3>
          <div class="cal">
            <div class="cal__head"><button type="button" data-month="-1" aria-label="Mes anterior">${ic('left')}</button><b>${label}</b><button type="button" data-month="1" aria-label="Mes siguiente">${ic('right')}</button></div>
            <div class="cal__grid">${cells}</div>
          </div>
          ${horas}`;
      }
      if (booking.step === 1) {
        const d = booking.data; const v = (k) => esc(d[k] || '');
        return `
          <h3>El vehículo y tus datos</h3>
          <div class="form-grid" id="dataForm">
            <div class="field full"><label for="b-veh">Vehículo a inspeccionar *</label><input class="input" id="b-veh" data-k="vehiculo" value="${v('vehiculo')}" maxlength="120" placeholder="Marca, modelo y año. Ej: Toyota Hilux 2021"></div>
            <div class="field"><label for="b-donde">¿Quién lo vende?</label><select class="select" id="b-donde" data-k="donde">${['Particular', 'Automotora'].map((o) => `<option ${d.donde === o ? 'selected' : ''}>${o}</option>`).join('')}</select></div>
            <div class="field"><label for="b-com">Comuna *</label><select class="select" id="b-com" data-k="comuna"><option value="">Selecciona</option>${COMUNAS.map((c) => `<option ${d.comuna === c ? 'selected' : ''}>${c}</option>`).join('')}</select></div>
            <div class="field full"><label for="b-dir">Dirección donde está el auto</label><input class="input" id="b-dir" data-k="direccion" value="${v('direccion')}" maxlength="200" placeholder="Si aún no la tienes, la coordinamos por WhatsApp"></div>
            <div class="field full"><label for="b-pres">¿Estarás presente en la inspección?</label><select class="select" id="b-pres" data-k="presente"><option value="si" ${d.presente !== 'no' ? 'selected' : ''}>Sí, voy a estar</option><option value="no" ${d.presente === 'no' ? 'selected' : ''}>No, prefiero la inspección remota</option></select></div>
            <div class="field"><label for="b-nombre">Tu nombre *</label><input class="input" id="b-nombre" data-k="nombre" value="${v('nombre')}" maxlength="80" autocomplete="name"></div>
            <div class="field"><label for="b-tel">Tu teléfono *</label><input class="input" id="b-tel" data-k="telefono" value="${v('telefono')}" maxlength="30" inputmode="tel" placeholder="+56 9 …" autocomplete="tel"></div>
            <div class="field full"><label for="b-link">Link de la publicación (opcional)</label><input class="input" id="b-link" data-k="link" value="${v('link')}" maxlength="500" placeholder="Yapo, Chileautos, Marketplace…"></div>
            <div class="field full"><label for="b-nota">Comentarios (opcional)</label><textarea class="textarea" id="b-nota" data-k="nota" maxlength="1000" placeholder="Ej: el vendedor solo puede después de las 14:00">${v('nota')}</textarea></div>
            <input type="text" data-k="web" name="web" tabindex="-1" autocomplete="off" aria-hidden="true" style="position:absolute;left:-9999px;width:1px;height:1px;opacity:0">
          </div>`;
      }
      return `
        <h3>Reserva tu hora</h3>
        <p style="color:var(--muted)">Al tocar "Reservar hora", el ${diaLargo(booking.date)} a las ${booking.time} queda guardado para ti y le avisamos a nuestro inspector.</p>
        <div class="remote-steps" style="margin-top:16px">
          <div class="remote-step"><span class="ic">${ic('calendar')}</span><div><b>1. Reservas la hora</b><p>La guardamos por 1 hora para que alcances a transferir.</p></div></div>
          <div class="remote-step"><span class="ic">${ic('card')}</span><div><b>2. Transfieres el abono de ${clp(ABONO)}</b><p>El resto lo pagas el día de la inspección. Te mandamos los datos de la cuenta empresa por WhatsApp. Si avisas con 24 horas, cambiamos la fecha o te lo devolvemos.</p></div></div>
          <div class="remote-step"><span class="ic">${ic('check')}</span><div><b>3. Inspeccionamos</b><p>El saldo de ${clp(plan.precio - ABONO)} se paga el día de la inspección.</p></div></div>
        </div>
        ${booking.error ? `<p class="booking-error" role="alert">${esc(booking.error)} <a href="${waLink(mensajeReserva())}" target="_blank" rel="noopener">Escríbenos por WhatsApp</a>.</p>` : ''}`;
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
          <div class="total"><span>Abono para confirmar</span><span>${clp(ABONO)}</span></div>
          ${d.comuna === 'Otra comuna' ? '<p style="margin:14px 0 0;font-size:13px;color:var(--muted)">Para otras comunas te confirmamos el traslado por WhatsApp.</p>' : ''}
        </aside>`;
    };

    const nav = () => {
      if (booking.reserva) return `<span></span><a class="btn btn--gold" href="${waLink(mensajeReserva())}" target="_blank" rel="noopener">${ic('chat')} Pedir datos para el abono</a>`;
      const atras = booking.step > 0 ? `<button type="button" class="btn btn--outline" data-go="-1" ${booking.enviando ? 'disabled' : ''}>${ic('left')} Atrás</button>` : '<span></span>';
      if (booking.step === 2) return `${atras}<button type="button" class="btn btn--gold" data-action="reservar" data-ev="agendar_enviado" ${booking.enviando ? 'disabled' : ''}>${ic('calendar')} ${booking.enviando ? 'Reservando…' : 'Reservar hora'}</button>`;
      return `${atras}<button type="button" class="btn btn--gold" data-go="1" ${canNext() ? '' : 'disabled'}>Continuar ${ic('arrow')}</button>`;
    };

    const draw = () => {
      root.innerHTML = `
        <div class="booking">
          <div class="panel">
            <div class="stepper">${STEPS.map((s, i) => `<div class="${i <= booking.step ? 'on' : ''}">${i + 1}. ${s}</div>`).join('')}</div>
            ${stepBody()}
            <div class="wizard-nav">${nav()}</div>
            ${booking.step === 2 && !booking.reserva ? `<p style="font-size:12.5px;color:var(--muted);margin:14px 0 0;text-align:right">Tus datos se usan solo para coordinar la inspección. <a href="#/privacidad" style="text-decoration:underline">Política de privacidad</a>.${RECAPTCHA_KEY ? ' Protegido por reCAPTCHA: se aplican la <a href="https://policies.google.com/privacy" target="_blank" rel="noopener" style="text-decoration:underline">privacidad</a> y las <a href="https://policies.google.com/terms" target="_blank" rel="noopener" style="text-decoration:underline">condiciones</a> de Google.' : ''}</p>` : ''}
          </div>
          ${summary()}
        </div>`;
    };

    const reservar = async () => {
      booking.enviando = true; booking.error = ''; draw();
      try {
        const r = await fetch(RESERVAR_URL, {
          method: 'POST', headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ ...booking.data, fecha: booking.date, hora: booking.time, captcha: await tokenCaptcha() }),
        });
        const j = await r.json().catch(() => ({}));
        if (!r.ok || !j.ok) {
          booking.error = j.error || 'No pudimos guardar tu reserva.';
          if (/tomar|pasó|pronto/.test(booking.error)) {
            // La hora ya no está: recarga la agenda y vuelve a elegir.
            delete agenda[booking.date.slice(0, 7)]; booking.time = null; booking.step = 0; cargarVisibles();
          }
        } else {
          booking.reserva = { codigo: j.codigo, vence: j.vence };
          delete agenda[booking.date.slice(0, 7)];
        }
      } catch (e) {
        booking.error = 'No hay conexión o el sistema de reservas no responde.';
      }
      booking.enviando = false; draw();
      root.scrollIntoView({ behavior: 'smooth', block: 'start' });
    };

    root.addEventListener('click', (e) => {
      const t = e.target;
      const mo = t.closest('[data-month]'); if (mo) {
        const n = new Date(booking.month.getFullYear(), booking.month.getMonth() + +mo.dataset.month, 1);
        if (n >= new Date(today.getFullYear(), today.getMonth(), 1) && n <= new Date(today.getFullYear(), today.getMonth() + 2, 1)) booking.month = n;
        cargarVisibles();
        return draw();
      }
      const dt = t.closest('[data-date]'); if (dt) { booking.date = dt.dataset.date; booking.time = null; booking.error = ''; return draw(); }
      const tm = t.closest('[data-time]'); if (tm) { booking.time = tm.dataset.time; return draw(); }
      if (t.closest('[data-action="reservar"]')) { if (!booking.enviando) reservar(); return; }
      const go = t.closest('[data-go]'); if (go) {
        booking.step = Math.min(2, Math.max(0, booking.step + +go.dataset.go)); booking.error = ''; draw();
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
    cargarVisibles();
    cargarCaptcha();
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
          <div class="mascot-side">
            <img src="assets/img/aguila.png" alt="" loading="lazy" width="403" height="640">
            <span class="bubble">¡Yo te lo encuentro! 🦅</span>
          </div>
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
          <p style="font-size:12.5px;color:var(--muted);margin:10px 0 0;text-align:center">Se abre WhatsApp con tu solicitud. Sin costo ni compromiso. <a href="#/privacidad" style="text-decoration:underline">Cómo usamos tus datos</a>.</p>
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
      sumar(['busqueda_enviada']);
      window.open(link, '_blank', 'noopener');
      const nombre = esc(fd.nombre.trim().split(' ')[0]);
      f.innerHTML = `
        <div class="success" style="padding:20px 6px">
          <div class="check">${ic('check')}</div>
          <h2 class="display" style="color:#fff">¡Gracias, ${nombre}!</h2>
          <p style="color:var(--muted)">Abrimos WhatsApp con tu solicitud. Envía el mensaje y te contactamos para partir la búsqueda.</p>
          <a class="btn btn--gold" style="margin-top:12px" href="${link}" target="_blank" rel="noopener">${ic('chat')} Abrir WhatsApp de nuevo</a>
        </div>`;
      f.scrollIntoView({ behavior: 'smooth', block: 'center' });
    });
  }

  /* ---------------- política de privacidad ---------------- */
  // Fuente: docs/politica-privacidad.md (mantener ambos textos iguales).
  const PRIVACIDAD_FECHA = '23 de noviembre de 2026';
  function viewPrivacidad() {
    const correo = '<a href="mailto:servicios.atlasmotors@gmail.com">servicios.atlasmotors@gmail.com</a>';
    return `
    <section class="page-hero">
      <div class="container">
        <div class="crumbs"><a href="#/">Inicio</a> / Política de privacidad</div>
        <h1>Política de privacidad</h1>
        <p>Qué datos tratamos, para qué y cómo puedes ejercer tus derechos. Última actualización: ${PRIVACIDAD_FECHA}.</p>
      </div>
    </section>
    <section class="section section--tight">
      <div class="container legal">
        <h2>1. Quiénes somos</h2>
        <p>Atlas Motors Chile SpA (RUT 78.422.947-5, domicilio en Pasaje O’Higgins 2470A, La Serena, Región de Coquimbo) es responsable del tratamiento de los datos personales que se describen en esta política.</p>
        <p>Contacto para temas de privacidad: ${correo}, WhatsApp <a href="${waLink()}" target="_blank" rel="noopener">${TEL}</a>.</p>

        <h2>2. Qué datos tratamos y para qué</h2>
        <p><b>Si agendas una inspección.</b> Guardamos el día y la hora que reservas, tu nombre, teléfono, comuna, la dirección y los datos del auto que nos das, y los comentarios que escribas. Los usamos para coordinar y prestar la inspección, y solo los ve el equipo de Atlas Motors. En la agenda pública del sitio solo se ve que la hora está ocupada, nunca quién la reservó. Para evitar abusos, contamos cuántas reservas se hacen desde una misma conexión al día sin guardar tu dirección IP, y al reservar usamos reCAPTCHA de Google, que revisa señales del navegador para distinguir personas de programas automáticos.</p>
        <p><b>Si pides una búsqueda.</b> El sitio web no guarda tus datos: el formulario arma un mensaje que tú envías por WhatsApp. Con ese mensaje recibimos tu nombre, teléfono, comuna y lo que buscas, y los usamos para prestar el servicio.</p>
        <p><b>Si inspeccionamos un auto para ti.</b> Registramos tu nombre y teléfono, los datos del vehículo (marca, modelo, año, patente y kilometraje), el lugar de la inspección, el resultado del checklist, comentarios, fotos y videos cortos del vehículo (con sonido, para registrar ruidos o fugas). Los usamos para hacer la inspección, preparar el informe y enviártelo, y para responder consultas o reclamos sobre el servicio.</p>
        <p><b>Si publicas tu auto en nuestro sitio.</b> Publicamos solo los datos del vehículo, el precio, la comuna, las fotos y videos que elijas y el resumen de la inspección. <b>No publicamos tu nombre, teléfono ni la patente.</b> Los interesados nos escriben a nosotros. Solo publicamos con tu autorización y puedes pedir que lo quitemos en cualquier momento.</p>
        <p><b>Si visitas atlasmotors.cl.</b> No usamos cookies ni herramientas de seguimiento de terceros. Para saber qué le sirve a la gente, contamos de forma anónima las visitas y algunos clics (por ejemplo, cuántas personas tocan WhatsApp o guardan un auto): solo sumamos totales por día, sin guardar tu IP ni nada que te identifique. Tu navegador guarda la fecha de tu primera y última visita (para distinguir visitas nuevas de las que vuelven) y los autos que marques como favoritos; eso queda solo en tu dispositivo y lo puedes borrar limpiando los datos del sitio. Nuestros proveedores de alojamiento (GitHub y Google) pueden registrar datos técnicos de la visita, como la dirección IP, para operar y proteger el servicio.</p>

        <h2>3. Base para tratar tus datos</h2>
        <p>Tratamos tus datos porque son necesarios para prestar el servicio que nos pides y, en el caso de la publicación de tu auto, porque nos das tu consentimiento. También podemos tratarlos para cumplir obligaciones legales, como las tributarias, y por nuestro interés legítimo en proteger la seguridad de nuestros sistemas y prevenir fraudes.</p>

        <h2>4. Con quién compartimos tus datos</h2>
        <p>No vendemos tus datos. Los compartimos solo con proveedores que nos ayudan a operar y que los tratan por encargo nuestro:</p>
        <ul>
          <li><b>Google (Firebase / Google Cloud):</b> almacenamiento de reservas, inspecciones, fotos y videos. Los servidores están en Chile (Santiago) y en Estados Unidos.</li>
          <li><b>GitHub:</b> alojamiento del sitio web (no recibe datos de clientes).</li>
          <li><b>WhatsApp (Meta):</b> comunicación contigo, cuando tú nos escribes.</li>
        </ul>
        <p>Algunos de estos proveedores están fuera de Chile. Trabajamos solo con proveedores que ofrecen garantías adecuadas de protección de datos, conforme a la ley.</p>

        <h2>5. Cuánto tiempo guardamos los datos</h2>
        <p>Las reservas que no llegan a hacerse (sin abono o canceladas) las eliminamos dentro de 30 días. Guardamos los datos de las inspecciones por 2 años desde la inspección, para responder consultas o reclamos sobre el servicio, y luego los eliminamos. Las publicaciones de autos se eliminan cuando el auto se vende o cuando lo pides. Los respaldos de seguridad se borran automáticamente a las 8 semanas.</p>

        <h2>6. Cómo protegemos tus datos</h2>
        <p>Solo el equipo autorizado de Atlas Motors accede a los datos de clientes, con usuario y clave. Las conexiones son cifradas, aplicamos reglas de acceso en la base de datos y hacemos respaldos periódicos.</p>

        <h2>7. Tus derechos</h2>
        <p>Puedes pedirnos en cualquier momento <b>acceder</b> a tus datos, <b>rectificarlos</b>, <b>suprimirlos</b>, <b>oponerte</b> a su tratamiento, pedir su <b>portabilidad</b> o el <b>bloqueo</b> temporal, y retirar tu consentimiento para la publicación de tu auto. Escríbenos a ${correo} o por WhatsApp y te responderemos en un plazo de 30 días corridos. Si no quedas conforme, puedes recurrir a la Agencia de Protección de Datos Personales.</p>

        <h2>8. Cambios a esta política</h2>
        <p>Si cambiamos esta política, publicaremos la nueva versión en esta página con su fecha de actualización.</p>
      </div>
    </section>`;
  }

  function viewNotFound() {
    return `<section class="section"><div class="container" style="text-align:center"><h1 class="display">Página no encontrada</h1><p>El vehículo o la página que buscas no existe.</p><a class="btn btn--gold" href="#/">Volver al inicio</a></div></section>`;
  }

  /* Águila del inicio: cambia lo que dice cada tanto y al tocarla abre la ayuda */
  function bindAguila() {
    const eagle = $('.eagle'); if (!eagle) return;
    const say = eagle.querySelector('.eagle__say');
    const frases = ['¿Te ayudo?', '¿Buscas auto?', '¡Lo reviso por ti!', '¿Agendamos?'];
    let n = 0;
    const t = setInterval(() => {
      if (!document.body.contains(eagle)) return clearInterval(t);
      n = (n + 1) % frases.length;
      say.textContent = frases[n];
      say.classList.remove('cambia'); void say.offsetWidth; say.classList.add('cambia');
    }, 4000);
    eagle.addEventListener('click', () => { const b = $('#helper .helper__btn'); if (b && !$('#helper .helper__panel')) b.click(); });
  }

  /* ---------------- ayudante flotante (mascota) ---------------- */
  function mountHelper() {
    const h = $('#helper'); let open = false;
    // Hasta que la persona abre la ayuda, el círculo late para llamar la atención.
    const usado = () => !!sessionStorageSafe('hint');
    const draw = () => {
      h.classList.toggle('helper--llama', !open && !usado());
      h.innerHTML = `
        ${open ? `<div class="helper__panel">
          <header><img src="assets/img/aguila-cara.png" alt=""><div><b>¿Te ayudo?</b><small>El ojo de águila de Atlas Motors</small></div></header>
          <div class="opts">
            <a href="#/agendar">${ic('calendar')} Quiero agendar una inspección</a>
            <a href="#/busqueda">${ic('target')} Búsquenme un auto</a>
            <a href="${waLink()}" target="_blank" rel="noopener">${ic('chat')} Hablar por WhatsApp</a>
            <a href="${IG}" target="_blank" rel="noopener">${ic('instagram')} Ver nuestro Instagram</a>
          </div>
        </div>` : ''}
        <div class="helper__row">
          ${open ? '' : '<button class="helper__label" type="button" tabindex="-1" aria-hidden="true"><b>¿Te ayudo?</b><small>Agenda o pregúntanos</small></button>'}
          <button class="helper__btn" aria-label="${open ? 'Cerrar ayuda' : '¿Te ayudo? Agenda o pregúntanos'}" aria-expanded="${open}">${open ? ic('x') : '<img src="assets/img/aguila-cara.png" alt="">'}</button>
        </div>`;
    };
    h.addEventListener('click', (e) => {
      if (e.target.closest('.helper__btn, .helper__label')) { open = !open; sessionStorageSafe('hint', '1'); draw(); }
      else if (e.target.closest('a')) { open = false; draw(); }
    });
    window.addEventListener('hashchange', () => { if (open) { open = false; draw(); } });
    draw();
  }
  function sessionStorageSafe(k, v) {
    try { if (v === undefined) return sessionStorage.getItem('atlas-' + k); sessionStorage.setItem('atlas-' + k, v); } catch (e) { return null; }
  }

  /* ---------------- router ---------------- */
  function route() {
    const raw = location.hash.replace(/^#/, '') || '/';
    const [path] = raw.split('?');
    const parts = path.split('/').filter(Boolean);
    pintarAutos = null;
    contarPagina(parts);
    let html, bind, nav = parts[0] || 'home';
    switch (parts[0]) {
      case undefined: html = viewHome(); bind = () => { bindBuscador(); bindDestacados(); if (window.AtlasHistoria) window.AtlasHistoria.bind(); if (window.AtlasViaje) window.AtlasViaje.bind(); bindAguila(); bindInstagram(); }; break;
      case 'autos': html = viewAutos(); bind = bindAutos; nav = 'autos'; break;
      case 'auto': html = viewAutoShell(); bind = () => bindAuto(parts[1]); nav = 'autos'; break;
      case 'informe': html = viewInforme(parts[1] || CARS[0].id); nav = 'inspeccion'; break;
      case 'inspeccion': html = viewInspeccion(); break;
      case 'agendar': html = viewAgendar(); bind = bindAgendar; break;
      case 'busqueda': html = viewBusqueda(); bind = bindBusqueda; break;
      case 'privacidad': html = viewPrivacidad(); break;
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
    document.title = ({ home: 'Atlas Motors · Inspección precompra de vehículos en la Región de Coquimbo', autos: 'Autos en venta · Atlas Motors', inspeccion: 'Inspección precompra · Atlas Motors', agendar: 'Agendar inspección · Atlas Motors', busqueda: 'Búsqueda personalizada · Atlas Motors', privacidad: 'Política de privacidad · Atlas Motors' })[nav] || 'Atlas Motors';
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
  contarVisita();
  const gPie = $('#gFooter'); if (gPie) gPie.innerHTML = googleBadge();
  route();
})();
