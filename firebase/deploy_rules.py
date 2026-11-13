"""Publica firestore.rules en el proyecto atlas-motors-cl usando el login de gcloud.

Uso: python3 firebase/deploy_rules.py
(Alternativa equivalente cuando esté instalado el CLI: firebase deploy --only firestore:rules)
"""
import json
import pathlib
import subprocess
import urllib.request

PROJECT = 'atlas-motors-cl'
RULES = pathlib.Path(__file__).with_name('firestore.rules').read_text()
TOKEN = subprocess.check_output(['gcloud', 'auth', 'print-access-token'], text=True).strip()


def call(method, url, body):
    req = urllib.request.Request(url, data=json.dumps(body).encode(), method=method, headers={
        'Authorization': f'Bearer {TOKEN}', 'x-goog-user-project': PROJECT, 'Content-Type': 'application/json'})
    with urllib.request.urlopen(req) as r:
        return json.load(r)


base = f'https://firebaserules.googleapis.com/v1/projects/{PROJECT}'
rs = call('POST', f'{base}/rulesets', {'source': {'files': [{'name': 'firestore.rules', 'content': RULES}]}})
rel = call('PATCH', f'{base}/releases/cloud.firestore',
           {'release': {'name': f'projects/{PROJECT}/releases/cloud.firestore', 'rulesetName': rs['name']}})
print('Reglas publicadas:', rel['rulesetName'])
