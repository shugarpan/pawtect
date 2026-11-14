# Pawtect | Sitio de ayuda con Neon

## 1. Base de datos en Neon
1. Crea un proyecto en neon.tech y abre el **SQL Editor**.
2. Ejecuta `sql/01_schema.sql` y luego `sql/02_seed_simulado.sql` (datos de prueba, no reales).
3. En Neon copia la **connection string** (Connect > Pooled connection).

## 2. Publicar en Vercel
1. Sube esta carpeta a un repositorio de GitHub e impórtalo en vercel.com (o usa `npx vercel`).
2. En Settings > Environment Variables agrega `DATABASE_URL` (la de Neon) y `JWT_SECRET` (una cadena larga aleatoria).
3. Despliega. La dirección del sitio es la que va dentro del QR de los accesorios.
Prueba local: `npm install` y `npx vercel dev` (con un archivo `.env` basado en `.env.example`).

## 3. Cuentas de prueba (clave: demo1234)
- admin@pawtect.demo (ve todos los colegios)
- responsable1@pawtect.demo y psicologo1@pawtect.demo (I.E. Demo N.° 1)
- responsable2@pawtect.demo (I.E. Demo N.° 2)
Códigos para "Ver mi caso": PW-DEMO01 a PW-DEMO16.

## 4. Antes de usarlo con estudiantes reales
- Borra los datos de prueba: `DELETE FROM solicitudes WHERE es_simulado;` y cambia o elimina las cuentas demo.
- Los datos son de menores de edad: acuerda con el colegio quién puede ver los casos y cómo se protegen (la ley peruana de protección de datos personales aplica).
