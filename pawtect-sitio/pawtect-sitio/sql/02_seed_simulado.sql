-- Pawtect | Datos de SIMULACIÓN (no reales) para probar el sitio. Ejecutar después del esquema, en una base nueva.
-- Todas las cuentas de prueba usan la clave: demo1234

INSERT INTO colegios (nombre) VALUES
  ('I.E. Demo N.° 1 (simulada)'),
  ('I.E. Demo N.° 2 (simulada)');

-- Colegios reales de Huancayo (se muestran en el selector del sitio)
INSERT INTO colegios (nombre, distrito)
SELECT v.n, 'Huancayo' FROM (VALUES
  ('Colegio Emblemático Santa Isabel'),
  ('Colegio Nuestra Señora de Cocharcas'),
  ('Colegio María Inmaculada'),
  ('I.E. 30001 Santa Rosa de Lima'),
  ('I.E. 30003 Pedro R. Díaz Huamán'),
  ('I.E. 30005 San Francisco de Asís'),
  ('I.E. 30059 Rosa de América')
) AS v(n)
WHERE NOT EXISTS (SELECT 1 FROM colegios c WHERE c.nombre = v.n);

INSERT INTO usuarios (colegio_id, nombre, email, clave_hash, rol) VALUES
  (NULL, 'Admin Demo',          'admin@pawtect.demo',        crypt('demo1234', gen_salt('bf')), 'admin'),
  (1,    'Responsable Demo 1',  'responsable1@pawtect.demo', crypt('demo1234', gen_salt('bf')), 'responsable'),
  (1,    'Psicóloga Demo 1',    'psicologo1@pawtect.demo',   crypt('demo1234', gen_salt('bf')), 'psicologo'),
  (2,    'Responsable Demo 2',  'responsable2@pawtect.demo', crypt('demo1234', gen_salt('bf')), 'responsable');

INSERT INTO solicitudes (codigo, colegio_id, accesorio, tipo, urgencia, descripcion, anonimo, nombre_estudiante, grado, avisar_padres, contacto_padres, estado, es_simulado, creado_en) VALUES
 ('PW-DEMO01',1,'pulsera','acoso_verbal','normal','Un grupo se burla de mi apodo en el salón y ya no quiero participar en clase.',TRUE,NULL,'2.° sec.',FALSE,NULL,'en_revision',TRUE, now()-interval '9 days'),
 ('PW-DEMO02',2,'llavero','acoso_fisico','alta','Me empujan en el pasillo a la salida de educación física casi todos los días.',TRUE,NULL,'1.° sec.',FALSE,NULL,'en_mediacion',TRUE, now()-interval '12 days'),
 ('PW-DEMO03',1,'peluche','exclusion','normal','Nadie me deja sentarme con ellos en el recreo desde hace semanas.',FALSE,'Estudiante Demo A','3.° sec.',TRUE,'999000001','recibida',TRUE, now()-interval '1 day'),
 ('PW-DEMO04',2,'collar','ciberacoso','alta','Subieron una foto mía a un chat del salón con burlas.',TRUE,NULL,'4.° sec.',FALSE,NULL,'en_revision',TRUE, now()-interval '4 days'),
 ('PW-DEMO05',1,'llavero','amenaza','urgente','Un compañero me dijo que me va a esperar a la salida para pegarme.',TRUE,NULL,'2.° sec.',FALSE,NULL,'en_revision',TRUE, now()-interval '2 days'),
 ('PW-DEMO06',2,'pulsera','bienestar_emocional','urgente','Me siento muy triste y sin ganas de venir al colegio desde hace mucho.',FALSE,'Estudiante Demo B','5.° sec.',TRUE,'999000002','en_revision',TRUE, now()-interval '3 days'),
 ('PW-DEMO07',1,'peluche','otro','normal','Me quitan mi dinero del recreo y se ríen.',TRUE,NULL,'1.° sec.',FALSE,NULL,'recibida',TRUE, now()-interval '2 hours'),
 ('PW-DEMO08',2,'collar','acoso_verbal','normal','Imitan mi forma de hablar y todos se ríen cuando respondo.',TRUE,NULL,'3.° sec.',FALSE,NULL,'resuelta',TRUE, now()-interval '25 days'),
 ('PW-DEMO09',1,'pulsera','ciberacoso','normal','Me insultan por mensajes en el grupo de WhatsApp del aula.',FALSE,'Estudiante Demo C','4.° sec.',FALSE,NULL,'en_mediacion',TRUE, now()-interval '8 days'),
 ('PW-DEMO10',2,'llavero','otro','normal','Vi que escondían la mochila de un compañero para molestarlo y quiero avisar.',TRUE,NULL,'2.° sec.',FALSE,NULL,'recibida',TRUE, now()-interval '5 hours'),
 ('PW-DEMO11',1,'llavero','acoso_fisico','urgente','Me golpearon en el baño y me da miedo ir solo.',TRUE,NULL,'1.° sec.',FALSE,NULL,'en_mediacion',TRUE, now()-interval '6 days'),
 ('PW-DEMO12',2,'peluche','acoso_verbal','alta','Dicen cosas de mi familia para hacerme sentir mal.',TRUE,NULL,'3.° sec.',FALSE,NULL,'recibida',TRUE, now()-interval '1 day 3 hours'),
 ('PW-DEMO13',1,'pulsera','exclusion','normal','Me dejaron de hablar en el grupo del equipo de vóley sin motivo.',TRUE,NULL,'5.° sec.',FALSE,NULL,'resuelta',TRUE, now()-interval '30 days'),
 ('PW-DEMO14',2,'collar','amenaza','alta','Me amenazan con publicar algo mío si no hago su tarea.',TRUE,NULL,'4.° sec.',FALSE,NULL,'recibida',TRUE, now()-interval '20 hours'),
 ('PW-DEMO15',1,'peluche','acoso_verbal','normal','Me insultan por mi forma de vestir.',FALSE,'Estudiante Demo D','2.° sec.',TRUE,'999000003','resuelta',TRUE, now()-interval '18 days'),
 ('PW-DEMO16',2,'llavero','bienestar_emocional','alta','Una compañera llora todos los días en el recreo y nadie la ayuda.',TRUE,NULL,'3.° sec.',FALSE,NULL,'en_revision',TRUE, now()-interval '7 days');

-- Responsable asignado a los casos ya atendidos
UPDATE solicitudes s SET responsable_id = (SELECT u.id FROM usuarios u WHERE u.colegio_id = s.colegio_id AND u.rol = 'responsable' LIMIT 1)
WHERE s.es_simulado AND s.estado <> 'recibida';

-- Historial de seguimiento (publico = TRUE se muestra al estudiante)
INSERT INTO seguimientos (solicitud_id, usuario_id, nota, estado_nuevo, publico, creado_en)
SELECT s.id, s.responsable_id, v.nota, v.estado, v.publico, s.creado_en + interval '1 day'
FROM (VALUES
 ('PW-DEMO01','Se conversó con la tutora del aula y se observó el recreo.','en_revision',TRUE),
 ('PW-DEMO02','Se citó a los estudiantes involucrados para una mediación.','en_mediacion',TRUE),
 ('PW-DEMO04','Se pidió guardar las capturas y se contactó a la familia.','en_revision',FALSE),
 ('PW-DEMO05','Caso priorizado: se reforzó la vigilancia en la salida.','en_revision',TRUE),
 ('PW-DEMO06','Derivado a psicología para una cita esta semana.','en_revision',TRUE),
 ('PW-DEMO08','Se mediaron las partes y se acordaron compromisos.','resuelta',TRUE),
 ('PW-DEMO09','Se habló con el aula sobre el uso respetuoso del grupo.','en_mediacion',TRUE),
 ('PW-DEMO11','Se activó el protocolo y se citó a los padres.','en_mediacion',FALSE),
 ('PW-DEMO13','Se reintegró a la estudiante al equipo con apoyo de la tutora.','resuelta',TRUE),
 ('PW-DEMO15','Se hizo una charla de respeto en el aula. Caso cerrado.','resuelta',TRUE),
 ('PW-DEMO16','Se acompañó a la compañera y se informó a psicología.','en_revision',TRUE)
) AS v(codigo, nota, estado, publico)
JOIN solicitudes s ON s.codigo = v.codigo;

UPDATE solicitudes s SET actualizado_en = s.creado_en + interval '1 day' WHERE s.es_simulado AND s.estado <> 'recibida';

-- Para borrar los datos de prueba antes de usar el sitio en serio:
-- DELETE FROM solicitudes WHERE es_simulado;
