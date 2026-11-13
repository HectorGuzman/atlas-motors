/* Datos del sitio de Atlas Motors. */
(function () {
  const W = (path) => `https://upload.wikimedia.org/wikipedia/commons/thumb/${path}`;

  /* Auto del informe de ejemplo (fotos de Wikimedia Commons, solo de referencia).
     El marketplace real vendrá desde la app de inspecciones. */
  const CARS = [
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
  ];

  /* Checklist en el orden en que Matías recorre el vehículo (igual que la app de inspecciones) */
  const CHECKLIST = [
    { cat: 'Carrocería y pintura', icon: 'car', items: ['Inspección visual 360°', 'Espesor de pintura pieza por pieza', 'Alineación de paneles', 'Óxido', 'Parabrisas y vidrios', 'Ópticas y focos'] },
    { cat: 'Estructura y chasis', icon: 'shield', items: ['Bisagras, pernos y sellos de puertas, capó y maletero', 'Largueros, pilares y piso', 'Chasis: soldaduras y choques'] },
    { cat: 'Motor', icon: 'engine', items: ['Refrigerante: medición, nivel y depósito', 'Correas', 'Fugas en motor', 'Cableado', 'Líquido de frenos e hidráulico', 'Nivel de aceite y tapa de aceite', 'Señales de sobrecalentamiento'] },
    { cat: 'Parte baja y suspensión', icon: 'disc', items: ['Fugas por debajo', 'Palieres', 'Bandejas y bujes', 'Fuelles', 'Cremallera de dirección', 'Amortiguadores delanteros y traseros', 'Neumáticos'] },
    { cat: 'Interior y electricidad', icon: 'seat', items: ['Cinturones y asientos', 'Alzavidrios, espejos y cierre', 'Radio y comandos al volante', 'Parasoles y techo', 'Aire acondicionado', 'Luces e intermitentes', 'Testigos del tablero'] },
    { cat: 'Escáner', icon: 'scan', items: ['Códigos de falla en todos los módulos', 'Kilometraje real', 'Parámetros en vivo', 'Caja automática: temperatura y nivel', 'Batería y carga'] },
    { cat: 'Prueba de ruta', icon: 'gauge', items: ['Ruidos de motor', 'Respuesta del motor', 'Embrague y cambios', 'Tren delantero y trasero', 'Frenado y dirección', 'Tracción 4x4 (si aplica)'] },
    { cat: 'Documentos', icon: 'doc', items: ['Permiso de circulación', 'Revisión técnica', 'Seguro obligatorio (SOAP)', 'Historial de mantenciones'] },
  ];

  /* Precio actual del servicio: $50.000, con 50 % de abono para reservar. */
  const ABONO = 0.5;
  const PLANES = [
    { id: 'completa', nombre: 'Completa', precio: 50000, desc: 'Autos, SUV y camionetas. Bencina, diésel y alta gama.', incluye: ['Recorrido completo en 8 etapas', 'Medición de pintura pieza por pieza', 'Escáner con parámetros en vivo', 'Prueba de ruta', 'Costo estimado de las reparaciones', 'Informe PDF con fotos', 'Disponible en modalidad remota'] },
  ];

  window.ATLAS = { CARS, CHECKLIST, PLANES, ABONO };
})();
