// Pawtect | API única (funciones serverless de Vercel) conectada a Neon.
import { neon } from '@neondatabase/serverless';
import crypto from 'node:crypto';

// OJO: la URL escrita aquí queda visible para quien vea el repositorio. Si defines DATABASE_URL en Vercel, esa tiene prioridad.
const DB_URL = process.env.DATABASE_URL || 'postgresql://neondb_owner:npg_jbt5pKVrvG3e@ep-crimson-math-beitddue-pooler.c-9.us-east-2.aws.neon.tech/neondb?sslmode=require&channel_binding=require';
const sql = neon(DB_URL);
const SECRET = process.env.JWT_SECRET || crypto.createHash('sha256').update(DB_URL).digest('hex');
const TIPOS = ['acoso_verbal','acoso_fisico','exclusion','ciberacoso','amenaza','bienestar_emocional','otro'];
const URG = ['normal','alta','urgente'];
const ACC = ['pulsera','collar','peluche','llavero','otro'];
const EST = ['recibida','en_revision','en_mediacion','resuelta'];

const b64 = (s) => Buffer.from(s).toString('base64url');
const firma = (d) => crypto.createHmac('sha256', SECRET).update(d).digest('base64url');
const crearToken = (u) => { const d = b64(JSON.stringify({ ...u, exp: Date.now() + 8 * 3600e3 })); return d + '.' + firma(d); };
function leerToken(req) {
  const [d, f] = (req.headers.authorization || '').replace('Bearer ', '').split('.');
  if (!SECRET || !d || !f) return null;
  const esp = Buffer.from(firma(d)), got = Buffer.from(f);
  if (esp.length !== got.length || !crypto.timingSafeEqual(esp, got)) return null;
  const u = JSON.parse(Buffer.from(d, 'base64url'));
  return u.exp > Date.now() ? u : null;
}
const A = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
const nuevoCodigo = () => 'PW-' + Array.from({ length: 6 }, () => A[crypto.randomInt(A.length)]).join('');
const txt = (v, max) => (typeof v === 'string' && v.trim() ? v.trim().slice(0, max) : null);

export default async function handler(req, res) {
  const op = req.query.op, b = req.body || {}, post = req.method === 'POST';
  try {
    if (op === 'colegios') return res.json(await sql`SELECT id, nombre FROM colegios ORDER BY nombre`);

    if (op === 'crear' && post) {
      const desc = txt(b.descripcion, 2000), colegio = parseInt(b.colegio_id, 10);
      if (!desc || desc.length < 10 || !colegio || !TIPOS.includes(b.tipo) || !URG.includes(b.urgencia) || !ACC.includes(b.accesorio))
        return res.status(400).json({ error: 'Revisa los datos: falta el colegio o la descripción es muy corta.' });
      const anonimo = b.anonimo !== false, avisar = b.avisar_padres === true;
      for (let i = 0; i < 5; i++) {
        const r = await sql`INSERT INTO solicitudes (codigo, colegio_id, accesorio, tipo, urgencia, descripcion, anonimo, nombre_estudiante, grado, avisar_padres, contacto_padres)
          VALUES (${nuevoCodigo()}, ${colegio}, ${b.accesorio}, ${b.tipo}, ${b.urgencia}, ${desc}, ${anonimo},
                  ${anonimo ? null : txt(b.nombre, 100)}, ${txt(b.grado, 30)}, ${avisar}, ${avisar ? txt(b.contacto_padres, 30) : null})
          ON CONFLICT (codigo) DO NOTHING RETURNING codigo`;
        if (r.length) return res.status(201).json({ codigo: r[0].codigo });
      }
      return res.status(500).json({ error: 'No se pudo generar el código. Intenta de nuevo.' });
    }

    if (op === 'consultar') {
      const codigo = String(req.query.codigo || '').trim().toUpperCase();
      const c = await sql`SELECT id, estado, creado_en, actualizado_en FROM solicitudes WHERE codigo = ${codigo}`;
      if (!c.length) return res.status(404).json({ error: 'No encontramos ese código.' });
      const notas = await sql`SELECT nota, estado_nuevo, creado_en FROM seguimientos WHERE solicitud_id = ${c[0].id} AND publico ORDER BY creado_en`;
      return res.json({ estado: c[0].estado, creado_en: c[0].creado_en, actualizado_en: c[0].actualizado_en, notas });
    }

    if (op === 'login' && post) {
      const email = String(b.email || '').trim().toLowerCase();
      const r = await sql`SELECT id, nombre, rol, colegio_id FROM usuarios WHERE email = ${email} AND clave_hash = crypt(${String(b.clave || '')}, clave_hash)`;
      if (!r.length) return res.status(401).json({ error: 'Correo o clave incorrectos.' });
      return res.json({ token: crearToken(r[0]), usuario: r[0] });
    }

    const u = leerToken(req);
    if (!u) return res.status(401).json({ error: 'Sesión no válida. Inicia sesión de nuevo.' });

    if (op === 'casos') {
      return res.json(await sql`SELECT s.id, s.codigo, s.tipo, s.urgencia, s.estado, s.accesorio, s.anonimo, s.es_simulado, s.creado_en, c.nombre AS colegio
        FROM solicitudes s JOIN colegios c ON c.id = s.colegio_id
        WHERE (${u.colegio_id}::int IS NULL OR s.colegio_id = ${u.colegio_id}::int)
        ORDER BY (s.estado = 'resuelta'), CASE s.urgencia WHEN 'urgente' THEN 0 WHEN 'alta' THEN 1 ELSE 2 END, s.creado_en DESC`);
    }

    if (op === 'caso') {
      const id = parseInt(req.query.id, 10);
      const c = await sql`SELECT s.*, c.nombre AS colegio FROM solicitudes s JOIN colegios c ON c.id = s.colegio_id
        WHERE s.id = ${id} AND (${u.colegio_id}::int IS NULL OR s.colegio_id = ${u.colegio_id}::int)`;
      if (!c.length) return res.status(404).json({ error: 'Caso no encontrado.' });
      const seg = await sql`SELECT g.nota, g.estado_nuevo, g.publico, g.creado_en, us.nombre AS autor
        FROM seguimientos g LEFT JOIN usuarios us ON us.id = g.usuario_id WHERE g.solicitud_id = ${id} ORDER BY g.creado_en`;
      return res.json({ caso: c[0], seguimientos: seg });
    }

    if (op === 'actualizar' && post) {
      const id = parseInt(b.id, 10), nota = txt(b.nota, 1000);
      if (!EST.includes(b.estado) || !nota) return res.status(400).json({ error: 'Elige un estado y escribe una nota.' });
      const c = await sql`SELECT id FROM solicitudes WHERE id = ${id} AND (${u.colegio_id}::int IS NULL OR colegio_id = ${u.colegio_id}::int)`;
      if (!c.length) return res.status(404).json({ error: 'Caso no encontrado.' });
      await sql.transaction([
        sql`UPDATE solicitudes SET estado = ${b.estado}, responsable_id = COALESCE(responsable_id, ${u.id}), actualizado_en = now() WHERE id = ${id}`,
        sql`INSERT INTO seguimientos (solicitud_id, usuario_id, nota, estado_nuevo, publico) VALUES (${id}, ${u.id}, ${nota}, ${b.estado}, ${b.publico === true})`,
      ]);
      return res.json({ ok: true });
    }

    if (op === 'cambiar_clave' && post) {
      const nueva = String(b.nueva || '');
      if (nueva.length < 8) return res.status(400).json({ error: 'La nueva clave debe tener al menos 8 caracteres.' });
      const r = await sql`UPDATE usuarios SET clave_hash = crypt(${nueva}, gen_salt('bf')) WHERE id = ${u.id} AND clave_hash = crypt(${String(b.actual || '')}, clave_hash) RETURNING id`;
      return r.length ? res.json({ ok: true }) : res.status(400).json({ error: 'La clave actual no es correcta.' });
    }

    if (op === 'usuarios' || op === 'crear_usuario') {
      if (u.rol !== 'admin') return res.status(403).json({ error: 'Solo el administrador puede hacer esto.' });
      if (op === 'usuarios') return res.json(await sql`SELECT u.id, u.nombre, u.email, u.rol, c.nombre AS colegio FROM usuarios u LEFT JOIN colegios c ON c.id = u.colegio_id ORDER BY u.rol, u.nombre`);
      const email = String(b.email || '').trim().toLowerCase(), nombre = txt(b.nombre, 100), clave = String(b.clave || '');
      const colegio = b.colegio_id ? parseInt(b.colegio_id, 10) : null;
      if (!nombre || !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email) || !['responsable', 'psicologo', 'admin'].includes(b.rol) || clave.length < 8 || (b.rol !== 'admin' && !colegio))
        return res.status(400).json({ error: 'Completa nombre, correo válido, rol, colegio (si no es administrador) y una clave de 8 o más caracteres.' });
      const r = await sql`INSERT INTO usuarios (colegio_id, nombre, email, clave_hash, rol) VALUES (${b.rol === 'admin' ? null : colegio}, ${nombre}, ${email}, crypt(${clave}, gen_salt('bf')), ${b.rol}) ON CONFLICT (email) DO NOTHING RETURNING id`;
      return r.length ? res.status(201).json({ ok: true }) : res.status(409).json({ error: 'Ese correo ya tiene cuenta.' });
    }

    return res.status(404).json({ error: 'Operación no válida.' });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ error: 'Error del servidor.' });
  }
}
