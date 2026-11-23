// Horario de Matías: lunes a sábado, inspecciones de 45 min + 45 min de traslado,
// desde las 9:00. La última parte a las 19:30 y termina a las 20:15.
// La app (mobile/lib/agenda.dart) y la web (assets/js/app.js) usan las mismas horas.
const HORAS = ['09:00', '10:30', '12:00', '13:30', '15:00', '16:30', '18:00', '19:30'];
const DIAS_ADELANTE = 60; // hasta cuántos días hacia adelante se puede reservar
const MIN_ANTICIPACION_MS = 2 * 3600e3; // no se reserva una hora que parte en menos de 2 h
const ESPERA_ABONO_MS = 3600e3; // una reserva sin abono se libera a la hora
const ZONA = 'America/Santiago';

const partes = new Intl.DateTimeFormat('en-CA', {
  timeZone: ZONA, year: 'numeric', month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit', hour12: false,
});

/** Fecha y hora de Chile para un instante: { fecha: 'AAAA-MM-DD', hora: 'HH:MM' }. */
function enChile(ms) {
  const p = Object.fromEntries(partes.formatToParts(new Date(ms)).map((x) => [x.type, x.value]));
  return { fecha: `${p.year}-${p.month}-${p.day}`, hora: `${p.hour === '24' ? '00' : p.hour}:${p.minute}` };
}

/** Instante (ms) en que parte la hora `hora` del día `fecha`, en horario de Chile. */
function inicio(fecha, hora) {
  const [y, m, d] = fecha.split('-').map(Number);
  const [h, mi] = hora.split(':').map(Number);
  const supuesto = Date.UTC(y, m - 1, d, h, mi);
  // Diferencia entre la hora de Chile y UTC en ese momento (cambia con el horario de verano).
  const c = enChile(supuesto);
  const [cy, cm, cd] = c.fecha.split('-').map(Number);
  const [ch, cmi] = c.hora.split(':').map(Number);
  const desfase = Date.UTC(cy, cm - 1, cd, ch, cmi) - supuesto;
  return supuesto - desfase;
}

function fechaValida(fecha) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(fecha)) return false;
  const [y, m, d] = fecha.split('-').map(Number);
  const dt = new Date(Date.UTC(y, m - 1, d));
  return dt.getUTCFullYear() === y && dt.getUTCMonth() === m - 1 && dt.getUTCDate() === d;
}

function diaHabil(fecha) {
  const [y, m, d] = fecha.split('-').map(Number);
  return new Date(Date.UTC(y, m - 1, d)).getUTCDay() !== 0; // domingo no
}

/** Por qué no se puede reservar esa hora, o null si se puede. */
function motivoNoReservable(fecha, hora, ahora) {
  if (!fechaValida(fecha) || !HORAS.includes(hora)) return 'Hora no válida.';
  if (!diaHabil(fecha)) return 'Los domingos no atendemos.';
  const parte = inicio(fecha, hora);
  if (parte - ahora < MIN_ANTICIPACION_MS) return 'Esa hora ya pasó o es muy pronto. Elige otra.';
  if (parte - ahora > (DIAS_ADELANTE + 1) * 86400e3) return 'Solo se puede reservar hasta dos meses adelante.';
  return null;
}

/** Una hora de la agenda está tomada si está confirmada, bloqueada o pendiente sin vencer. */
function ocupada(celda, ahora) {
  if (!celda) return false;
  if (celda.e === 'p') return typeof celda.v === 'number' && celda.v > ahora;
  return celda.e === 'c' || celda.e === 'b';
}

/** Hasta cuándo se guarda una reserva sin abono: 1 hora (siempre antes de que empiece: se reserva con 2 h). */
function vence(fecha, hora, ahora) {
  return Math.min(ahora + ESPERA_ABONO_MS, inicio(fecha, hora));
}

module.exports = { HORAS, DIAS_ADELANTE, ESPERA_ABONO_MS, enChile, inicio, fechaValida, diaHabil, motivoNoReservable, ocupada, vence };
