"""Publica las reglas de Firestore y Storage en el proyecto atlas-motors-cl
usando el login de gcloud.

Uso: python3 firebase/deploy_rules.py
"""
import json
import pathlib
import subprocess
import urllib.error
import urllib.request

PROJECT = 'atlas-motors-cl'
AQUI = pathlib.Path(__file__).parent
TOKEN = subprocess.check_output(['gcloud', 'auth', 'print-access-token'], text=True).strip()

# release -> archivo de reglas
RELEASES = {
    'cloud.firestore': 'firestore.rules',
    'firebase.storage/atlas-motors-cl-fotos': 'storage.rules',
    'firebase.storage/atlas-motors-cl.firebasestorage.app': 'storage-cerrado.rules',
}


def call(method, url, body):
    req = urllib.request.Request(url, data=json.dumps(body).encode(), method=method, headers={
        'Authorization': f'Bearer {TOKEN}', 'x-goog-user-project': PROJECT, 'Content-Type': 'application/json'})
    with urllib.request.urlopen(req) as r:
        return json.load(r)


base = f'https://firebaserules.googleapis.com/v1/projects/{PROJECT}'
for release, archivo in RELEASES.items():
    texto = (AQUI / archivo).read_text()
    rs = call('POST', f'{base}/rulesets', {'source': {'files': [{'name': archivo, 'content': texto}]}})
    nombre = f'projects/{PROJECT}/releases/{release}'
    try:
        call('PATCH', f'{base}/releases/{release}', {'release': {'name': nombre, 'rulesetName': rs['name']}})
    except urllib.error.HTTPError as e:
        if e.code != 404:
            raise
        call('POST', f'{base}/releases', {'name': nombre, 'rulesetName': rs['name']})
    print(f'{archivo} -> {release}')
