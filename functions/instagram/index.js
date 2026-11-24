// Función `instagram`: copia a la web lo que Matías publica en @atlas.motors.cl.
// Solo lee (el token es de solo lectura, permiso instagram_basic). Corre cada
// 20 minutos con Cloud Scheduler.
//
//  - Lee las últimas publicaciones y las historias activas con la API de Instagram.
//  - Copia las imágenes (y los videos de las historias) a Storage, porque los
//    enlaces que entrega Instagram vencen a los pocos días.
//  - Deja todo en el documento público instagram/feed, que la web lee.
//
// Token: secreto `instagram-token` de Secret Manager, llega como IG_TOKEN.
const functions = require('@google-cloud/functions-framework');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();
const BUCKET = 'atlas-motors-cl-fotos';
const CARPETA = 'instagram/';
const IG_ID = '17841479011304079';
const API = 'https://graph.facebook.com/v23.0';
const N_POSTS = 12;
const MAX_IMG = 10 * 1024 * 1024;
const MAX_VIDEO = 40 * 1024 * 1024;
const TEXTO = 300;

async function graph(ruta, token) {
  const r = await fetch(`${API}/${ruta}`, { headers: { Authorization: `Bearer ${token}` } });
  const j = await r.json().catch(() => ({}));
  if (!r.ok || j.error) throw new Error(`Instagram ${r.status}: ${j.error?.message || 'sin respuesta'}`);
  return j;
}

const urlPublica = (nombre) => `https://firebasestorage.googleapis.com/v0/b/${BUCKET}/o/${encodeURIComponent(nombre)}?alt=media`;
const PREFIJO_URL = `https://firebasestorage.googleapis.com/v0/b/${BUCKET}/o/`;
/** Nombre del archivo en Storage a partir de su URL pública (solo dentro de instagram/). */
function nombreDe(url) {
  if (typeof url !== 'string' || !url.startsWith(PREFIJO_URL)) return '';
  const n = decodeURIComponent(url.slice(PREFIJO_URL.length).split('?')[0]);
  return n.startsWith(CARPETA) && !n.includes('..') ? n : '';
}

/** Copia un archivo de Instagram a Storage (si no estaba ya) y devuelve su URL pública. */
async function copiar(bucket, url, nombre, tipo, max) {
  const f = bucket.file(nombre);
  const [existe] = await f.exists();
  if (!existe) {
    const r = await fetch(url);
    if (!r.ok) throw new Error(`descarga ${r.status} ${nombre}`);
    const ct = (r.headers.get('content-type') || '').split(';')[0];
    if (!ct.startsWith(tipo)) throw new Error(`tipo ${ct} ${nombre}`);
    const buf = Buffer.from(await r.arrayBuffer());
    if (buf.length > max) throw new Error(`muy grande ${nombre}`);
    await f.save(buf, { contentType: ct, resumable: false, metadata: { cacheControl: 'public, max-age=86400' } });
  }
  return urlPublica(nombre);
}

/** Imagen que representa la publicación: la foto, o la portada si es video. */
function imagenDe(m) {
  if (m.media_type === 'VIDEO') return m.thumbnail_url;
  if (m.media_type === 'CAROUSEL_ALBUM') {
    const c = m.children?.data?.[0];
    if (c) return c.media_type === 'VIDEO' ? c.thumbnail_url : c.media_url;
  }
  return m.media_url;
}

const tipo = (t) => (t === 'VIDEO' ? 'video' : t === 'CAROUSEL_ALBUM' ? 'carrusel' : 'foto');

async function actualizar(token) {
  const bucket = admin.storage().bucket(BUCKET);
  const campos = 'id,caption,media_type,media_url,thumbnail_url,permalink,timestamp';
  const [perfil, media, stories] = await Promise.all([
    graph(`${IG_ID}?fields=username,name`, token),
    graph(`${IG_ID}/media?fields=${campos},children{media_type,media_url,thumbnail_url}&limit=${N_POSTS}`, token),
    graph(`${IG_ID}/stories?fields=id,media_type,media_url,thumbnail_url,permalink,timestamp`, token),
  ]);

  const usados = new Set();
  const posts = [];
  for (const m of media.data || []) {
    const src = imagenDe(m);
    if (!src) continue;
    try {
      const nombre = `${CARPETA}${m.id}.jpg`;
      posts.push({
        id: m.id,
        tipo: tipo(m.media_type),
        img: await copiar(bucket, src, nombre, 'image/', MAX_IMG),
        link: m.permalink || `https://www.instagram.com/${perfil.username}/`,
        fecha: m.timestamp,
        texto: (m.caption || '').slice(0, TEXTO),
      });
      usados.add(nombre);
    } catch (e) {
      console.warn('post', m.id, e.message);
    }
  }

  const historias = [];
  for (const s of stories.data || []) {
    try {
      const h = { id: s.id, tipo: s.media_type === 'VIDEO' ? 'video' : 'foto', fecha: s.timestamp, link: s.permalink || '' };
      const img = s.media_type === 'VIDEO' ? s.thumbnail_url : s.media_url;
      if (img) {
        h.img = await copiar(bucket, img, `${CARPETA}h-${s.id}.jpg`, 'image/', MAX_IMG);
        usados.add(`${CARPETA}h-${s.id}.jpg`);
      }
      if (s.media_type === 'VIDEO' && s.media_url) {
        h.video = await copiar(bucket, s.media_url, `${CARPETA}h-${s.id}.mp4`, 'video/', MAX_VIDEO);
        usados.add(`${CARPETA}h-${s.id}.mp4`);
      }
      if (h.img || h.video) historias.push(h);
    } catch (e) {
      console.warn('historia', s.id, e.message);
    }
  }
  historias.sort((a, b) => a.fecha.localeCompare(b.fecha));

  // Archivos del feed anterior: los que ya no se usen se borran después. Se
  // sacan del documento (no listando el bucket) para que la función solo tenga
  // acceso a instagram/ y no vea las fotos de inspecciones.
  const antes = (await db.doc('instagram/feed').get()).data() || {};
  const previos = new Set();
  for (const x of [...(antes.posts || []), ...(antes.historias || [])]) {
    for (const u of [x.img, x.video]) {
      const n = nombreDe(u);
      if (n) previos.add(n);
    }
  }

  await db.doc('instagram/feed').set({
    usuario: perfil.username,
    nombre: perfil.name || '',
    posts,
    historias,
    actualizado: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Borra lo que ya no se muestra (historias vencidas, publicaciones antiguas o borradas).
  const sobran = [...previos].filter((n) => !usados.has(n));
  await Promise.all(sobran.map((n) => bucket.file(n).delete({ ignoreNotFound: true }).catch((e) => console.warn('borrar', n, e.message))));

  return { posts: posts.length, historias: historias.length, borrados: sobran.length };
}

functions.http('instagram', async (req, res) => {
  const token = (process.env.IG_TOKEN || '').trim();
  if (!token) return res.status(500).send('Falta IG_TOKEN');
  try {
    const r = await actualizar(token);
    console.log('instagram', JSON.stringify(r));
    res.json(r);
  } catch (e) {
    // Si Instagram falla se deja el feed anterior tal cual.
    console.error('instagram', e);
    res.status(500).send('error');
  }
});

module.exports = { imagenDe, tipo };
