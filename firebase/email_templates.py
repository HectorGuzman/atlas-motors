"""Plantillas de correo de Firebase Auth en español y con la marca Atlas Motors.

Uso: python3 firebase/email_templates.py
Variables que reemplaza Firebase: %APP_NAME%, %EMAIL%, %LINK%, %DISPLAY_NAME%.
"""
import json
import subprocess
import urllib.request

PROJECT = 'atlas-motors-cl'
TOKEN = subprocess.check_output(['gcloud', 'auth', 'print-access-token'], text=True).strip()
LOGO = 'https://www.atlasmotors.cl/assets/img/logo-wordmark.png'


def correo(titulo, intro, boton, nota):
    return f"""<div style="margin:0;padding:0;background:#f4efe2">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#f4efe2;padding:32px 12px;font-family:Arial,Helvetica,sans-serif">
<tr><td align="center">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:520px;background:#ffffff;border-radius:16px;overflow:hidden">
<tr><td style="background:#070a08;padding:26px 24px;text-align:center;border-bottom:3px solid #d4a62a">
<img src="{LOGO}" alt="Atlas Motors" width="190" style="display:inline-block;width:190px;max-width:70%;height:auto">
<div style="color:#e9cf7f;font-size:11px;letter-spacing:4px;margin-top:8px">INSPECCIONES</div>
</td></tr>
<tr><td style="padding:30px 28px 8px;color:#16241b">
<h1 style="margin:0 0 14px;font-size:22px;color:#0b2418">{titulo}</h1>
<p style="margin:0 0 22px;font-size:15px;line-height:1.6;color:#3d4a42">{intro}</p>
<p style="margin:0 0 26px;text-align:center">
<a href="%LINK%" style="display:inline-block;background:#d4a62a;background-image:linear-gradient(135deg,#f3d36b,#d4a62a 45%,#b8860b);color:#070a08;text-decoration:none;font-weight:bold;font-size:15px;padding:14px 28px;border-radius:999px">{boton}</a>
</p>
<p style="margin:0 0 8px;font-size:13px;line-height:1.6;color:#6b776f">{nota}</p>
<p style="margin:0 0 24px;font-size:12px;line-height:1.5;color:#8e9a92;word-break:break-all">Si el botón no funciona, copia este enlace en tu navegador:<br>%LINK%</p>
</td></tr>
<tr><td style="background:#0b2418;padding:18px 24px;text-align:center;color:#b9c2bb;font-size:12px;line-height:1.6">
Atlas Motors · Inspección precompra de vehículos en la Región de Coquimbo<br>
<a href="https://www.atlasmotors.cl" style="color:#e9cf7f;text-decoration:none">www.atlasmotors.cl</a>
</td></tr>
</table>
</td></tr>
</table>
</div>"""


reset = {
    'senderDisplayName': 'Atlas Motors',
    'subject': 'Crea tu clave para la app de Atlas Motors',
    'body': correo(
        'Crea tu clave',
        'Hola. Recibimos una solicitud para crear o cambiar la clave de la cuenta <b>%EMAIL%</b> '
        'en la app de inspecciones de Atlas Motors. Toca el botón para elegir tu clave.',
        'Crear mi clave',
        'Si no pediste esto, ignora este correo: tu clave actual sigue funcionando.'),
    'bodyFormat': 'HTML',
}
verify = {
    'senderDisplayName': 'Atlas Motors',
    'subject': 'Confirma tu correo en Atlas Motors',
    'body': correo(
        'Confirma tu correo',
        'Hola %DISPLAY_NAME%. Toca el botón para confirmar que <b>%EMAIL%</b> es tu correo.',
        'Confirmar correo',
        'Si no creaste una cuenta en Atlas Motors, ignora este correo.'),
    'bodyFormat': 'HTML',
}

# Firebase no deja cambiar el asunto ni el cuerpo de sus correos en este
# proyecto (EMAIL_TEMPLATE_UPDATE_NOT_ALLOWED). Lo que sí se puede: idioma
# español y nombre del remitente. El diseño de arriba queda listo para
# mandarlo nosotros desde una Cloud Function (enlace generado con el Admin SDK).
body = {'notification': {'sendEmail': {'resetPasswordTemplate': {'senderDisplayName': 'Atlas Motors'}},
                         'defaultLocale': 'es'}}
mask = 'notification.sendEmail.resetPasswordTemplate.senderDisplayName,notification.defaultLocale'
req = urllib.request.Request(
    f'https://identitytoolkit.googleapis.com/admin/v2/projects/{PROJECT}/config?updateMask={mask}',
    data=json.dumps(body).encode(), method='PATCH',
    headers={'Authorization': f'Bearer {TOKEN}', 'x-goog-user-project': PROJECT, 'Content-Type': 'application/json'})
with urllib.request.urlopen(req) as r:
    out = json.load(r)['notification']
print('Idioma:', out.get('defaultLocale'), '· Remitente:', out['sendEmail']['resetPasswordTemplate'].get('senderDisplayName'))

if __name__ == '__main__':
    import pathlib
    pathlib.Path(__file__).with_name('correo-clave.html').write_text(reset['body'])
