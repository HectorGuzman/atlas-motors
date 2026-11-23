"""Administra quién entra a la app de Atlas Motors y con qué perfil.

Perfiles:
  admin   Matías y Héctor: inspecciones, informes, publicar y Garage.
  garage  Fotografía, video y venta: solo Garage (precio, fotos y videos de los
          autos en venta). No ve las inspecciones.

Uso (con el login de gcloud):
  python3 firebase/equipo.py                         lista el equipo
  python3 firebase/equipo.py agregar CORREO PERFIL "Nombre"
  python3 firebase/equipo.py quitar CORREO           le quita el acceso (la cuenta queda, sin permisos)

Antes de agregar a alguien, crea su cuenta en la consola de Firebase
(Authentication > Agregar usuario). Después, que entre a la app con
"¿Olvidaste tu clave?" para crear su propia clave.
"""
import json
import subprocess
import sys
import urllib.request

PROJECT = 'atlas-motors-cl'
BASE = f'https://firestore.googleapis.com/v1/projects/{PROJECT}/databases/(default)/documents/equipo'
TOKEN = subprocess.check_output(['gcloud', 'auth', 'print-access-token'], text=True).strip()
HEADERS = {'Authorization': f'Bearer {TOKEN}', 'x-goog-user-project': PROJECT, 'Content-Type': 'application/json'}
PERFILES = ('admin', 'garage')


def call(method, url, body=None):
    req = urllib.request.Request(url, data=json.dumps(body).encode() if body is not None else None,
                                 headers=HEADERS, method=method)
    with urllib.request.urlopen(req) as r:
        txt = r.read()
        return json.loads(txt) if txt else {}


def uid_de(correo):
    r = call('POST', f'https://identitytoolkit.googleapis.com/v1/projects/{PROJECT}/accounts:lookup',
             {'email': [correo]})
    users = r.get('users') or []
    if not users:
        sys.exit(f'No hay una cuenta con el correo {correo}. Créala primero en la consola de Firebase.')
    return users[0]['localId']


args = sys.argv[1:]
if not args:
    for d in call('GET', BASE).get('documents', []):
        f = {k: next(iter(v.values())) for k, v in d.get('fields', {}).items()}
        print(f"{f.get('rol', '?'):<8} {f.get('nombre', ''):<24} {f.get('correo', '')}")
elif args[0] == 'agregar' and len(args) == 4 and args[2] in PERFILES:
    correo, rol, nombre = args[1].strip().lower(), args[2], args[3]
    uid = uid_de(correo)
    call('PATCH', f'{BASE}/{uid}', {'fields': {
        'correo': {'stringValue': correo}, 'rol': {'stringValue': rol}, 'nombre': {'stringValue': nombre}}})
    print(f'{nombre} ({correo}) quedó con perfil {rol}.')
elif args[0] == 'quitar' and len(args) == 2:
    uid = uid_de(args[1].strip().lower())
    call('DELETE', f'{BASE}/{uid}')
    print(f'{args[1]} ya no tiene acceso a la app.')
else:
    sys.exit(__doc__)
