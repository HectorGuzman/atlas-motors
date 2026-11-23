const test = require('node:test');
const assert = require('node:assert');
const H = require('../horario');

test('inicio respeta la hora de Chile (verano e invierno)', () => {
  // Noviembre: Chile en UTC-3. Julio: UTC-4.
  assert.strictEqual(new Date(H.inicio('2026-11-24', '09:00')).toISOString(), '2026-11-24T12:00:00.000Z');
  assert.strictEqual(new Date(H.inicio('2026-07-14', '09:00')).toISOString(), '2026-07-14T13:00:00.000Z');
  assert.deepStrictEqual(H.enChile(H.inicio('2026-11-24', '19:30')), { fecha: '2026-11-24', hora: '19:30' });
});

test('qué se puede reservar', () => {
  const ahora = H.inicio('2026-11-23', '10:00'); // lunes
  assert.strictEqual(H.motivoNoReservable('2026-11-24', '09:00', ahora), null);
  assert.match(H.motivoNoReservable('2026-11-29', '09:00', ahora), /domingos/); // domingo
  assert.match(H.motivoNoReservable('2026-11-23', '10:30', ahora), /pronto/); // parte en 30 min
  assert.strictEqual(H.motivoNoReservable('2026-11-23', '12:00', ahora), null); // en 2 h
  assert.match(H.motivoNoReservable('2026-11-24', '09:15', ahora), /no válida/);
  assert.match(H.motivoNoReservable('2026-02-30', '09:00', ahora), /no válida/);
  assert.match(H.motivoNoReservable('2027-03-01', '09:00', ahora), /dos meses/);
});

test('ocupada y vencimiento del abono', () => {
  const ahora = H.inicio('2026-11-23', '22:00');
  assert.strictEqual(H.ocupada(null, ahora), false);
  assert.strictEqual(H.ocupada({ e: 'b' }, ahora), true);
  assert.strictEqual(H.ocupada({ e: 'c' }, ahora), true);
  assert.strictEqual(H.ocupada({ e: 'p', v: ahora + 1 }, ahora), true);
  assert.strictEqual(H.ocupada({ e: 'p', v: ahora - 1 }, ahora), false);
  // El abono se espera 1 hora.
  assert.strictEqual(H.vence('2026-11-30', '09:00', ahora), ahora + 3600e3);
  // Nunca después de que empieza la inspección.
  assert.ok(H.vence('2026-11-24', '09:00', ahora) <= H.inicio('2026-11-24', '09:00'));
});
