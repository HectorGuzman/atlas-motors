# Atlas Motors — sitio web

Sitio de **Atlas Motors**: inspección precompra de vehículos y búsqueda personalizada en la Región de Coquimbo. Publicado en GitHub Pages: https://hectorguzman.github.io/atlas-motors/

Sin backend: las solicitudes (agenda y búsqueda) se envían por WhatsApp al +56 9 3559 5554, con el mensaje ya armado. El abono del 50 % se paga por transferencia, coordinada por WhatsApp.

## Secciones

| Ruta | Contenido |
|---|---|
| `#/` | Inicio: servicios, cómo funciona, mascota "¿Te ayudo?" y aviso del marketplace (próximamente) |
| `#/inspeccion` | Inspección precompra: recorrido en 8 etapas, inspección remota, "no es un diagnóstico" y precio |
| `#/agendar` | Agenda en 3 pasos: día y hora, vehículo y datos, envío por WhatsApp |
| `#/busqueda` | Búsqueda personalizada: cómo funciona y formulario que se envía por WhatsApp |
| `#/informe` | Informe de inspección de ejemplo |
| `#/autos` | Marketplace: por ahora una página de "próximamente" |

## Stack

HTML, CSS y JavaScript puros, sin build. El router funciona por hash para que el sitio corra en GitHub Pages.

- `index.html`: layout (header, footer, ayudante flotante). Al publicar cambios, sube el `?v=N` de los CSS/JS para evitar caché.
- `assets/css/styles.css`: design system (verde bosque + dorado del logo)
- `assets/js/data.js`: checklist, precio y el auto del informe de ejemplo
- `assets/js/app.js`: vistas y lógica

## Correr localmente

```bash
python3 -m http.server 5173
```

Luego abre http://localhost:5173.

## Créditos

Las fotos de vehículos vienen de Wikimedia Commons (CC BY-SA) y son solo de referencia.
