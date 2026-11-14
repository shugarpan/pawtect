-- Pawtect | Crea TU cuenta de administrador. Edita el nombre, el correo y la clave y ejecútalo SOLO en el SQL Editor de Neon.
-- No subas este archivo a GitHub con tu clave escrita.
INSERT INTO usuarios (colegio_id, nombre, email, clave_hash, rol)
VALUES (NULL, 'TU NOMBRE', 'tucorreo@ejemplo.com', crypt('CAMBIA-ESTA-CLAVE', gen_salt('bf')), 'admin');

-- Cuando termines de probar, borra los datos y las cuentas de prueba (en este orden):
-- DELETE FROM solicitudes WHERE es_simulado;
-- DELETE FROM usuarios WHERE email LIKE '%@pawtect.demo';
