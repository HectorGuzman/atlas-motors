# Atlas Motors — mockup web

Mockup visual de la plataforma de **Atlas Motors**, el primer marketplace de vehículos inspeccionados en la Región de Coquimbo, con servicios de inspección precompra y búsqueda personalizada.

> Versión demo: los vehículos, precios, pagos y notificaciones son de ejemplo. Todavía no hay backend.

## Secciones

| Ruta | Contenido |
|---|---|
| `#/` | Inicio: hero, buscador, autos destacados, servicios, pasos, mascota "¿Te ayudo?" y testimonios |
| `#/autos` | Marketplace con filtros (tipo, marca, transmisión, precio) y orden |
| `#/auto/:id` | Detalle con galería de fotos, video de inspección, puntaje, checklist por categoría y descarga de informe |
| `#/informe/:id` | Informe de inspección imprimible y descargable como PDF |
| `#/inspeccion` | Servicio de inspección precompra: qué es, cifras, qué incluye y precios |
| `#/agendar` | Agenda en 4 pasos: plan, calendario y hora, datos y dirección, abono del 50 % (simulado) y confirmación |
| `#/busqueda` | Búsqueda personalizada: cómo funciona, modelo sin costo y formulario |

## Stack

HTML, CSS y JavaScript puros, sin build. El router funciona por hash para que el sitio corra en GitHub Pages.

- `index.html`: layout (header, footer, ayudante flotante)
- `assets/css/styles.css`: design system (verde bosque + dorado del logo)
- `assets/js/data.js`: datos de ejemplo (más adelante vendrán de la API)
- `assets/js/app.js`: vistas y lógica

## Correr localmente

```bash
python3 -m http.server 5173
```

Luego abre http://localhost:5173.

## Créditos

Las fotos de vehículos vienen de Wikimedia Commons (CC BY-SA) y son solo de referencia.
