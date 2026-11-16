"""Activa o desactiva la cuenta de prueba (prueba@atlasmotors.cl) en el equipo.

Mientras está fuera del equipo puede iniciar sesión, pero no ve ni escribe
inspecciones (las reglas exigen estar en `equipo`). Actívala solo para probar.

Uso: python3 firebase/cuenta_prueba.py on|off
"""
import json
import subprocess
import sys
import urllib.request

PROJECT = 'atlas-motors-cl'
UID = 'KqGPlupw9DfmfyDyWU5mLSitw6D2'
DOC = f'https://firestore.googleapis.com/v1/projects/{PROJECT}/databases/(default)/documents/equipo/{UID}'

if len(sys.argv) != 2 or sys.argv[1] not in ('on', 'off'):
    sys.exit(__doc__)

token = subprocess.check_output(['gcloud', 'auth', 'print-access-token'], text=True).strip()
headers = {'Authorization': f'Bearer {token}', 'x-goog-user-project': PROJECT, 'Content-Type': 'application/json'}
if sys.argv[1] == 'on':
    body = {'fields': {'nombre': {'stringValue': 'Cuenta de prueba'}, 'rol': {'stringValue': 'inspector'},
                       'correo': {'stringValue': 'prueba@atlasmotors.cl'}}}
    req = urllib.request.Request(DOC, data=json.dumps(body).encode(), headers=headers, method='PATCH')
else:
    req = urllib.request.Request(DOC, headers=headers, method='DELETE')
urllib.request.urlopen(req)
print('Cuenta de prueba', 'activada' if sys.argv[1] == 'on' else 'desactivada')
