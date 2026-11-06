/* Datos de ejemplo del mockup. Más adelante vendrán desde el backend. */
(function () {
  const W = (path) => `https://upload.wikimedia.org/wikipedia/commons/thumb/${path}`;

  const CARS = [
    {
      id: 'ford-ranger-raptor-2023',
      marca: 'Ford', modelo: 'Ranger Raptor', version: '3.0 V6 Biturbo 4x4 AT', anio: 2023,
      precio: 42990000, km: 18500, combustible: 'Bencina', transmision: 'Automática', traccion: '4x4',
      tipo: 'Camioneta', color: 'Gris Conquer', comuna: 'La Serena', vendedor: 'Particular',
      score: 96, fechaInspeccion: '2026-10-28', destacado: true,
      fotos: [
        W('3/3f/Ford_Ranger_Raptor_%28P703%29_1X7A6774.jpg/1280px-Ford_Ranger_Raptor_%28P703%29_1X7A6774.jpg'),
        W('2/27/Ford_Ranger_Raptor_%28P703%29_1X7A6776.jpg/1280px-Ford_Ranger_Raptor_%28P703%29_1X7A6776.jpg'),
        W('b/b2/Ford_Ranger_Raptor_%28P703%29_1X7A6978.jpg/1280px-Ford_Ranger_Raptor_%28P703%29_1X7A6978.jpg'),
        W('e/e8/Ford_Ranger_Raptor_-_20231003-P1003802.jpg/1280px-Ford_Ranger_Raptor_-_20231003-P1003802.jpg'),
      ],
      resumen: 'Unidad impecable, un dueño, mantenciones al día en concesionario. Sin choques estructurales.',
      observaciones: [
        { nivel: 'obs', texto: 'Neumáticos traseros al 60 %. Recomendable cambio en 10.000 km.' },
        { nivel: 'ok', texto: 'Escáner sin códigos de falla activos ni históricos.' },
      ],
    },
    {
      id: 'vw-amarok-2023',
      marca: 'Volkswagen', modelo: 'Amarok', version: '2.0 BiTDI Highline 4Motion', anio: 2023,
      precio: 34490000, km: 32000, combustible: 'Diésel', transmision: 'Automática', traccion: '4x4',
      tipo: 'Camioneta', color: 'Plata', comuna: 'Coquimbo', vendedor: 'Automotora',
      score: 91, fechaInspeccion: '2026-10-30', destacado: true,
      fotos: [
        W('9/97/Volkswagen_Amarok_Mk2_1X7A0807.jpg/1280px-Volkswagen_Amarok_Mk2_1X7A0807.jpg'),
        W('a/a8/Volkswagen_Amarok_Mk2_1X7A0808.jpg/1280px-Volkswagen_Amarok_Mk2_1X7A0808.jpg'),
        W('c/c9/Volkswagen_Amarok_Mk2_1X7A0852.jpg/1280px-Volkswagen_Amarok_Mk2_1X7A0852.jpg'),
        W('f/fd/Volkswagen_Amarok_Mk2_Auto_Zuerich_2023_1X7A1337.jpg/1280px-Volkswagen_Amarok_Mk2_Auto_Zuerich_2023_1X7A1337.jpg'),
      ],
      resumen: 'Buen estado general. Detalle estético menor en parachoques trasero.',
      observaciones: [
        { nivel: 'obs', texto: 'Rayón superficial en parachoques trasero (lado izquierdo).' },
        { nivel: 'obs', texto: 'Pastillas de freno delanteras al 40 %.' },
        { nivel: 'ok', texto: 'Motor sin fugas, turbo sin juego.' },
      ],
    },
    {
      id: 'kia-sportage-2023',
      marca: 'Kia', modelo: 'Sportage', version: '2.0 EX 4x2 AT', anio: 2023,
      precio: 21990000, km: 24800, combustible: 'Bencina', transmision: 'Automática', traccion: '4x2',
      tipo: 'SUV', color: 'Blanco Nieve', comuna: 'La Serena', vendedor: 'Particular',
      score: 94, fechaInspeccion: '2026-11-02', destacado: true,
      fotos: [
        W('9/97/2023_Kia_Sportage_%28NQ5%29_in_White%2C_front_left.jpg/1280px-2023_Kia_Sportage_%28NQ5%29_in_White%2C_front_left.jpg'),
        W('d/db/2023_Kia_Sportage_%28NQ5%29_in_White%2C_rear_right.jpg/1280px-2023_Kia_Sportage_%28NQ5%29_in_White%2C_rear_right.jpg'),
        W('9/9d/2023_Kia_Sportage_Hybrid.jpg/1280px-2023_Kia_Sportage_Hybrid.jpg'),
      ],
      resumen: 'Muy buen estado. Pintura original en todas las piezas medidas.',
      observaciones: [
        { nivel: 'ok', texto: 'Espesor de pintura original en las 12 piezas medidas.' },
        { nivel: 'obs', texto: 'Filtro de habitáculo sucio, cambio sugerido.' },
      ],
    },
    {
      id: 'hyundai-tucson-2022',
      marca: 'Hyundai', modelo: 'Tucson', version: '2.0 GL 4x2 AT', anio: 2022,
      precio: 19490000, km: 41200, combustible: 'Bencina', transmision: 'Automática', traccion: '4x2',
      tipo: 'SUV', color: 'Gris Titanio', comuna: 'Ovalle', vendedor: 'Particular',
      score: 88, fechaInspeccion: '2026-10-21', destacado: true,
      fotos: [
        W('f/f1/Hyundai_Tucson_%28NX4%29_1X7A0424.jpg/1280px-Hyundai_Tucson_%28NX4%29_1X7A0424.jpg'),
        W('8/87/2022_Hyundai_Tucson_Hybrid.jpg/1280px-2022_Hyundai_Tucson_Hybrid.jpg'),
        W('0/00/2022_Hyundai_Tucson_SEL_with_HTRAC_All_Wheel_Drive.jpg/1280px-2022_Hyundai_Tucson_SEL_with_HTRAC_All_Wheel_Drive.jpg'),
      ],
      resumen: 'Estado correcto para su kilometraje. Puerta trasera con repintado.',
      observaciones: [
        { nivel: 'obs', texto: 'Puerta trasera derecha repintada (sin daño estructural).' },
        { nivel: 'obs', texto: 'Batería con 68 % de salud.' },
        { nivel: 'ok', texto: 'Suspensión y dirección sin holguras.' },
      ],
    },
    {
      id: 'mazda-cx5-2022',
      marca: 'Mazda', modelo: 'CX-5', version: '2.0 R 4x2 AT', anio: 2022,
      precio: 20990000, km: 36700, combustible: 'Bencina', transmision: 'Automática', traccion: '4x2',
      tipo: 'SUV', color: 'Gris Máquina', comuna: 'La Serena', vendedor: 'Automotora',
      score: 93, fechaInspeccion: '2026-10-25',
      fotos: [
        W('e/ec/2022_Mazda_CX-5_2.0_front.jpg/1280px-2022_Mazda_CX-5_2.0_front.jpg'),
        W('f/f5/2022_Mazda_CX-5_2.0_back.jpg/1280px-2022_Mazda_CX-5_2.0_back.jpg'),
        W('f/f8/Mazda_CX-5_%28KF%29_Facelift_1X7A0331_%282%29.jpg/1280px-Mazda_CX-5_%28KF%29_Facelift_1X7A0331_%282%29.jpg'),
      ],
      resumen: 'Excelente mantención. Interior cuidado, sin olores ni desgaste.',
      observaciones: [
        { nivel: 'ok', texto: 'Historial de mantenciones completo con timbres.' },
        { nivel: 'obs', texto: 'Plumillas limpiaparabrisas gastadas.' },
      ],
    },
    {
      id: 'mitsubishi-l200-2020',
      marca: 'Mitsubishi', modelo: 'L200', version: '2.4 Katana CRT 4x4 MT', anio: 2020,
      precio: 17990000, km: 78400, combustible: 'Diésel', transmision: 'Manual', traccion: '4x4',
      tipo: 'Camioneta', color: 'Blanco', comuna: 'Coquimbo', vendedor: 'Particular',
      score: 82, fechaInspeccion: '2026-10-18',
      fotos: [
        W('a/a2/Mitsubishi_L200_%2850740742278%29.jpg/1280px-Mitsubishi_L200_%2850740742278%29.jpg'),
        W('f/f3/Mitsubishi_L200_Crew_Cab_Gapsa.jpg/1280px-Mitsubishi_L200_Crew_Cab_Gapsa.jpg'),
      ],
      resumen: 'Camioneta de trabajo con uso acorde. Mecánica sana, detalles por desgaste.',
      observaciones: [
        { nivel: 'fail', texto: 'Embrague con patinaje leve: cambio recomendado (~$450.000).' },
        { nivel: 'obs', texto: 'Pisadera derecha con golpe.' },
        { nivel: 'ok', texto: 'Caja de transferencia 4x4 funcionando correctamente.' },
      ],
    },
    {
      id: 'suzuki-swift-2021',
      marca: 'Suzuki', modelo: 'Swift', version: '1.2 GLX MT', anio: 2021,
      precio: 9490000, km: 45300, combustible: 'Bencina', transmision: 'Manual', traccion: '4x2',
      tipo: 'Hatchback', color: 'Rojo', comuna: 'La Serena', vendedor: 'Particular',
      score: 90, fechaInspeccion: '2026-11-01',
      fotos: [
        W('7/74/2021_Suzuki_Swift_GLX.jpg/1280px-2021_Suzuki_Swift_GLX.jpg'),
        W('a/a2/2021_Suzuki_Swift_GLX_%28Rear%29.jpg/1280px-2021_Suzuki_Swift_GLX_%28Rear%29.jpg'),
        W('d/d3/2021_Suzuki_Swift_Hybrid_Interior.jpg/1280px-2021_Suzuki_Swift_Hybrid_Interior.jpg'),
      ],
      resumen: 'Ideal como primer auto. Económico y en muy buen estado.',
      observaciones: [
        { nivel: 'ok', texto: 'Sin códigos de falla. Consumo dentro de lo esperado.' },
        { nivel: 'obs', texto: 'Tapiz del asiento conductor con desgaste leve.' },
      ],
    },
    {
      id: 'chevrolet-tracker-2021',
      marca: 'Chevrolet', modelo: 'Tracker', version: '1.2 Turbo LT AT', anio: 2021,
      precio: 13990000, km: 52100, combustible: 'Bencina', transmision: 'Automática', traccion: '4x2',
      tipo: 'SUV', color: 'Blanco', comuna: 'Coquimbo', vendedor: 'Automotora',
      score: 86, fechaInspeccion: '2026-10-27',
      fotos: [
        W('9/90/Chevrolet_Tracker_003.jpg/1280px-Chevrolet_Tracker_003.jpg'),
        W('5/54/Chevrolet_Tracker_004.jpg/1280px-Chevrolet_Tracker_004.jpg'),
      ],
      resumen: 'Buen estado general, mantención de 50.000 km recién realizada.',
      observaciones: [
        { nivel: 'obs', texto: 'Amortiguadores delanteros con desgaste moderado.' },
        { nivel: 'ok', texto: 'Mantención de 50.000 km realizada con boleta.' },
      ],
    },
  ];

  /* Plantilla del checklist de inspección (resumen de 150 puntos) */
  const CHECKLIST = [
    { cat: 'Carrocería y pintura', icon: 'car', items: ['Medición de espesor de pintura (12 piezas)', 'Alineación de paneles y luces', 'Golpes, abolladuras y rayones', 'Corrosión y óxido', 'Parabrisas y vidrios', 'Ópticas y focos'] },
    { cat: 'Estructura y chasis', icon: 'shield', items: ['Largueros y travesaños', 'Pilares A/B/C', 'Puntos de soldadura de fábrica', 'Piso y maleta', 'Evidencia de choque estructural'] },
    { cat: 'Motor', icon: 'engine', items: ['Fugas de aceite y refrigerante', 'Estado de correas', 'Ruidos anormales en frío y caliente', 'Humo de escape', 'Soportes de motor', 'Nivel y estado de fluidos'] },
    { cat: 'Escáner electrónico', icon: 'scan', items: ['Códigos de falla activos', 'Códigos históricos', 'Módulos ABS / Airbag', 'Kilometraje en módulos vs. tablero', 'Salud de batería y alternador'] },
    { cat: 'Transmisión y tracción', icon: 'gear', items: ['Cambios de marcha', 'Embrague / convertidor', 'Tracción 4x4 / reductora', 'Homocinéticas y cardán'] },
    { cat: 'Suspensión, dirección y frenos', icon: 'disc', items: ['Amortiguadores', 'Bujes y rótulas', 'Juego de dirección', 'Discos y pastillas', 'Neumáticos y aros'] },
    { cat: 'Interior y equipamiento', icon: 'seat', items: ['Tablero y testigos', 'Aire acondicionado / climatizador', 'Alzavidrios y cierre centralizado', 'Multimedia y cámaras', 'Tapicería y olores'] },
    { cat: 'Documentación', icon: 'doc', items: ['Padrón y permiso de circulación', 'Revisión técnica vigente', 'Certificado de anotaciones (prendas)', 'Multas impagas', 'Historial de mantenciones'] },
  ];

  const PLANES = [
    { id: 'esencial', nombre: 'Esencial', precio: 39990, desc: 'Para autos de ciudad y hatchbacks.', incluye: ['Checklist de 90 puntos', 'Escáner OBD completo', 'Medición de pintura', 'Informe digital en 24 h'] },
    { id: 'completa', nombre: 'Completa', precio: 59990, desc: 'La más pedida. SUV, sedán y camionetas.', destacado: true, incluye: ['Checklist de 150 puntos', 'Escáner OBD + módulos', 'Medición de pintura y estructura', 'Prueba en ruta', 'Revisión de documentos', 'Informe con fotos y video'] },
    { id: 'premium', nombre: 'Premium 4x4', precio: 79990, desc: 'Camionetas 4x4, alta gama y vehículos de trabajo.', incluye: ['Todo lo de Completa', 'Revisión de tracción 4x4 y reductora', 'Inspección bajo carrocería en elevador', 'Asesoría de precio y negociación', 'Acompañamiento a la compra'] },
  ];

  const TESTIMONIOS = [
    { nombre: 'Camila R.', ciudad: 'La Serena', texto: 'Iba a comprar una SUV que se veía perfecta. Matías encontró que tenía un choque estructural. Me salvó de un error de millones.', auto: 'SUV 2019' },
    { nombre: 'Rodrigo P.', ciudad: 'Coquimbo', texto: 'La búsqueda personalizada fue increíble. Me encontraron una Hilux dentro de mi presupuesto y negociaron un mejor precio.', auto: 'Toyota Hilux 2021' },
    { nombre: 'Francisca M.', ciudad: 'Ovalle', texto: 'El informe es súper claro, con fotos y video. Fui a negociar con el vendedor con datos en la mano.', auto: 'Hatchback 2020' },
  ];

  window.ATLAS = { CARS, CHECKLIST, PLANES, TESTIMONIOS };
})();
