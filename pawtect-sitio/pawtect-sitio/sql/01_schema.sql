-- Pawtect | Esquema para Neon (PostgreSQL). Ejecutar en el SQL Editor de Neon.
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS colegios (
  id       SERIAL PRIMARY KEY,
  nombre   VARCHAR(120) NOT NULL,
  distrito VARCHAR(60)  NOT NULL DEFAULT 'Huancayo'
);

CREATE TABLE IF NOT EXISTS usuarios (
  id         SERIAL PRIMARY KEY,
  colegio_id INT REFERENCES colegios(id),            -- NULL = administrador general
  nombre     VARCHAR(100) NOT NULL,
  email      VARCHAR(120) NOT NULL UNIQUE,
  clave_hash TEXT NOT NULL,                          -- crypt(clave, gen_salt('bf'))
  rol        VARCHAR(20) NOT NULL CHECK (rol IN ('responsable','psicologo','admin'))
);

CREATE TABLE IF NOT EXISTS solicitudes (
  id             SERIAL PRIMARY KEY,
  codigo         VARCHAR(12) NOT NULL UNIQUE,        -- código de seguimiento para el estudiante
  colegio_id     INT NOT NULL REFERENCES colegios(id),
  accesorio      VARCHAR(20) NOT NULL CHECK (accesorio IN ('pulsera','collar','peluche','llavero','otro')),
  tipo           VARCHAR(30) NOT NULL CHECK (tipo IN ('acoso_verbal','acoso_fisico','exclusion','ciberacoso','amenaza','bienestar_emocional','otro')),
  urgencia       VARCHAR(10) NOT NULL DEFAULT 'normal' CHECK (urgencia IN ('normal','alta','urgente')),
  descripcion    TEXT NOT NULL,
  anonimo        BOOLEAN NOT NULL DEFAULT TRUE,
  nombre_estudiante VARCHAR(100),                    -- solo si anonimo = FALSE
  grado          VARCHAR(30),
  avisar_padres  BOOLEAN NOT NULL DEFAULT FALSE,     -- lo decide el estudiante
  contacto_padres VARCHAR(30),
  estado         VARCHAR(20) NOT NULL DEFAULT 'recibida' CHECK (estado IN ('recibida','en_revision','en_mediacion','resuelta')),
  responsable_id INT REFERENCES usuarios(id),
  es_simulado    BOOLEAN NOT NULL DEFAULT FALSE,     -- TRUE = dato de prueba
  creado_en      TIMESTAMPTZ NOT NULL DEFAULT now(),
  actualizado_en TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS seguimientos (
  id           SERIAL PRIMARY KEY,
  solicitud_id INT NOT NULL REFERENCES solicitudes(id) ON DELETE CASCADE,
  usuario_id   INT REFERENCES usuarios(id),
  nota         TEXT NOT NULL,
  estado_nuevo VARCHAR(20) NOT NULL CHECK (estado_nuevo IN ('recibida','en_revision','en_mediacion','resuelta')),
  publico      BOOLEAN NOT NULL DEFAULT FALSE,       -- TRUE = lo ve el estudiante con su código
  creado_en    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_solicitudes_colegio_estado ON solicitudes (colegio_id, estado);
CREATE INDEX IF NOT EXISTS idx_seguimientos_solicitud ON seguimientos (solicitud_id);
