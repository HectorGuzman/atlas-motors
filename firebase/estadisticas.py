"""Resumen de las estadísticas anónimas de atlasmotors.cl (colección `estadisticas`).

Uso: python3 firebase/estadisticas.py [días]      (por defecto, los últimos 30)

Usa el login de gcloud. Suma los contadores de cada día y los muestra agrupados.
Los autos aparecen con su nombre si siguen publicados.
"""
import datetime
import json
import subprocess
import sys
import urllib.request
from collections import Counter

PROJECT = 'atlas-motors-cl'
BASE = f'https://firestore.googleapis.com/v1/projects/{PROJECT}/databases/(default)/documents'
TOKEN = subprocess.check_output(['gcloud', 'auth', 'print-access-token'], text=True).strip()


def get(url):
    req = urllib.request.Request(url, headers={'Authorization': f'Bearer {TOKEN}', 'x-goog-user-project': PROJECT})
    with urllib.request.urlopen(req) as r:
        return json.load(r)


def documentos(coleccion):
    token = ''
    while True:
        j = get(f'{BASE}/{coleccion}?pageSize=300' + (f'&pageToken={token}' if token else ''))
        yield from j.get('documents', [])
        token = j.get('nextPageToken')
        if not token:
            return


dias = int(sys.argv[1]) if len(sys.argv) > 1 else 30
desde = (datetime.date.today() - datetime.timedelta(days=dias - 1)).isoformat()
total, por_dia = Counter(), {}
for d in documentos('estadisticas'):
    dia = d['name'].rsplit('/', 1)[1]
    if dia < desde:
        continue
    c = Counter({k: int(v['integerValue']) for k, v in d.get('fields', {}).items() if 'integerValue' in v})
    por_dia[dia] = c
    total.update(c)

nombres = {}
for d in documentos('publicaciones'):
    f = d.get('fields', {})
    val = lambda k: next(iter(f.get(k, {}).values()), '')
    nombres[''.join(ch for ch in d['name'].rsplit('/', 1)[1].lower() if ch.isalnum())[:40]] = f"{val('marca')} {val('modelo')} {val('anio')}".strip()


def bloque(titulo, filas):
    filas = [(n, v) for n, v in filas if v]
    if not filas:
        return
    print(f'\n{titulo}')
    for n, v in filas:
        print(f'  {n:<34} {v:>6}')


print(f'Estadísticas de atlasmotors.cl · últimos {dias} días (desde {desde}) · {len(por_dia)} días con datos')
bloque('Visitantes (uno por navegador y día)', [('Total', total['visitantes']), ('Nuevos', total['visitantes_nuevos']),
                                               ('Vuelven', total['visitantes_recurrentes'])])
bloque('De dónde llegan', sorted(((k[7:], v) for k, v in total.items() if k.startswith('origen_')), key=lambda x: -x[1]))
bloque('Dispositivo', [('Celular', total['disp_movil']), ('Computador', total['disp_escritorio'])])
bloque('Páginas vistas', sorted(((k[3:], v) for k, v in total.items() if k.startswith('pv_')), key=lambda x: -x[1]))
bloque('Acciones', [(n, total[k]) for k, n in [
    ('wa', 'WhatsApp (botones generales)'), ('wa_auto', 'WhatsApp "Me interesa" en un auto'),
    ('agendar_enviado', 'Agendar: envió por WhatsApp'), ('busqueda_enviada', 'Búsqueda: envió por WhatsApp'),
    ('avisame_enviado', 'Avísame: envió por WhatsApp'), ('compartir_wa', 'Compartir auto por WhatsApp'),
    ('compartir_copiar', 'Copiar enlace de un auto'), ('fav_agregar', 'Guardó en favoritos'), ('fav_quitar', 'Quitó de favoritos'),
    ('ficha', 'Descargó ficha de inspección'), ('instagram', 'Clic a Instagram'), ('google_opiniones', 'Clic a opiniones de Google'),
    ('llamar', 'Clic en llamar')]])

autos = {}
for k, v in total.items():
    if k.startswith('a_'):
        id_, ev = k[2:].rsplit('_', 1)
        autos.setdefault(id_, Counter())[ev] += v
if autos:
    print('\nAutos (vistas · WhatsApp · compartido · favoritos · ficha)')
    for id_, c in sorted(autos.items(), key=lambda x: -x[1]['vista']):
        print(f"  {nombres.get(id_, id_ + ' (ya no publicado)'):<34} {c['vista']:>5} {c['wa']:>5} {c['compartir']:>5} {c['fav']:>5} {c['ficha']:>5}")

if por_dia:
    print('\nVisitantes por día')
    for dia in sorted(por_dia)[-14:]:
        print(f"  {dia}  {por_dia[dia]['visitantes']:>4}  {'█' * min(por_dia[dia]['visitantes'], 60)}")
