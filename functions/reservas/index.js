// Función `reservar`: la web de atlasmotors.cl la llama cuando alguien agenda una
// inspección. Toma la hora (queda "pendiente de abono" por 1 hora), guarda los datos
// del cliente donde solo el equipo los ve y avisa a los admin con una notificación.
//
// Datos en Firestore:
//  agenda/{AAAA-MM}   pública (la web la lee para mostrar horas libres). Sin datos
//                     personales: h.{AAAA-MM-DD}.{HH:MM} = { e: 'p'|'c'|'b', v?: ms, r?: id }
//                     p = pendiente de abono (vence en v), c = confirmada, b = bloqueada.
//  reservas/{id}      privada (solo admin): nombre, teléfono, auto, dirección…
//  limites/{hash}     cuántas reservas hizo hoy una misma conexión (sin la IP).
const functions = require('@google-cloud/functions-framework');
const admin = require('firebase-admin');
const crypto = require('crypto');
const H = require('./horario');

admin.initializeApp();
const db = admin.firestore();

const ORIGENES = new Set(['https://www.atlasmotors.cl', 'https://atlasmotors.cl', 'http://127.0.0.1:5173', 'http://localhost:5173']);
const MAX_POR_DIA = 3; // reservas por conexión al día
const CAMPOS = { nombre: 80, telefono: 30, vehiculo: 120, donde: 30, comuna: 60, direccion: 200, presente: 2, link: 500, nota: 1000 };
const OBLIGATORIOS = ['nombre', 'telefono', 'vehiculo', 'comuna'];

class Rechazo extends Error {}

// reCAPTCHA invisible (reCAPTCHA Enterprise del mismo proyecto). La clave del sitio
// llega por la variable RECAPTCHA_KEY al desplegar; sin ella no se exige.
const RECAPTCHA_KEY = process.env.RECAPTCHA_KEY || '';
const PUNTAJE_MINIMO = 0.5; // 0 = bot seguro, 1 = persona

async function verificarCaptcha(token) {
  if (!RECAPTCHA_KEY) return;
  if (typeof token !== 'string' || !token) throw new Rechazo('No pudimos verificar que no eres un robot. Recarga la página e intenta de nuevo.');
  let r;
  try {
    const { access_token: acceso } = await admin.credential.applicationDefault().getAccessToken();
    const proyecto = process.env.GOOGLE_CLOUD_PROJECT || process.env.GCLOUD_PROJECT || 'atlas-motors-cl';
    const resp = await fetch(`https://recaptchaenterprise.googleapis.com/v1/projects/${proyecto}/assessments`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${acceso}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ event: { token, siteKey: RECAPTCHA_KEY, expectedAction: 'reservar' } }),
    });
    if (!resp.ok) throw new Error(`reCAPTCHA ${resp.status}: ${await resp.text()}`);
    r = await resp.json();
  } catch (e) {
    // Si el servicio de Google falla, no se pierde la reserva: siguen el límite
    // diario por conexión y el campo trampa.
    console.error('captcha', e);
    return;
  }
  const ok = r.tokenProperties?.valid && r.tokenProperties?.action === 'reservar' && (r.riskAnalysis?.score ?? 0) >= PUNTAJE_MINIMO;
  if (!ok) {
    console.warn('captcha rechazado', r.tokenProperties?.invalidReason, r.riskAnalysis?.score);
    throw new Rechazo('No pudimos verificar que no eres un robot. Intenta de nuevo o escríbenos por WhatsApp.');
  }
}

function limpiar(body) {
  const d = {};
  for (const [k, max] of Object.entries(CAMPOS)) {
    const v = body[k];
    if (v != null && typeof v !== 'string') throw new Rechazo('Datos no válidos.');
    d[k] = (v || '').trim().slice(0, max);
  }
  for (const k of OBLIGATORIOS) if (!d[k]) throw new Rechazo('Faltan datos obligatorios.');
  if ((d.telefono.match(/\d/g) || []).length < 8) throw new Rechazo('Revisa el teléfono.');
  if (d.link && !/^https?:\/\//i.test(d.link)) d.link = '';
  d.presente = d.presente === 'no' ? 'no' : 'si';
  return d;
}

function codigo() {
  const letras = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  return Array.from(crypto.randomBytes(5), (b) => letras[b % letras.length]).join('');
}

async function contarConexion(req, ahora) {
  const ip = String(req.headers['x-forwarded-for'] || req.ip || '').split(',')[0].trim();
  const dia = H.enChile(ahora).fecha;
  const ref = db.collection('limites').doc(crypto.createHash('sha256').update(`${ip}|${dia}|atlas`).digest('hex').slice(0, 32));
  await db.runTransaction(async (tx) => {
    const n = (await tx.get(ref)).get('n') || 0;
    if (n >= MAX_POR_DIA) throw new Rechazo('Ya hiciste varias reservas hoy. Escríbenos por WhatsApp para otra.');
    tx.set(ref, { n: n + 1, expira: admin.firestore.Timestamp.fromMillis(ahora + 2 * 86400e3) });
  });
}

async function avisar(reserva, id) {
  const equipo = await db.collection('equipo').where('rol', '==', 'admin').get();
  const tokens = [];
  equipo.forEach((d) => (d.get('fcm') || []).forEach((t) => typeof t === 'string' && tokens.push({ uid: d.id, t })));
  if (!tokens.length) return;
  const [, m, dd] = reserva.fecha.split('-');
  const res = await admin.messaging().sendEachForMulticast({
    tokens: tokens.map((x) => x.t),
    notification: {
      title: 'Nueva inspección agendada',
      body: `${dd}/${m} a las ${reserva.hora} · ${reserva.vehiculo} en ${reserva.comuna}. Pendiente de abono.`,
    },
    data: { tipo: 'reserva', id, fecha: reserva.fecha, hora: reserva.hora },
    apns: { payload: { aps: { sound: 'default' } } },
  });
  // Quita los tokens de teléfonos que ya no existen.
  const malos = res.responses
    .map((r, i) => (!r.success && /registration-token-not-registered|invalid-registration-token|invalid-argument/.test(r.error?.code || '') ? tokens[i] : null))
    .filter(Boolean);
  await Promise.all(malos.map((x) => db.collection('equipo').doc(x.uid).update({ fcm: admin.firestore.FieldValue.arrayRemove(x.t) })));
}

// Borra reservas que no se hicieron (canceladas o vencidas sin abono) con más de
// 30 días, y los contadores de conexiones viejos. Corre en cada reserva nueva.
async function limpiarViejas(ahora) {
  const corte = admin.firestore.Timestamp.fromMillis(ahora - 30 * 86400e3);
  const [rs, ls] = await Promise.all([
    db.collection('reservas').where('creada', '<', corte).orderBy('creada').limit(50).get(),
    db.collection('limites').where('expira', '<', admin.firestore.Timestamp.fromMillis(ahora)).limit(50).get(),
  ]);
  const lote = db.batch();
  rs.forEach((d) => {
    const vencida = d.get('estado') === 'pendiente' && d.get('vence') && d.get('vence').toMillis() < ahora;
    if (d.get('estado') === 'cancelada' || vencida) lote.delete(d.ref);
  });
  ls.forEach((d) => lote.delete(d.ref));
  await lote.commit();
}

functions.http('reservar', async (req, res) => {
  const origen = req.get('origin');
  if (ORIGENES.has(origen)) {
    res.set('Access-Control-Allow-Origin', origen);
    res.set('Vary', 'Origin');
  }
  if (req.method === 'OPTIONS') {
    res.set('Access-Control-Allow-Methods', 'POST');
    res.set('Access-Control-Allow-Headers', 'Content-Type');
    res.set('Access-Control-Max-Age', '3600');
    return res.status(204).send('');
  }
  if (req.method !== 'POST' || !ORIGENES.has(origen)) return res.status(403).json({ error: 'No permitido.' });

  const ahora = Date.now();
  try {
    const b = req.body && typeof req.body === 'object' ? req.body : {};
    if (b.web) return res.json({ ok: true, codigo: codigo() }); // campo trampa: lo llenan solo los bots
    const fecha = String(b.fecha || '');
    const hora = String(b.hora || '');
    const motivo = H.motivoNoReservable(fecha, hora, ahora);
    if (motivo) throw new Rechazo(motivo);
    const datos = limpiar(b);
    await verificarCaptcha(b.captcha);
    await contarConexion(req, ahora);

    const ref = db.collection('reservas').doc();
    const agendaRef = db.collection('agenda').doc(fecha.slice(0, 7));
    const reserva = {
      ...datos, fecha, hora, codigo: codigo(), estado: 'pendiente', origen: 'web', vista: false,
      vence: admin.firestore.Timestamp.fromMillis(H.vence(fecha, hora, ahora)),
      creada: admin.firestore.FieldValue.serverTimestamp(),
    };
    await db.runTransaction(async (tx) => {
      const ag = await tx.get(agendaRef);
      const celda = ag.exists ? ag.get(new admin.firestore.FieldPath('h', fecha, hora)) : null;
      if (H.ocupada(celda, ahora)) throw new Rechazo('Esa hora se acaba de tomar. Elige otra.');
      tx.set(agendaRef, { h: { [fecha]: { [hora]: { e: 'p', v: reserva.vence.toMillis(), r: ref.id } } } }, { merge: true });
      tx.set(ref, reserva);
    });

    try { await avisar(reserva, ref.id); } catch (e) { console.error('aviso', e); }
    try { await limpiarViejas(ahora); } catch (e) { console.error('limpieza', e); }
    return res.json({ ok: true, codigo: reserva.codigo, vence: reserva.vence.toMillis() });
  } catch (e) {
    if (e instanceof Rechazo) return res.status(400).json({ error: e.message });
    console.error(e);
    return res.status(500).json({ error: 'No pudimos guardar tu reserva. Escríbenos por WhatsApp.' });
  }
});
