"""Genera assets/catalogo.json (marcas y modelos) desde la nómina de tasación
fiscal de vehículos livianos del SII.

Uso:
  curl -L -o liv2026.xlsx https://www.sii.cl/servicios_online/tasacion_fiscal_vehiculos/liv2026.xlsx
  python3 tool/sii_catalogo.py liv2026.xlsx assets/catalogo.json

Se excluyen motos y cuatrimotos. Solo usa la biblioteca estándar.
"""
import collections, json, re, sys, zipfile
import xml.etree.ElementTree as ET

NS = '{http://schemas.openxmlformats.org/spreadsheetml/2006/main}'
EXCLUIR = {'Moto', 'Cuatrimoto'}
MARCAS = {'KIA MOTORS': 'Kia', 'MERCEDES BENZ': 'Mercedes-Benz', 'SSANGYONG': 'SsangYong', 'GREAT WALL': 'Great Wall'}


def filas(path):
    z = zipfile.ZipFile(path)
    ss = [''.join(t.text or '' for t in si.iter(NS + 't'))
          for si in ET.parse(z.open('xl/sharedStrings.xml')).getroot().iter(NS + 'si')]
    for _, el in ET.iterparse(z.open('xl/worksheets/sheet1.xml')):
        if el.tag != NS + 'row':
            continue
        r = {}
        for c in el.iter(NS + 'c'):
            v = c.find(NS + 'v')
            if v is not None:
                r[re.match(r'[A-Z]+', c.get('r')).group()] = ss[int(v.text)] if c.get('t') == 's' else v.text
        yield r
        el.clear()


def palabra(w, corto):
    # Siglas y códigos quedan en mayúscula: BMW, MG, RAV4, L200, ASX, CR-V.
    if len(w) <= corto or any(ch.isdigit() for ch in w) or not re.search(r'[AEIOUÁÉÍÓÚ]', w):
        return w
    return w[0] + w[1:].lower()


def bonito(s, corto):
    return ' '.join('-'.join(palabra(p, corto) for p in w.split('-')) for w in s.split())


def main(src, dst):
    cat = collections.defaultdict(collections.Counter)
    dentro = False
    for r in filas(src):
        if r.get('A') == 'Código SII':
            dentro = True
            continue
        marca, modelo = (r.get('D') or '').strip(), (r.get('E') or '').strip()
        if not dentro or not marca or not modelo or r.get('C') in EXCLUIR:
            continue
        cat[MARCAS.get(marca) or bonito(marca, 3)][bonito(modelo, 2)] += 1
    # Ordenado por cantidad de versiones: lo más común aparece primero.
    out = [{'m': m, 'o': [k for k, _ in mods.most_common()]}
           for m, mods in sorted(cat.items(), key=lambda kv: -sum(kv[1].values()))]
    json.dump(out, open(dst, 'w', encoding='utf-8'), ensure_ascii=False, separators=(',', ':'))
    print(len(out), 'marcas,', sum(len(x['o']) for x in out), 'modelos ->', dst)


if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
