-- Pawtect | Colegios de Huancayo para el selector. Se puede ejecutar varias veces sin duplicar.
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
